//! This module contains the mailer confguration

use serde::{Deserialize, Serialize};

use lettre::smtp::authentication::Credentials;
use lettre::{SmtpClient, Transport};
use lettre_email::Email;

use crate::Result;

fn default_mailer_root() -> String {
    String::new()
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
