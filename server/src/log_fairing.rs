//! This module contains the fairing used to log things.

use chrono::Local;

use rocket::fairing::{Fairing, Info, Kind};
use rocket::{Data, Request, Response, Rocket};

/// The struct represents the fairing used to log things.
#[derive(Clone)]
pub struct Log {}

impl Log {
    /// Creates a new log fairing.
    pub fn fairing() -> Log {
        Log {}
    }
}

impl Fairing for Log {
    fn info(&self) -> Info {
        Info {
            name: "Log Fairing",
            kind: Kind::Response,
        }
    }

    fn on_attach(&self, rocket: Rocket) -> Result<Rocket, Rocket> {
        Ok(rocket.manage(self.clone()))
    }

    fn on_launch(&self, _: &Rocket) {}

    fn on_request(&self, _: &mut Request, _: &Data) {}

    fn on_response(&self, request: &Request, response: &mut Response) {
        let ip = match request.client_ip() {
            Some(ip) => format!("{}", ip),
            None => String::from("Unknown addr"),
        };

        info!(
            "{} - [{}] {} {} {}",
            ip,
            Local::now().to_rfc2822(),
            request.method(),
            request.uri(),
            response.status().code
        );
    }
}
