//! This module contains the notification struct.

use ergol::prelude::*;

use rocket::serde::json::{json, Value};

use crate::db::user::User;

/// A notification to a user.
#[ergol]
pub struct Notification {
    /// The id of the notification.
    #[id]
    pub id: i32,

    /// The title of the notification.
    pub title: String,

    /// The content of the notification.
    pub content: String,

    /// Whether the notification has been read or not.
    pub read: bool,

    /// The user that received the notification.
    #[many_to_one(notifications)]
    pub owner: User,
}

impl Notification {
    /// Returns a json representation of the notification.
    pub fn to_json(&self) -> Value {
        json!({
            "type": "notification",
            "title": self.title,
            "content": self.content,
            "read": self.read,
            "id": self.id,
        })
    }
}
