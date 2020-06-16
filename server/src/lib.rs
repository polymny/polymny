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

pub mod config;
pub mod db;
pub mod mailer;
pub mod routes;
pub mod templates;

/// This module contains the database schema and is generated by diesel.
#[allow(missing_docs)]
pub mod generated_schema;

/// This module contains the part of the schema that cannot be automatically generated.
#[allow(missing_docs)]
pub mod schema;

use std::io::Cursor;
use std::path::PathBuf;
use std::{error, fmt, io, result};

use bcrypt::BcryptError;

use rocket::fairing::AdHoc;
use rocket::http::{ContentType, Status};
use rocket::request::Request;
use rocket::response::{self, NamedFile, Responder, Response};
use rocket::State;

use rocket_contrib::databases::diesel as rocket_diesel;
use rocket_contrib::serve::StaticFiles;

use crate::config::Config;
use crate::db::user::User;
use crate::templates::{index_html, setup_html};

macro_rules! impl_from_error {
    ($type: ty, $variant: path, $from: ty) => {
        impl From<$from> for $type {
            fn from(e: $from) -> $type {
                $variant(e)
            }
        }
    };
}

#[doc(hidden)]
#[macro_export]
macro_rules! log_ { ($name:ident: $($args:tt)*) => { $name!(target: "_", $($args)*) }; }
#[doc(hidden)]
#[macro_export]
macro_rules! launch_info { ($($args:tt)*) => { info!(target: "launch", $($args)*) } }
#[doc(hidden)]
#[macro_export]
macro_rules! launch_info_ { ($($args:tt)*) => { info!(target: "launch_", $($args)*) } }
#[doc(hidden)]
#[macro_export]
macro_rules! error_ { ($($args:expr),+) => { log_!(error: $($args),+); }; }
#[doc(hidden)]
#[macro_export]
macro_rules! info_ { ($($args:expr),+) => { log_!(info: $($args),+); }; }
#[doc(hidden)]
#[macro_export]
macro_rules! trace_ { ($($args:expr),+) => { log_!(trace: $($args),+); }; }
#[doc(hidden)]
#[macro_export]
macro_rules! debug_ { ($($args:expr),+) => { log_!(debug: $($args),+); }; }
#[doc(hidden)]
#[macro_export]
macro_rules! warn_ { ($($args:expr),+) => { log_!(warn: $($args),+); }; }

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
        error_!("Responding with {}", self);
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

/// The index page.
#[get("/")]
pub fn index<'a>(db: Database, user: Option<User>) -> Result<Response<'a>> {
    let user_and_projects = if let Some(user) = user.as_ref() {
        Some((user, user.projects(&db)?))
    } else {
        None
    };

    let flags = user_and_projects.map(|(user, projects)| {
        json!({
            "page": "index",
            "username": user.username,
            "projects": projects,
            "active_project":"",
        })
    });

    let response = Response::build()
        .header(ContentType::HTML)
        .sized_body(Cursor::new(index_html(flags)))
        .finalize();

    Ok(response)
}

/// A page that moves the client directly to the capsule view.
#[get("/preparation/capsule/<id>")]
pub fn capsule<'a>(db: Database, user: Option<User>, id: i32) -> Result<Response<'a>> {
    let user_and_projects = if let Some(user) = user.as_ref() {
        Some((user, user.projects(&db)?))
    } else {
        None
    };

    let flags = {
        match user.as_ref().map(|x| x.get_capsule_by_id(id, &db)) {
            Some(Ok(capsule)) => {
                let slide_show = capsule.get_slide_show(&db)?;
                let slides = capsule.get_slides(&db)?;
                let background = capsule.get_background(&db)?;
                let logo = capsule.get_logo(&db)?;

                user_and_projects.map(|(user, projects)| {
                    json!({
                        "page":       "preparation/capsule",
                        "username":   user.username,
                        "projects":   projects,
                        "capsule" :   capsule,
                        "slide_show": slide_show,
                        "slides":     slides,
                        "background":  background,
                        "logo":        logo,
                        "active_project":"",
                       "structure":   capsule.structure,
                    })
                })
            }

            _ => user_and_projects.map(|(user, projects)| {
                json!({
                    "username": user.username,
                    "projects": projects,
                    "page": "index",
                    "active_project": "",
                })
            }),
        }
    };

    let response = Response::build()
        .header(ContentType::HTML)
        .sized_body(Cursor::new(index_html(flags)))
        .finalize();

    Ok(response)
}

/// The route for the setup page, available only when Rocket.toml does not exist yet.
#[get("/")]
pub fn setup<'a>() -> Response<'a> {
    Response::build()
        .header(ContentType::HTML)
        .sized_body(Cursor::new(setup_html()))
        .finalize()
}

/// The route for static files that require authorization.
#[get("/<path..>")]
pub fn data<'a>(path: PathBuf, user: User, config: State<Config>) -> Option<NamedFile> {
    println!("{:?}", path);
    if path.starts_with(user.username) {
        let data_path = config.data_path.join(path);
        NamedFile::open(data_path).ok()
    } else {
        None
    }
}

/// Starts the server.
pub fn main() {
    rocket::ignite()
        .attach(Database::fairing())
        .attach(AdHoc::on_attach("Config fairing", |rocket| {
            let config = Config::from(&rocket.config());
            Ok(rocket.manage(config))
        }))
        .mount("/", routes![index, capsule])
        .mount("/dist", StaticFiles::from("dist"))
        .mount("/data", routes![data])
        .mount(
            "/api/",
            routes![
                routes::auth::new_user,
                routes::auth::activate,
                routes::auth::login,
                routes::auth::logout,
                routes::project::new_project,
                routes::project::get_project,
                routes::project::get_capsules,
                routes::project::all_projects,
                routes::project::update_project,
                routes::project::delete_project,
                routes::project::project_upload,
                routes::capsule::new_capsule,
                routes::capsule::get_capsule,
                routes::capsule::all_capsules,
                routes::capsule::update_capsule,
                routes::capsule::delete_capsule,
                routes::capsule::upload_slides,
                routes::capsule::upload_background,
                routes::capsule::upload_logo,
                routes::capsule::gos_order,
                routes::capsule::upload_record,
                routes::capsule::capsule_edition,
                routes::asset::get_asset,
                routes::asset::all_assets,
                routes::asset::delete_asset,
                routes::slide::get_slide,
                routes::slide::update_slide,
                routes::loggedin::quick_upload_slides,
            ],
        )
        .launch()
        // This .kind() is here to prevent the server from panicking in case the config file is not
        // available. launch() returns an Error that when dropped, panics if it has not been
        // handled. Using .kind() here marks the error as handled.
        .kind();

    // If we arrive here, it means that the server failed to start.
    // Unless it's due to a programming mistake, this means that the configuration is broken.
    // In this case, we will spawn another server that asks for the configuration.
    rocket::ignite()
        .mount("/", routes![setup])
        .mount("/", StaticFiles::from("dist"))
        .mount(
            "/api/",
            routes![
                routes::setup::test_database,
                routes::setup::test_mailer,
                routes::setup::setup_config
            ],
        )
        .launch()
        .kind();
}
