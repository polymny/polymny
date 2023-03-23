//! This module contains all the routes of the app.

use std::path::PathBuf;

use rocket::fs::NamedFile;
use rocket::http::Status;
use rocket::request::{FromRequest, Request};
use rocket::response::content::RawHtml as Html;
use rocket::response::{self, Redirect, Responder, Response};
use rocket::serde::json::{json, Value};
use rocket::State as S;

use crate::config::Config;
use crate::db::capsule::Role;
use crate::db::user::{Plan, User};
use crate::templates::index_html;
use crate::{Db, Error, HashId, Lang, Result};

pub mod admin;
pub mod capsule;
pub mod notification;
pub mod user;
pub mod watch;

/// A struct to help us deal with cross origin requests.
pub struct Cors<R> {
    /// The home to which you want to allow the cross origin requests.
    home: Option<String>,

    /// The inner response.
    r: R,
}

/// A struct that can be two types of responders.
pub enum Either<L, R> {
    /// The first variant.
    Left(L),

    /// The second variant.
    Right(R),
}

impl<'r, 'o: 'r, L, R> Responder<'r, 'o> for Either<L, R>
where
    L: Responder<'r, 'o>,
    R: Responder<'r, 'o>,
{
    fn respond_to(self, request: &'r Request<'_>) -> response::Result<'o> {
        match self {
            Either::Left(l) => l.respond_to(request),
            Either::Right(r) => r.respond_to(request),
        }
    }
}

impl<R> Cors<R> {
    /// Creates a new cors response.
    pub fn new(home: &Option<String>, r: R) -> Cors<R> {
        Cors {
            home: home.clone(),
            r,
        }
    }

    /// Creates a new ok cors response.
    pub fn ok(home: &Option<String>, r: R) -> Cors<Result<R>> {
        Cors {
            home: home.clone(),
            r: Ok(r),
        }
    }

    /// Creates a new err cors response.
    pub fn err(home: &Option<String>, e: Status) -> Cors<Result<R>> {
        Cors {
            home: home.clone(),
            r: Err(Error(e)),
        }
    }
}

impl<'r, R> Responder<'r, 'static> for Cors<R>
where
    R: Responder<'r, 'static>,
{
    fn respond_to(self, request: &'r Request<'_>) -> response::Result<'static> {
        let mut response = match self.r.respond_to(request) {
            Ok(r) => r,
            Err(e) => Response::build().status(e).finalize(),
        };

        if let Some(home) = self.home {
            response.set_raw_header("Access-Control-Allow-Origin", home);
            response.set_raw_header("Access-Control-Allow-Methods", "OPTIONS,POST");
            response.set_raw_header("Access-Control-Allow-Headers", "Content-Type");
        }

        Ok(response)
    }
}

/// Prepares the global flags.
pub fn global_flags(config: &S<Config>, lang: &Lang) -> Value {
    json!({
        "serverConfig": {
            "root": config.root,
            "socketRoot": config.socket_root,
            "videoRoot": config.video_root,
            "version": config.version,
            "commit": config.commit,
            "home": config.home,
            "registrationDisabled": config.registration_disabled,
            "requestLanguage": lang,
        },
    })
}

/// Route to allow CORS request from home page.
#[options("/")]
pub fn index_cors(config: &S<Config>) -> Cors<()> {
    Cors::new(&config.home, ())
}

/// Route to the index.
#[get("/")]
pub async fn index<'a>(
    config: &S<Config>,
    db: Db,
    user: Option<User>,
    lang: Lang,
) -> Cors<Either<Html<String>, Redirect>> {
    let (json, redirect) = match user {
        Some(ref user) => (
            Some(user.to_json(&db).await),
            (config.premium_only != (user.plan >= Plan::PremiumLvl1)) && user.plan != Plan::Admin,
        ),
        None => (None, false),
    };

    match (redirect, config.other_host.as_ref()) {
        (true, Some(host)) => {
            return Cors::new(&config.home, Either::Right(Redirect::to(host.clone())));
        }
        _ => (),
    };

    let body = index_html(json!({
        "user": match json {
            Some(Ok(json)) => json,
            _ => json!(null),
         },
         "global": global_flags(&config, &lang)
    }));

    Cors::new(&config.home, Either::Left(Html(body)))
}

/// Returns the same content as the async page, but without cors headers.
pub async fn index_without_cors(
    config: &S<Config>,
    db: Db,
    user: Option<User>,
    lang: Lang,
) -> Either<Html<String>, Redirect> {
    let (json, redirect) = match user {
        Some(ref user) => (
            Some(user.to_json(&db).await),
            (config.premium_only != (user.plan >= Plan::PremiumLvl1)) && user.plan != Plan::Admin,
        ),
        None => (None, false),
    };

    match (redirect, config.other_host.as_ref()) {
        (true, Some(host)) => {
            return Either::Right(Redirect::to(host.clone()));
        }
        _ => (),
    };

    let body = index_html(json!({
        "user": match json {
            Some(Ok(json)) => {
                json
            },
            _ =>
                json!(null)
            },
         "global": global_flags(&config, &lang)
    }));

    Either::Left(Html(body))
}

/// The route to the preparation of a capsule.
#[get("/capsule/preparation/<_id>")]
pub async fn preparation(
    config: &S<Config>,
    db: Db,
    user: Option<User>,
    _id: String,
    lang: Lang,
) -> Either<Html<String>, Redirect> {
    index_without_cors(config, db, user, lang).await
}

