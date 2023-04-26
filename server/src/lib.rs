//! This crate is the library for polymny.

#![warn(missing_docs)]

#[macro_use]
extern crate rocket;

pub mod command;
pub mod config;
pub mod db;
pub mod log_fairing;
pub mod mailer;
pub mod routes;
pub mod templates;
pub mod websockets;

use std::error::Error as StdError;
use std::fmt;
use std::fs::OpenOptions;
use std::ops::Deref;
use std::path::Path;
use std::result::Result as StdResult;
use std::sync::Arc;

use lazy_static::lazy_static;

use serde::de;
use serde::{Deserialize, Deserializer, Serialize, Serializer};

use tokio::fs::remove_dir_all;
use tokio::sync::Semaphore;

use ergol::deadpool::managed::Object;
use ergol::tokio_postgres::Error as TpError;
use ergol::{tokio, Pool};

use rocket::fairing::AdHoc;
use rocket::http::Status;
use rocket::request::{FromParam, FromRequest, Outcome, Request};
use rocket::response::{self, Responder};
use rocket::shield::{NoSniff, Permission, Shield};
use rocket::{Ignite, Rocket, State};

use crate::command::run_command;
use crate::config::Config;
use crate::websockets::{websocket, WebSockets};

lazy_static! {
    /// The harsh encoder and decoder for capsule ids.
    pub static ref HARSH: Harsh = {
        let config = Config::from_figment(&rocket::Config::figment());
        let harsh = Harsh(
            harsh::Harsh::builder()
                .salt(config.harsh_secret)
                .length(config.harsh_length)
                .build()
                .unwrap(),
        );
        harsh
    };
}

/// The error type of this library.
#[derive(Debug)]
pub struct Error(pub Status);

/// The result type of this library
pub type Result<T> = StdResult<T, Error>;

impl<'r, 's: 'r> Responder<'r, 's> for Error {
    fn respond_to(self, request: &'r Request) -> response::Result<'s> {
        self.0.respond_to(request)
    }
}

impl fmt::Display for Error {
    fn fmt(&self, fmt: &mut fmt::Formatter) -> fmt::Result {
        write!(fmt, "errored with status {}", self.0)
    }
}

impl StdError for Error {}

macro_rules! impl_from_error {
    ( $from: ty) => {
        impl From<$from> for Error {
            fn from(_: $from) -> Error {
                Error(Status::InternalServerError)
            }
        }
    };
}

impl_from_error!(std::io::Error);
impl_from_error!(TpError);
impl_from_error!(bcrypt::BcryptError);
impl_from_error!(tungstenite::Error);
impl_from_error!(std::str::Utf8Error);
impl_from_error!(std::num::ParseIntError);

/// A wrapper for a database connection extrated from a pool.
pub struct Db(Object<ergol::pool::Manager>);

impl Db {
    /// Extracts a database from a pool.
    pub async fn from_pool(pool: Pool) -> Result<Db> {
        Ok(Db(pool
            .get()
            .await
            .map_err(|_| Error(Status::InternalServerError))?))
    }
}

impl std::ops::Deref for Db {
    type Target = Object<ergol::pool::Manager>;
    fn deref(&self) -> &Self::Target {
        &*&self.0
    }
}

#[rocket::async_trait]
impl<'r> FromRequest<'r> for Db {
    type Error = Error;

    async fn from_request(request: &'r Request<'_>) -> Outcome<Self, Self::Error> {
        let pool = match request.guard::<&State<Pool>>().await {
            Outcome::Success(pool) => pool,
            Outcome::Failure(_) => {
                return Outcome::Failure((
                    Status::InternalServerError,
                    Error(Status::InternalServerError),
                ))
            }
            Outcome::Forward(()) => return Outcome::Forward(()),
        };

        let db = match pool.get().await {
            Ok(db) => db,
            Err(_) => {
                return Outcome::Failure((
                    Status::InternalServerError,
                    Error(Status::InternalServerError),
                ))
            }
        };

        Outcome::Success(Db(db))
    }
}

/// Helper type to retrieve the accepted language from a request.
#[derive(Serialize, Deserialize)]
pub struct Lang(pub String);

#[rocket::async_trait]
impl<'r> FromRequest<'r> for Lang {
    type Error = Error;

    async fn from_request(request: &'r Request<'_>) -> Outcome<Self, Self::Error> {
        Outcome::Success(Lang(
            request
                .headers()
                .get("accept-language")
                .nth(0)
                .and_then(|x| x.split(",").nth(0))
                .and_then(|x| x.split(";").nth(0))
                .map(String::from)
                .unwrap_or_else(|| String::from("en-US")),
        ))
    }
}

/// Helper type for harsh.
pub struct Harsh(harsh::Harsh);

impl Harsh {
    /// Decodes a harsh id easily.
    pub fn decode<T: Into<String>>(&self, id: T) -> Result<i32> {
        Ok(*self
            .0
            .decode(id.into())
            .map_err(|_| Error(Status::NotFound))?
            .get(0)
            .ok_or(Error(Status::NotFound))? as i32)
    }

