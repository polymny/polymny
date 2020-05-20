//! This module contains all the routes related to capsules.
use std::fs::{self, create_dir};
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};

use diesel::ExpressionMethods;
use diesel::RunQueryDsl;

use rocket::http::ContentType;
use rocket::Data;

use rocket_contrib::json::{Json, JsonValue};

use rocket_multipart_form_data::{
    FileField, MultipartFormData, MultipartFormDataField, MultipartFormDataOptions,
};

use uuid::Uuid;

use tempfile::tempdir;

use crate::db::asset::{Asset, AssetType, AssetsObject};
use crate::db::capsule::Capsule;
use crate::db::project::Project;
use crate::db::slide::Slide;
use crate::db::user::User;
use crate::routes::slide::UpdateSlideForm;
use crate::schema::capsules;
use crate::schema::slides;
use crate::{Database, Error, Result};

/// A struct that serves the purpose of veryifing the form.
#[derive(Deserialize, Debug)]
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

    /// the project associated to the capsule.
    pub project_id: i32,

    /// Reference to capsule background image
    pub background_id: Option<i32>,

    /// Reference to  capsule logo
    pub logo_id: Option<i32>,
}

/// A struct/form for update (PUT) operations
#[derive(Deserialize, AsChangeset, Debug)]
#[table_name = "capsules"]
pub struct UpdateCapsuleForm {
    /// The (unique) name of the capsule.
    pub name: Option<String>,

    /// The title the capsule.
    pub title: Option<String>,

    /// Reference to pdf file of caspusle
    pub slide_show_id: Option<Option<i32>>,

    /// The description of the capsule.
    pub description: Option<String>,

    /// Reference to capsule background image
    pub background_id: Option<Option<i32>>,

    /// Reference to  capsule logo
    pub logo_id: Option<Option<i32>>,
}

/// internal function for data format
fn format_capsule_data(db: &Database, capsule: &Capsule) -> Result<JsonValue> {
    Ok(json!({ "capsule":     capsule,
               "slide_show":  capsule.get_slide_show(&db)?,
               "slides":      capsule.get_slides(&db)? ,
               "projects":    capsule.get_projects(&db)?,
               "background":  capsule.get_background(&db)?,
               "logo":        capsule.get_logo(&db)?,
    }))
}

/// The route to register new capsule.
#[post("/new-capsule", data = "<capsule>")]
pub fn new_capsule(db: Database, user: User, capsule: Json<NewCapsuleForm>) -> Result<JsonValue> {
    user.get_project_by_id(capsule.project_id, &db)?;

    let capsule = Capsule::new(
        &db,
        &capsule.name,
        &capsule.title,
        capsule.slide_show_id,
        &capsule.description,
        capsule.background_id,
        capsule.logo_id,
        Some(Project::get_by_id(capsule.project_id, &db)?),
    )?;

    Ok(json!(capsule))
}

/// The route to get a capsule.
#[get("/capsule/<id>")]
pub fn get_capsule(db: Database, user: User, id: i32) -> Result<JsonValue> {
    let capsule = user.get_capsule_by_id(id, &db)?;
    format_capsule_data(&db, &capsule)
}

/// Get all the capsules .
#[get("/capsules")]
pub fn all_capsules(db: Database, _user: User) -> Result<JsonValue> {
    Ok(json!(Capsule::all(&db)?))
}

/// Update a capsule
#[put("/capsule/<capsule_id>", data = "<capsule_form>")]
pub fn update_capsule(
    db: Database,
    user: User,
    capsule_id: i32,
    capsule_form: Json<UpdateCapsuleForm>,
) -> Result<JsonValue> {
    user.get_capsule_by_id(capsule_id, &db)?;

    use crate::schema::capsules::dsl::id;
    diesel::update(capsules::table)
        .filter(id.eq(capsule_id))
        .set(&capsule_form.into_inner())
        .execute(&db.0)?;

    Ok(json!({ "capsule": Capsule::get_by_id(capsule_id, &db)? }))
}
/// Delete a capsule
#[delete("/capsule/<id>")]
pub fn delete_capsule(db: Database, user: User, id: i32) -> Result<JsonValue> {
    let capsule = user.get_capsule_by_id(id, &db)?;
    Ok(json!({"nb capsules deleted": capsule.delete(&db)?}))
}

