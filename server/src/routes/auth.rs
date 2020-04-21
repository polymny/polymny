//! This module contains all the routes related to login.

use std::io::Cursor;

use rocket::http::{Cookie, Cookies};
use rocket::response::{Redirect, Response};
use rocket::State;

use rocket_contrib::json::{Json, JsonValue};

use crate::db::session::Session;
use crate::db::user::User;
use crate::mailer::Mailer;
use crate::{Database, Result};

/// A struct that serves the purpose of veryifing the form.
#[derive(Deserialize)]
pub struct NewUserForm {
    /// The username of the form.
    username: String,

    /// The email of the form.
    email: String,

    /// The password of the form.
    password: String,
}

/// The route to register new users.
#[post("/new-user", data = "<user>")]
pub fn new_user(
    db: Database,
    mailer: State<Option<Mailer>>,
    user: Json<NewUserForm>,
) -> Result<Response> {
    let user = User::create(&user.username, &user.email, &user.password, mailer.inner())?;
    user.save(&db)?;

    Ok(Response::build().sized_body(Cursor::new("")).finalize())
}

/// The route to active a user.
#[get("/activate/<key>")]
pub fn activate(db: Database, key: String, mut cookies: Cookies) -> Result<Redirect> {
    let user = User::activate(&key, &db)?;
    let session = user.save_session(&db)?;
    cookies.add_private(Cookie::new("EXAUTH", session.secret));
    Ok(Redirect::to("/"))
}

/// A struct that serves for form veryfing.
#[derive(Deserialize)]
pub struct LoginForm {
    /// The username in the form.
    username: String,

    /// The password in the form.
    password: String,
}

/// The login page.
#[post("/login", data = "<login>")]
pub fn login(db: Database, mut cookies: Cookies, login: Json<LoginForm>) -> Result<JsonValue> {
    let user = User::authenticate(&login.username, &login.password, &db)?;
    let session = user.save_session(&db)?;

    cookies.add_private(Cookie::new("EXAUTH", session.secret));

    Ok(json!({"username": user.username, "projects": user.projects(&db)?}))
}

/// Returns the username.
#[post("/session")]
pub fn session(db: Database, user: User) -> Result<JsonValue> {
    Ok(json!({"username": user.username, "projects": user.projects(&db)?}))
}

/// The logout page.
#[post("/logout")]
pub fn logout(db: Database, mut cookies: Cookies) -> Result<()> {
    let cookie = cookies.get_private("EXAUTH");
    if let Some(cookie) = cookie {
        Session::delete_from_secret(cookie.value(), &db)?;
    }
    Ok(())
}
