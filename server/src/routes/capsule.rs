//! This module contains all the routes related to capsules.
use std::fs::{self, create_dir, File};
use std::io::{self, Write};
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};

use serde_json::json as serde_json;

use diesel::ExpressionMethods;
use diesel::RunQueryDsl;

use rocket::http::ContentType;
use rocket::{Data, State};

use rocket_contrib::json::{Json, JsonValue};

use rocket_multipart_form_data::{
    FileField, MultipartFormData, MultipartFormDataField, MultipartFormDataOptions,
};

use uuid::Uuid;

use tempfile::tempdir;

use crate::config::Config;
use crate::db::asset::{Asset, AssetType, AssetsObject};
use crate::db::capsule::Capsule;
use crate::db::project::Project;
use crate::db::slide::{Slide, SlideWithAsset};
use crate::db::user::User;
use crate::schema::capsules;
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

    /// Reference to generated video for this capsule
    pub video_id: Option<Option<i32>>,
}

/// internal function for data format
fn format_capsule_data(db: &Database, capsule: &Capsule) -> Result<JsonValue> {
    Ok(json!({ "capsule":     capsule,
               "slide_show":  capsule.get_slide_show(&db)?,
               "slides":      capsule.get_slides(&db)? ,
               "projects":    capsule.get_projects(&db)?,
               "background":  capsule.get_background(&db)?,
               "logo":        capsule.get_logo(&db)?,
               "structure":   capsule.structure,
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
    config: State<Config>,
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
                        &format!("/data/{}", server_path.to_str().unwrap()),
                    )?;
                    AssetsObject::new(&db, asset.id, capsule.id, AssetType::Capsule)?;

                    let mut output_path = config.data_path.clone();
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

                    let mut child = Command::new("convert")
                        .arg("-density")
                        .arg("300")
                        .arg(format!("{}", &output_path.to_str().unwrap()))
                        .arg("-resize")
                        .arg("1920x1080!")
                        .arg(format!("{}/'%02'.png", dir.path().display()))
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
                    let mut capsule_structure = vec![];

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
                            &format!("/data/{}", server_path.to_str().unwrap()),
                        )?;
                        // When generated a slide take position (idx*100) and one per GOS
                        let slide = Slide::new(&db, asset.id, idx, "Dummy prompt")?;
                        let mut output_path = config.data_path.clone();
                        output_path.push(server_path);
                        create_dir(output_path.parent().unwrap()).ok();
                        fs::copy(e, &output_path)?;
                        idx += 1;
                        capsule_structure.push(GosStructure {
                            record_path: None,
                            slides: vec![slide.id],
                            transitions: vec![],
                            locked: false,
                        });
                    }

                    dir.close()?;

                    {
                        use crate::schema::capsules::dsl::{id as cid, structure};
                        diesel::update(capsules::table)
                            .filter(cid.eq(id))
                            .set(structure.eq(serde_json!(capsule_structure)))
                            .execute(&db.0)?;
                    }

                    // TODO: return capsule details like get_capsule
                    let capsule = user.get_capsule_by_id(id, &db)?;
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
    config: &State<Config>,
    db: &Database,
    user: &User,
    capsule: &Capsule,
    content_type: &ContentType,
    data: Data,
) -> Result<Asset> {
    let mut options = MultipartFormDataOptions::new();
    options.allowed_fields.push(
        MultipartFormDataField::file("file").size_limit(128 * 1024 * 1024 * 1024 * 1024 * 1024),
    );
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
                        &format!("/data/{}", server_path.to_str().unwrap()),
                    )?;
                    AssetsObject::new(&db, asset.id, capsule.id, AssetType::Capsule)?;

                    let mut output_path = config.data_path.clone();
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
    config: State<Config>,
    db: Database,
    user: User,
    content_type: &ContentType,
    id: i32,
    data: Data,
) -> Result<JsonValue> {
    let capsule = user.get_capsule_by_id(id, &db)?;
    let asset = upload_file(&config, &db, &user, &capsule, content_type, data)?;
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
    config: State<Config>,
    db: Database,
    user: User,
    content_type: &ContentType,
    id: i32,
    data: Data,
) -> Result<JsonValue> {
    let capsule = user.get_capsule_by_id(id, &db)?;
    let asset = upload_file(&config, &db, &user, &capsule, content_type, data)?;
    use crate::schema::capsules::dsl;
    diesel::update(capsules::table)
        .filter(dsl::id.eq(capsule.id))
        .set(dsl::logo_id.eq(asset.id))
        .execute(&db.0)?;

    format_capsule_data(&db, &user.get_capsule_by_id(id, &db)?)
}

