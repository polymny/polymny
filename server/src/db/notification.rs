//! This module contains the structures needed to manipulate notifications.

use diesel::prelude::*;

use crate::db::user::User;
use crate::schema::notifications;
use crate::{Database, Result};

#[allow(missing_docs)]
mod notification_style {
    /// The different styles a notification can have.
    #[derive(Debug, PartialEq, Eq, DbEnum, Serialize, Copy, Clone)]
    pub enum NotificationStyle {
        /// Some information about something that happened.
        Info,

        /// A warning that indicates that a problem may occur.
        Warning,

        /// Something went wrong.
        Error,
    }

    impl NotificationStyle {
        /// Converts the style to a string.
        pub fn to_str(self) -> &'static str {
            match self {
                NotificationStyle::Info => "info",
                NotificationStyle::Warning => "warning",
                NotificationStyle::Error => "danger",
            }
        }
    }
}

pub use notification_style::NotificationStyleMapping as Notification_style;
pub use notification_style::{NotificationStyle, NotificationStyleMapping};

/// A notification that belongs to a user.
#[derive(Identifiable, Queryable, Associations, PartialEq, Debug)]
#[table_name = "notifications"]
#[belongs_to(User)]
pub struct Notification {
    /// The id of the notification.
    pub id: i32,

    /// The owner of the notification.
    pub user_id: i32,

    /// The title the notification.
    pub title: String,

    /// The message of the notification.
    pub content: String,

    /// Whether the notification is read or not.
    pub read: bool,

    /// The style of the notification.
    pub style: NotificationStyle,
}

impl Notification {
    /// Creates a new notofication and stores it in the database.
    pub fn new(
        style: NotificationStyle,
        user_id: i32,
        title: &str,
        content: &str,
        db: &Database,
    ) -> Result<()> {
        Ok(NewNotification {
            user_id,
            title: title.to_owned(),
            content: content.to_owned(),
            style,
        }
        .save(&db)?)
    }
}

/// A new notification not stored in the database yet.
#[derive(Debug, Insertable)]
#[table_name = "notifications"]
pub struct NewNotification {
    /// The owner of the notification.
    pub user_id: i32,

    /// The title the notification.
    pub title: String,

    /// The message of the notification.
    pub content: String,

    /// The style of the notification.
    pub style: NotificationStyle,
}

impl NewNotification {
    /// Saves a notification.
    pub fn save(&self, db: &Database) -> Result<()> {
        diesel::insert_into(notifications::table)
            .values(self)
            .execute(&db.0)?;
        Ok(())
    }
}
