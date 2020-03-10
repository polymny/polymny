//! This module contains all the routes related to capsules.
use std::fs;
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};

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
use crate::db::gos::Gos;
use crate::db::slide::Slide;
use crate::db::user::User;
use crate::schema::capsules;
use crate::{Database, Result};

/// A struct that serves the purpose of veryifing the form.
#[derive(FromForm, Debug)]
pub struct NewCapsuleForm {
    /// The (unique) name of the capsule.
    pub name: String,

    /// The title the capsule.
    pub title: String,

    /// Reference to pdf file of caspusle
    // TODO: add reference to asset table
    pub slide_show_id: Option<i32>,

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
    pub slide_show_id: Option<Option<i32>>,

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
            capsule.slide_show_id,
            &capsule.description,
            None,
        )?}))
}

/// The route to get a capsule.
#[get("/capsule/<id>")]
pub fn get_capsule(db: Database, id: i32) -> Result<JsonValue> {
    let capsule = Capsule::get_by_id(id, &db)?;
    Ok(json!({ "capsule":     capsule,
               "slide_show":  capsule.get_slide_show(&db)?,
               "projects":    capsule.get_projects(&db)?,
               "goss":        capsule.get_goss(&db)? ,
               "slides":      capsule.get_slides(&db)?} ))
}

/// Get all the capsules .
#[get("/capsules")]
pub fn all_capsules(db: Database, mut cookies: Cookies) -> Result<JsonValue> {
    let cookie = cookies.get_private("EXAUTH");
    let _user = User::from_session(cookie.unwrap().value(), &db)?;
    Ok(json!(Capsule::all(&db)?))
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

    Ok(json!({ "capsule": Capsule::get_by_id(capsule_id, &db)? }))
}
/// Delete a capsule
#[delete("/capsule/<id>")]
pub fn delete_capsule(db: Database, mut cookies: Cookies, id: i32) -> Result<JsonValue> {
    let cookie = cookies.get_private("EXAUTH");
    let _user = User::from_session(cookie.unwrap().value(), &db)?;
    let capsule = Capsule::get_by_id(id, &db)?;
    Ok(json!({ "nb capsules deleted":
        capsule.delete(&db)?}))
}

/// Upload a presentation (slides)
#[post("/capsule/<id>/upload_slides", data = "<data>")]
pub fn upload_slides(
    db: Database,
    mut cookies: Cookies,
    content_type: &ContentType,
    id: i32,
    data: Data,
) -> Result<JsonValue> {
    let cookie = cookies.get_private("EXAUTH");
    let user = User::from_session(cookie.unwrap().value(), &db)?;
    let capsule = Capsule::get_by_id(id, &db)?;

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

                    //update capsule with the ref to the uploaded pdf
                    use crate::schema::capsules::dsl;
                    diesel::update(capsules::table)
                        .filter(dsl::id.eq(capsule.id))
                        .set(dsl::slide_show_id.eq(asset.id))
                        .execute(&db.0)?;

                    // if exists remove all prevouis generatd goss and slides
                    // TODO: Brutal way add an option to upload pdf without supression of
                    // all goss and slides
                    for item in capsule.get_goss(&db)? {
                        let (gos, slides) = item;
                        for slide in slides {
                            AssetsObject::delete_by_object(&db, slide.id, AssetType::Slide)?;
                            slide.delete(&db)?;
                            //TODO: supress file on disk
                        }
                        gos.delete(&db)?;
                    }

                    // Generates images one per presentation page
                    let dir = tempdir()?;

                    let command = format!(
                        "convert -density 300 {pdf} -resize 1920x1080! {temp}/'%02d'.png",
                        pdf = &output_path.to_str().unwrap(),
                        temp = dir.path().display()
                    );
                    println!("command = {:#?}", command);

                    let mut child = Command::new("sh")
                        .arg("-c")
                        .arg(command)
                        .stdout(Stdio::piped())
                        .stderr(Stdio::piped())
                        .spawn()
                        .expect("failed to execute child");

                    child.wait().expect("failed to wait on child");

                    let mut entries: Vec<_> =
                        fs::read_dir(&dir)?.map(|res| res.unwrap().path()).collect();
                    entries.sort();

                    let mut idx = 1;
                    for e in entries {
                        // Create one GOS and associated per image
                        // one slide per GOS
                        let gos = Gos::new(&db, idx, capsule.id)?;
                        let stem = Path::new(file_name).file_stem().unwrap().to_str().unwrap();
                        let mut output_path = PathBuf::from("dist");
                        let uuid = Uuid::new_v4();
                        let slide_name = format!("{}__{}.png", stem, idx);
                        output_path.push(&user.username);
                        output_path.push("extract");
                        output_path.push(format!("{}_{}", uuid, slide_name));
                        fs::rename(e, &output_path)?;
                        idx += 1;

                        let asset =
                            Asset::new(&db, uuid, &slide_name, &output_path.to_str().unwrap())?;

                        Slide::new(&db, 1, gos.id, asset.id)?;
                    }
                    dir.close()?;
                    return Ok(json!({ "file_name": file_name,
                                       "capsule": capsule,
                                       "goss": capsule.get_goss(&db)?
                    }));
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
