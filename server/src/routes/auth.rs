//! This module contains all the routes related to login.

use std::io::Cursor;

use rocket::State;
use rocket::response::{Response, Redirect};
use rocket::request::Form;
use rocket::http::{Cookie, Cookies};

use rocket_contrib::json::JsonValue;

use crate::db::session::Session;
use crate::db::user::User;
use crate::mailer::Mailer;
use crate::{Database, Result};

/// A struct that serves the purpose of veryifing the form.
#[derive(FromForm)]
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
pub fn new_user<'a>(db: Database, mailer: State<Mailer>, user: Form<NewUserForm>) -> Result<Response<'a>> {

    let user = User::create(&user.username, &user.email, &user.password, Some(&mailer))?;
    user.save(&db)?;

    Ok(Response::build()
        .sized_body(Cursor::new(""))
        .finalize())
}

/// The route to active a user.
#[get("/activate/<key>")]
pub fn activate(db: Database, key: String) -> Result<Redirect> {

    User::activate(&key, &db)?;
    Ok(Redirect::to("/"))

}

/// A struct that serves for form veryfing.
#[derive(FromForm)]
pub struct LoginForm {
    /// The username in the form.
    username: String,

    /// The password in the form.
    password: String,
}

/// The login page.
#[post("/login", data = "<login>")]
pub fn login(db: Database, mut cookies: Cookies, login: Form<LoginForm>) -> Result<JsonValue> {

    let user = User::authenticate(&login.username, &login.password, &db)?;
    let session = user.save_session(&db)?;

    cookies.add_private(Cookie::new("EXAUTH", session.secret));

    Ok(json!({"username": user.username}))
}

/// Returns the username.
#[post("/session")]
pub fn session(db: Database, mut cookies: Cookies) -> Result<JsonValue> {
    let cookie = cookies.get_private("EXAUTH");
    let user = User::from_session(cookie.unwrap().value(), &db)?;
    Ok(json!({"username": user.username}))
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
