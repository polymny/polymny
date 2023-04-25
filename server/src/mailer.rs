//! This module contains the mailer confguration

use serde::{Deserialize, Serialize};

use lettre::message::{header, MultiPart, SinglePart};
use lettre::transport::smtp::authentication::Credentials;
use lettre::{Message, SmtpTransport, Transport};

use rocket::http::Status;

use crate::{Error, Result};

fn default_mailer_root() -> String {
    String::new()
}

fn default_mailer_delay() -> u64 {
    60
}

/// A structure that will be used to hold a mail configuration.
///
/// This is the mail account chouette will use to send its emails.
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct Mailer {
    /// Root of the server.
    ///
    /// Can be useful to build urls.
    #[serde(default = "default_mailer_root")]
    pub root: String,

    /// Whether a mail will be sent for users to activate their accounts.
    #[serde(rename = "mailer_require_email_validation")]
    pub require_email_validation: bool,

    /// The smtp server of the mail account.
    #[serde(rename = "mailer_host")]
    pub server: String,

    /// The username of the mail account.
    #[serde(rename = "mailer_user")]
    pub username: String,

    /// The password of the mail account.
    #[serde(rename = "mailer_password")]
    pub password: String,

    /// The delay between two mails for mailing campaign, in seconds.
    #[serde(default = "default_mailer_delay")]
    #[serde(rename = "mailer_delay")]
    pub delay: u64,
}

impl Mailer {
    /// Creates a new mailer.
    pub fn new(
        require_email_validation: bool,
        root: String,
        server: String,
        username: String,
        password: String,
        delay: u64,
    ) -> Mailer {
        Mailer {
            root,
            require_email_validation,
            server,
            username,
            password,
            delay,
        }
    }

    /// Uses a mailer to send an email.
    pub fn send_mail(&self, to: &str, subject: String, text: String, html: String) -> Result<()> {
        let email = Message::builder()
            .from(
                self.username
                    .clone()
                    .parse()
                    .map_err(|_| Error(Status::InternalServerError))?,
            )
            .to(to.parse().map_err(|_| Error(Status::InternalServerError))?)
            .subject(subject)
            .multipart(
                MultiPart::alternative()
                    .singlepart(
                        SinglePart::builder()
                            .header(header::ContentType::TEXT_PLAIN)
                            .body(text),
                    )
                    .singlepart(
                        SinglePart::builder()
                            .header(header::ContentType::TEXT_HTML)
                            .body(html),
                    ),
            )
            .map_err(|_| Error(Status::InternalServerError))?;

        let client = SmtpTransport::relay(&self.server)
            .expect("Failed to create smtp client")
            .credentials(Credentials::new(
                self.username.clone(),
                self.password.clone(),
            ))
            .build();

        client
            .send(&email)
            .map_err(|_| Error(Status::InternalServerError))?;

        Ok(())
    }
}
