//! This module contains all the routes that deal with the user.

use std::borrow::Cow;

use time::Duration;

use serde::{Deserialize, Serialize};

use tokio::fs::remove_dir_all;

use rocket::form::Form;
use rocket::http::{Cookie, CookieJar, SameSite, Status};
use rocket::response::content::RawHtml as Html;
use rocket::response::Redirect;
use rocket::serde::json::{json, Json, Value};
use rocket::State as S;

use crate::config::Config;
use crate::db::capsule::Role;
use crate::db::session::Session;
use crate::db::user::User;
use crate::routes::global_flags;
use crate::routes::Cors;
use crate::templates::index_html;
use crate::{Db, Error, Lang, Result};

/// Creates then authentication cookies.
fn add_cookies(value: &str, config: &Config, cookies: &CookieJar) {
    let max_age = Duration::weeks(4);

    let v = Cow::into_owned(value.into());
    let mut cookie = Cookie::new("EXAUTH", v);
    cookie.set_max_age(Some(max_age));
    cookie.set_same_site(SameSite::Lax);
    if let Some(domain) = config.cookie_domain.as_ref() {
        cookie.set_domain(Cow::into_owned(domain.into()));
    }
    cookies.add_private(cookie);

    let mut cookie = Cookie::new("EXAUTH2", "true");
    cookie.set_max_age(Some(max_age));
    cookie.set_http_only(false);
    if let Some(domain) = config.cookie_domain.as_ref() {
        cookie.set_domain(Cow::into_owned(domain.into()));
    }
    cookies.add(cookie);
}

/// Removes the authentication cookies
fn remove_cookies(value: &str, config: &Config, cookies: &CookieJar) {
    let max_age = Duration::weeks(4);

    let v = Cow::into_owned(value.into());
    let mut cookie = Cookie::new("EXAUTH", v);
    cookie.set_max_age(Some(max_age));
    if let Some(domain) = config.cookie_domain.as_ref() {
        cookie.set_domain(Cow::into_owned(domain.into()));
    }
    cookies.remove_private(cookie);

    let mut cookie = Cookie::new("EXAUTH2", "true");
    cookie.set_http_only(false);
    cookie.set_max_age(Some(max_age));
    if let Some(domain) = config.cookie_domain.as_ref() {
        cookie.set_domain(Cow::into_owned(domain.into()));
    }
    cookies.remove(cookie);
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

    /// True if the user subsribes to the newsletter.
    subscribed: bool,
}

/// Route to allow CORS request from home page.
#[options("/new-user")]
pub fn new_user_cors<'a>(config: &S<Config>) -> Cors<()> {
    Cors::new(&config.home, ())
}

/// The route to register new users.
#[post("/new-user", data = "<user>")]
pub async fn new_user<'a>(db: Db, config: &S<Config>, user: Json<NewUserForm>) -> Cors<Status> {
    let user = User::new(
        &user.username,
        &user.email,
        &user.password,
        user.0.subscribed,
        &config.mailer,
        &db,
        &config,
    )
    .await;

    let status = match user {
        Ok(_) => Status::Ok,
        Err(Error(s)) => s,
    };

    Cors::new(&config.home, status)
}

/// The route to active a user.
#[get("/activate/<key>")]
pub async fn activate<'a>(
    db: Db,
    config: &S<Config>,
    key: String,
    cookies: &CookieJar<'_>,
) -> Result<Redirect> {
    let mut user = User::get_by_activation_key(key, &db)
        .await?
        .ok_or(Error(Status::NotFound))?;

    user.activated = true;
    user.activation_key = None;
    user.save(&db).await?;
    let session = user.save_session(&db).await?;
    add_cookies(&session.secret, &config, cookies);
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

/// Route to allow CORS request from home page.
#[options("/login")]
pub fn login_external_cors(config: &S<Config>) -> Cors<()> {
    Cors::new(&config.home, ())
}

/// The login route to login from somewhere else.
#[post("/login", data = "<login>")]
pub async fn login_external<'a>(
    db: Db,
    cookies: &CookieJar<'_>,
    config: &S<Config>,
    login: Form<LoginForm>,
) -> Cors<Result<Redirect>> {
    let user = match User::get_by_username(&login.username, &db).await {
        Ok(u) => u,
        _ => return Cors::err(&config.home, Status::Unauthorized),
    };

    let user = match user {
        Some(user) => user,
        None => match User::get_by_email(&login.username, &db).await {
            Ok(Some(u)) => u,
            _ => return Cors::err(&config.home, Status::Unauthorized),
        },
    };

    match user.test_password(&login.password) {
        Ok(()) => (),
        _ => return Cors::err(&config.home, Status::Unauthorized),
    }

    if !user.activated {
        return Cors::err(&config.home, Status::Unauthorized);
    }

    let session = match user.save_session(&db).await {
        Ok(s) => s,
        Err(_) => return Cors::err(&config.home, Status::InternalServerError),
    };

    add_cookies(&session.secret, &config, cookies);

    Cors::ok(&config.home, Redirect::to(config.root.clone()))
}

