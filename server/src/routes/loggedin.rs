//! This module contains all the routes related to loggedIn request

use std::fs::{self, create_dir};
use std::path::{Path, PathBuf};

use serde_json::json as serde_json;

use diesel::ExpressionMethods;
use diesel::RunQueryDsl;

use rocket::http::ContentType;
use rocket::{Data, State};
use rocket_contrib::json::{Json, JsonValue};
use rocket_multipart_form_data::{
    FileField, MultipartFormData, MultipartFormDataField, MultipartFormDataOptions,
};

use tempfile::tempdir;
use uuid::Uuid;

use crate::command::run_command;
use crate::config::Config;
use crate::db::asset::Asset;
use crate::db::capsule::Capsule;
use crate::db::project::Project;
use crate::db::slide::Slide;
use crate::db::user::User;
use crate::routes::capsule::{format_capsule_data, GosStructure};
use crate::schema::{capsules, users};
use crate::webcam::{webcam_position_to_str, webcam_size_to_str, EditionOptions};

use crate::{Database, Error, Result};

/// Upload a presentation (slides)
#[post("/quick_upload_slides", data = "<data>")]
pub fn quick_upload_slides(
    config: State<Config>,
    db: Database,
    user: User,
    content_type: &ContentType,
    data: Data,
) -> Result<JsonValue> {
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

                    let mut output_path = config.data_path.clone();
                    output_path.push(server_path);

                    println!("output_path {:#?}", output_path);
                    create_dir(output_path.parent().unwrap()).ok();
                    fs::copy(path, &output_path)?;

                    let project = Project::create(
                        &format!(
                            "{}__{}",
                            PathBuf::from(file_name)
                                .file_stem()
                                .unwrap()
                                .to_str()
                                .unwrap(),
                            asset.uuid
                        ),
                        user.id,
                    )?
                    .save(&db)?;
                    let capsule = Capsule::new(
                        &db,
                        &format!(
                            "{}__{}",
                            PathBuf::from(file_name)
                                .file_stem()
                                .unwrap()
                                .to_str()
                                .unwrap(),
                            asset.uuid
                        ),
                        "title-1",
                        None,
                        "",
                        None,
                        None,
                        Some(project),
                    )?;
                    //update capsule with the ref to the uploaded pdf
                    use crate::schema::capsules::dsl;
                    diesel::update(capsules::table)
                        .filter(dsl::id.eq(capsule.id))
                        .set(dsl::slide_show_id.eq(asset.id))
                        .execute(&db.0)?;

                    // Generates images one per presentation page
                    let dir = tempdir()?;

                    let command_output_path = format!("{}", &output_path.to_str().unwrap());
                    let command_input_path = format!("{}/'%02'.png", dir.path().display());
                    let command = vec![
                        "convert",
                        "-density",
                        "300",
                        &command_output_path,
                        "-resize",
                        "1920x1080!",
                        &command_input_path,
                    ];

                    run_command(&command)?;

                    let mut entries: Vec<_> =
                        fs::read_dir(&dir)?.map(|res| res.unwrap().path()).collect();
                    entries.sort();

                    let mut capsule_structure = vec![];

                    for (idx, e) in entries.iter().enumerate() {
                        // Create one GOS and associated per image
                        // one slide per GOS
                        let stem = Path::new(&asset.name)
                            .file_stem()
                            .unwrap()
                            .to_str()
                            .unwrap();
                        let uuid = Uuid::new_v4();
                        let slide_name = format!("{}__{}.png", stem, idx);
                        let mut server_path = PathBuf::from(&user.username);
                        server_path.push("extract");
                        server_path.push(format!("{}_{}", uuid, slide_name));
                        let slide_asset =
                            Asset::new(&db, uuid, &slide_name, server_path.to_str().unwrap())?;
                        // When generated a slide take position (idx*100) and one per GOS
                        let slide = Slide::new(&db, slide_asset.id, capsule.id, "Dummy prompt")?;
                        let mut output_path = config.data_path.clone();
                        output_path.push(server_path);
                        create_dir(output_path.parent().unwrap()).ok();
                        fs::copy(e, &output_path)?;
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
                            .filter(cid.eq(capsule.id))
                            .set(structure.eq(serde_json!(capsule_structure)))
                            .execute(&db.0)?;
                    }

                    // TODO: return capsule details like get_capsule
                    let capsule = user.get_capsule_by_id(capsule.id, &db)?;
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
    return Err(Error::NotFound);
}

/// Upload a presentation (slides)
#[put("/options", data = "<data>")]
pub fn options(db: Database, user: User, data: Json<EditionOptions>) -> Result<JsonValue> {
    // Perform the update
    use crate::schema::users::dsl;
    println!("data= {:#?}", data);
    diesel::update(users::table)
        .filter(dsl::id.eq(user.id))
        .set(dsl::edition_options.eq(serde_json!(data.into_inner())))
        .execute(&db.0)?;

    let nuser = User::get_by_id(user.id, &db)?;
    let options = nuser.get_edition_options()?;
    println!("{:#?}", options);
    Ok(json!({"username": nuser.username,
        "projects": nuser.projects(&db)?,
        "active_project": "",
        "with_video": options.with_video,
        "webcam_size": webcam_size_to_str(options.webcam_size),
        "webcam_position": webcam_position_to_str(options.webcam_position),
    }))
}
