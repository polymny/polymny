//! This module contains the struct useful for the configuration.

use std::path::PathBuf;

use crate::mailer::Mailer;

/// The config of the server.
#[derive(Clone)]
pub struct Config {
    /// The root of the app.
    pub root: String,

    /// The homepage.
    pub home: String,

    /// The path where the data should be saved.
    pub data_path: PathBuf,

    /// The path where the log should be saved.
    pub log_path: PathBuf,

    /// The path where the videos will be published.
    pub videos_path: PathBuf,

    /// The url to which the websocket server must listen.
    pub socket_listen: String,

    /// The root of the socket server.
    pub socket_root: String,

    /// The root of the video streaming server.
    pub video_root: String,

    /// Whether the server is in beta mode or not.
    pub beta: bool,

    /// Whether the background matting is enabled or not.
    pub matting_enabled: bool,

    /// The domain on which the cookies should be set.
    pub cookie_domain: Option<String>,

    /// The mailer, if any.
    pub mailer: Option<Mailer>,

    /// The version of the crate.
    pub version: &'static str,

    /// The hash of the git commit.
    pub commit: &'static str,

    /// pdf to png conversion : target size
    pub pdf_target_size: String,

    /// pdf to png conversion : target density
    pub pdf_target_density: String,
}

impl Config {
    /// Creates the config struct from rocket's configuration.
    pub fn from(config: &rocket::Config) -> Config {
        let root = config.get_string("root").unwrap();

        let home = config.get_string("home").unwrap_or_else(|_| root.clone());

        let data_path = config
            .get_string("data_path")
            .unwrap_or_else(|_| String::from("data"));

        let log_path = config
            .get_string("log_path")
            .unwrap_or_else(|_| String::from("log.txt"));

        let videos_path = config
            .get_string("videos_path")
            .unwrap_or_else(|_| String::from("videos"));

        let socket_listen = config
            .get_string("socket_listen")
            .unwrap_or_else(|_| String::from("localhost:8001"));

        let socket_root = config
            .get_string("socket_root")
            .unwrap_or_else(|_| String::from("/"));

        let video_root = config
            .get_string("video_root")
            .unwrap_or_else(|_| String::from("/"));

        let pdf_target_size = config
            .get_string("pdf_target_size")
            .unwrap_or_else(|_| String::from("1920x1080"));

        let pdf_target_density = config
            .get_string("pdf_target_density")
            .unwrap_or_else(|_| String::from("380"));

        let beta = config.get_bool("beta").unwrap_or(false);
        let matting_enabled = config.get_bool("matting_enabled").unwrap_or(false);

        #[cfg(feature = "git")]
        let commit = compile_time_run::run_command_str!("git", "rev-parse", "--short", "HEAD");
        #[cfg(not(feature = "git"))]
        let commit = "unknown";

        Config {
            root,
            home,
            data_path: PathBuf::from(data_path),
            log_path: PathBuf::from(log_path),
            videos_path: PathBuf::from(videos_path),
            socket_listen,
            socket_root,
            video_root,
            beta,
            matting_enabled,
            mailer: Mailer::from_config(config),
            version: env!("CARGO_PKG_VERSION"),
            commit,
            pdf_target_size,
            pdf_target_density,
            cookie_domain: config.get_string("cookie_domain").ok(),
        }
    }
}
