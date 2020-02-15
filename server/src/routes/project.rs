//! This module contains all the routes related to projects.

use std::fs;
use std::path::PathBuf;

use rocket::http::{ContentType, Cookies};
use rocket::request::Form;
use rocket::Data;

use rocket_contrib::json::JsonValue;

use rocket_multipart_form_data::{
    FileField, MultipartFormData, MultipartFormDataField, MultipartFormDataOptions,
};

use uuid::Uuid;

use crate::db::asset::{Asset, AssetObject, AssetType};
use crate::db::project::Project;
use crate::db::user::User;
use crate::{Database, Result};

/// A struct that serves the purpose of veryifing the form.
#[derive(FromForm)]
pub struct NewProjectForm {
    /// The username of the form.
    project_name: String,
}

/// The route to register new project.
#[post("/new-project", data = "<project>")]
pub fn new_project<'a>(
    db: Database,
    mut cookies: Cookies,
    project: Form<NewProjectForm>,
) -> Result<JsonValue> {
    let cookie = cookies.get_private("EXAUTH");
    let user = User::from_session(cookie.unwrap().value(), &db)?;
    let project = Project::create(&project.project_name, user.id)?;

    Ok(json!({ "project": project.save(&db)? }))
}

/// The route to get a project.
#[get("/project/<id>")]
pub fn get_project(db: Database, id: i32) -> Result<JsonValue> {
    let project = Project::get(id, &db)?;
    Ok(json!({ "project": project }))
}

/// Get all the projects .
#[get("/projects")]
pub fn all_projects(db: Database, mut cookies: Cookies) -> Result<JsonValue> {
    let cookie = cookies.get_private("EXAUTH");
    let _user = User::from_session(cookie.unwrap().value(), &db)?;
    Ok(json!({ "projects": Project::all(&db)?}))
}

/// Update a project
#[put("/project/<id>", data = "<project_form>")]
pub fn update_project(
    db: Database,
    mut cookies: Cookies,
    id: i32,
    project_form: Form<NewProjectForm>,
) -> Result<JsonValue> {
    let cookie = cookies.get_private("EXAUTH");
    let user = User::from_session(cookie.unwrap().value(), &db)?;
    let project = Project::get(id, &db)?;
    Ok(json!({ "project":
        project.update(&db, &project_form.project_name, user.id)? }))
}
/// Delete a project
#[delete("/project/<id>")]
pub fn delete_project(db: Database, mut cookies: Cookies, id: i32) -> Result<JsonValue> {
    let cookie = cookies.get_private("EXAUTH");
    let _user = User::from_session(cookie.unwrap().value(), &db)?;
    let project = Project::get(id, &db)?;
    Ok(json!({ "nb projects deleted":
        project.delete(&db)?}))
}

/// Upload an asset in the project
#[post("/project/<id>/upload", data = "<data>")]
pub fn project_upload(
    db: Database,
    mut cookies: Cookies,
    content_type: &ContentType,
    id: i32,
    data: Data,
) -> Result<JsonValue> {
    let cookie = cookies.get_private("EXAUTH");
    let user = User::from_session(cookie.unwrap().value(), &db)?;
    let project = Project::get(id, &db)?;

    let mut options = MultipartFormDataOptions::new();
    options
        .allowed_fields
        .push(MultipartFormDataField::file("file").size_limit(128 * 1024 * 1024));
    let multipart_form_data = MultipartFormData::parse(content_type, data, options).unwrap();
    //TODO: handle errors from multipart form dat ?
    // cf.https://github.com/magiclen/rocket-multipart-form-data/blob/master/examples/image_uploader.rs

    let file = multipart_form_data.files.get("file");

    if let Some(file) = file {
        match file {
            FileField::Single(file) => {
                let file_name = &file.file_name;
                let path = &file.path;

                if let Some(file_name) = file_name {
                    let mut output_path = PathBuf::from("dist");
                    output_path.push(&user.username);
                    let uuid = Uuid::new_v4();
                    output_path.push(format!("{}_{}", uuid, file_name));
                    fs::rename(path, &output_path)?;
                    let asset = Asset::new(&db, uuid, file_name, &output_path.to_str().unwrap())?;
                    AssetObject::new(&db, asset.id, project.id, AssetType::Project)?;
                    return Ok(json!({ "file_name": file_name, "project": user.projects(&db)? }));
                }
            }
            FileField::Multiple(_files) => {
                // TODO: handle mutlile files
                todo!()
            }
        };
    } else {
        todo!();
    }

    Ok(json!({"project_name": project.project_name}))
}
