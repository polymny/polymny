//! This module contains the structures to manipulate users.

use serde_json::{json, Value as Json};

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

use crate::db::capsule::Capsule;
use crate::db::project::Project;
use crate::db::session::{NewSession, Session};
use crate::db::slide::Slide;
use crate::mailer::Mailer;
use crate::schema::{sessions, users};
use crate::templates::{
    reset_password_email_html, reset_password_email_plain_text, validation_email_html,
    validation_email_plain_text, validation_new_email_html, validation_new_email_plain_text,
};
use crate::webcam::{str_to_webcam_position, str_to_webcam_size, WebcamPosition, WebcamSize};
use crate::Database;
use crate::{Error, Result};

/// A user of polymny.
#[derive(Identifiable, Queryable, PartialEq, Debug, Serialize)]
pub struct User {
    /// The id of the user.
    pub id: i32,

    /// The username of the user.
    pub username: String,

    /// The email of the user.
    pub email: String,

    /// The email when a user wants to change their email.
    pub secondary_email: Option<String>,

    /// The BCrypt hash of the password of the user.
    pub hashed_password: String,

    /// Whether the user is activated or not.
    pub activated: bool,

    /// The activation key of the user if it is not active.
    pub activation_key: Option<String>,

    /// The key to reset the password user.
    pub reset_password_key: Option<String>,

    /// The structure of the editions options.
    ///
    /// This json should be of the form
    /// ```
    ///  {
    ///     with_video: bool,
    ///     webcam_size: String or WebcamSize,
    ///     webcam_position: String or WebcamPosition,
    ///  ]
    /// ```
    pub edition_options: Option<Json>,
}

/// A user that is stored into the database yet.
#[derive(Debug, Insertable, Deserialize)]
#[table_name = "users"]
pub struct NewUser {
    /// The username of the user.
    pub username: String,

    /// The email of the new user.
    pub email: String,

    /// The email when a user wants to change their email.
    pub secondary_email: Option<String>,

    /// The BCrypt hashed password of the new user.
    pub hashed_password: String,

    /// Whether the new user is automatically activated or not.
    pub activated: bool,

    /// The activation key of the new user.
    pub activation_key: Option<String>,

    /// The key to reset the password user.
    pub reset_password_key: Option<String>,

    /// The structure of the editions options.
    pub edition_options: Option<Json>,
}

/// Set of Webcam view options
#[derive(Serialize, Deserialize, Debug)]
pub struct EditionOptions {
    /// Only audio, or audio + video option
    pub with_video: bool,

    /// Size of webcam view
    pub webcam_size: WebcamSize,

    /// Position of webcam view in slide
    pub webcam_position: WebcamPosition,
}

impl User {
    /// Creates a new user.
    pub fn create(
        username: &str,
        email: &str,
        password: &str,
        mailer: &Option<Mailer>,
    ) -> Result<NewUser> {
        // Verify username constraints: the username must follow this regex [a-zA-Z0-9._-]* and len
        // > 3
        if username.len() < 4 {
            return Err(Error::NotFound);
        }

        for c in username.chars() {
            if !(c.is_ascii_alphanumeric() || c == '-' || c == '_' || c == '.') {
                return Err(Error::NotFound);
            }
        }

        // Hash the password
        let hashed_password = hash(&password, DEFAULT_COST)?;

        match mailer {
            Some(mailer) if mailer.require_email_validation => {
                // Generate the activation key
                let rng = OsRng {};
                let activation_key = rng.sample_iter(&Alphanumeric).take(40).collect::<String>();

                let activation_url = format!("{}/activate/{}", mailer.root, activation_key);
                let text = validation_email_plain_text(&activation_url);
                let html = validation_email_html(&activation_url);

                mailer.send_mail(email, String::from("Welcome to Polymny"), text, html)?;

                Ok(NewUser {
                    username: String::from(username),
                    email: String::from(email),
                    secondary_email: None,
                    hashed_password,
                    activated: false,
                    activation_key: Some(activation_key),
                    reset_password_key: None,
                    edition_options: Some(json!([])),
                })
            }

            _ => Ok(NewUser {
                username: String::from(username),
                email: String::from(email),
                secondary_email: None,
                hashed_password,
                activated: true,
                activation_key: None,
                reset_password_key: None,
                edition_options: Some(json!([])),
            }),
        }
    }

    /// Gets a user by email.
    pub fn get_by_email(email: &str, db: &PgConnection) -> Result<User> {
        use crate::schema::users::dsl;
        let user = dsl::users.filter(dsl::email.eq(email)).first::<User>(db);
        Ok(user?)
    }

    /// Gets a user by activation key.
    pub fn get_by_activation_key(key: &str, db: &PgConnection) -> Result<User> {
        use crate::schema::users::dsl;
        let user = dsl::users
            .filter(dsl::activation_key.eq(key))
            .first::<User>(db);
        Ok(user?)
    }

