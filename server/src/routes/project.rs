//! This module contains all the routes related to projects.

use std::fs;

use rocket::http::ContentType;
use rocket::{Data, State};

use rocket_contrib::json::{Json, JsonValue};

use rocket_multipart_form_data::{
    FileField, MultipartFormData, MultipartFormDataField, MultipartFormDataOptions,
};

use uuid::Uuid;

use crate::config::Config;
use crate::db::asset::{Asset, AssetType, AssetsObject};
use crate::db::project::Project;
use crate::db::user::User;
use crate::{Database, Result};

/// A struct that serves the purpose of veryifing the form.
#[derive(Deserialize)]
pub struct NewProjectForm {
    /// The username of the form.
    project_name: String,
}

/// The route to register new project.
#[post("/new-project", data = "<project>")]
pub fn new_project(db: Database, user: User, project: Json<NewProjectForm>) -> Result<JsonValue> {
    let project = Project::create(&project.project_name, user.id)?;
    Ok(json!(project.save(&db)?))
}

/// The route to get a project.
#[get("/project/<id>")]
pub fn get_project(db: Database, user: User, id: i32) -> Result<JsonValue> {
    Ok(json!(user.get_project_by_id(id, &db)?))
}

/// The route to get the capsules from a project.
#[get("/project/<id>/capsules")]
pub fn get_capsules(db: Database, user: User, id: i32) -> Result<JsonValue> {
    let project = user.get_project_by_id(id, &db)?;
    Ok(json!(project.get_capsules(&db)?))
}

/// Get all the projects .
#[get("/projects")]
pub fn all_projects(db: Database, _user: User) -> Result<JsonValue> {
    Ok(json!(Project::all(&db)?))
}

/// Update a project
#[put("/project/<id>", data = "<project_form>")]
pub fn update_project(
    db: Database,
    user: User,
    id: i32,
    project_form: Json<NewProjectForm>,
) -> Result<JsonValue> {
    let project = user.get_project_by_id(id, &db)?;
    Ok(json!(project.update(
        &db,
        &project_form.project_name,
        user.id
    )?))
}
/// Delete a project
#[delete("/project/<id>")]
pub fn delete_project(db: Database, user: User, id: i32) -> Result<JsonValue> {
    let project = user.get_project_by_id(id, &db)?;
    Ok(json!({"nb projects deleted": project.delete(&db)?}))
}

/// Upload an asset in the project
#[post("/project/<id>/upload", data = "<data>")]
pub fn project_upload(
    config: State<Config>,
    db: Database,
    user: User,
    content_type: &ContentType,
    id: i32,
    data: Data,
) -> Result<JsonValue> {
    let project = user.get_project_by_id(id, &db)?;

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
                    let mut output_path = config.data_path.clone();
                    output_path.push(&user.username);
                    let uuid = Uuid::new_v4();
                    output_path.push(format!("{}_{}", uuid, file_name));
                    fs::rename(path, &output_path)?;
                    let asset = Asset::new(&db, uuid, file_name, &output_path.to_str().unwrap())?;
                    AssetsObject::new(&db, asset.id, project.id, AssetType::Project)?;
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
