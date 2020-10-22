//! This crate contains all the functions and structs required for the server.

#![warn(missing_docs)]
#![feature(proc_macro_hygiene, decl_macro)]

#[macro_use]
extern crate log;
#[macro_use]
extern crate serde;
#[macro_use]
extern crate rocket;
#[macro_use]
extern crate rocket_contrib;
#[macro_use]
extern crate diesel;
#[macro_use]
extern crate diesel_derive_enum;

pub mod command;
pub mod config;
pub mod db;
pub mod log_fairing;
pub mod mailer;
pub mod routes;
pub mod templates;
pub mod webcam;

/// This module contains the database schema and is generated by diesel.
#[allow(missing_docs, unused_imports)]
pub mod schema;

use std::collections::HashMap;
use std::fs::OpenOptions;
use std::io::Cursor;
use std::net::{TcpListener, TcpStream};
use std::sync::{Arc, Mutex};
use std::{error, fmt, io, result, thread};

use tungstenite::protocol::WebSocket;
use tungstenite::server::accept;
use tungstenite::Message;

use bcrypt::BcryptError;

use diesel::pg::PgConnection;
use diesel::prelude::*;

use rocket::config::{Config as RConfig, Environment, RocketConfig};
use rocket::fairing::AdHoc;
use rocket::http::{ContentType, Status};
use rocket::request::Request;
use rocket::response::{self, Responder, Response};
use rocket::State;

use rocket_contrib::databases::diesel as rocket_diesel;
use rocket_contrib::serve::StaticFiles;

use crate::config::Config;
use crate::db::user::User;
use crate::log_fairing::Log;

macro_rules! impl_from_error {
    ($type: ty, $variant: path, $from: ty) => {
        impl From<$from> for $type {
            fn from(e: $from) -> $type {
                $variant(e)
            }
        }
    };
}

/// The different errors that can occur when processing a request.
#[derive(Debug)]
pub enum Error {
    /// Couldn't connect to the database.
    DatabaseConnectionError(diesel::ConnectionError),

    /// Error while running a database request.
    DatabaseRequestError(diesel::result::Error),

    /// A session key was received but there was no such session.
    SessionDoesNotExist,

    /// A user try to log in but typed the wrong username or password.
    AuthenticationFailed,

    /// An argument is missing in a form.
    MissingArgumentInForm(String),

    /// An error occured while computing some bcrypt hash.
    BcryptError(BcryptError),

    /// An I/O error occured.
    IoError(io::Error),

    /// An error occured while trying to create a mail.
    MailError(lettre_email::error::Error),

    /// An error occured while trying to send a mail.
    SendMailError(lettre::smtp::error::Error),

    /// Empty Database request
    DatabaseRequestEmptyError(String),

    /// Tried to access data that requires to be logged in.
    RequiresLogin,

    /// 404 Not Found.
    NotFound,

    /// ffmpeg Transcode Error
    TranscodeError,
}

impl_from_error!(
    Error,
    Error::DatabaseConnectionError,
    diesel::ConnectionError
);
impl_from_error!(Error, Error::DatabaseRequestError, diesel::result::Error);
impl_from_error!(Error, Error::BcryptError, BcryptError);
impl_from_error!(Error, Error::IoError, io::Error);
impl_from_error!(Error, Error::MailError, lettre_email::error::Error);
impl_from_error!(Error, Error::SendMailError, lettre::smtp::error::Error);

impl Error {
    /// Returns the HTTP status corresponding to the error.
    pub fn status(&self) -> Status {
        match self {
            Error::DatabaseConnectionError(_)
            | Error::DatabaseRequestError(_)
            | Error::IoError(_)
            | Error::MailError(_)
            | Error::SendMailError(_)
            | Error::BcryptError(_)
            | Error::DatabaseRequestEmptyError(_)
            | Error::TranscodeError => Status::InternalServerError,

            Error::SessionDoesNotExist | Error::AuthenticationFailed | Error::RequiresLogin => {
                Status::Unauthorized
            }

            Error::MissingArgumentInForm(_) | Error::NotFound => Status::NotFound,
        }
    }

    /// Returns the complementary message.
    pub fn message(&self) -> String {
        match self {
            Error::DatabaseConnectionError(e) => {
                format!("failed to connect to the database: {}", e)
            }
            Error::DatabaseRequestError(e) => format!("request to database failed: {}", e),
            Error::SessionDoesNotExist => format!("there is not such session"),
            Error::AuthenticationFailed => format!("authentication failed"),
            Error::MissingArgumentInForm(e) => format!("missing argument \"{}\" in form", e),
            Error::BcryptError(e) => format!("error in password hashing: {}", e),
            Error::IoError(e) => format!("io error: {}", e),
            Error::MailError(e) => format!("error sending mail: {}", e),
            Error::SendMailError(e) => format!("error sending mail: {}", e),
            Error::DatabaseRequestEmptyError(e) => format!("no database entry for \"{}\"", e),
            Error::RequiresLogin => format!("this request requires you to be logged in"),
            Error::NotFound => format!("the route requested does not exist"),
            Error::TranscodeError => format!("Video transcode error"),
        }
    }
}

impl fmt::Display for Error {
    fn fmt(&self, fmt: &mut fmt::Formatter) -> fmt::Result {
        write!(fmt, "{}: {}", self.status(), self.message())
    }
}

impl error::Error for Error {}

/// The result type of this library.
pub type Result<T> = result::Result<T, Error>;

impl<'r> Responder<'r> for Error {
    fn respond_to(self, _: &Request) -> response::Result<'r> {
        error!("Responding with {}", self);
        Ok(Response::build()
            .status(self.status())
            .header(ContentType::JSON)
            .sized_body(Cursor::new(
                json!({
                    "status": self.status().to_string(),
                    "message": self.message(),
                })
                .to_string(),
            ))
            .finalize())
    }
}

