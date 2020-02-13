//! This module contains the routes that we use to setup and generate the Rocket.toml.

use diesel::pg::PgConnection;
use diesel::Connection;

use rocket::request::Form;

use crate::Result;

/// A struct that verifies the form for the database check route.
#[derive(FromForm)]
pub struct DatabaseTestForm {
    /// The hostname of the database.
    hostname: String,

    /// The username of the user that connects to the database.
    username: String,

    /// The password of the user that connects to the database.
    password: String,

    /// The name of the database.
    name: String,
}

/// Tests a database connection from its credentials.
#[post("/test-database", data = "<form>")]
pub fn test_database(form: Form<DatabaseTestForm>) -> Result<()> {
    // Build postgres url from credentials
    let url = format!(
        "postgres://{}:{}@{}/{}",
        form.username, form.password, form.hostname, form.name,
    );

    // Try to connect to the database
    PgConnection::establish(&url)?;

    // If we reach here, it is a success
    Ok(())
}