/// The structure of a gos.
#[derive(Serialize, Deserialize, Debug)]
pub struct GosStructure {
    /// The ids of the slides of the gos.
    pub slides: Vec<i32>,

    /// The moments when the user went to the next slides, in milliseconds.
    pub transitions: Vec<i32>,

    /// The path to the record if any.
    pub record_path: Option<String>,

    /// Whether the gos is locked or not.
    pub locked: bool,
}

/// order capsule gos and slide
#[post("/capsule/<id>/gos_order", data = "<goss>")]
pub fn gos_order(
    db: Database,
    user: User,
    id: i32,
    goss: Json<Vec<GosStructure>>,
) -> Result<JsonValue> {
    let capsule = user.get_capsule_by_id(id, &db)?;
    let mut goss = goss.into_inner();

    // Verifiy that the goss doesn't violate authorizations.
    // All slides must belong to the user.
    for gos in &goss {
        for slide in &gos.slides {
            user.get_slide_by_id(*slide, &db)?;
        }
    }

    // The user is not allowed to modify the record_path.
    for gos in 0..goss.len() {
        if goss[gos].record_path != None {
            goss[gos].record_path = Some(
                capsule.structure.as_array().unwrap()[gos]
                    .get("record_path")
                    .unwrap()
                    .as_str()
                    .unwrap()
                    .to_string(),
            );
        }
    }

    // Perform the update
    use crate::schema::capsules::dsl::{id as cid, structure};
    diesel::update(capsules::table)
        .filter(cid.eq(id))
        .set(structure.eq(serde_json!(goss)))
        .execute(&db.0)?;

    let capsule = user.get_capsule_by_id(id, &db)?;
    format_capsule_data(&db, &capsule)
}

/// Route to upload a record.
#[post("/capsule/<capsule_id>/<gos>/upload_record", data = "<data>")]
pub fn upload_record(
    config: State<Config>,
    db: Database,
    user: User,
    capsule_id: i32,
    gos: usize,
    data: Data,
) -> Result<JsonValue> {
    let mut capsule = user.get_capsule_by_id(capsule_id, &db)?;

    let file_name = &format!("capsule.mp4");

    let mut server_path = PathBuf::from(&user.username);
    let uuid = Uuid::new_v4();
    server_path.push(format!("{}_{}", uuid, file_name));
    let asset = Asset::new(
        &db,
        uuid,
        file_name,
        &format!("/data/{}", server_path.to_str().unwrap()),
    )?;
    AssetsObject::new(&db, asset.id, capsule.id, AssetType::Capsule)?;

    let mut output_path = config.data_path.clone();
    output_path.push(server_path);

    println!("output_path {:#?}", output_path);
    create_dir(output_path.parent().unwrap()).ok();
    // fs::copy(path, &output_path)?;
    data.stream_to(&mut File::create(output_path)?)?;

    *capsule.structure.as_array_mut().unwrap()[gos]
        .get_mut("record_path")
        .unwrap() = serde_json!(asset.asset_path);

    *capsule.structure.as_array_mut().unwrap()[gos]
        .get_mut("locked")
        .unwrap() = serde_json!(true);

    use crate::schema::capsules::dsl::{id as cid, structure};
    diesel::update(capsules::table)
        .filter(cid.eq(capsule_id))
        .set(structure.eq(serde_json!(capsule.structure)))
        .execute(&db.0)?;

    format_capsule_data(&db, &capsule)
}

