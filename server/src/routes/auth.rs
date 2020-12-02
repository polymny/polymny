//! This module contains all the routes related to login.

use std::borrow::Cow;
use std::io::Cursor;

use rocket::http::{ContentType, Cookie, Cookies, Status};
use rocket::request::Form;
use rocket::response::{Redirect, Response};
use rocket::State;

use rocket_contrib::json::{Json, JsonValue};

use crate::config::Config;
use crate::db::session::Session;
use crate::db::user::User;
use crate::templates::index_html;
use crate::webcam::{webcam_position_to_str, webcam_size_to_str};
use crate::{Database, Error, Result};

/// Creates an authentication cookie.
fn cookie(value: &str, config: &Config) -> Cookie<'static> {
    let v = Cow::into_owned(value.into());
    let mut cookie = Cookie::new("EXAUTH", v);
    if let Some(domain) = config.cookie_domain.as_ref() {
        cookie.set_domain(Cow::into_owned(domain.into()));
    }
    cookie
}

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

/// Route to allow CORS request from home page.
#[options("/new-user")]
pub fn new_user_cors<'a>(config: State<Config>) -> Response<'a> {
    Response::build()
        .raw_header("Access-Control-Allow-Origin", config.home.clone())
        .raw_header("Access-Control-Allow-Methods", "OPTIONS,POST")
        .raw_header("Access-Control-Allow-Headers", "Content-Type")
        .finalize()
}

/// The route to register new users.
#[post("/new-user", data = "<user>")]
pub fn new_user(db: Database, config: State<Config>, user: Json<NewUserForm>) -> Response {
    let mut base = Response::build();
    let base = base
        .raw_header("Access-Control-Allow-Origin", config.home.clone())
        .raw_header("Access-Control-Allow-Methods", "OPTIONS,POST")
        .raw_header("Access-Control-Allow-Headers", "Content-Type");

    let user = User::create(
        &user.username,
        &user.email,
        &user.password,
        &config.mailer,
        &db,
    );

    let user = match user {
        Ok(user) => user,
        Err(Error::NotFound) => return base.status(Status::NotFound).finalize(),
        _ => return base.status(Status::InternalServerError).finalize(),
    };

    match user.save(&db) {
        Ok(_) => base.finalize(),
        Err(_) => base.status(Status::InternalServerError).finalize(),
    }
}

/// The route to active a user.
#[get("/activate/<key>")]
pub fn activate(
    db: Database,
    key: String,
    mut cookies: Cookies,
    config: State<Config>,
) -> Result<Redirect> {
    let user = User::activate(&key, &db)?;
    let session = user.save_session(&db)?;
    cookies.add_private(cookie(&session.secret, &config));
    Ok(Redirect::to("/"))
}

/// A struct that serves for form veryfing.
#[derive(Deserialize, FromForm)]
pub struct LoginForm {
    /// The username in the form.
    username: String,

    /// The password in the form.
    password: String,
}

/// The login page.
#[post("/login", data = "<login>")]
pub fn login_and_redirect(
    db: Database,
    mut cookies: Cookies,
    login: Form<LoginForm>,
    config: State<Config>,
) -> Redirect {
    let user = match User::authenticate(&login.username, &login.password, &db) {
        Ok(u) => u,
        Err(_) => return Redirect::to("/"),
    };
    let session = match user.save_session(&db) {
        Ok(u) => u,
        Err(_) => return Redirect::to("/"),
    };
    cookies.add_private(cookie(&session.secret, &config.inner()));
    Redirect::to("/")
}

/// The login page.
#[post("/login", data = "<login>")]
pub fn login(
    db: Database,
    mut cookies: Cookies,
    login: Json<LoginForm>,
    config: State<Config>,
) -> Result<JsonValue> {
    let user = User::authenticate(&login.username, &login.password, &db)?;
    let session = user.save_session(&db)?;

    let edition_options = user.get_edition_options()?;
    cookies.add_private(cookie(&session.secret, &config));

    Ok(json!({"username": user.username,
        "page": "home",
        "projects": user.projects(&db)?,
        "active_project": "",
        "with_video": edition_options.with_video,
        "webcam_size": webcam_size_to_str(edition_options.webcam_size),
        "webcam_position": webcam_position_to_str(edition_options.webcam_position),
        "cookie": session.secret,
        "notifications": user.notifications(&db)?,
    }))
}

/// Returns the username.
#[post("/session")]
pub fn session(db: Database, user: User) -> Result<JsonValue> {
    let edition_options = user.get_edition_options()?;
    Ok(json!({ "username": user.username,
            "projects": user.projects(&db)?,
            "active_project": "",
            "with_video": edition_options.with_video,
            "webcam_size": webcam_size_to_str(edition_options.webcam_size),
            "webcam_position": webcam_position_to_str(edition_options.webcam_position),
            "notifications": user.notifications(&db)?,
    }))
}

