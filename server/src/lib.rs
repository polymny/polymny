#![feature(proc_macro_hygiene, decl_macro)]

#[macro_use] extern crate serde;
#[macro_use] extern crate rocket;
#[macro_use] extern crate rocket_contrib;
#[macro_use] extern crate diesel;
#[macro_use] extern crate lazy_static;

pub mod db;
pub mod schema;
pub mod mailer;
pub mod routes;

use std::{io, result, fmt, error};
use std::process::exit;
use bcrypt::BcryptError;
use rocket::fairing::AdHoc;
use tera::Tera;


macro_rules! impl_from_error {
    ($type: ty, $variant: path, $from: ty) => {
        impl From<$from> for $type {
            fn from(e: $from) -> $type {
                $variant(e)
            }
        }
    }
}

lazy_static! {
    /// The templates our server will use.
    pub static ref TEMPLATES: tera::Tera = {
        let mut tera = match Tera::new("assets/templates/*") {
            Ok(t) => t,
            Err(e) => {
                println!("Parsing error(s) in tera templates: {}", e);
                exit(1);
            }
        };
        tera.autoescape_on(vec!["html", ".sql"]);
        tera
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

    /// An error occured while rendering a template.
    TeraError(tera::Error),
}

impl_from_error!(Error, Error::DatabaseConnectionError, diesel::ConnectionError);
impl_from_error!(Error, Error::DatabaseRequestError, diesel::result::Error);
impl_from_error!(Error, Error::BcryptError, BcryptError);
impl_from_error!(Error, Error::IoError, io::Error);
impl_from_error!(Error, Error::MailError, lettre_email::error::Error);
impl_from_error!(Error, Error::SendMailError, lettre::smtp::error::Error);
impl_from_error!(Error, Error::TeraError, tera::Error);

impl fmt::Display for Error {
    fn fmt(&self, fmt: &mut fmt::Formatter) -> fmt::Result {
        match self {
            Error::DatabaseConnectionError(e) =>
                write!(fmt, "failed to connect to the database: {}", e),

            Error::DatabaseRequestError(e) =>
                write!(fmt, "request to database failed: {}", e),

            Error::SessionDoesNotExist =>
                write!(fmt, "there is not such session"),

            Error::AuthenticationFailed =>
                write!(fmt, "authentication failed"),

            Error::MissingArgumentInForm(e) =>
                write!(fmt, "missing argument \"{}\" in form", e),

            Error::BcryptError(e) =>
                write!(fmt, "error in password hashing: {}", e),

            Error::IoError(e) =>
                write!(fmt, "io error: {}", e),

            Error::MailError(e) =>
                write!(fmt, "error sending mail: {}", e),

            Error::SendMailError(e) =>
                write!(fmt, "error sending mail: {}", e),

            Error::TeraError(e) =>
                write!(fmt, "error rendering template: {}", e),
        }
    }
}

impl error::Error for Error {}

/// The result type of this library.
pub type Result<T> = result::Result<T, Error>;

use std::io::Cursor;

use rocket::http::{Cookies, ContentType};
use rocket::response::Response;

use rocket_contrib::databases::diesel as rocket_diesel;
use rocket_contrib::serve::StaticFiles;

use tera::Context;

use crate::db::user::User;
use crate::mailer::Mailer;

/// Our database type.
#[database("database")]
pub struct Database(rocket_diesel::PgConnection);

/// The index page.
#[get("/")]
pub fn index(db: Database, mut cookies: Cookies) -> Result<Response> {
    let cookie = cookies.get_private("EXAUTH");
    let mut context = Context::new();

    let flags = if cookie.is_none() {
        "".to_string()
    } else {
        match User::from_session(cookie.unwrap().value(), &db) {
            Ok(user) => {
                let json = json!({"username": user.username, "projects": user.projects(&db)?});
                format!("flags: {},", json.0)
            },
            Err(_) => "".to_string(),
        }
    };


    context.insert("flags", &flags);

    let response = Response::build()
        .header(ContentType::HTML)
        .sized_body(Cursor::new(TEMPLATES.render("index.tera", &context)?))
        .finalize();

    Ok(response)
}


pub fn main() {
    rocket::ignite()
       .attach(Database::fairing())
       .attach(AdHoc::on_attach("Mailer fairing", |rocket| {
           let mailer = Mailer::from_config(rocket.config());
           Ok(rocket.manage(mailer))
       }))
       .mount("/", routes![index])
       .mount("/", StaticFiles::from("dist"))
       .mount("/api/", routes![
            routes::auth::new_user,
            routes::auth::activate,
            routes::auth::login,
            routes::auth::logout,
            routes::project::new_project,
            routes::project::get_project,
            routes::project::projects,
            routes::capsule::new_capsule,
            routes::capsule::get_capsule,
            routes::capsule::capsules,
       ])
       .launch();
}
