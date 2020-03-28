//! This module contains the mailer confguration

use lettre::smtp::authentication::Credentials;
use lettre::{SmtpClient, Transport};
use lettre_email::Email;

use rocket::Config;

use crate::Result;

/// A structure that will be used to hold a mail configuration.
///
/// This is the mail account chouette will use to send its emails.
#[derive(Clone, Debug)]
pub struct Mailer {
    /// Root of the server.
    ///
    /// Can be useful to build urls.
    pub root: String,

    /// Whether a mail will be sent for users to activate their accounts.
    pub require_email_validation: bool,

    /// The smtp server of the mail account.
    pub server: String,

    /// The username of the mail account.
    pub username: String,

    /// The password of the mail account.
    pub password: String,
}

impl Mailer {
    /// Creates a new mailer.
    pub fn new(
        require_email_validation: bool,
        root: String,
        server: String,
        username: String,
        password: String,
    ) -> Mailer {
        Mailer {
            root,
            require_email_validation,
            server,
            username,
            password,
        }
    }

    /// Creates a mailer from the rocket config.
    pub fn from_config(config: &Config) -> Option<Mailer> {
        if config.get_bool("mailer_enabled").ok() == Some(false) {
            return None;
        }

        let root = config.get_string("root").ok()?;
        let host = config.get_string("mailer_host").ok()?;
        let user = config.get_string("mailer_user").ok()?;
        let password = config.get_string("mailer_password").ok()?;
        let require_email_validation = config.get_bool("require_email_validation").ok()?;

        Some(Mailer::new(
            require_email_validation,
            root,
            host,
            user,
            password,
        ))
    }

    /// Uses a mailer to send an email.
    pub fn send_mail(&self, to: &str, subject: String, text: String, html: String) -> Result<()> {
        let email = Email::builder()
            .from(self.username.clone())
            .to(to)
            .subject(subject)
            .alternative(html, text)
            .build()?;

        let mut client = SmtpClient::new_simple(&self.server)
            .expect("Failed to create smtp client")
            .credentials(Credentials::new(
                self.username.clone(),
                self.password.clone(),
            ))
            .transport();

        client.send(email.into())?;

        Ok(())
    }
}
