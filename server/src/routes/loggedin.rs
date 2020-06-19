//! This module contains all the routes related to loggedIn request

use std::fs::{self, create_dir};
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};

use serde_json::json as serde_json;

use diesel::ExpressionMethods;
use diesel::RunQueryDsl;

use rocket::http::ContentType;
use rocket::{Data, State};
use rocket_contrib::json::JsonValue;
use rocket_multipart_form_data::{
    FileField, MultipartFormData, MultipartFormDataField, MultipartFormDataOptions,
};

use tempfile::tempdir;
use uuid::Uuid;

use crate::config::Config;
use crate::db::asset::Asset;
use crate::db::capsule::Capsule;
use crate::db::project::Project;
use crate::db::slide::Slide;
use crate::db::user::User;
use crate::routes::capsule::{format_capsule_data, GosStructure};
use crate::schema::capsules;

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

                    println!(" assset: {:#?}", asset);
                    let project =
                        Project::create(&format!("project-{}", asset.uuid), user.id)?.save(&db)?;
                    let capsule = Capsule::new(
                        &db,
                        &format!("capsule-{}", asset.uuid),
                        "title-1",
                        None,
                        "",
                        None,
                        None,
                        Some(project),
                    )?;
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
                        let slide = Slide::new(&db, slide_asset.id, idx, "Dummy prompt")?;
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
