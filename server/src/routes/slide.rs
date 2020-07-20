//! This module contains all the routes related to slides.

use std::fs::{self, create_dir};
use std::path::{Path, PathBuf};

use diesel::ExpressionMethods;
use diesel::RunQueryDsl;

use rocket::http::ContentType;
use rocket::{Data, State};
use rocket_contrib::json::{Json, JsonValue};

use rocket_multipart_form_data::{
    FileField, MultipartFormData, MultipartFormDataField, MultipartFormDataOptions,
};

use uuid::Uuid;

use crate::command::run_command;
use crate::config::Config;
use crate::db::asset::{Asset, AssetType, AssetsObject};
use crate::db::slide::{Slide, SlideWithAsset};
use crate::db::user::User;
use crate::schema::slides;
use crate::{Database, Error, Result};

/// A struct to  update Slides
#[derive(Deserialize, AsChangeset, Debug)]
#[table_name = "slides"]
pub struct UpdateSlideForm {
    /// The asset associated to slide.
    pub asset_id: Option<i32>,

    /// capsule id
    pub capsule_id: Option<i32>,

    /// The prompt text.
    pub prompt: Option<String>,

    /// The extra field
    pub extra_id: Option<Option<i32>>,
}

/// The route to get a asset.
#[get("/slide/<id>")]
pub fn get_slide(db: Database, user: User, id: i32) -> Result<JsonValue> {
    let slide = user.get_slide_by_id(id, &db)?;
    Ok(json!(slide))
}

/// The route to get a asset.
#[put("/slide/<slide_id>", data = "<slide_form>")]
pub fn update_slide(
    db: Database,
    user: User,
    slide_id: i32,
    slide_form: Json<UpdateSlideForm>,
) -> Result<JsonValue> {
    user.get_slide_by_id(slide_id, &db)?;

    println!("slide info to update : {:#?}", slide_form);

    use crate::schema::slides::dsl::id;
    diesel::update(slides::table)
        .filter(id.eq(slide_id))
        .set(&slide_form.into_inner())
        .execute(&db.0)?;

    let slide = Slide::get(slide_id, &db)?;
    Ok(json!(SlideWithAsset::new(&slide, &db)?))
}
/// The route to get a asset.
#[put("/slide/<slide_id>/move", data = "<move_slide>")]
pub fn move_slide(
    db: Database,
    user: User,
    slide_id: i32,
    move_slide: Json<UpdateSlideForm>,
) -> Result<JsonValue> {
    let slide = user.get_slide_by_id(slide_id, &db)?;
    println!("Move slide : {:#?}", move_slide);

    use crate::schema::slides::dsl::id;
    diesel::update(slides::table)
        .filter(id.eq(slide_id))
        .set(&move_slide.into_inner())
        .execute(&db.0)?;

    Ok(json!(slide))
}

/// Upload logo
#[post("/slide/<id>/upload_resource", data = "<data>")]
pub fn upload_resource(
    config: State<Config>,
    db: Database,
    user: User,
    content_type: &ContentType,
    id: i32,
    data: Data,
) -> Result<JsonValue> {
    let slide = user.get_slide_by_id(id, &db)?;
    let asset = upload_file(&config, &db, &user, id, content_type, data)?;
    println!("asset = {:#?}", asset);

    let mut asset_path = config.data_path.clone();
    asset_path.push(asset.asset_path);

    let transcoded_asset = {
        let file_stem = Path::new(&asset.name)
            .file_stem()
            .unwrap()
            .to_str()
            .unwrap();
        let mut server_path = PathBuf::from(&user.username);
        let uuid = Uuid::new_v4();
        let file_name = format!("{}_transcoded.mp4", file_stem);
        server_path.push(format!("{}_{}", uuid, file_name));
        Asset::new(&db, uuid, &file_name, server_path.to_str().unwrap())
    }?;

    AssetsObject::new(&db, transcoded_asset.id, slide.id, AssetType::Slide)?;
    println!("transcoded_asset = {:#?}", transcoded_asset);
    let mut transcoded_path = config.data_path.clone();
    transcoded_path.push(transcoded_asset.asset_path);

    let command = vec![
        "ffmpeg",
        "-hide_banner",
        "-y",
        "-i",
        &asset_path.to_str().unwrap(),
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
        "-acodec",
        "aac",
        "-s",
        "hd1080",
        &transcoded_path.to_str().unwrap(),
    ];

    let child = run_command(&command).unwrap();
    println!("Transcoded status: {}", child.status);

    if child.status.success() {
        println!("status: {}", child.status);
        use crate::schema::slides::dsl;
        diesel::update(slides::table)
            .filter(dsl::id.eq(slide.id))
            .set(dsl::extra_id.eq(transcoded_asset.id))
            .execute(&db.0)?;
    } else {
        AssetsObject::get_by_asset(&db, transcoded_asset.id)?.delete(&db)?;
        Asset::get(transcoded_asset.id, &db)?.delete(&db)?;
        return Err(Error::TranscodeError);
    };

    let slide = user.get_slide_by_id(id, &db)?;
    Ok(json!(SlideWithAsset::get_by_id(slide.id, &db)?))
}
/// Upload logo
#[post("/slide/<id>/delete_resource")]
pub fn delete_resource(db: Database, user: User, id: i32) -> Result<JsonValue> {
    let slide = user.get_slide_by_id(id, &db)?;

    match slide.extra_id {
        Some(_extra_id) => {
            use crate::schema::slides::dsl;
            diesel::update(slides::table)
                .filter(dsl::id.eq(slide.id))
                .set(&UpdateSlideForm {
                    asset_id: Some(slide.asset_id),
                    capsule_id: Some(slide.capsule_id),
                    prompt: Some(slide.prompt),
                    extra_id: Some(None),
                })
                .execute(&db.0)?;
        }
        None => println!("No additional resource to remove"),
    }

    let slide = user.get_slide_by_id(id, &db)?;
    Ok(json!(SlideWithAsset::get_by_id(slide.id, &db)?))
}
// TODO: unify this focntion with uploaf_file from src/route/capsule.rd
fn upload_file(
    config: &State<Config>,
    db: &Database,
    user: &User,
    id: i32,
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
                    AssetsObject::new(&db, asset.id, id, AssetType::Slide)?;

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
