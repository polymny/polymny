//! This module contains all the routes related to capsules.

use std::io::Cursor;

use rocket::response::{Response};
use rocket::request::Form;

use rocket_contrib::json::JsonValue;

use crate::db::capsule::Capsule;
use crate::{Database, Result};

/// A struct that serves the purpose of veryifing the form.
#[derive(FromForm)]
pub struct NewCapsuleForm {
    /// The (unique) name of the capsule.
    pub name: String,

    /// The title the capsule.
    pub title: Option<String>,

    /// Reference to pdf file of caspusle
    // TODO: add reference to asset table
    pub slides: Option<String>,

    /// The description of the capsule.
    pub description: Option<String>,

}

/// The route to register new capsule.
#[post("/new-capsule", data = "<capsule>")]
pub fn new_capsule<'a>( db: Database, capsule: Form<NewCapsuleForm>) -> Result<Response<'a>> {

    Capsule::new(&db, &capsule.name,
        capsule.title.as_deref(),
        capsule.slides.as_deref(),
        capsule.description.as_deref(),
        &None)?;

    Ok(Response::build()
        .sized_body(Cursor::new(""))
        .finalize())
}

/// The route to get a capsule.
#[get("/capsule/<id>")]
pub fn get_capsule(db: Database, id: i32) -> Result<JsonValue> {

    let capsule = Capsule::get(id, &db)?;
    Ok(json!({"capsulename": capsule.name}))

}

/// Get all the capsules .
#[get("/capsules")]
pub fn capsules() -> &'static str {
 "Hello capsules"
 }