/// Upload a presentation (slides)
#[post("/capsule/<id>/upload_slides", data = "<data>")]
pub fn upload_slides(
    db: Database,
    user: User,
    content_type: &ContentType,
    id: i32,
    data: Data,
) -> Result<JsonValue> {
    let capsule = user.get_capsule_by_id(id, &db)?;

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
                    let mut server_path = PathBuf::from(&user.username);
                    let uuid = Uuid::new_v4();
                    server_path.push(format!("{}_{}", uuid, file_name));
                    let asset = Asset::new(
                        &db,
                        uuid,
                        file_name,
                        &format!("/{}", server_path.to_str().unwrap()),
                    )?;
                    AssetsObject::new(&db, asset.id, capsule.id, AssetType::Capsule)?;

                    let mut output_path = PathBuf::from("dist");
                    output_path.push(server_path);
                    create_dir(output_path.parent().unwrap()).ok();
                    fs::copy(path, &output_path)?;

                    //update capsule with the ref to the uploaded pdf
                    use crate::schema::capsules::dsl;
                    diesel::update(capsules::table)
                        .filter(dsl::id.eq(capsule.id))
                        .set(dsl::slide_show_id.eq(asset.id))
                        .execute(&db.0)?;

                    // if exists remove all prevouis generatd goss and slides
                    // TODO: Brutal way add an option to upload pdf without supression of
                    // all goss and slides
                    for slide in capsule.get_slides(&db)? {
                        AssetsObject::delete_by_object(&db, slide.id, AssetType::Slide)?;
                        slide.delete(&db)?;
                        //TODO: supress file on disk
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

                    //TODO : use enumerate  instead of idx ?
                    let mut idx = 1;
                    for e in entries {
                        // Create one GOS and associated per image
                        // one slide per GOS
                        let stem = Path::new(file_name).file_stem().unwrap().to_str().unwrap();
                        let uuid = Uuid::new_v4();
                        let slide_name = format!("{}__{}.png", stem, idx);
                        let mut server_path = PathBuf::from(&user.username);
                        server_path.push("extract");
                        server_path.push(format!("{}_{}", uuid, slide_name));
                        let asset = Asset::new(
                            &db,
                            uuid,
                            &slide_name,
                            &format!("/{}", server_path.to_str().unwrap()),
                        )?;
                        // When generated a slide take position (idx*100) and one per GOS
                        Slide::new(&db, idx, 1, idx, asset.id, id, "Dummy prompt")?;
                        let mut output_path = PathBuf::from("dist");
                        output_path.push(server_path);
                        create_dir(output_path.parent().unwrap()).ok();
                        fs::copy(e, &output_path)?;
                        idx += 1;
                    }
                    dir.close()?;
                    // TODO: return capsule details like get_capsule
                    return format_capsule_data(&db, &capsule);
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

fn upload_file(
    db: &Database,
    user: &User,
    capsule: &Capsule,
    content_type: &ContentType,
    data: Data,
) -> Result<Asset> {
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
                    let mut server_path = PathBuf::from(&user.username);
                    let uuid = Uuid::new_v4();
                    server_path.push(format!("{}_{}", uuid, file_name));
                    let asset = Asset::new(
                        &db,
                        uuid,
                        file_name,
                        &format!("/{}", server_path.to_str().unwrap()),
                    )?;
                    AssetsObject::new(&db, asset.id, capsule.id, AssetType::Capsule)?;

                    let mut output_path = PathBuf::from("dist");
                    output_path.push(server_path);

                    println!("output_path {:#?}", output_path);
                    create_dir(output_path.parent().unwrap()).ok();
                    fs::copy(path, &output_path)?;
                    return Ok(asset);
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
    return Err(Error::NotFound);
}

/// Upload a background
#[post("/capsule/<id>/upload_background", data = "<data>")]
pub fn upload_background(
    db: Database,
    user: User,
    content_type: &ContentType,
    id: i32,
    data: Data,
) -> Result<JsonValue> {
    let capsule = user.get_capsule_by_id(id, &db)?;
    let asset = upload_file(&db, &user, &capsule, content_type, data)?;
    use crate::schema::capsules::dsl;
    diesel::update(capsules::table)
        .filter(dsl::id.eq(capsule.id))
        .set(dsl::slide_show_id.eq(asset.id))
        .execute(&db.0)?;

    format_capsule_data(&db, &user.get_capsule_by_id(id, &db)?)
}

/// Upload logo
#[post("/capsule/<id>/upload_logo", data = "<data>")]
pub fn upload_logo(
    db: Database,
    user: User,
    content_type: &ContentType,
    id: i32,
    data: Data,
) -> Result<JsonValue> {
    let capsule = user.get_capsule_by_id(id, &db)?;
    let asset = upload_file(&db, &user, &capsule, content_type, data)?;
    use crate::schema::capsules::dsl;
    diesel::update(capsules::table)
        .filter(dsl::id.eq(capsule.id))
        .set(dsl::logo_id.eq(asset.id))
        .execute(&db.0)?;

    format_capsule_data(&db, &user.get_capsule_by_id(id, &db)?)
}
/// order capsule gos and slide
#[post("/capsule/<id>/gos_order", data = "<goss>")]
pub fn gos_order(
    db: Database,
    user: User,
    id: i32,
    goss: Json<Vec<Vec<i32>>>,
) -> Result<JsonValue> {
    let capsule = user.get_capsule_by_id(id, &db)?;

    let mut position = 1;
    for (gos, slides) in goss.iter().enumerate() {
        for (position_in_gos, slide_id) in slides.iter().enumerate() {
            use crate::schema::slides::dsl::id;
            diesel::update(slides::table)
                .filter(id.eq(slide_id))
                .set(&UpdateSlideForm {
                    position: Some(position),
                    position_in_gos: Some((position_in_gos + 1) as i32),
                    gos: Some((gos + 1) as i32),
                    asset_id: None,
                    capsule_id: None,
                    prompt: None,
                })
                .execute(&db.0)?;
            position += 1;
        }
    }
    format_capsule_data(&db, &capsule)
}
