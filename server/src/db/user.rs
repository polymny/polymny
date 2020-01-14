//! This module contains the structures to manipulate users.

use tera::Context;

use diesel::prelude::*;
use diesel::RunQueryDsl;
use diesel::pg::PgConnection;

use rand::Rng;
use rand::rngs::OsRng;
use rand::distributions::Alphanumeric;

use bcrypt::{DEFAULT_COST, hash};

use crate::{Error, Result, TEMPLATES};
use crate::schema::{users, sessions};
use crate::db::session::{Session, NewSession};
use crate::mailer::Mailer;

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
#[derive(Debug, Insertable)]
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
    pub fn create(username: &str, email: &str, password: &str, mailer: &Option<Mailer>) -> Result<NewUser> {

        // Hash the password
        let hashed_password = hash(&password, DEFAULT_COST)?;

        if let Some(mailer) = mailer {

            // Generate the activation key
            let rng = OsRng {};
            let activation_key = rng
                .sample_iter(&Alphanumeric)
                .take(40)
                .collect::<String>();

            let mut context = Context::new();

            let activation_url = format!("{}/api/activate/{}", mailer.root, activation_key);
            context.insert("activation_url", &activation_url);

            let text = TEMPLATES.render("email_address_validation.txt", &context)?;
            let html = TEMPLATES.render("email_address_validation.html", &context)?;

            mailer.send_mail(email, String::from("Welcome"), text, html)?;

            Ok(NewUser {
                username: String::from(username),
                email: String::from(email),
                hashed_password: hashed_password,
                activated: false,
                activation_key: Some(activation_key),
            })

        } else {
            Ok(NewUser {
                username: String::from(username),
                email: String::from(email),
                hashed_password: hashed_password,
                activated: true,
                activation_key: None,
            })
        }

    }

    /// Activates a user from its activation key.
    pub fn activate(key: &str, db: &PgConnection) -> Result<()> {
        use crate::schema::users::dsl::*;

        let none: Option<String> = None;

        diesel::update(users.filter(activation_key.eq(key)))
            .set((activation_key.eq(none), activated.eq(true)))
            .get_result::<User>(db)?;

        Ok(())
    }

    /// Authenticates a user from its username and password.
    pub fn authenticate(auth_username: &str, auth_password: &str, db: &PgConnection) -> Result<User> {
        use crate::schema::users::dsl::*;

        let user = users
            .filter(username.eq(auth_username))
            .filter(activated.eq(true))
            .select((id, username, email, hashed_password, activated, activation_key))
            .first::<User>(db);

        let user = match user {
            Ok(user) => user,
            Err(_) => return Err(Error::AuthenticationFailed),
        };

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
        let secret = rng
            .sample_iter(&Alphanumeric)
            .take(40)
            .collect::<String>();

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
        use crate::schema::users::dsl as users;
        use crate::schema::sessions::dsl as sessions;

        let session = sessions::sessions
            .filter(sessions::secret.eq(secret))
            .first::<Session>(db)?;

        let user = users::users
            .filter(users::id.eq(session.user_id))
            .first::<User>(db)?;

        Ok(user)
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



