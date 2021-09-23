//! This module contains the fairing used to log things.

use chrono::Local;

use rocket::fairing::{Fairing, Info, Kind};
use rocket::{Request, Response};

/// The struct represents the fairing used to log things.
#[derive(Clone)]
pub struct Log {}

impl Log {
    /// Creates a new log fairing.
    pub fn fairing() -> Log {
        Log {}
    }
}

#[rocket::async_trait]
impl Fairing for Log {
    fn info(&self) -> Info {
        Info {
            name: "Log Fairing",
            kind: Kind::Response,
        }
    }

    async fn on_response<'r>(&self, req: &'r Request<'_>, res: &mut Response<'r>) {
        let ip = match req.client_ip() {
            Some(ip) => format!("{}", ip),
            None => String::from("Unknown addr"),
        };

        info!(
            "{} - [{}] {} {} {}",
            ip,
            Local::now().to_rfc2822(),
            req.method(),
            req.uri(),
            res.status().code
        );
    }
}