/// The logout page.
#[post("/logout")]
pub fn logout(db: Database, mut cookies: Cookies, config: State<Config>) -> Result<()> {
    {
        let cookie = cookies.get_private("EXAUTH");
        if let Some(cookie) = cookie {
            Session::delete_from_secret(cookie.value(), &db)?;
        }
    }
    let cookie = cookie("EXAUTH", &config);
    cookies.remove_private(cookie);
    Ok(())
}

/// Route to allow CORS request from home page.
#[options("/request-new-password")]
pub fn request_new_password_cors<'a>(config: State<Config>) -> Response<'a> {
    Response::build()
        .raw_header("Access-Control-Allow-Origin", config.home.clone())
        .raw_header("Access-Control-Allow-Methods", "OPTIONS,POST")
        .raw_header("Access-Control-Allow-Headers", "Content-Type")
        .finalize()
}

/// The form for requesting a new password.
#[derive(Serialize, Deserialize)]
pub struct RequestNewPasswordForm {
    /// The email.
    pub email: String,
}

/// The route that requests an email to change a password.
#[post("/request-new-password", data = "<form>")]
pub fn request_new_password(
    config: State<Config>,
    db: Database,
    form: Json<RequestNewPasswordForm>,
) -> Response {
    let mut response = Response::build();
    let response = response
        .raw_header("Access-Control-Allow-Origin", config.home.clone())
        .raw_header("Access-Control-Allow-Methods", "OPTIONS,POST")
        .raw_header("Access-Control-Allow-Headers", "Content-Type");

    let mut user = match User::get_by_email(&form.email, &db.0) {
        Ok(user) => user,
        Err(_) => return response.status(Status::NotFound).finalize(),
    };

    match user.change_password(&config.mailer, &db.0) {
        Ok(_) => response.finalize(),
        Err(_) => response.status(Status::InternalServerError).finalize(),
    }
}

/// The page that prompts a user for a new password.
#[get("/reset-password/<key>")]
pub fn reset_password<'a>(key: String) -> Result<Response<'a>> {
    let response = Response::build()
        .header(ContentType::HTML)
        .sized_body(Cursor::new(index_html(json!({
            "flags": json!({
                "page": "reset-password",
                "key": key,
            })
        }))))
        .finalize();

    Ok(response)
}

/// The form for changing a password.
///
/// To change a password, we require to authenticate the user. This can be done by the old
/// password, or by the reset password key in the database. Only one of those is necessary.
#[derive(Serialize, Deserialize)]
pub struct ChangePasswordForm {
    /// The old password.
    pub username_and_old_password: Option<(String, String)>,

    /// The reset password key.
    pub key: Option<String>,

    /// The new password.
    pub new_password: String,
}

/// Changes the user password.
#[post("/change-password", data = "<form>")]
pub fn change_password(
    db: Database,
    form: Json<ChangePasswordForm>,
    mut cookies: Cookies,
    config: State<Config>,
) -> Result<JsonValue> {
    let user = match (&form.username_and_old_password, &form.key) {
        (None, None) => return Err(Error::NotFound),
        (Some((username, old_password)), _) => {
            let mut user = User::authenticate(username, old_password, &db.0)?;
            user.update_password(&form.new_password, &db.0)?;
            user
        }
        (_, Some(key)) => User::update_password_by_key(key, &form.new_password, &db.0)?,
    };

    let session = user.save_session(&db)?;
    let edition_options = user.get_edition_options()?;
    cookies.add_private(cookie(&session.secret, &config));
    let notifications = user.notifications(&db).unwrap();

    Ok(json!({"username": user.username,
              "projects": user.projects(&db)?,
              "page": "index",
              "active_project": "",
              "with_video": edition_options.with_video,
              "webcam_size": webcam_size_to_str(edition_options.webcam_size),
              "webcam_position": webcam_position_to_str(edition_options.webcam_position),
              "cookie": session.secret,
              "notifications": notifications,
    }))
}

/// The form for changing an email address.
///
/// Changing the email needs the old password.
#[derive(Serialize, Deserialize)]
pub struct ChangeEmailForm {
    /// The old password.
    pub password: String,

    /// The new email.
    pub new_email: String,
}

/// Route to change a user email.
#[post("/change-email", data = "<form>")]
pub fn change_email(
    config: State<Config>,
    db: Database,
    user: User,
    form: Json<ChangeEmailForm>,
) -> Result<JsonValue> {
    let mut user = User::authenticate(&user.username, &form.password, &db.0)?;
    user.change_email(&form.new_email, &config.mailer, &db.0)?;
    Ok(json!({}))
}

/// Route to validate a user email change.
#[get("/validate-email-change/<key>")]
pub fn validate_email_change(key: String, db: Database) -> Result<Redirect> {
    User::validate_email_change(&key, &db.0)?;
    Ok(Redirect::to("/"))
}
