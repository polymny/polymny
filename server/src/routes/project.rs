//! This module contains all the routes related to projects.

use std::io::Cursor;

use rocket::response::{Response};
use rocket::request::Form;
use rocket::http::Cookies;

use rocket_contrib::json::JsonValue;

use crate::db::project::Project;
use crate::db::user::User;
use crate::{Database, Result};

/// A struct that serves the purpose of veryifing the form.
#[derive(FromForm)]
pub struct NewProjectForm {
    /// The username of the form.
    projectname: String,

}

/// The route to register new project.
#[post("/new-project", data = "<project>")]
pub fn new_project<'a>( db: Database, mut cookies: Cookies, project: Form<NewProjectForm>) -> Result<Response<'a>> {

    // get user
    let cookie = cookies.get_private("EXAUTH");
    let user = User::from_session(cookie.unwrap().value(), &db)?;
    //Ok(json!({"username": user.username}));

    let project = Project::create(&project.projectname, user.id)?;
    project.save(&db)?;

    Ok(Response::build()
        .sized_body(Cursor::new(""))
        .finalize())
}

/// The route to get a project.
#[get("/project/<id>")]
pub fn get_project(db: Database, id: i32) -> Result<JsonValue> {

    let project = Project::get(id, &db)?;
    Ok(json!({"projectname": project.projectname}))

}

/// Get all the projects .
#[get("/projects")]
pub fn projects() -> &'static str {
 "Hello projects"
 }
