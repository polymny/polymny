//! This module contains all the routes.

pub mod asset;
pub mod auth;
pub mod capsule;
pub mod loggedin;
pub mod notification;
pub mod project;
pub mod setup;
pub mod slide;

use std::io::Cursor;
use std::path::PathBuf;

use rocket::http::ContentType;
use rocket::response::Response;
use rocket::State;

use rocket_contrib::json::JsonValue;

use rocket_seek_stream::SeekStream;

use crate::config::Config;
use crate::db::user::User;
use crate::templates;
use crate::webcam::{webcam_position_to_str, webcam_size_to_str};
use crate::{Database, Error, Result};

fn capsule_flags(db: &Database, user: &Option<User>, id: i32, page: &str) -> Result<JsonValue> {
    let user_and_projects = if let Some(user) = user.as_ref() {
        let x = user.get_capsule_by_id(id, &db)?;
        let projects = x
            .get_projects_with_capsules(&db)?
            .into_iter()
            .filter(|x| x.user_id == user.id)
            .collect::<Vec<_>>();
        Some((user, projects))
    } else {
        None
    };
    Ok(match user.as_ref().map(|x| x.get_capsule_by_id(id, &db)) {
        Some(Ok(capsule)) => {
            let slide_show = capsule.get_slide_show(&db)?;
            let slides = capsule.get_slides(&db)?;
            let background = capsule.get_background(&db)?;
            let logo = capsule.get_logo(&db)?;
            let capsule = capsule.with_video(&db)?;

            user_and_projects
                .map(|(user, projects)| {
                    let edition_options = user.get_edition_options().unwrap();
                    let session = user.session(&db).unwrap();
                    let notifications = user.notifications(&db).unwrap();

                    json!({
                        "page":       page,
                        "username":   user.username,
                        "projects":   projects,
                        "capsule" :   capsule,
                        "slide_show": slide_show,
                        "slides":     slides,
                        "background":  background,
                        "logo":        logo,
                        "active_project":"",
                        "structure":   capsule.structure,
                        "with_video": edition_options.with_video,
                        "webcam_size": webcam_size_to_str(edition_options.webcam_size),
                        "webcam_position": webcam_position_to_str(edition_options.webcam_position),
                        "cookie": session.secret,
                        "notifications": notifications,
                    })
                })
                .unwrap_or_else(|| json!(null))
        }

        _ => user_and_projects
            .map(|(user, projects)| {
                let edition_options = user.get_edition_options().unwrap();
                let session = user.session(&db).unwrap();
                let notifications = user.notifications(&db).unwrap();

                json!({
                    "username": user.username,
                    "projects": projects,
                    "page": "index",
                    "active_project": "",
                    "with_video": edition_options.with_video,
                    "webcam_size": webcam_size_to_str(edition_options.webcam_size),
                    "webcam_position": webcam_position_to_str(edition_options.webcam_position),
                    "cookie": session.secret,
                    "notifications": notifications,
                })
            })
            .unwrap_or_else(|| json!(null)),
    })
}

fn project_flags(db: &Database, user: &Option<User>, id: i32, page: &str) -> Result<JsonValue> {
    let user_and_projects = if let Some(user) = user.as_ref() {
        let project = user.get_project_by_id(id, &db)?;
        let capsules = project
            .get_capsules(&db)?
            .into_iter()
            .map(|x| x.with_video(&db))
            .collect::<Result<Vec<_>>>()?;
        let projects = user.projects(&db)?;
        Some((user, project, capsules, projects))
    } else {
        None
    };

    Ok(user_and_projects
        .map(|(user, project, capsules, projects)| {
            let edition_options = user.get_edition_options().unwrap();
            let session = user.session(&db).unwrap();
            let notifications = user.notifications(&db).unwrap();
            json!({
                "page": page,
                "username": user.username,
                "projects": projects,
                "project": project,
                "capsules": capsules,
                "active_project": "",
                "with_video": edition_options.with_video,
                "webcam_size": webcam_size_to_str(edition_options.webcam_size),
                "webcam_position": webcam_position_to_str(edition_options.webcam_position),
                "cookie": session.secret,
                "notifications": notifications,
            })
        })
        .unwrap_or_else(|| json!(null)))
}

fn settings_flags(db: &Database, user: &Option<User>, page: &str) -> Result<JsonValue> {
    let user_projects_options = if let Some(user) = user.as_ref() {
        let projects = user.projects(&db)?;
        let edition_options = user.get_edition_options().unwrap();
        Some((user, projects, edition_options))
    } else {
        None
    };

    Ok(user_projects_options
        .map(|(user, projects, edition_options)| {
            let session = user.session(&db).unwrap();
            let notifications = user.notifications(&db).unwrap();
            json!({
                "page": page,
                "username": user.username,
                "with_video": edition_options.with_video,
                "projects": projects,
                "active_project": "",
                "webcam_size": webcam_size_to_str(edition_options.webcam_size),
                "webcam_position": webcam_position_to_str(edition_options.webcam_position),
                "cookie": session.secret,
                "notifications": notifications,
            })
        })
        .unwrap_or_else(|| json!(null)))
}