/// The route to the acquisition of a capsule.
#[get("/capsule/acquisition/<_id>/<_gos_id>")]
pub async fn acquisition(
    config: &S<Config>,
    db: Db,
    user: Option<User>,
    _id: String,
    _gos_id: u64,
    lang: Lang,
) -> Either<Html<String>, Redirect> {
    index_without_cors(config, db, user, lang).await
}

/// The route to the production of a capsule.
#[get("/capsule/production/<_id>/<_gos_id>")]
pub async fn production(
    config: &S<Config>,
    db: Db,
    user: Option<User>,
    _id: String,
    _gos_id: u64,
    lang: Lang,
) -> Either<Html<String>, Redirect> {
    index_without_cors(config, db, user, lang).await
}

/// The route to the publication of a capsule.
#[get("/capsule/publication/<_id>")]
pub async fn publication(
    config: &S<Config>,
    db: Db,
    user: Option<User>,
    _id: String,
    lang: Lang,
) -> Either<Html<String>, Redirect> {
    index_without_cors(config, db, user, lang).await
}

/// The route to the publication of a capsule.
#[get("/capsule/options/<_id>")]
pub async fn options(
    config: &S<Config>,
    db: Db,
    user: Option<User>,
    _id: String,
    lang: Lang,
) -> Either<Html<String>, Redirect> {
    index_without_cors(config, db, user, lang).await
}

/// The route to the profile page.
#[get("/profile")]
pub async fn profile(
    config: &S<Config>,
    db: Db,
    user: Option<User>,
    lang: Lang,
) -> Either<Html<String>, Redirect> {
    index_without_cors(config, db, user, lang).await
}

/// The route to the admin dashboard page.
#[get("/admin")]
pub async fn admin_dashboard(
    config: &S<Config>,
    db: Db,
    user: Option<User>,
    lang: Lang,
) -> Either<Html<String>, Redirect> {
    index_without_cors(config, db, user, lang).await
}

/// The route to the admin users page.
#[get("/admin/users/<_page>")]
pub async fn admin_users(
    config: &S<Config>,
    db: Db,
    user: Option<User>,
    _page: String,
    lang: Lang,
) -> Either<Html<String>, Redirect> {
    index_without_cors(config, db, user, lang).await
}

/// The route to the admin user page.
#[get("/admin/user/<_id>")]
pub async fn admin_user(
    config: &S<Config>,
    db: Db,
    user: Option<User>,
    _id: String,
    lang: Lang,
) -> Either<Html<String>, Redirect> {
    index_without_cors(config, db, user, lang).await
}

/// The route to the admin capsules page.
#[get("/admin/capsules/<_page>")]
pub async fn admin_capsules(
    config: &S<Config>,
    db: Db,
    user: Option<User>,
    _page: String,
    lang: Lang,
) -> Either<Html<String>, Redirect> {
    index_without_cors(config, db, user, lang).await
}

/// The route to the settings of a capsule.
#[get("/capsule/settings/<_id>")]
pub async fn capsule_settings(
    config: &S<Config>,
    db: Db,
    user: Option<User>,
    _id: String,
    lang: Lang,
) -> Either<Html<String>, Redirect> {
    index_without_cors(config, db, user, lang).await
}

/// The 404 catcher.
#[catch(404)]
pub async fn not_found<'a>(request: &'_ Request<'a>) -> Either<Html<String>, Redirect> {
    let db = Db::from_request(request).await.unwrap();
    let config = request.guard::<&S<Config>>().await.unwrap();
    let user = Option::<User>::from_request(request).await.unwrap();
    let lang = Lang::from_request(request).await.unwrap();
    index_without_cors(config, db, user, lang).await
}

/// The route for asset static files that require authorization.
#[get("/<capsule_id>/assets/<path..>")]
pub async fn assets<'a>(
    capsule_id: HashId,
    path: PathBuf,
    user: User,
    config: &S<Config>,
    db: Db,
) -> Result<NamedFile> {
    let (_, _) = user
        .get_capsule_with_permission(*capsule_id, Role::Read, &db)
        .await?;

    NamedFile::open(
        config
            .data_path
            .join(format!("{}", *capsule_id))
            .join("assets")
            .join(path),
    )
    .await
    .map_err(|_| Error(Status::NotFound))
}

/// The route for the output video of a capsule that requires authorization.
#[get("/<capsule_id>/output.mp4")]
pub async fn produced_video<'a>(
    capsule_id: HashId,
    user: User,
    config: &S<Config>,
    db: Db,
) -> Result<NamedFile> {
    let (_, _) = user
        .get_capsule_with_permission(*capsule_id, Role::Read, &db)
        .await?;

    NamedFile::open(
        config
            .data_path
            .join(format!("{}", *capsule_id))
            .join("output.mp4"),
    )
    .await
    .map_err(|_| Error(Status::NotFound))
}

/// The route for temporary static files that require authorization.
#[get("/<capsule_id>/tmp/<path..>")]
pub async fn tmp<'a>(
    capsule_id: HashId,
    path: PathBuf,
    user: User,
    config: &S<Config>,
    db: Db,
) -> Result<NamedFile> {
    let (_, _) = user
        .get_capsule_with_permission(*capsule_id, Role::Read, &db)
        .await?;

    NamedFile::open(
        config
            .data_path
            .join(format!("{}", *capsule_id))
            .join("tmp")
            .join(path),
    )
    .await
    .map_err(|_| Error(Status::NotFound))
}

/// The route for static files.
#[get("/<path..>")]
pub async fn dist(path: PathBuf) -> Result<NamedFile> {
    NamedFile::open(PathBuf::from("dist").join(path))
        .await
        .map_err(|_| Error(Status::NotFound))
}