    /// Encodes an id.
    pub fn encode(&self, input: i32) -> String {
        self.0.encode(&[input as u64])
    }
}

/// A hash id that can be used in routes.
#[derive(Copy, Clone)]
pub struct HashId(pub i32);

impl HashId {
    /// Returns the hash id.
    pub fn hash(self) -> String {
        HARSH.encode(self.0)
    }

    /// Returns the hash id with a specific harsh code.
    ///
    /// This function is usefull when using polymny as a library, and running binaries outside from
    /// where the Rocket.toml is right.
    pub fn hash_with_secret(self, secret: &str, length: usize) -> Result<String> {
        let harsh = harsh::Harsh::builder()
            .salt(secret)
            .length(length)
            .build()
            .map_err(|_| Error(Status::InternalServerError))?;
        Ok(harsh.encode(&[self.0 as u64]))
    }
}

impl Serialize for HashId {
    fn serialize<S>(&self, serializer: S) -> StdResult<S::Ok, S::Error>
    where
        S: Serializer,
    {
        serializer.serialize_str(&HARSH.encode(self.0))
    }
}

impl<'de> Deserialize<'de> for HashId {
    fn deserialize<D>(deserializer: D) -> StdResult<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        let s = String::deserialize(deserializer)?;
        Ok(HashId(HARSH.decode(s).map_err(|_| {
            de::Error::custom("failed to decode hashid")
        })?))
    }
}

