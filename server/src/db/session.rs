//! This module contains the session struct and how it interacts with the database.

use ergol::prelude::*;

use crate::db::user::User;
use crate::{Db, Error};

/// The cookie allowing a user to stay logged in.
#[ergol]
pub struct Session {
    /// The id of the session.
    #[id]
    pub id: i32,

    /// The string encoding the session.
    #[unique]
    pub secret: String,

    /// The user referenced by the session.
    #[many_to_one(sessions)]
    pub owner: User,
}

impl Session {
    /// Creates and saves a session.
    pub async fn new(secret: String, owner: &User, db: &Db) -> Result<Session, Error> {
        let session = Session::create(secret, owner).save(db).await?;
        Ok(session)
    }
}