/// Returns the json for the global info.
fn global(config: &State<Config>) -> JsonValue {
    json!({
        "socket_root": config.socket_root,
        "video_root": config.video_root,
        "beta": config.beta,
        "version": config.version,
        "commit": config.commit,
        "matting_enabled": config.matting_enabled,
        "home": config.home,
    })
}

/// Helper to answer the HTML page with the Elm code as well as flags.
fn helper_html<'a>(config: &State<Config>, flags: JsonValue) -> Response<'a> {
    Response::build()
        .header(ContentType::HTML)
        .sized_body(Cursor::new(templates::index_html(helper_json(
            config, flags,
        ))))
        .finalize()
}

/// Helper to answer the JSON info as well as flags.
fn helper_json(config: &State<Config>, flags: JsonValue) -> JsonValue {
    json!({"global": global(config), "flags": flags})
}

macro_rules! make_route {
    ($route: expr, $db: ident, $user: ident, $function: expr, $function_html: ident, $function_json: ident) => {
        #[allow(missing_docs)]
        #[get($route, format = "text/html", rank = 1)]
        pub fn $function_html<'a>(
            config: State<Config>,
            $db: Database,
            $user: Option<User>,
        ) -> Result<Response<'a>> {
            Ok(helper_html(&config, $function))
        }

        #[allow(missing_docs)]
        #[get($route, format = "application/json", rank = 2)]
        pub fn $function_json<'a>(
            config: State<Config>,
            $db: Database,
            $user: Option<User>,
        ) -> Result<JsonValue> {
            Ok(helper_json(&config, $function))
        }
    };

    ($route: expr, $db: ident, $user: ident, $param: expr, $ty: ty, $function: expr, $function_html: ident, $function_json: ident) => {
        #[allow(missing_docs)]
        #[get($route, format = "text/html", rank = 1)]
        pub fn $function_html<'a>(
            config: State<Config>,
            $db: Database,
            $user: Option<User>,
            $param: $ty,
        ) -> Result<Response<'a>> {
            Ok(helper_html(&config, $function))
        }

        #[allow(missing_docs)]
        #[get($route, format = "application/json", rank = 2)]
        pub fn $function_json<'a>(
            config: State<Config>,
            $db: Database,
            $user: Option<User>,
            $param: $ty,
        ) -> Result<JsonValue> {
            Ok(helper_json(&config, $function))
        }
    };
}

/// The json for the index page.
fn index(db: Database, user: Option<User>) -> Result<JsonValue> {
    let user_and_projects = if let Some(user) = user.as_ref() {
        Some((user, user.projects(&db)?))
    } else {
        None
    };

    Ok(user_and_projects
        .map(|(user, projects)| {
            let edition_options = user.get_edition_options().unwrap();
            let session = user.session(&db).unwrap();
            let notifications = user.notifications(&db).unwrap();
            json!({
                "page": "index",
                "username": user.username,
                "projects": projects,
                "active_project":"",
                "with_video": edition_options.with_video,
                "webcam_size": webcam_size_to_str(edition_options.webcam_size),
                "webcam_position": webcam_position_to_str(edition_options.webcam_position),
                "cookie": session.secret,
                "notifications": notifications,
            })
        })
        .unwrap_or_else(|| json!(null)))
}

make_route!("/", db, user, index(db, user)?, index_html, index_json);

make_route!(
    "/capsule/<id>/preparation",
    db,
    user,
    id,
    i32,
    capsule_flags(&db, &user, id, "preparation/capsule")?,
    capsule_preparation_html,
    capsule_preparation_json
);

make_route!(
    "/capsule/<id>/acquisition",
    db,
    user,
    id,
    i32,
    capsule_flags(&db, &user, id, "acquisition/capsule")?,
    capsule_acquisition_html,
    capsule_acquisition_json
);

make_route!(
    "/capsule/<id>/edition",
    db,
    user,
    id,
    i32,
    capsule_flags(&db, &user, id, "edition/capsule")?,
    capsule_edition_html,
    capsule_edition_json
);

make_route!(
    "/project/<id>",
    db,
    user,
    id,
    i32,
    project_flags(&db, &user, id, "project")?,
    project_html,
    project_json
);

make_route!(
    "/settings",
    db,
    user,
    settings_flags(&db, &user, "settings")?,
    settings_html,
    settings_json
);

/// The route for the setup page, available only when Rocket.toml does not exist yet.
#[get("/")]
pub fn setup<'a>() -> Response<'a> {
    Response::build()
        .header(ContentType::HTML)
        .sized_body(Cursor::new(templates::setup_html()))
        .finalize()
}

/// The route for static files that require authorization.
#[get("/<path..>")]
pub fn data<'a>(path: PathBuf, user: User, config: State<Config>) -> Result<SeekStream<'a>> {
    if path.starts_with(user.username) {
        let data_path = config.data_path.join(path);
        Ok(SeekStream::from_path(data_path)?)
    } else {
        Err(Error::NotFound)
    }
}
