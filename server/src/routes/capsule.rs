//! This module contains all the routes related to capsules.

use std::io::Cursor;

use rocket::request::Form;
use rocket::response::Response;

use rocket::http::Cookies;
use rocket_contrib::json::JsonValue;

use crate::db::capsule::Capsule;
use crate::db::user::User;
use crate::{Database, Result};

/// A struct that serves the purpose of veryifing the form.
#[derive(FromForm, Debug)]
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

/// A struct that serves the purpose of veryifing the form.
#[derive(FromForm, Debug)]
pub struct UpdateCapsuleForm {
    /// The (unique) name of the capsule.
    pub name: Option<String>,

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
pub fn new_capsule<'a>(db: Database, capsule: Form<NewCapsuleForm>) -> Result<JsonValue> {
    Ok(json!({
        "capsule":
        Capsule::new(
            &db,
            &capsule.name,
            capsule.title.as_deref(),
            capsule.slides.as_deref(),
            capsule.description.as_deref(),
            &None,
        )?}))
}

/// The route to get a capsule.
#[get("/capsule/<id>")]
pub fn get_capsule(db: Database, id: i32) -> Result<JsonValue> {
    let capsule = Capsule::get(id, &db)?;
    Ok(json!({ "capsule": capsule }))
}

/// Get all the capsules .
#[get("/capsules")]
pub fn all_capsules(db: Database, mut cookies: Cookies) -> Result<JsonValue> {
    let cookie = cookies.get_private("EXAUTH");
    let _user = User::from_session(cookie.unwrap().value(), &db)?;
    Ok(json!({ "capsules": Capsule::all(&db)?}))
}

/// Update a capsule
#[put("/capsule/<id>", data = "<capsule_form>")]
pub fn update_capsule(
    db: Database,
    mut cookies: Cookies,
    id: i32,
    capsule_form: Form<UpdateCapsuleForm>,
) -> Result<JsonValue> {
    let cookie = cookies.get_private("EXAUTH");
    let _user = User::from_session(cookie.unwrap().value(), &db)?;
    let capsule = Capsule::get(id, &db)?;
    println!("{:#?}", capsule_form);
    Ok(json!({ "capsule":
        capsule.update(&db,
            capsule_form.name.as_deref(),
            capsule_form.title.as_deref(),
            capsule_form.slides.as_deref(),
            capsule_form.description.as_deref())? }))
}
/// Delete a capsule
#[delete("/capsule/<id>")]
pub fn delete_capsule(db: Database, mut cookies: Cookies, id: i32) -> Result<JsonValue> {
    let cookie = cookies.get_private("EXAUTH");
    let _user = User::from_session(cookie.unwrap().value(), &db)?;
    let capsule = Capsule::get(id, &db)?;
    Ok(json!({ "nb capsules deleted":
        capsule.delete(&db)?}))
}
