use std::error::Error;
use std::fmt;

use diesel::pg::PgConnection;
use diesel::prelude::*;
use rocket::Rocket;

impl Error for NotFoundError {}

use serde::Deserialize;

use server::db::capsule::{Capsule, CapsulesProject};
use server::db::gos::Gos;
use server::db::project::Project;
use server::db::slide::Slide;
use server::db::user::User;

const SAMPLE: &str = include_str!("../../tests/samples.yml");

#[derive(Debug)]
pub struct NotFoundError {}

impl fmt::Display for NotFoundError {
    fn fmt(&self, fmt: &mut fmt::Formatter) -> fmt::Result {
        write!(fmt, "could not found database url")
    }
}

#[derive(Deserialize, Debug)]
pub struct SampleSlide {
    pub position_in_gos: i32,
}

#[derive(Deserialize, Debug)]
pub struct SampleGos {
    pub position: i32,
    slides: Option<Vec<SampleSlide>>,
}

#[derive(Deserialize, Debug)]
struct SampleCapsule {
    name: String,
    title: String,
    description: String,
    slides: String,
    goss: Option<Vec<SampleGos>>,
}

#[derive(Deserialize, Debug)]
struct SampleProject {
    project_name: String,
    capsules: Option<Vec<String>>,
}

#[derive(Deserialize, Debug)]
struct SampleUser {
    username: String,
    email: String,
    password: String,
    projects: Option<Vec<SampleProject>>,
}
#[derive(Deserialize, Debug)]
struct Sample<T> {
    //users: HashMap<String, User>,
    users: Vec<T>,
    capsules: Vec<SampleCapsule>,
}

fn parse_sample() -> Result<Sample<SampleUser>, Box<dyn Error>> {
    // Read the JSON contents of the file as an instance of `User`.
    let u = serde_yaml::from_str(SAMPLE)?;
    // Return the `User`.
    Ok(u)
}

fn main() -> Result<(), Box<dyn Error>> {
    let rocket = Rocket::ignite();
    let config = rocket.config();

    let database_url = config
        .get_table("databases")?
        .get_key_value("database")
        .ok_or(NotFoundError {})?
        .1
        .as_table()
        .ok_or(NotFoundError {})?
        .get_key_value("url")
        .ok_or(NotFoundError {})?
        .1
        .as_str()
        .ok_or(NotFoundError {})?;

    let db = PgConnection::establish(&database_url)
        .unwrap_or_else(|_| panic!("Error connecting to {}", database_url));

    let sample = parse_sample()?;

    for sample_capsule in sample.capsules {
        let capsule = Capsule::new(
            &db,
            &sample_capsule.name,
            &sample_capsule.title,
            &sample_capsule.slides,
            &sample_capsule.description,
            None,
        )?;
        if let Some(goss) = sample_capsule.goss {
            println!(
                "found GOS : {:#?} for capsule {}",
                goss, sample_capsule.name
            );
            for sample_gos in goss {
                let gos = Gos::create(sample_gos.position, capsule.id)?.save(&db)?;
                if let Some(slides) = sample_gos.slides {
                    for sample_slide in slides {
                        Slide::create(sample_slide.position_in_gos, gos.id)?.save(&db)?;
                    }
                }
            }
        }
    }

    for sample_user in sample.users {
        let user = User::create(
            &sample_user.username,
            &sample_user.email,
            &sample_user.password,
            &None,
        )?
        .save(&db)?;

        if let Some(projects) = sample_user.projects {
            println!(
                "found projects : {:#?} for user {}",
                projects, sample_user.username
            );
            for sample_project in projects {
                let project = Project::create(&sample_project.project_name, user.id)?.save(&db)?;

                if let Some(capsules) = sample_project.capsules {
                    //println!("found capsule : {:#?} for project {:#?}", capsules, &sample_project.capsules);
                    for capsule_ref in capsules {
                        let db_capsule = Capsule::get_by_name(&capsule_ref, &db)?;
                        println!("found capsule : {:#?}", db_capsule);
                        CapsulesProject::new(&db, db_capsule.id, project.id)?;
                    }
                }
            }
        }
    }

    Ok(())
}
