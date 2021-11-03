//! This module contains the route to watch videos.

use std::path::PathBuf;

use rocket::fs::NamedFile;
use rocket::http::Status;
use rocket::response::content::Html;
use rocket::State as S;

use crate::config::Config;
use crate::db::capsule::{Capsule, Privacy, Role};
use crate::db::task_status::TaskStatus;
use crate::db::user::User;
use crate::templates::video_html;
use crate::{Db, Error, HashId, Result};

/// The route that serves HTML to watch videos.
#[get("/v/<capsule_id>", rank = 1)]
pub async fn watch<'a>(user: Option<User>, capsule_id: HashId, db: Db) -> Result<Html<String>> {
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

    Ok(Html(video_html(&format!(
        "/v/{}/manifest.m3u8",
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