/// Our database type.
#[database("database")]
pub struct Database(rocket_diesel::PgConnection);

/// Starts the main server.
pub fn start_server(rocket_config: RConfig) {
    let server_config = Config::from(&rocket_config);
    let server_config_clone = rocket_config.clone();

    let rocket = if rocket_config.environment == Environment::Production {
        use simplelog::*;

        let mut config = ConfigBuilder::new();
        config.set_max_level(LevelFilter::Off);
        config.set_time_level(LevelFilter::Off);
        let config = config.build();

        let file = OpenOptions::new()
            .append(true)
            .create(true)
            .open(&server_config.log_path)
            .unwrap();

        let module = vec![String::from(module_path!())];

        WriteLogger::init(LevelFilter::Info, config, file, module).unwrap();

        rocket::custom(rocket_config).attach(Log::fairing())
    } else {
        rocket::custom(rocket_config)
    };

    let socks: Arc<Mutex<HashMap<i32, WebSocket<TcpStream>>>> =
        Arc::new(Mutex::new(HashMap::new()));
    let socks_clone = socks.clone();

    thread::spawn(move || {
        start_websocket_server(server_config_clone, socks_clone);
    });

    rocket
        .attach(Database::fairing())
        .attach(AdHoc::on_attach("Config fairing", |rocket| {
            Ok(rocket.manage(server_config))
        }))
        .attach(AdHoc::on_attach("Websockets fairing", |rocket| {
            Ok(rocket.manage(socks))
        }))
        .mount(
            "/",
            routes![
                routes::index_html,
                routes::index_json,
                routes::capsule_preparation_html,
                routes::capsule_preparation_json,
                routes::capsule_acquisition_html,
                routes::capsule_acquisition_json,
                routes::capsule_edition_html,
                routes::capsule_edition_json,
                routes::project_html,
                routes::project_json,
                routes::settings_html,
                routes::settings_json,
                routes::auth::activate,
                routes::auth::reset_password,
                routes::auth::validate_email_change,
                test_route,
            ],
        )
        .mount("/dist", StaticFiles::from("dist"))
        .mount("/data", routes![routes::data])
        .mount(
            "/api/",
            routes![
                routes::auth::new_user,
                routes::auth::login,
                routes::auth::logout,
                routes::auth::change_password,
                routes::auth::request_new_password,
                routes::auth::change_email,
                routes::project::new_project,
                routes::project::get_project,
                routes::project::get_capsules,
                routes::project::update_project,
                routes::project::delete_project,
                routes::project::project_upload,
                routes::capsule::new_capsule,
                routes::capsule::get_capsule,
                routes::capsule::update_capsule,
                routes::capsule::delete_capsule,
                routes::capsule::upload_slides,
                routes::capsule::upload_background,
                routes::capsule::upload_logo,
                routes::capsule::gos_order,
                routes::capsule::upload_record,
                routes::capsule::capsule_edition,
                routes::capsule::capsule_publication,
                routes::capsule::validate_capsule,
                routes::capsule::capsule_options,
                routes::asset::get_asset,
                routes::asset::delete_asset,
                routes::slide::get_slide,
                routes::slide::update_slide,
                routes::slide::upload_resource,
                routes::slide::delete_resource,
                routes::slide::replace_slide,
                routes::slide::new_slide,
                routes::loggedin::quick_upload_slides,
                routes::loggedin::options,
            ],
        )
        .launch();
}

/// A test route for websockets.
#[get("/test")]
pub fn test_route(
    user: User,
    socks: State<Arc<Mutex<HashMap<i32, WebSocket<TcpStream>>>>>,
) -> Result<()> {
    if let Some(sock) = socks.lock().unwrap().get_mut(&user.id) {
        sock.write_message(Message::text("sup")).unwrap();
    }
    Ok(())
}

/// Starts the setup server.
pub fn start_setup_server() {
    rocket::ignite()
        .mount("/", routes![routes::setup])
        .mount("/", StaticFiles::from("dist"))
        .mount(
            "/api/",
            routes![
                routes::setup::test_database,
                routes::setup::test_mailer,
                routes::setup::setup_config
            ],
        )
        .launch();
}

/// Starts the server.
pub fn start() {
    match RocketConfig::read() {
        Ok(config) => {
            RocketConfig::active_default().unwrap();
            let rocket_config = config.active().clone();
            start_server(rocket_config);
        }

        _ => {
            // If we arrive here, it means that the server failed to start, because the
            // configuration is broken or missing. In this case, we will spawn another server that
            // asks for the configuration.
            start_setup_server();
        }
    };
}

/// Starts the websocket server.
pub fn start_websocket_server(
    config: rocket::Config,
    socks: Arc<Mutex<HashMap<i32, WebSocket<TcpStream>>>>,
) {
    let server_config = Config::from(&config);
    let server = TcpListener::bind(&server_config.socket_root).unwrap();
    for stream in server.incoming() {
        let config = config.clone();
        let socks = socks.clone();
        thread::spawn(move || {
            let mut websocket = accept(stream.unwrap()).unwrap();
            let msg = websocket.read_message().unwrap();
            let database_url = config
                .get_table("databases")
                .unwrap()
                .get_key_value("database")
                .unwrap()
                .1
                .as_table()
                .unwrap()
                .get_key_value("url")
                .unwrap()
                .1
                .as_str()
                .unwrap();
            let db = PgConnection::establish(&database_url)
                .unwrap_or_else(|_| panic!("Error connecting to {}", database_url));
            if let Message::Text(secret) = msg {
                let user = User::from_session(&secret, &db).unwrap();
                socks.lock().unwrap().insert(user.id, websocket);
            }
        });
    }
}
