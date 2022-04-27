//! This module contains the route to watch videos.

use std::io::Cursor;
use std::path::PathBuf;

use rocket::fs::NamedFile;
use rocket::http::{ContentType, Status};
use rocket::request::Request;
use rocket::response::{self, Responder, Response};
use rocket::State as S;

use crate::config::Config;
use crate::db::capsule::{Capsule, Privacy, Role};
use crate::db::task_status::TaskStatus;
use crate::db::user::Plan;
use crate::db::user::User;
use crate::routes::Cors;
use crate::templates::video_html;
use crate::{Db, Error, HashId, Result};

/// A custom response type for allowing iframes on the watch route.
pub struct CustomResponse(String);

impl<'r, 'o: 'r> Responder<'r, 'o> for CustomResponse {
    fn respond_to(self, _request: &'r Request<'_>) -> response::Result<'o> {
        Ok(Response::build()
            .sized_body(self.0.len(), Cursor::new(self.0))
            .header(ContentType::HTML)
            .finalize())
    }
}

/// The route that serves HTML to watch videos.
#[get("/v/<capsule_id>", rank = 1)]
pub async fn watch<'a>(
    config: &S<Config>,
    user: Option<User>,
    capsule_id: HashId,
    db: Db,
) -> Result<CustomResponse> {
    let capsule = Capsule::get_by_id(*capsule_id as i32, &db)
        .await?
        .ok_or(Error(Status::NotFound))?;

    if capsule.published != TaskStatus::Done {
        return Err(Error(Status::NotFound));
    }

    // Check authorization.
    if capsule.privacy == Privacy::Private {
        match user {
            None => return Err(Error(Status::Unauthorized)),
            Some(user) => {
                user.get_capsule_with_permission(*capsule_id, Role::Read, &db)
                    .await?;
            }
        }
    }

    // Check if video is on current host or other host.

    // If there is another host
    let mut host = String::new();

    if let Some(other_host) = &config.other_host {
        // Look of the owner of the capsule
        let owner = capsule.owner(&db).await?;
        // If premium state doesn't match the owner plan
        if config.premium_only != (owner.plan >= Plan::PremiumLvl1) {
            // Redirect to the other host
            host = other_host.to_string();
        }
    }

    Ok(CustomResponse(video_html(&format!(
        "{}/v/{}/manifest.m3u8",
        host,
        capsule_id.hash()
    ))))
}

/// The route that serves files inside published videos.
#[get("/v/<capsule_id>/<path..>", rank = 2)]
pub async fn watch_asset(
    user: Option<User>,
    capsule_id: HashId,
    path: PathBuf,
    config: &S<Config>,
    db: Db,
) -> Cors<Result<NamedFile>> {
    Cors::new(
        &Some("*".to_string()),
        watch_asset_aux(user, capsule_id, path, config, db).await,
    )
}

/// Helper function to the route that serves files inside published videos.
///
/// Makes us able to easily wrap cors.
pub async fn watch_asset_aux(
    user: Option<User>,
    capsule_id: HashId,
    path: PathBuf,
    config: &S<Config>,
    db: Db,
) -> Result<NamedFile> {
    let capsule = Capsule::get_by_id(*capsule_id as i32, &db)
        .await?
        .ok_or(Error(Status::NotFound))?;

    if capsule.published != TaskStatus::Done {
        return Err(Error(Status::NotFound));
    }

    // Check authorization.
    if capsule.privacy == Privacy::Private {
        match user {
            None => return Err(Error(Status::Unauthorized)),
            Some(user) => {
                user.get_capsule_with_permission(*capsule_id, Role::Read, &db)
                    .await?;
            }
        }
    }

    NamedFile::open(
        config
            .data_path
            .join(format!("{}", *capsule_id))
            .join("output")
            .join(path),
    )
    .await
    .map_err(|_| Error(Status::NotFound))
}

/// The route for the js file that contains elm-video.
#[get("/v/polymny-video-full.min.js")]
pub async fn polymny_video() -> Result<NamedFile> {
    NamedFile::open(PathBuf::from("dist").join("polymny-video-full.min.js"))
        .await
        .map_err(|_| Error(Status::NotFound))
}