/// Route to allow CORS request from home page.
#[options("/login")]
pub fn login_cors(config: &S<Config>) -> Cors<()> {
    Cors::new(&config.home, ())
}

/// The login page.
#[post("/login", data = "<login>")]
pub async fn login(
    db: Db,
    config: &S<Config>,
    cookies: &CookieJar<'_>,
    login: Json<LoginForm>,
) -> Cors<Result<Value>> {
    match login_wrapper(db, config, cookies, login).await {
        Ok(v) => Cors::ok(&config.home, v),
        Err(Error(e)) => Cors::err(&config.home, e),
    }
}

/// Content of the login function.
pub async fn login_wrapper(
    db: Db,
    config: &S<Config>,
    cookies: &CookieJar<'_>,
    login: Json<LoginForm>,
) -> Result<Value> {
    let user = User::get_by_username(&login.username, &db)
        .await
        .map_err(|_| Error(Status::Unauthorized))?;

    let user = match user {
        Some(user) => user,
        None => match User::get_by_email(&login.username, &db).await {
            Ok(Some(u)) => u,
            _ => return Err(Error(Status::Unauthorized)),
        },
    };

    user.test_password(&login.password)?;

    if !user.activated {
        return Err(Error(Status::Unauthorized));
    }

    let session = user.save_session(&db).await?;

    add_cookies(&session.secret, &config, cookies);

    Ok(user.to_json(&db).await?)
}

/// The logout page.
#[post("/logout")]
pub async fn logout(db: Db, config: &S<Config>, cookies: &CookieJar<'_>) -> Result<()> {
    {
        let cookie = cookies.get_private("EXAUTH");
        if let Some(cookie) = cookie {
            let session = Session::get_by_secret(cookie.value(), &db)
                .await?
                .ok_or(Error(Status::NotFound))?;

            session.delete(&db).await?;
        }
    }

    remove_cookies("", &config, cookies);
    Ok(())
}

/// Route to allow CORS request from home page.
#[options("/request-new-password")]
pub fn request_new_password_cors<'a>(config: &S<Config>) -> Cors<()> {
    Cors::new(&config.home, ())
}

/// The form for requesting a new password.
#[derive(Serialize, Deserialize)]
pub struct RequestNewPasswordForm {
    /// The email.
    pub email: String,
}

/// The route that requests an email to change a password.
#[post("/request-new-password", data = "<form>")]
pub async fn request_new_password<'a>(
    config: &S<Config>,
    db: Db,
    form: Json<RequestNewPasswordForm>,
) -> Cors<Status> {
    let mut user = match User::get_by_email(&form.email, &db).await {
        Ok(Some(user)) => user,
        _ => return Cors::new(&config.home, Status::Ok),
    };

    match user.request_change_password(&config.mailer, &db).await {
        Ok(_) => Cors::new(&config.home, Status::Ok),
        Err(_) => Cors::new(&config.home, Status::InternalServerError),
    }
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
pub async fn change_password(
    db: Db,
    form: Json<ChangePasswordForm>,
    config: &S<Config>,
    cookies: &CookieJar<'_>,
) -> Result<Value> {
    let mut user = match (&form.username_and_old_password, &form.key) {
        (None, None) => return Err(Error(Status::BadRequest)),
        (Some((username, old_password)), _) => {
            User::authenticate(username, old_password, &db).await?
        }
        (_, Some(key)) => User::get_by_reset_password_key(Some(key.to_string()), &db)
            .await?
            .ok_or(Error(Status::BadRequest))?,
    };

    user.set_password(&form.new_password)?;
    user.reset_password_key = None;
    let session = user.save_session(&db).await?;
    add_cookies(&session.secret, &config, cookies);
    user.save(&db).await?;
    let json = user.to_json(&db).await?;

    Ok(json)
}

/// Link to the form that reset the user's password.
#[get("/reset-password/<key>")]
pub async fn reset_password<'a>(
    db: Db,
    config: &S<Config>,
    key: String,
    lang: Lang,
) -> Result<Html<String>> {
    let user = User::get_by_reset_password_key(Some(key), &db).await;

    match user {
        Ok(Some(_)) => (),
        Ok(None) => return Err(Error(Status::NotFound)),
        _ => return Err(Error(Status::InternalServerError)),
    }

    let body = index_html(json!({ "user": json!(null), "global": global_flags(&config, &lang) }));
    Ok(Html(body))
}

