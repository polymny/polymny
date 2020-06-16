//! This module contains the struct useful for the configuration.

use std::path::PathBuf;

use crate::mailer::Mailer;

/// The config of the server.
pub struct Config {
    /// The path where the data should be saved.
    pub data_path: PathBuf,

    /// The mailer, if any.
    pub mailer: Option<Mailer>,
}

impl Config {
    /// Creates the config struct from rocket's configuration.
    pub fn from(config: &rocket::Config) -> Config {
        let data_path = config
            .get_string("data_path")
            .unwrap_or_else(|_| String::from("data"));

        Config {
            data_path: PathBuf::from(data_path),
            mailer: Mailer::from_config(config),
        }
    }
}
