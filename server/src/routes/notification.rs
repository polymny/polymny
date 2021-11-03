//! This module contains the routes for notification management.

use rocket::http::Status;

use crate::db::notification::Notification;
use crate::db::user::User;
use crate::{Db, Error, Result};

/// Route that marks a notification as read.
#[post("/mark-as-read/<id>")]
pub async fn mark_as_read(user: User, db: Db, id: i32) -> Result<()> {
    let mut notification = Notification::get_by_id(id, &db)
        .await?
        .ok_or(Error(Status::BadRequest))?;

    if notification.owner(&db).await?.id != user.id {
        return Err(Error(Status::Forbidden));
    }

    notification.read = true;
    notification.save(&db).await?;

    Ok(())
}

/// Route that deletes a notifcation.
#[delete("/notification/<id>")]
pub async fn delete(user: User, db: Db, id: i32) -> Result<()> {
    let notification = Notification::get_by_id(id, &db)
        .await?
        .ok_or(Error(Status::BadRequest))?;

    if notification.owner(&db).await?.id != user.id {
        return Err(Error(Status::Forbidden));
    }

    notification.delete(&db).await?;

    Ok(())
}
