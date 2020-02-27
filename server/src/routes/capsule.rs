//! This module contains all the routes related to capsules.
use std::path::PathBuf;
use std::process::{Command, Stdio};
use std::str;
use std::{fs, io};

use diesel::ExpressionMethods;
use diesel::RunQueryDsl;

use rocket::http::{ContentType, Cookies};
use rocket::request::Form;
use rocket::Data;

use rocket_contrib::json::JsonValue;

use rocket_multipart_form_data::{
    FileField, MultipartFormData, MultipartFormDataField, MultipartFormDataOptions,
};

use uuid::Uuid;

use tempfile::tempdir;

use crate::db::asset::{Asset, AssetType, AssetsObject};
use crate::db::capsule::Capsule;
use crate::db::user::User;
use crate::schema::capsules;
use crate::{Database, Error, Result};

/// A struct that serves the purpose of veryifing the form.
#[derive(FromForm, Debug)]
pub struct NewCapsuleForm {
    /// The (unique) name of the capsule.
    pub name: String,

    /// The title the capsule.
    pub title: String,

    /// Reference to pdf file of caspusle
    // TODO: add reference to asset table
    pub slide_asset_id: Option<i32>,

    /// The description of the capsule.
    pub description: String,
}

/// A struct/form for update (PUT) operations
#[derive(FromForm, AsChangeset, Debug)]
#[table_name = "capsules"]
pub struct UpdateCapsuleForm {
    /// The (unique) name of the capsule.
    pub name: Option<String>,

    /// The title the capsule.
    pub title: Option<String>,

    /// Reference to pdf file of caspusle
    // TODO: add reference to asset table
    pub slide_asset_id: Option<Option<i32>>,

    /// The description of the capsule.
    pub description: Option<String>,
}

/// The route to register new capsule.
#[post("/new-capsule", data = "<capsule>")]
pub fn new_capsule(db: Database, capsule: Form<NewCapsuleForm>) -> Result<JsonValue> {
    Ok(json!({
        "capsule":
        Capsule::new(
            &db,
            &capsule.name,
            &capsule.title,
            capsule.slide_asset_id,
            &capsule.description,
            None,
        )?}))
}

/// The route to get a capsule.
#[get("/capsule/<id>")]
pub fn get_capsule(db: Database, id: i32) -> Result<JsonValue> {
    // let (capsule, projects) = Capsule::get(id, &db)?;
    // Ok(json!({ "capsule": capsule, "projects": projects } ))
    let (capsule, projects, goss) = Capsule::get_by_id(id, &db)?;
    Ok(json!({ "capsule": capsule, "projects": projects, "goss": goss } ))
}

/// Get all the capsules .
#[get("/capsules")]
pub fn all_capsules(db: Database, mut cookies: Cookies) -> Result<JsonValue> {
    let cookie = cookies.get_private("EXAUTH");
    let _user = User::from_session(cookie.unwrap().value(), &db)?;
    Ok(json!({ "capsules": Capsule::all(&db)?}))
}

/// Update a capsule
#[put("/capsule/<capsule_id>", data = "<capsule_form>")]
pub fn update_capsule(
    db: Database,
    mut cookies: Cookies,
    capsule_id: i32,
    capsule_form: Form<UpdateCapsuleForm>,
) -> Result<JsonValue> {
    let cookie = cookies.get_private("EXAUTH");
    let _user = User::from_session(cookie.unwrap().value(), &db)?;

    use crate::schema::capsules::dsl::id;
    diesel::update(capsules::table)
        .filter(id.eq(capsule_id))
        .set(&capsule_form.into_inner())
        .execute(&db.0)?;

    Ok(json!({ "capsule": Capsule::get(capsule_id, &db)? }))
}
/// Delete a capsule
#[delete("/capsule/<id>")]
pub fn delete_capsule(db: Database, mut cookies: Cookies, id: i32) -> Result<JsonValue> {
    let cookie = cookies.get_private("EXAUTH");
    let _user = User::from_session(cookie.unwrap().value(), &db)?;
    let (capsule, _, _) = Capsule::get_by_id(id, &db)?;
    Ok(json!({ "nb capsules deleted":
        capsule.delete(&db)?}))
}

/// Upload a presentation (slides)
#[post("/project/<id>/upload_slides", data = "<data>")]
pub fn project_upload(
    db: Database,
    mut cookies: Cookies,
    content_type: &ContentType,
    id: i32,
    data: Data,
) -> Result<JsonValue> {
    let cookie = cookies.get_private("EXAUTH");
    let user = User::from_session(cookie.unwrap().value(), &db)?;
    let (capsule, _, _) = Capsule::get_by_id(id, &db)?;

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
                    // Store uploaded presentation
                    let mut output_path = PathBuf::from("dist");
                    output_path.push(&user.username);
                    let uuid = Uuid::new_v4();
                    output_path.push(format!("{}_{}", uuid, file_name));
                    fs::rename(path, &output_path)?;
                    let asset = Asset::new(&db, uuid, file_name, &output_path.to_str().unwrap())?;
                    AssetsObject::new(&db, asset.id, capsule.id, AssetType::Capsule)?;

                    // Generates images one per presentation page
                    let dir = tempdir()?;

                    let command = format!(
                        "convert -verbose -density 300 {pdf} -resize 1920x1080! {temp}/'%02d'.png",
                        pdf = &output_path.to_str().unwrap(),
                        temp = dir.path().display()
                    );
                    println!("command = {:#?}", command);

                    let child = Command::new("sh")
                        .arg("-c")
                        .arg(command)
                        .stdout(Stdio::piped())
                        .stderr(Stdio::piped())
                        .spawn()
                        .expect("failed to execute child");

                    println!("child = {:#?}", child);
                    let output = child.wait_with_output().expect("failed to wait on child");
                    let out: Vec<&str> = str::from_utf8(&output.stderr)
                        .unwrap()
                        .split("\n")
                        .collect();
                    println!("output = {:#?}", str::from_utf8(&output.stderr));
                    println!("out = {:#?}", &out);

                    let mut entries = fs::read_dir(&dir)?
                        .map(|res| res.map(|e| e.path()))
                        .collect::<Result<Vec<_>, Error>>()?;
                    entries.sort();

                    for e in entries {
                        println!("{:#?}", e);
                    }
                    dir.close()?;
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

    Ok(json!({ "capsule": capsule }))
}