    /// Requests the user to change its password.
    pub fn change_password(&mut self, mailer: &Option<Mailer>, db: &PgConnection) -> Result<()> {
        let rng = OsRng {};
        let key = rng.sample_iter(&Alphanumeric).take(40).collect::<String>();

        use crate::schema::users::dsl::*;
        diesel::update(users.filter(id.eq(self.id)))
            .set(reset_password_key.eq(Some(key.clone())))
            .execute(db)?;

        self.reset_password_key = Some(key.clone());

        match mailer {
            Some(mailer) => {
                let activation_url = format!("{}/reset-password/{}", mailer.root, key);
                let text = reset_password_email_plain_text(&activation_url);
                let html = reset_password_email_html(&activation_url);

                mailer.send_mail(
                    &self.email,
                    String::from("Reset your Polymny password"),
                    text,
                    html,
                )?;
            }

            _ => (),
        }

        Ok(())
    }

    /// Changes the email an requests an email change validation.
    pub fn change_email(
        &mut self,
        new_email: &str,
        mailer: &Option<Mailer>,
        db: &PgConnection,
    ) -> Result<()> {
        match mailer {
            Some(mailer) if mailer.require_email_validation => {
                let rng = OsRng {};
                let key = rng.sample_iter(&Alphanumeric).take(40).collect::<String>();

                use crate::schema::users::dsl::*;
                diesel::update(users.filter(id.eq(self.id)))
                    .set((
                        activation_key.eq(Some(key.clone())),
                        secondary_email.eq(Some(new_email)),
                    ))
                    .execute(db)?;

                let activation_url = format!("{}/validate-email-change/{}", mailer.root, key);
                let text = validation_new_email_plain_text(&activation_url);
                let html = validation_new_email_html(&activation_url);

                mailer.send_mail(
                    new_email,
                    String::from("Change your Polymny email"),
                    text,
                    html,
                )?;
            }

            _ => {
                use crate::schema::users::dsl::*;
                diesel::update(users.filter(id.eq(self.id)))
                    .set(email.eq(new_email))
                    .execute(db)?;
            }
        }
        Ok(())
    }

    /// Validates the email change of a user.
    pub fn validate_email_change(key: &str, db: &PgConnection) -> Result<User> {
        use crate::schema::users::dsl::*;

        let user = User::get_by_activation_key(key, db)?;
        let none: Option<String> = None;

        Ok(diesel::update(users.filter(activation_key.eq(key)))
            .set((
                email.eq(user.secondary_email.ok_or(Error::NotFound)?),
                activation_key.eq(none.clone()),
                secondary_email.eq(none),
            ))
            .get_result::<User>(db)?)
    }

    /// Updates the user password.
    pub fn update_password(&mut self, new_password: &str, db: &PgConnection) -> Result<()> {
        let new_hashed_password = hash(new_password, DEFAULT_COST)?;

        use crate::schema::users::dsl::*;
        let none: Option<String> = None;
        diesel::update(users.filter(id.eq(self.id)))
            .set((
                hashed_password.eq(new_hashed_password.clone()),
                reset_password_key.eq(none),
            ))
            .execute(db)?;

        self.hashed_password = new_hashed_password;

        Ok(())
    }

    /// Returns a user from a reset password key.
    pub fn update_password_by_key(
        key: &str,
        new_password: &str,
        db: &PgConnection,
    ) -> Result<User> {
        let new_hashed_password = hash(new_password, DEFAULT_COST)?;

        use crate::schema::users::dsl::*;
        let none: Option<String> = None;

        Ok(diesel::update(users.filter(reset_password_key.eq(key)))
            .set((
                hashed_password.eq(new_hashed_password.clone()),
                reset_password_key.eq(none),
            ))
            .get_result::<User>(db)?)
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
                secondary_email,
                hashed_password,
                activated,
                activation_key,
                reset_password_key,
                edition_options,
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
        let projects = capsule.get_projects(db)?;
        let is_allowed = projects.into_iter().any(|x| x.user_id == self.id);

        if is_allowed {
            Ok(capsule)
        } else {
            Err(Error::NotFound)
        }
    }

    /// Gets a slide if the user has authorization to access to it, not found otherwise.
    pub fn get_slide_by_id(&self, slide_id: i32, db: &Database) -> Result<Slide> {
        let slide = Slide::get(slide_id, db)?;
        // Check that the user owns a project containing the capsule
        self.get_capsule_by_id(slide.capsule_id, db)?;
        Ok(slide)
    }

    /// Gets Webcam option in db or default values if not set
    pub fn get_edition_options(&self) -> Result<EditionOptions> {
        let v = EditionOptions {
            with_video: true,
            webcam_size: WebcamSize::Medium,
            webcam_position: WebcamPosition::BottomLeft,
        };
        let options = self
            .edition_options
            .as_ref()
            .map(|x| EditionOptions {
                with_video: x.get("with_video").unwrap().as_bool().unwrap(),
                webcam_size: str_to_webcam_size(
                    &x.get("webcam_size").unwrap().as_str().unwrap().to_string(),
                ),
                webcam_position: str_to_webcam_position(
                    &x.get("webcam_position")
                        .unwrap()
                        .as_str()
                        .unwrap()
                        .to_string(),
                ),
            })
            .unwrap_or(v);
        Ok(options)
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
