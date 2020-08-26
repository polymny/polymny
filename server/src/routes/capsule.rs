//! This module contains all the routes related to capsules.
use std::fs::{self, create_dir, File};
use std::io::{self, Write};
use std::path::{Path, PathBuf};

use serde_json::json as serde_json;

use diesel::ExpressionMethods;
use diesel::RunQueryDsl;

use rocket::http::ContentType;
use rocket::{Data, State};

use rocket_contrib::json::{Json, JsonValue};

use rocket_multipart_form_data::{
    FileField, MultipartFormData, MultipartFormDataField, MultipartFormDataOptions, TextField,
};

use uuid::Uuid;

use tempfile::tempdir;

use crate::command;
use crate::config::Config;
use crate::db::asset::{Asset, AssetType, AssetsObject};
use crate::db::capsule::{Capsule, PublishedType};
use crate::db::project::Project;
use crate::db::slide::{Slide, SlideWithAsset};
use crate::db::user::User;
use crate::schema::capsules;
use crate::webcam::{
    position_in_pixels, size_in_pixels, str_to_webcam_position, str_to_webcam_size, EditionOptions,
    WebcamPosition, WebcamSize,
};
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
pub fn format_capsule_data(db: &Database, capsule: &Capsule) -> Result<JsonValue> {
    Ok(json!({ "capsule":     capsule,
               "slide_show":  capsule.get_slide_show(&db)?,
               "slides":      capsule.get_slides(&db)? ,
               "projects":    capsule.get_projects(&db)?,
               "background":  capsule.get_background(&db)?,
               "logo":        capsule.get_logo(&db)?,
               "structure":   capsule.structure,
               "video":       capsule.get_video(&db)?,
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
                    let asset = Asset::new(&db, uuid, file_name, server_path.to_str().unwrap())?;
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
                    command::export_slides(&output_path, dir.path())?;

                    let mut entries: Vec<_> =
                        fs::read_dir(&dir)?.map(|res| res.unwrap().path()).collect();
                    entries.sort();

                    let mut capsule_structure = vec![];

                    for (idx, e) in entries.iter().enumerate() {
                        // Create one GOS and associated per image
                        // one slide per GOS
                        let stem = Path::new(file_name).file_stem().unwrap().to_str().unwrap();
                        let uuid = Uuid::new_v4();
                        let slide_name = format!("{}__{}.png", stem, idx);
                        let mut server_path = PathBuf::from(&user.username);
                        server_path.push("extract");
                        server_path.push(format!("{}_{}", uuid, slide_name));
                        let asset =
                            Asset::new(&db, uuid, &slide_name, server_path.to_str().unwrap())?;

                        let slide = Slide::new(&db, asset.id, id, "")?;
                        let mut output_path = config.data_path.clone();
                        output_path.push(server_path);
                        create_dir(output_path.parent().unwrap()).ok();
                        fs::copy(e, &output_path)?;

                        capsule_structure.push(GosStructure {
                            record_path: None,
                            background_path: None,
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
                    let asset = Asset::new(&db, uuid, file_name, server_path.to_str().unwrap())?;
                    AssetsObject::new(&db, asset.id, capsule.id, AssetType::Capsule)?;

                    let mut output_path = config.data_path.clone();
                    output_path.push(server_path);

                    info!("uploaded file path output_path {:#?}", output_path);
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

    /// The path to the background image if any.
    pub background_path: Option<String>,

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
    content_type: &ContentType,
) -> Result<JsonValue> {
    let mut options = MultipartFormDataOptions::new();
    options.allowed_fields.push(
        MultipartFormDataField::file("file").size_limit(128 * 1024 * 1024 * 1024 * 1024 * 1024),
    );
    options.allowed_fields.push(
        MultipartFormDataField::file("background")
            .size_limit(128 * 1024 * 1024 * 1024 * 1024 * 1024),
    );
    options
        .allowed_fields
        .push(MultipartFormDataField::text("structure"));
    let multipart_form_data = MultipartFormData::parse(content_type, data, options).unwrap();
    //TODO: handle errors from multipart form dat ?
    // cf.https://github.com/magiclen/rocket-multipart-form-data/blob/master/examples/image_uploader.rs
    let file = multipart_form_data.files.get("file");
    let video_asset = if let Some(file) = file {
        match file {
            FileField::Single(file) => {
                let file_name = &file.file_name;
                let path = &file.path;
                if let Some(file_name) = file_name {
                    let mut server_path = PathBuf::from(&user.username);
                    let uuid = Uuid::new_v4();
                    server_path.push(format!("{}_{}", uuid, file_name));
                    let asset = Asset::new(&db, uuid, file_name, server_path.to_str().unwrap())?;
                    AssetsObject::new(&db, asset.id, capsule_id, AssetType::Capsule)?;
                    let mut output_path = config.data_path.clone();
                    output_path.push(server_path);
                    info!("record  output_path {:#?}", output_path);
                    create_dir(output_path.parent().unwrap()).ok();
                    fs::copy(path, &output_path)?;
                    asset
                } else {
                    todo!();
                }
            }
            FileField::Multiple(_files) => {
                // TODO: handle mutlile files
                todo!()
            }
        }
    } else {
        todo!();
    };

    let file = multipart_form_data.files.get("background");
    let background_asset = if let Some(file) = file {
        match file {
            FileField::Single(file) => {
                let file_name = &file.file_name;
                let path = &file.path;
                if let Some(file_name) = file_name {
                    let mut server_path = PathBuf::from(&user.username);
                    let uuid = Uuid::new_v4();
                    server_path.push(format!("{}_{}", uuid, file_name));
                    let asset = Asset::new(&db, uuid, file_name, server_path.to_str().unwrap())?;
                    AssetsObject::new(&db, asset.id, capsule_id, AssetType::Capsule)?;
                    let mut output_path = config.data_path.clone();
                    output_path.push(server_path);
                    info!("record  output_path {:#?}", output_path);
                    create_dir(output_path.parent().unwrap()).ok();
                    fs::copy(path, &output_path)?;
                    asset
                } else {
                    todo!();
                }
            }
            FileField::Multiple(_files) => {
                // TODO: handle mutlile files
                todo!()
            }
        }
    } else {
        todo!();
    };

    let text = match multipart_form_data.texts.get("structure") {
        Some(TextField::Single(field)) => &field.text,
        _ => panic!(),
    };
    let structure: Vec<GosStructure> = serde_json::from_str(text).unwrap();
    // Verifiy that the goss doesn't violate authorizations.
    // All slides must belong to the user.
    for gos in &structure {
        for slide in &gos.slides {
            user.get_slide_by_id(*slide, &db)?;
        }
    }
    // let mut structure: Vec<GosStructure> =
    //     serde_json::from_str(multipart_form_data.texts.get("structure").unwrap().text).unwrap();
    let capsule = user.get_capsule_by_id(capsule_id, &db)?;
    let mut v: Vec<GosStructure> = serde_json::from_value(capsule.structure).unwrap();
    v[gos].record_path = Some(video_asset.asset_path.clone());
    v[gos].background_path = Some(background_asset.asset_path.clone());
    v[gos].locked = true;
    {
        use crate::schema::capsules::dsl::{id as cid, structure};
        diesel::update(capsules::table)
            .filter(cid.eq(capsule_id))
            .set(structure.eq(serde_json!(v)))
            .execute(&db.0)?;
    }
    let capsule = user.get_capsule_by_id(capsule_id, &db)?;
    format_capsule_data(&db, &capsule)
}

/// Post inout data for edition
#[derive(Deserialize, Debug)]
pub struct PostEdition {
    /// Video and audio or audio only
    pub with_video: Option<bool>,

    /// Webcam size
    pub webcam_size: Option<String>,

    /// Webcam  Position
    pub webcam_position: Option<String>,
}

/// order capsule gos and slide
#[post("/capsule/<id>/edition", data = "<post_data>")]
pub fn capsule_edition(
    config: State<Config>,
    db: Database,
    user: User,
    id: i32,
    post_data: Json<PostEdition>,
) -> Result<JsonValue> {
    let capsule = user.get_capsule_by_id(id, &db)?;
    let dir = tempdir()?;
    let pip_path = dir.path().join(format!("pipList_{}.txt", capsule.id));
    let mut pip_file = File::create(&pip_path)?;

    let structure: Vec<GosStructure> = serde_json::from_value(capsule.structure).unwrap();
    let mut run_ffmpeg_command = true ;

    for (idx, gos) in structure.into_iter().enumerate() {
        // TODO : only first slide . Assumption one slide per gos ( ie one slide per record)
        let slide_id = gos.slides[0];
        let slide = SlideWithAsset::get_by_id(slide_id, &db)?;
        match slide.extra {
            Some(asset) => {
                info!(
                    "In slide {} merging with extra data = {:#?}",
                    idx, asset.asset_path
                );
                let mut extra_path = config.data_path.clone();
                extra_path.push(asset.asset_path);

                pip_file.write(format!("file '{}'\n", extra_path.to_str().unwrap()).as_bytes())?;
            }
            None => {
                let mut ffmpeg_command = Vec::new();

                let mut slide_path = config.data_path.clone();
                slide_path.push(slide.asset.asset_path);
                let pip_out = dir.path().join(format!("pip{}_{:03}.mp4", capsule.id, idx));
                let webcam_size = {
                    match &post_data.webcam_size {
                        Some(x) => str_to_webcam_size(x),
                        _ => WebcamSize::Medium,
                    }
                };
                let webcam_position = {
                    match &post_data.webcam_position {
                        Some(x) => str_to_webcam_position(x),
                        _ => WebcamPosition::BottomLeft,
                    }
                };

                let filter_complex = format!(
                    "[0] scale=1920:1080 [slide] ;[1]scale={}:-1 [pip]; [slide][pip] overlay={}",
                    size_in_pixels(&webcam_size),
                    position_in_pixels(&webcam_position)
                );

                let mut record = config.data_path.clone();
                match gos.record_path {
                    Some(record_path) => {
                        record.push(record_path);

                        if post_data.with_video.unwrap_or(true) {
                            run_ffmpeg_command = false ;
                            ffmpeg_command.extend(
                                vec![
                                    "ffmpeg",
                                    "-hide_banner",
                                    "-y",
                                    "-i",
                                    &slide_path.to_str().unwrap(),
                                    "-i",
                                    &record.to_str().unwrap(),
                                    "-filter_complex",
                                    &filter_complex,
                                ]
                                .into_iter(),
                            );

                        // extract record to frames
                            // path to script
                            let extraire_path = String::from("/home/pample/Bureau/Stage_Keying/polymny/scripts/extraire.sh");
                            // command
                            let extraire_command = vec![
                                "bash",
                                &extraire_path,
                                &record.to_str().unwrap(),
                            ];
                            let extraire_child = command::run_command(&extraire_command)?;
                            if !extraire_child.status.success() {
                                return Err(Error::TranscodeError);
                            }

                        // apply segmentation and matting on record frames
                            // path to script
                            let traiter_path = "/home/pample/Bureau/Stage_Keying/polymny/scripts/traiter.sh";
                            // path to frames folder
                            let input_ext: &str = "_input";
                            let record_frames = format!("{}{}", record.to_str().unwrap(), input_ext);
                            // path to background image
                            let back_ext: &str = "_back.png";
                            let background_path = format!("{}{}", record.to_str().unwrap(), back_ext);
                            // overlay position and scale
                            let pos_pixels_xy = format!("{}", position_in_pixels(&webcam_position));
                            let size_pixels = format!("{}", size_in_pixels(&webcam_size));
                            // command
                            let matting_command  = vec![
                                "bash",
                                traiter_path,
                                &record_frames,
                                &background_path,
                                &slide_path.to_str().unwrap(),
                                &pos_pixels_xy,
                                &size_pixels,
                            ];
                            let matting_child = command::run_command(&matting_command)?;
                            if !matting_child.status.success() {
                                return Err(Error::TranscodeError);
                            }

                        // build video from incruster.py
                            // path to script
                            let reconstruire_path = String::from("/home/pample/Bureau/Stage_Keying/polymny/scripts/reconstruire.sh");
                            // command
                            let reconstruire_command = vec![
                                "bash",
                                &reconstruire_path,
                                &record_frames,
                                &pip_out.to_str().unwrap(),
                            ];
                            let reconstruire_child = command::run_command(&reconstruire_command)?;
                            if !reconstruire_child.status.success() {
                                return Err(Error::TranscodeError);
                            }

                        // webcam position and size info update
                            let capsule_edition_options = EditionOptions {
                                                            with_video: post_data.with_video.unwrap_or(true),
                                                            webcam_size: webcam_size,
                                                            webcam_position: webcam_position,
                                                        };
                            info!("capsule_edition_options= {:#?}", capsule_edition_options);
                            use crate::schema::capsules::dsl;
                            diesel::update(capsules::table)
                                .filter(dsl::id.eq(capsule.id))
                                .set(dsl::edition_options.eq(serde_json!(capsule_edition_options)))
                                .execute(&db.0)?;
                                
                        } else {
                            ffmpeg_command.extend(
                                vec![
                                    "ffmpeg",
                                    "-hide_banner",
                                    "-y",
                                    "-loop",
                                    "1",
                                    "-i",
                                    &slide_path.to_str().unwrap(),
                                    "-i",
                                    &record.to_str().unwrap(),
                                    "-map",
                                    "0:v:0",
                                    "-map",
                                    "1:a:0",
                                    "-shortest",
                                ]
                                .into_iter(),
                            );
                        }
                    }

                    None => {
                        // ffmpeg -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=44100 -loop 1 -i tmp/slide2.png -c:v libx264 -t 3 -pix_fmt yuv420p -s hd1080 -r 25 -shortest out.mp4
                        ffmpeg_command.extend(
                            vec![
                                "ffmpeg",
                                "-y",
                                "-hide_banner",
                                "-f",
                                "lavfi",
                                "-i",
                                "anullsrc=channel_layout=stereo:sample_rate=44100",
                                "-loop",
                                "1",
                                "-i",
                                &slide_path.to_str().unwrap(),
                                "-t",
                                "3",
                                "-shortest",
                            ]
                            .into_iter(),
                        );
                    }
                }
                // here finalisation of output stream
                ffmpeg_command.extend(
                    vec![
                        "-profile:v",
                        "main",
                        "-pix_fmt",
                        "yuv420p",
                        "-level",
                        "3.1",
                        "-b:v",
                        "440k",
                        "-ar",
                        "44100",
                        "-ab",
                        "128k",
                        "-vcodec",
                        "libx264",
                        "-preset",
                        "medium",
                        "-tune",
                        "stillimage",
                        "-acodec",
                        "aac",
                        "-s",
                        "hd1080",
                        "-r",
                        "25",
                        &pip_out.to_str().unwrap(),
                    ]
                    .into_iter(),
                );
                if run_ffmpeg_command {
                    let child = command::run_command(&ffmpeg_command)?;
                    if !child.status.success() {
                        return Err(Error::TranscodeError);
                    }    
                }

                pip_file.write(format!("file '{}'\n", &pip_out.to_str().unwrap()).as_bytes())?;
            }
        }
    }

    // concat all generated pip videos
    let file_name = || {
        if post_data.with_video.unwrap_or(true) {
            format!("capsule_audio_and_video.mp4")
        } else {
            format!("capsule_audio_only.mp4")
        }
    };

    let mut server_path = PathBuf::from(&user.username);
    let uuid = Uuid::new_v4();
    server_path.push(format!("{}_{}", uuid, &file_name()));

    let mut output = config.data_path.clone();
    output.push(&server_path);

    let output = output.to_str().unwrap();

    let command = vec![
        "ffmpeg",
        "-hide_banner",
        "-y",
        "-f",
        "concat",
        "-safe",
        "0",
        "-i",
        &pip_path.to_str().unwrap(),
        "-c",
        "copy",
        output,
    ];

    let child = command::run_command(&command)?;

    if child.status.success() {
        let asset = Asset::new(&db, uuid, &file_name(), server_path.to_str().unwrap())?;
        AssetsObject::new(&db, asset.id, capsule.id, AssetType::Capsule)?;

        // Add video_id to capsule
        use crate::schema::capsules::dsl;
        diesel::update(capsules::table)
            .filter(dsl::id.eq(capsule.id))
            .set((
                dsl::video_id.eq(asset.id),
                dsl::published.eq(PublishedType::NotPublished),
            ))
            .execute(&db.0)?;
    } else {
        // for debug pupose if needed
        //
        info!("command = {:#?}", command);
        io::stdout().write_all(&child.stdout).unwrap();
        io::stderr().write_all(&child.stderr).unwrap();
        return Err(Error::TranscodeError);
    }

    dir.close()?;

    let capsule = user.get_capsule_by_id(id, &db)?;
    format_capsule_data(&db, &capsule)
}

/// The route to publish a video.
#[post("/capsule/<id>/publication")]
pub fn capsule_publication(config: State<Config>, db: Database, user: User, id: i32) -> Result<()> {
    let capsule = user.get_capsule_by_id(id, &db)?;

    match capsule.published {
        PublishedType::Publishing => return Err(Error::NotFound),
        PublishedType::Published => (),
        _ => (),
    }

    use crate::schema::capsules::dsl;
    diesel::update(capsules::table)
        .filter(dsl::id.eq(capsule.id))
        .set(dsl::published.eq(PublishedType::Publishing))
        .execute(&db.0)?;

    let asset = Asset::get_by_id(capsule.video_id.ok_or(Error::NotFound)?, &db)?;
    let input_path = config.data_path.join(&asset.0.asset_path);
    let input_path = input_path.to_str().unwrap();
    let output_path = config.videos_path.join(asset.0.uuid.to_string());
    let output_path = output_path.to_str().unwrap();
    let command = vec!["dash-encode", "encode", input_path, output_path];

    let child = command::run_command(&command)?;

    if child.status.success() {
        use crate::schema::capsules::dsl;
        diesel::update(capsules::table)
            .filter(dsl::id.eq(capsule.id))
            .set(dsl::published.eq(PublishedType::Published))
            .execute(&db.0)?;
    } else {
        use crate::schema::capsules::dsl;
        diesel::update(capsules::table)
            .filter(dsl::id.eq(capsule.id))
            .set(dsl::published.eq(PublishedType::NotPublished))
            .execute(&db.0)?;
        error!(
            "command {:?} failed:\nSTDOUT\n{}\n\nSTDERR\n{}",
            command,
            String::from_utf8(child.stdout).unwrap(),
            String::from_utf8(child.stderr).unwrap()
        );
    }

    Ok(())
}