/// order capsule gos and slide
#[post("/capsule/<id>/edition")]
pub fn capsule_edition(
    config: State<Config>,
    db: Database,
    user: User,
    id: i32,
) -> Result<JsonValue> {
    let capsule = user.get_capsule_by_id(id, &db)?;
    let pip_list = "/tmp/pipList.txt";
    let mut file = File::create(pip_list)?;

    for (idx, gos) in capsule
        .structure
        .as_array()
        .unwrap()
        .into_iter()
        .enumerate()
    {
        let record_path = gos.as_object().unwrap()["record_path"].as_str().unwrap();
        // TODO : only fist slide . Assumption one slide per gos ( ie one slide per record)
        let slide_id = gos.as_object().unwrap()["slides"].as_array().unwrap()[0]
            .as_i64()
            .unwrap() as i32;
        let slide = SlideWithAsset::get_by_id(slide_id, &db)?;
        println!(
            "Piping gos {}\n record_path = {:#?}\n slide_path = {:#?}",
            idx, record_path, slide.asset.asset_path
        );

        // ffmpeg command to reproduce for overlay
        //
        // ffmpeg -y -i slide0.png -i record0.webm \
        // -filter_complex \
        // "[1]scale=300:-1 [pip]; \
        // [0][pip] overlay=main_w-overlay
        // _w-10:main_h-overlay_h-10" \
        // -profile:v main \
        // -level 3.1 -b:v 440k -ar 44100 -ab 128k \
        // -vcodec h264 -acodec mp3 \
        // $PIP1
        let pip_out = format!("/tmp/pip{}.mp4", idx);
        let mut slide_path = config.data_path.clone();
        slide_path.push(slide.asset.asset_path);
        let mut record = config.data_path.clone();
        record.push(record_path);

        let slide = slide_path.to_str().unwrap();
        let record = record.to_str().unwrap();
        let command = vec![
            "ffmpeg",
            "-hide_banner",
            "-y",
            "-i",
            &slide,
            "-i",
            &record,
            "-filter_complex",
            "[1]scale=300:-1 [pip]; [0][pip] overlay=main_w-overlay_w-10:main_h-overlay_h-10",
            "-profile:v",
            "main",
            "-level",
            "3.1",
            "-b:v",
            "440k",
            "-ar",
            "44100",
            "-ab",
            "128k",
            "-vcodec",
            "h264",
            "-acodec",
            "mp3",
            &pip_out,
        ];

        println!("command = {:#?}", command);
        let child = Command::new(command[0])
            .args(&command[1..])
            .output()
            .expect("failed to execute child");

        if !child.status.success() {
            // for debug pupose if needed
            io::stdout().write_all(&child.stdout).unwrap();
            io::stderr().write_all(&child.stderr).unwrap();
            return Err(Error::TranscodeError);
        }

        file.write(format!("file '{}'\n", pip_out).as_bytes())?;
    }
    // concat all generated pip videos
    let file_name = &format!("record.mp4");

    let mut server_path = PathBuf::from(&user.username);
    let uuid = Uuid::new_v4();
    server_path.push(format!("{}_{}", uuid, file_name));

    let mut output = config.data_path.clone();
    output.push(&server_path);

    let output = output.to_str().unwrap();

    println!("Generating video capsule ...");
    let command = vec![
        "ffmpeg",
        "-hide_banner",
        "-y",
        "-f",
        "concat",
        "-safe",
        "0",
        "-i",
        pip_list,
        "-c",
        "copy",
        output,
    ];

    let child = Command::new(command[0])
        .args(&command[1..])
        .output()
        .expect("failed to execute child");

    println!("status: {}", child.status);
    if child.status.success() {
        let asset = Asset::new(
            &db,
            uuid,
            file_name,
            &format!("/data/{}", server_path.to_str().unwrap()),
        )?;
        AssetsObject::new(&db, asset.id, capsule.id, AssetType::Capsule)?;

        // Add video_id to capsule
        use crate::schema::capsules::dsl;
        diesel::update(capsules::table)
            .filter(dsl::id.eq(capsule.id))
            .set(dsl::video_id.eq(asset.id))
            .execute(&db.0)?;
    } else {
        // for debug pupose if needed
        //
        println!("command = {:#?}", command);
        io::stdout().write_all(&child.stdout).unwrap();
        io::stderr().write_all(&child.stderr).unwrap();
        return Err(Error::TranscodeError);
    }

    let capsule = user.get_capsule_by_id(id, &db)?;
    format_capsule_data(&db, &capsule)
}
