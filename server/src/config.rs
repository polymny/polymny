//! This module contains the struct useful for the configuration.

use std::path::PathBuf;

use crate::mailer::Mailer;

/// The config of the server.
pub struct Config {
    /// The path where the data should be saved.
    pub data_path: PathBuf,

    /// The path where the log should be saved.
    pub log_path: PathBuf,

    /// The path where the videos will be published.
    pub videos_path: PathBuf,

    /// The mailer, if any.
    pub mailer: Option<Mailer>,
}

impl Config {
    /// Creates the config struct from rocket's configuration.
    pub fn from(config: &rocket::Config) -> Config {
        let data_path = config
            .get_string("data_path")
            .unwrap_or_else(|_| String::from("data"));

        let log_path = config
            .get_string("log_path")
            .unwrap_or_else(|_| String::from("log.txt"));

        let videos_path = config
            .get_string("videos_path")
            .unwrap_or_else(|_| String::from("videos"));

        Config {
            data_path: PathBuf::from(data_path),
            log_path: PathBuf::from(log_path),
            videos_path: PathBuf::from(videos_path),
            mailer: Mailer::from_config(config),
        }
    }
}
