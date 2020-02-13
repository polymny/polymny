//! This module contains all the routes related to projects.

use std::fs;
use std::path::PathBuf;

use rocket::http::Cookies;
use rocket::request::Form;

use rocket_contrib::json::JsonValue;

use crate::db::asset::{Asset, AssetObject};
use crate::db::project::Project;
use crate::db::user::User;
use crate::{Database, Result};

use rocket_multipart_form_data::{
    FileField, MultipartFormData, MultipartFormDataField, MultipartFormDataOptions,
};

use rocket::http::ContentType;
use rocket::Data;

/// A struct that serves the purpose of veryifing the form.
#[derive(FromForm)]
pub struct NewProjectForm {
    /// The username of the form.
    project_name: String,
}

/// The route to register new project.
#[post("/new-project", data = "<project>")]
pub fn new_project(
    db: Database,
    mut cookies: Cookies,
    project: Form<NewProjectForm>,
) -> Result<String> {
    let cookie = cookies.get_private("EXAUTH");
    let user = User::from_session(cookie.unwrap().value(), &db)?;

    let project = Project::create(&project.project_name, user.id)?;
    project.save(&db)?;

    Ok(format!("{}", project.last_visited.timestamp()))
}

/// The route to get a project.
#[get("/project/<id>")]
pub fn get_project(db: Database, id: i32) -> Result<JsonValue> {
    let project = Project::get(id, &db)?;
    Ok(json!({"project_name": project.project_name}))
}

/// Get all the projects .
#[get("/projects")]
pub fn projects(db: Database, mut cookies: Cookies) -> Result<JsonValue> {
    let cookie = cookies.get_private("EXAUTH");
    let user = User::from_session(cookie.unwrap().value(), &db)?;
    Ok(json!({"projects": user.projects(&db)?}))
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
    options.allowed_fields.push(
        MultipartFormDataField::raw("image")
            .size_limit(32 * 1024 * 1024)
            .content_type_by_string(Some(mime::IMAGE_STAR))
            .unwrap(),
    );
    options
        .allowed_fields
        .push(MultipartFormDataField::file("pdf").size_limit(32 * 1024 * 1024));
    let multipart_form_data = MultipartFormData::parse(content_type, data, options).unwrap();

    let pdf = multipart_form_data.files.get("pdf");

    if let Some(pdf) = pdf {
        println!("{:#?}", pdf);
        match pdf {
            FileField::Single(file) => {
                let file_name = &file.file_name;
                let path = &file.path;

                if let Some(file_name) = file_name {
                    let mut output_path = PathBuf::from("dist");
                    output_path.push(&user.username);
                    output_path.push(file_name);
                    fs::rename(path, &output_path)?;
                    let asset = Asset::new(&db, file_name, &output_path.to_str().unwrap())?;
                    let _asset_object =
                        AssetObject::new(&db, asset.id, project.id, &"project".to_string())?;
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