impl Deref for HashId {
    type Target = i32;
    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

impl<'a> FromParam<'a> for HashId {
    type Error = Error;
    fn from_param(param: &'a str) -> Result<Self> {
        Ok(HashId(HARSH.decode(param)?))
    }
}

/// Resets the database.
pub async fn reset_db() {
    let config = Config::from_figment(&rocket::Config::figment());
    let pool = ergol::pool(&config.databases.database.url, 32).unwrap();
    let db = Db::from_pool(pool).await.unwrap();

    remove_dir_all(&config.data_path).await.ok();

    ergol_cli::reset(".").await.unwrap();

    use crate::db::user::{Plan, User};

    let mut user = User::new(
        "Graydon",
        "graydon@example.com",
        "hashed",
        true,
        &None,
        &db,
        &config,
    )
    .await
    .unwrap();

    user.plan = Plan::Admin;
    user.save(&db).await.unwrap();

    User::new(
        "Evan",
        "evan@example.com",
        "hashed",
        true,
        &None,
        &db,
        &config,
    )
    .await
    .unwrap();
}

/// Calculate disk usage for each user.
pub async fn user_disk_usage() {
    let config = Config::from_figment(&rocket::Config::figment());
    let pool = ergol::pool(&config.databases.database.url, 32).unwrap();
    let db = Db::from_pool(pool).await.unwrap();

    use crate::db::capsule::Capsule;
    use crate::db::user::Plan;
    use ergol::prelude::*;

    for mut capsule in Capsule::select().execute(&db).await.unwrap() {
        let owner = capsule.owner(&db).await.unwrap();

        // Skip capsule if it is stored on the other host.
        if config.other_host.is_some() && (owner.plan >= Plan::PremiumLvl1) != config.premium_only {
            continue;
        }

        let path = &config.data_path.join(format!("{}", capsule.id));

        let output = run_command(&vec!["../scripts/psh", "du", path.to_str().unwrap()]);
        match &output {
            Ok(o) => {
                for line in std::str::from_utf8(&o.stdout)
                    .map_err(|_| Error(Status::InternalServerError))
                    .unwrap()
                    .lines()
                {
                    let du = line.parse::<i32>().unwrap();
                    if du != capsule.disk_usage {
                        capsule.disk_usage = du;
                        capsule.save(&db).await.unwrap();
                    }
                }
            }
            Err(_) => println!("error"),
        };
    }
}

/// update duration of all capsules
pub async fn update_video_duration() {
    let config = Config::from_figment(&rocket::Config::figment());
    let pool = ergol::pool(&config.databases.database.url, 32).unwrap();
    let db = Db::from_pool(pool).await.unwrap();

    use crate::db::capsule::Capsule;
    use ergol::prelude::*;

    let capsules = Capsule::select().execute(&db).await.unwrap();
    for mut capsule in capsules {
        let path = &config
            .data_path
            .join(format!("{}", capsule.id))
            .join("output.mp4");
        if Path::new(path).exists() {
            let output = run_command(&vec!["../scripts/psh", "duration", path.to_str().unwrap()]);

            match &output {
                Ok(o) => {
                    let line = ((std::str::from_utf8(&o.stdout)
                        .map_err(|_| Error(Status::InternalServerError))
                        .unwrap()
                        .trim()
                        .parse::<f32>()
                        .unwrap())
                        * 1000.) as i32;

                    capsule.duration_ms = line;
                    capsule.save(&db).await.ok();

                    println!(
                        " capsule {:4} {:9.1} s",
                        capsule.id,
                        capsule.duration_ms as f32 / 1000.0
                    );
                }
                Err(_) => error!("Impossible to get duration"),
            };
        }
    }
}

/// Starts the rocket server.
pub async fn rocket() -> StdResult<Rocket<Ignite>, rocket::Error> {
    let figment = rocket::Config::figment();
    let config = Config::from_figment(&figment);

    let rocket = if figment.profile() == "release" {
        use simplelog::*;

        let mut log_config = ConfigBuilder::new();
        log_config.set_max_level(LevelFilter::Off);
        log_config.set_time_level(LevelFilter::Off);
        let log_config = log_config.build();

        let file = OpenOptions::new()
            .append(true)
            .create(true)
            .open(&config.log_path)
            .unwrap();

        let module = vec![String::from(module_path!())];

        WriteLogger::init(LevelFilter::Info, log_config, file, module).unwrap();

        rocket::build().attach(log_fairing::Log::fairing())
    } else {
        rocket::build()
    };

    let shield = Shield::new()
        .enable(NoSniff::default())
        .enable(Permission::default());

    let rocket = rocket
        .attach(shield)
        .attach(AdHoc::on_ignite("Config", |rocket| async move {
            let config = Config::from_rocket(&rocket);
            rocket.manage(config)
        }))
        .attach(AdHoc::on_ignite("Database", |rocket| async move {
            let config = Config::from_rocket(&rocket);
            let pool = ergol::pool(&config.databases.database.url, 32).unwrap();
            rocket.manage(pool)
        }))
        .attach(AdHoc::on_ignite("WebSockets", |rocket| async move {
            rocket.manage(WebSockets::new())
        }))
        .attach(AdHoc::on_ignite("Semaphore", |rocket| async move {
            let config = config::Config::from_rocket(&rocket);
            rocket.manage(Arc::new(Semaphore::new(config.concurrent_tasks)))
        }))
        .mount(
            "/",
            routes![
                routes::user::login_external_cors,
                routes::user::login_external,
                routes::index_cors,
                routes::index,
                routes::preparation,
                routes::acquisition,
                routes::production,
                routes::publication,
                routes::options,
                routes::profile,
                routes::admin_dashboard,
                routes::admin_user,
                routes::admin_users,
                routes::admin_capsules,
                routes::capsule_settings,
                routes::user::activate,
                routes::user::unsubscribe,
                routes::user::reset_password,
                routes::user::validate_email,
                routes::user::validate_invitation,
                routes::watch::watch,
                routes::watch::watch_asset,
                routes::watch::polymny_video,
            ],
        )
        .mount(
            "/o/",
            routes![
                routes::index,
                routes::preparation,
                routes::acquisition,
                routes::production,
                routes::publication,
                routes::options,
                routes::profile,
                routes::admin_dashboard,
                routes::admin_user,
                routes::admin_users,
                routes::admin_capsules,
                routes::capsule_settings,
                // routes::user::reset_password,
                // routes::user::validate_email,
                // routes::user::validate_invitation,
            ],
        )
        .mount("/dist", routes![routes::dist])
        .mount(
            "/data",
            routes![routes::assets, routes::tmp, routes::produced_video],
        )
        .mount(
            "/api",
            if config.registration_disabled {
                routes![]
            } else {
                routes![routes::user::new_user_cors, routes::user::new_user,]
            },
        )
        .mount(
            "/api",
            routes![
                routes::user::login,
                routes::user::login_cors,
                routes::user::logout,
                routes::user::delete,
                routes::user::request_new_password,
                routes::user::request_new_password_cors,
                routes::user::change_password,
                routes::user::request_change_email,
                routes::user::request_invitation,
                routes::capsule::get_capsule,
                routes::capsule::empty_capsule,
                routes::capsule::new_capsule,
                routes::capsule::edit_capsule,
                routes::capsule::delete_capsule,
                routes::capsule::delete_project,
                routes::capsule::upload_record,
                routes::capsule::delete_record,
                routes::capsule::upload_pointer,
                routes::capsule::replace_slide,
                routes::capsule::add_slide,
                routes::capsule::add_gos,
                routes::capsule::produce,
                routes::capsule::produce_gos,
                routes::capsule::cancel_production,
                routes::capsule::publish,
                routes::capsule::cancel_publication,
                routes::capsule::unpublish,
                routes::capsule::cancel_video_upload,
                routes::capsule::duplicate,
                routes::capsule::invite,
                routes::capsule::deinvite,
                routes::capsule::change_role,
                routes::capsule::leave,
                routes::capsule::sound_track,
                routes::notification::mark_as_read,
                routes::notification::delete,
                routes::admin::get_dashboard,
                routes::admin::get_users,
                routes::admin::get_search_users,
                routes::admin::get_user,
                routes::admin::get_capsules,
                routes::admin::get_search_capsules,
                routes::admin::request_invite_user,
                routes::admin::delete_user,
                routes::admin::clear_websockets,
            ],
        )
        .register("/", catchers![routes::not_found])
        .ignite()
        .await?;

    let socks = rocket.state::<WebSockets>().unwrap();
    let pool = rocket.state::<Pool>().unwrap();
    tokio::spawn(websocket(socks.clone(), pool.clone()));

    rocket.launch().await
}
