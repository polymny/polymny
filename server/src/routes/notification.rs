//! This module contains the routes that changes notifcations.

use crate::db::user::User;
use crate::{Database, Result};

/// Mark a notifcation as read.
#[post("/mark-as-read/<id>")]
pub fn mark_as_read(db: Database, id: i32, user: User) -> Result<()> {
    user.mark_notification_as_read(id, &db)?;
    Ok(())
}
