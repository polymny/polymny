//! This module contains the structures needed to manipulate sessions.

use diesel::pg::PgConnection;
use diesel::prelude::*;

use crate::db::user::User;
use crate::schema::sessions;
use crate::{Error, Result};

/// A session that belongs to a user.
#[derive(Identifiable, Queryable, Associations, PartialEq, Debug)]
#[belongs_to(User)]
pub struct Session {
    /// The id of the session.
    pub id: i32,

    /// The owner of the session.
    pub user_id: i32,

    /// The secret id of the session.
    pub secret: String,
}

impl Session {
    /// Finds a session in the database from its secret key.
    ///
    /// Returns none if no session was found.
    pub fn from_secret(key: &str, db: &PgConnection) -> Result<Session> {
        use crate::schema::sessions::dsl::*;
        sessions
            .filter(secret.eq(key))
            .select((id, user_id, secret))
            .first::<Session>(db)
            .map_err(|_| Error::SessionDoesNotExist)
    }

    /// Removes a session in the database from its secret key.
    pub fn delete_from_secret(key: &str, db: &PgConnection) -> Result<()> {
        use crate::schema::sessions::dsl::*;
        diesel::delete(sessions.filter(secret.eq(key))).execute(db)?;
        Ok(())
    }
}

/// A new session not stored in the database yet.
#[derive(Debug, Insertable)]
#[table_name = "sessions"]
pub struct NewSession {
    /// The owner of the session.
    pub user_id: i32,

    /// The secret id of the session.
    pub secret: String,
}