/// The type to change a user's email address.
#[derive(Serialize, Deserialize)]
pub struct ChangeEmailForm {
    /// The new email address of the user.
    new_email: String,
}

/// Route to change a user email.
#[post("/request-change-email", data = "<form>")]
pub async fn request_change_email(
    mut user: User,
    db: Db,
    config: &S<Config>,
    form: Json<ChangeEmailForm>,
) -> Result<()> {
    if User::get_by_email(&form.new_email, &db).await?.is_some() {
        return Err(Error(Status::BadRequest));
    }

    user.request_change_email(form.0.new_email, &config.mailer, &db)
        .await?;
    Ok(())
}

/// Route to validate an email change.
#[get("/validate-email/<key>")]
pub async fn validate_email<'a>(key: String, db: Db) -> Result<Redirect> {
    match User::validate_change_email(key, &db).await {
        Ok(_) => Ok(Redirect::to("/profile/")),
        Err(Error(s)) => Err(Error(s)),
    }
}
/// The form for deleting a user.
#[derive(Serialize, Deserialize)]
pub struct DeleteUserForm {
    /// The password.
    pub current_password: String,
}

/// Route to delete user.
#[delete("/delete-user", data = "<form>")]
pub async fn delete(
    db: Db,
    user: User,
    config: &S<Config>,
    form: Json<DeleteUserForm>,
    cookies: &CookieJar<'_>,
) -> Result<()> {
    user.test_password(&form.current_password)?;
    let capsules = user.capsules(&db).await?;

    for (capsule, role) in capsules {
        if role == Role::Owner {
            let dir = config.data_path.join(format!("{}", capsule.id));
            remove_dir_all(dir).await?;
            capsule.delete(&db).await?;
        }
    }

    user.delete(&db).await?;
    remove_cookies("", &config, cookies);

    Ok(())
}

/// Unsubsribes the user from the newsletter.
#[get("/unsubscribe/<key>")]
pub async fn unsubscribe<'a>(db: Db, config: &S<Config>, key: String) -> Cors<Result<Redirect>> {
    let mut user = match User::get_by_unsubscribe_key(key, &db).await {
        Ok(Some(user)) => user,
        Ok(None) => return Cors::err(&config.home, Status::NotFound),
        _ => return Cors::err(&config.home, Status::InternalServerError),
    };

    user.unsubscribe_key = None;

    if user.save(&db).await.is_err() {
        return Cors::err(&config.home, Status::InternalServerError);
    }

    Cors::ok(&config.home, Redirect::to(config.root.clone()))
}

/// Link to the form that reset the user's password.
#[get("/validate-invitation/<key>")]
pub async fn validate_invitation<'a>(
    db: Db,
    config: &S<Config>,
    key: String,
    cookies: &CookieJar<'_>,
    lang: Lang,
) -> Result<Html<String>> {
    let user = User::get_by_activation_key(key, &db)
        .await?
        .ok_or(Error(Status::NotFound))?;

    let session = user.save_session(&db).await?;
    add_cookies(&session.secret, &config, cookies);

    let json = user.to_json(&db).await?;
    let body = index_html(json!({"user": json, "global": global_flags(&config, &lang) }));

    Ok(Html(body))
}

/// The form for validating inscription
/// The user enter the password
#[derive(Serialize, Deserialize)]
pub struct RequestInvitationForm {
    /// The password.
    pub password: String,
    /// The activation key.
    pub key: String,
}

/// The route to active a user.
#[post("/request-invitation", data = "<form>")]
pub async fn request_invitation<'a>(
    db: Db,
    config: &S<Config>,
    cookies: &CookieJar<'_>,
    form: Json<RequestInvitationForm>,
    lang: Lang,
) -> Result<Html<String>> {
    let mut user = User::get_by_activation_key(form.key.to_string(), &db)
        .await?
        .ok_or(Error(Status::NotFound))?;

    user.activated = true;
    user.activation_key = None;
    user.save(&db).await?;
    let session = user.save_session(&db).await?;
    add_cookies(&session.secret, &config, cookies);

    let json = user.to_json(&db).await?;
    let body = index_html(json!({"user": json, "global": global_flags(&config, &lang) }));
    Ok(Html(body))
}
