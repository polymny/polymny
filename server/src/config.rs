//! This module contains the struct useful for the configuration.

use std::path::PathBuf;

use serde::{Deserialize, Serialize};

use rocket::figment::Figment;
use rocket::Phase;

use crate::mailer::Mailer;

fn default_premium_only() -> bool {
    false
}

fn default_other_host() -> Option<String> {
    None
}

fn default_data_path() -> PathBuf {
    PathBuf::from("data")
}

fn default_log_path() -> PathBuf {
    PathBuf::from("log.txt")
}

fn default_videos_path() -> PathBuf {
    PathBuf::from("videos")
}

fn default_socket_listen() -> String {
    String::from("localhost:8001")
}

fn default_socket_root() -> String {
    String::from("/")
}

fn default_video_root() -> String {
    String::from("/")
}

fn default_pdf_target_size() -> String {
    String::from("1920x1080")
}

fn default_pdf_target_density() -> String {
    String::from("380")
}

fn default_beta() -> bool {
    false
}

fn default_mailer_enabled() -> bool {
    false
}

fn default_version() -> &'static str {
    env!("CARGO_PKG_VERSION")
}

fn default_concurrent_tasks() -> usize {
    16
}

fn default_quota_disk_free() -> i32 {
    3
}

fn default_quota_disk_premiumlvl1() -> usize {
    15
}

fn default_quota_disk_admin() -> usize {
    1000
}

fn default_registration_disabled() -> bool {
    false
}

#[cfg(feature = "git")]
fn default_commit() -> Option<&'static str> {
    Some(compile_time_run::run_command_str!(
        "git",
        "rev-parse",
        "--short",
        "HEAD"
    ))
}

#[cfg(not(feature = "git"))]
fn default_commit() -> Option<&'static str> {
    None
}

fn default_harsh_length() -> usize {
    0
}

/// The databases of the server.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Databases {
    /// The database of the server.
    pub database: Database,
}

/// The url of the database.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Database {
    /// The url of the database.
    pub url: String,
}

/// The config of the server.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    /// The root of the app.
    pub root: String,

    /// The homepage.
    pub home: Option<String>,

    /// Whether the instance should treat only premium requests or all requests.
    #[serde(default = "default_premium_only")]
    pub premium_only: bool,

    /// The other instance treating the other types of request (premium if premium_only is false or
    /// non premium).
    #[serde(default = "default_other_host")]
    pub other_host: Option<String>,

    /// The path where the data should be saved.
    #[serde(default = "default_data_path")]
    pub data_path: PathBuf,

    /// The path where the log should be saved.
    #[serde(default = "default_log_path")]
    pub log_path: PathBuf,

    /// The path where the videos will be published.
    #[serde(default = "default_videos_path")]
    pub videos_path: PathBuf,

    /// The url to which the websocket server must listen.
    #[serde(default = "default_socket_listen")]
    pub socket_listen: String,

    /// The root of the socket server.
    #[serde(default = "default_socket_root")]
    pub socket_root: String,

    /// The root of the video streaming server.
    #[serde(default = "default_video_root")]
    pub video_root: String,

    /// Whether the server is in beta mode or not.
    #[serde(default = "default_beta")]
    pub beta: bool,

    /// Whether new users can register on the website.
    #[serde(default = "default_registration_disabled")]
    pub registration_disabled: bool,

    /// The domain on which the cookies should be set.
    pub cookie_domain: Option<String>,

    /// Whether the mailer is enabled or not.
    #[serde(default = "default_mailer_enabled")]
    pub mailer_enabled: bool,

    /// The mailer, if any.
    #[serde(flatten)]
    pub mailer: Option<Mailer>,

    /// The version of the crate.
    #[serde(default = "default_version")]
    pub version: &'static str,

    /// The hash of the git commit.
    #[serde(default = "default_commit")]
    pub commit: Option<&'static str>,

    /// Random string to compute harsh hashids.
    pub harsh_secret: String,

    /// Minimum length of harsh hashids.
    #[serde(default = "default_harsh_length")]
    pub harsh_length: usize,

    /// Pdf to png conversion : target size.
    #[serde(default = "default_pdf_target_size")]
    pub pdf_target_size: String,

    /// Pdf to png conversion : target density.
    #[serde(default = "default_pdf_target_density")]
    pub pdf_target_density: String,

    /// Url of the databases.
    pub databases: Databases,

    /// Number of concurrent tasks allowed.
    #[serde(default = "default_concurrent_tasks")]
    pub concurrent_tasks: usize,

    /// Disk quota for free account
    #[serde(default = "default_quota_disk_free")]
    pub quota_disk_free: i32,

    /// Disk quota for premuim level 1 account
    #[serde(default = "default_quota_disk_premiumlvl1")]
    pub quota_disk_premiumlvl1: usize,

    /// Disk quota for admin account
    #[serde(default = "default_quota_disk_admin")]
    pub quota_disk_admin: usize,
}

impl Config {
    /// Creates the config struct from the rocket config.
    pub fn from_rocket<P: Phase>(rocket: &rocket::Rocket<P>) -> Config {
        Config::from_figment(rocket.figment())
    }

    /// Creates the config struct from the rocket figment.
    pub fn from_figment(figment: &Figment) -> Config {
        let mut config: Config = figment.extract().expect("Failed to parse config");

        if !config.mailer_enabled {
            config.mailer = None;
        }

        if let Some(mailer) = config.mailer.as_mut() {
            mailer.root = config.root.clone();
        }

        config
    }
}
