//! This module contains all the routes.

pub mod asset;
pub mod auth;
pub mod capsule;
pub mod loggedin;
pub mod project;
pub mod setup;
pub mod slide;

use std::io::Cursor;
use std::path::PathBuf;

use rocket::http::ContentType;
use rocket::response::{NamedFile, Response};
use rocket::State;

use rocket_contrib::json::JsonValue;

use crate::config::Config;
use crate::db::user::User;
use crate::templates::{index_html, setup_html};
use crate::{Database, Result};

/// Helper to answer the HTML page with the Elm code as well as flags.
pub fn helper<'a>(flags: JsonValue) -> Response<'a> {
    Response::build()
        .header(ContentType::HTML)
        .sized_body(Cursor::new(index_html(flags)))
        .finalize()
}

/// The index page.
#[get("/")]
pub fn index<'a>(config: State<Config>, db: Database, user: Option<User>) -> Result<Response<'a>> {
    let user_and_projects = if let Some(user) = user.as_ref() {
        Some((user, user.projects(&db)?))
    } else {
        None
    };

    let flags = user_and_projects
        .map(|(user, projects)| {
            json!({
                "page": "index",
                "username": user.username,
                "projects": projects,
                "active_project":"",
                "video_root": config.video_root,
                "beta": config.beta,
                "version": config.version,
            })
        })
        .unwrap_or_else(|| {
            json!({
                "video_root": config.video_root,
                "beta": config.beta,
                "version": config.version,
            })
        });

    Ok(helper(flags))
}

fn jsonify_flags(
    config: &Config,
    db: &Database,
    user: &Option<User>,
    id: i32,
    page: &str,
) -> Result<JsonValue> {
    let user_and_projects = if let Some(user) = user.as_ref() {
        Some((user, user.projects(&db)?))
    } else {
        None
    };

    Ok(match user.as_ref().map(|x| x.get_capsule_by_id(id, &db)) {
        Some(Ok(capsule)) => {
            let slide_show = capsule.get_slide_show(&db)?;
            let slides = capsule.get_slides(&db)?;
            let background = capsule.get_background(&db)?;
            let logo = capsule.get_logo(&db)?;
            let video = capsule.get_video(&db)?;

            user_and_projects
                .map(|(user, projects)| {
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
                        "video": video,
                        "video_root": config.video_root,
                        "beta": config.beta,
                        "version": config.version,
                    })
                })
                .unwrap_or_else(|| {
                    json!({
                        "video_root": config.video_root,
                        "beta": config.beta,
                        "version": config.version,
                    })
                })
        }

        _ => user_and_projects
            .map(|(user, projects)| {
                json!({
                    "username": user.username,
                    "projects": projects,
                    "page": "index",
                    "active_project": "",
                    "video_root": config.video_root,
                    "beta": config.beta,
                    "version": config.version,
                })
            })
            .unwrap_or_else(|| {
                json!({
                    "video_root": config.video_root,
                    "beta": config.beta,
                    "version": config.version,
                })
            }),
    })
}

/// A page that moves the client directly to the capsule view.
#[get("/capsule/<id>/preparation")]
pub fn capsule_preparation<'a>(
    config: State<Config>,
    db: Database,
    user: Option<User>,
    id: i32,
) -> Result<Response<'a>> {
    Ok(helper(jsonify_flags(
        &config,
        &db,
        &user,
        id,
        "preparation/capsule",
    )?))
}
/// A page that moves the client directly to the capsule view.
#[get("/capsule/<id>/acquisition")]
pub fn capsule_acquisition<'a>(
    config: State<Config>,
    db: Database,
    user: Option<User>,
    id: i32,
) -> Result<Response<'a>> {
    Ok(helper(jsonify_flags(
        &config,
        &db,
        &user,
        id,
        "acquisition/capsule",
    )?))
}

/// A page that moves the client directly to the capsule view.
#[get("/capsule/<id>/edition")]
pub fn capsule_edition<'a>(
    config: State<Config>,
    db: Database,
    user: Option<User>,
    id: i32,
) -> Result<Response<'a>> {
    Ok(helper(jsonify_flags(
        &config,
        &db,
        &user,
        id,
        "edition/capsule",
    )?))
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
    if path.starts_with(user.username) {
        let data_path = config.data_path.join(path);
        NamedFile::open(data_path).ok()
    } else {
        None
    }
}
