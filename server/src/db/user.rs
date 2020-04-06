//! This module contains the structures to manipulate users.

use diesel::pg::PgConnection;
use diesel::prelude::*;
use diesel::RunQueryDsl;

use rocket::http::Status;
use rocket::request::{FromRequest, Outcome, Request};

use rand::distributions::Alphanumeric;
use rand::rngs::OsRng;
use rand::Rng;

use bcrypt::{hash, DEFAULT_COST};

use serde::Deserialize;

use crate::db::capsule::{Capsule, CapsulesProject};
use crate::db::project::Project;
use crate::db::session::{NewSession, Session};
use crate::mailer::Mailer;
use crate::schema::{sessions, users};
use crate::templates::{validation_email_html, validation_email_plain_text};
use crate::Database;
use crate::{Error, Result};

/// A user of chouette.
#[derive(Identifiable, Queryable, PartialEq, Debug)]
pub struct User {
    /// The id of the user.
    pub id: i32,

    /// The username of the user.
    pub username: String,

    /// The email of the user.
    pub email: String,

    /// The BCrypt hash of the password of the user.
    pub hashed_password: String,

    /// Whether the user is activated or not.
    pub activated: bool,

    /// The activation key of the user if it is not active.
    pub activation_key: Option<String>,
}

/// A user that is stored into the database yet.
#[derive(Debug, Insertable, Deserialize)]
#[table_name = "users"]
pub struct NewUser {
    /// The username of the user.
    pub username: String,

    /// The email of the new user.
    pub email: String,

    /// The BCrypt hashed password of the new user.
    pub hashed_password: String,

    /// Whether the new user is automatically activated or not.
    pub activated: bool,

    /// The activation key of the new user.
    pub activation_key: Option<String>,
}

impl User {
    /// Creates a new user.
    pub fn create(
        username: &str,
        email: &str,
        password: &str,
        mailer: &Option<Mailer>,
    ) -> Result<NewUser> {
        // Hash the password
        let hashed_password = hash(&password, DEFAULT_COST)?;

        match mailer {
            Some(mailer) if mailer.require_email_validation => {
                // Generate the activation key
                let rng = OsRng {};
                let activation_key = rng.sample_iter(&Alphanumeric).take(40).collect::<String>();

                let activation_url = format!("{}/api/activate/{}", mailer.root, activation_key);
                let text = validation_email_plain_text(&activation_url);
                let html = validation_email_html(&activation_url);

                mailer.send_mail(email, String::from("Welcome"), text, html)?;

                Ok(NewUser {
                    username: String::from(username),
                    email: String::from(email),
                    hashed_password,
                    activated: false,
                    activation_key: Some(activation_key),
                })
            }

            _ => Ok(NewUser {
                username: String::from(username),
                email: String::from(email),
                hashed_password,
                activated: true,
                activation_key: None,
            }),
        }
    }

    /// Activates a user from its activation key and returns the user.
    pub fn activate(key: &str, db: &PgConnection) -> Result<User> {
        use crate::schema::users::dsl::*;

        let none: Option<String> = None;

        Ok(diesel::update(users.filter(activation_key.eq(key)))
            .set((activation_key.eq(none), activated.eq(true)))
            .get_result::<User>(db)?)
    }

    /// Authenticates a user from its username and password.
    pub fn authenticate(
        auth_username: &str,
        auth_password: &str,
        db: &PgConnection,
    ) -> Result<User> {
        use crate::schema::users::dsl::*;

        let user = users
            .filter(username.eq(auth_username))
            .filter(activated.eq(true))
            .select((
                id,
                username,
                email,
                hashed_password,
                activated,
                activation_key,
            ))
            .first::<User>(db)
            .map_err(|_| Error::AuthenticationFailed)?;

        match bcrypt::verify(&auth_password, &user.hashed_password) {
            Ok(true) => Ok(user),
            Ok(false) => Err(Error::AuthenticationFailed),
            Err(e) => Err(Error::BcryptError(e)),
        }
    }

    /// Creates or updates a session for a user that has been authenticated.
    pub fn save_session(&self, db: &PgConnection) -> Result<Session> {
        // Generate the secret
        let rng = OsRng {};
        let secret = rng.sample_iter(&Alphanumeric).take(40).collect::<String>();

        let session = NewSession {
            user_id: self.id,
            secret,
        };

        Ok(diesel::insert_into(sessions::table)
            .values(&session)
            .get_result(db)?)
    }

    /// Returns the user from its session secret.
    pub fn from_session(secret: &str, db: &PgConnection) -> Result<User> {
        use crate::schema::sessions::dsl as sessions;
        use crate::schema::users::dsl as users;

        let session = sessions::sessions
            .filter(sessions::secret.eq(secret))
            .first::<Session>(db)?;

        let user = users::users
            .filter(users::id.eq(session.user_id))
            .first::<User>(db)?;

        Ok(user)
    }

    /// Returns the list of the user's projects names.
    pub fn projects(&self, db: &PgConnection) -> Result<Vec<Project>> {
        use crate::schema::projects::dsl::*;
        Ok(projects.filter(user_id.eq(self.id)).load::<Project>(db)?)
    }

    /// Gets a project by id, returning an error if the project does not belong to the user.
    pub fn get_project_by_id(&self, project_id: i32, db: &Database) -> Result<Project> {
        let project = Project::get_by_id(project_id, &db)?;
        if project.user_id == self.id {
            Ok(project)
        } else {
            Err(Error::NotFound)
        }
    }

    /// Gets a capsule by id, returning an error if the capsule does not belong to the user.
    pub fn get_capsule_by_id(&self, capsule_id: i32, db: &Database) -> Result<Capsule> {
        let capsule = Capsule::get_by_id(capsule_id, &db)?;
        // TODO: do this in full SQL instead
        let is_allowed = CapsulesProject::belonging_to(&capsule)
            .load::<CapsulesProject>(&db.0)?
            .into_iter()
            .filter_map(|x| Project::get_by_id(x.project_id, &db).ok())
            .any(|x| x.user_id == self.id);

        if is_allowed {
            Ok(capsule)
        } else {
            Err(Error::NotFound)
        }
    }
}

impl<'a, 'r> FromRequest<'a, 'r> for User {
    type Error = Error;

    fn from_request(request: &'a Request<'r>) -> Outcome<Self, Self::Error> {
        let cookie = match request.cookies().get_private("EXAUTH") {
            Some(c) => c,
            _ => return Outcome::Failure((Status::NotFound, Error::RequiresLogin)),
        };

        let db: Database = match FromRequest::from_request(request) {
            Outcome::Success(db) => db,
            _ => return Outcome::Failure((Status::NotFound, Error::RequiresLogin)),
        };

        let user = match User::from_session(cookie.value(), &db) {
            Ok(user) => user,
            _ => return Outcome::Failure((Status::NotFound, Error::RequiresLogin)),
        };

        Outcome::Success(user)
    }
}

impl NewUser {
    /// Saves the new user into the database.
    pub fn save(&self, database: &PgConnection) -> Result<User> {
        Ok(diesel::insert_into(users::table)
            .values(self)
            .get_result(database)?)
    }
}
