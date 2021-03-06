//! This module contains all the routes related to capsules.
use std::fs::{self, create_dir, File};
use std::io::{self, Write};
use std::ops::Drop;
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
use crate::command::VideoMetadata;
use crate::config::Config;
use crate::db::asset::{Asset, AssetType, AssetsObject};
use crate::db::capsule::{ApiProductionChoices, Capsule, GosStructure, TaskStatus};
use crate::db::notification::NotificationStyle;
use crate::db::project::Project;
use crate::db::slide::{Slide, SlideWithAsset};
use crate::db::user::User;
use crate::schema::capsules;
use crate::{Database, Error, Result, WebSockets};

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
    Ok(json!({ "capsule":     capsule.with_video(&db)?,
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

    Ok(json!(Capsule::new(
        &db,
        &capsule.name,
        &capsule.title,
        capsule.slide_show_id,
        &capsule.description,
        capsule.background_id,
        capsule.logo_id,
        Some(Project::get_by_id(capsule.project_id, &db).map(|x| x.to_project())?),
    )?
    .with_video(&db)?))
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

    Ok(json!(Capsule::get_by_id(capsule_id, &db)?))
}
/// Delete a capsule
#[delete("/capsule/<id>")]
pub fn delete_capsule(db: Database, user: User, id: i32) -> Result<JsonValue> {
    user.get_capsule_by_id(id, &db)?;
    use crate::schema::capsules::dsl;
    let result = diesel::update(capsules::table)
        .filter(dsl::id.eq(id))
        .set(dsl::active.eq(false))
        .execute(&db.0)?;
    Ok(json!({ "nb capsules deleted": result }))
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
                let file_name = file.file_name.as_ref().map(|x| x.replace("'", "_"));
                let path = &file.path;
                if let Some(file_name) = file_name {
                    let mut server_path = PathBuf::from(&user.username);
                    let uuid = Uuid::new_v4();
                    server_path.push(format!("{}_{}", uuid, file_name));
                    let asset = Asset::new(
                        &db,
                        uuid,
                        file_name.as_ref(),
                        server_path.to_str().unwrap(),
                        Some(file.content_type.as_ref().unwrap().essence_str()),
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

                    command::export_slides(&config, &output_path, dir.path(), None)?;

                    let mut entries: Vec<_> =
                        fs::read_dir(&dir)?.map(|res| res.unwrap().path()).collect();
                    entries.sort();

                    let mut capsule_structure = vec![];

                    for (idx, e) in entries.iter().enumerate() {
                        // Create one GOS and associated per image
                        // one slide per GOS
                        let stem = Path::new(&file_name).file_stem().unwrap().to_str().unwrap();
                        let uuid = Uuid::new_v4();
                        let slide_name = format!("{}__{}.png", stem, idx);
                        let mut server_path = PathBuf::from(&user.username);
                        server_path.push("extract");
                        server_path.push(format!("{}_{}", uuid, slide_name));
                        let asset = Asset::new(
                            &db,
                            uuid,
                            &slide_name,
                            server_path.to_str().unwrap(),
                            Some("image/png"),
                        )?;

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
                            production_choices: None,
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
                let file_name = file.file_name.as_ref().map(|x| x.replace("'", "_"));
                let path = &file.path;
                if let Some(file_name) = file_name {
                    let mut server_path = PathBuf::from(&user.username);
                    let uuid = Uuid::new_v4();
                    server_path.push(format!("{}_{}", uuid, file_name));
                    let asset = Asset::new(
                        &db,
                        uuid,
                        file_name.as_ref(),
                        server_path.to_str().unwrap(),
                        Some(file.content_type.as_ref().unwrap().essence_str()),
                    )?;
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

/// order capsule gos and slide
#[post("/capsule/<id>/gos_order", data = "<goss>")]
pub fn gos_order(
    db: Database,
    user: User,
    id: i32,
    goss: Json<Vec<GosStructure>>,
) -> Result<JsonValue> {
    user.get_capsule_by_id(id, &db)?;
    let goss = goss.into_inner();

    // Verifiy that the goss doesn't violate authorizations.
    // All slides must belong to the user.
    for gos in &goss {
        for slide in &gos.slides {
            user.get_slide_by_id(*slide, &db)?;
        }
    }

    // The user is not allowed to modify the record_path.
    for gos in 0..goss.len() {
        if let Some(path) = goss[gos].record_path.as_ref() {
            // This code does not work
            // goss[gos].record_path = Some(
            //     capsule.structure.as_array().unwrap()[gos]
            //         .get("record_path")
            //         .unwrap()
            //         .as_str()
            //         .unwrap()
            //         .to_string(),
            // );

            // For the moment, only ensure that the path belongs to the right user
            if !path.starts_with(&user.username) {
                todo!("not authorized");
            }
        }
    }

    debug!("gos_ortder structure: {:#?}", goss);
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
                let file_name = file_name.clone().unwrap_or("unnamed".to_owned());
                let mut server_path = PathBuf::from(&user.username);
                let uuid = Uuid::new_v4();
                server_path.push(format!("{}_{}", uuid, file_name));
                let asset = Asset::new(
                    &db,
                    uuid,
                    &file_name,
                    server_path.to_str().unwrap(),
                    Some(file.content_type.as_ref().unwrap().essence_str()),
                )?;
                AssetsObject::new(&db, asset.id, capsule_id, AssetType::Capsule)?;
                let mut output_path = config.data_path.clone();
                output_path.push(server_path);
                info!("record  output_path {:#?}", output_path);
                create_dir(output_path.parent().unwrap()).ok();
                fs::copy(path, &output_path)?;
                let _metadata = VideoMetadata::metadata(&output_path);
                asset
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
                    let asset = Asset::new(
                        &db,
                        uuid,
                        file_name,
                        server_path.to_str().unwrap(),
                        Some(file.content_type.as_ref().unwrap().essence_str()),
                    )?;
                    AssetsObject::new(&db, asset.id, capsule_id, AssetType::Capsule)?;
                    let mut output_path = config.data_path.clone();
                    output_path.push(server_path);
                    info!("record  output_path {:#?}", output_path);
                    create_dir(output_path.parent().unwrap()).ok();
                    fs::copy(path, &output_path)?;
                    Some(asset)
                } else {
                    None
                }
            }
            FileField::Multiple(_files) => {
                // TODO: handle mutlile files
                todo!()
            }
        }
    } else {
        None
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
    v[gos].background_path = background_asset.map(|x| x.asset_path.clone());
    v[gos].transitions = structure[gos].transitions.clone();
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

/// Data for capsule validation.
#[derive(AsChangeset, Deserialize, Debug)]
#[table_name = "capsules"]
pub struct CapsuleValidationUpdate {
    /// Whether the capsule will be active or not.
    pub active: Option<bool>,

    /// The new name of the capsule.
    pub name: Option<String>,

    /// The gos structure.
    pub structure: serde_json::Value,
}

/// Data for capsule validation.
#[derive(Serialize, Deserialize, Debug)]
pub struct CapsuleValidation {
    /// The new name of the capsule.
    pub name: Option<String>,

    /// The id of the project in which to add the capsule.
    pub project_id: Option<i32>,

    /// The name of the project if the user wants to create a new project.
    pub project_name: Option<String>,

    /// The gos structure.
    pub structure: Vec<Vec<i32>>,
}

impl CapsuleValidation {
    /// Extracts the capsule validation update data.
    pub fn to_changeset(&self) -> CapsuleValidationUpdate {
        let new_structure = self
            .structure
            .clone()
            .into_iter()
            .map(|x| GosStructure {
                slides: x,
                transitions: vec![],
                record_path: None,
                background_path: None,
                locked: false,
                production_choices: None,
            })
            .collect::<Vec<_>>();

        CapsuleValidationUpdate {
            active: Some(true),
            name: self.name.clone(),
            structure: serde_json!(new_structure),
        }
    }
}

/// Validates a capsule.
#[post("/capsule/<capsule_id>/validate", data = "<data>")]
pub fn validate_capsule(
    db: Database,
    user: User,
    capsule_id: i32,
    data: Json<CapsuleValidation>,
) -> Result<JsonValue> {
    let capsule = user.get_capsule_by_id(capsule_id, &db)?;

    {
        let data = data.into_inner();

        // xor between data.project_id and data.project_name. It can be one or the other, but not
        // both
        if data.project_id.is_some() == data.project_name.is_some() {
            todo!("Better error message");
        }

        for gos in &data.structure {
            for slide in gos {
                user.get_slide_by_id(*slide, &db)?;
            }
        }

        let update = data.to_changeset();

        use crate::schema::capsules::dsl::id as cid;
        diesel::update(capsules::table)
            .filter(cid.eq(capsule_id))
            .set(&update)
            .execute(&db.0)?;

        if let Some(project_id) = data.project_id {
            use crate::schema::capsules_projects;
            diesel::update(capsules_projects::table)
                .filter(capsules_projects::dsl::capsule_id.eq(capsule.id))
                .set(capsules_projects::dsl::project_id.eq(project_id))
                .execute(&db.0)?;
        }

        if let Some(project_name) = data.project_name {
            // This means that the project was just created, so we will rename it.
            use crate::schema::projects;

            let old_projects = capsule.get_projects(&db)?;

            // There should be only one project
            assert!(old_projects.len() == 1);

            diesel::update(projects::table)
                .filter(projects::dsl::id.eq(old_projects[0].id))
                .set(projects::dsl::project_name.eq(project_name))
                .execute(&db.0)?;
        }
    }

    format_capsule_data(&db, &user.get_capsule_by_id(capsule_id, &db)?)
}

/// Route to update the capsule production choices.
#[post("/capsule/<id>/options", data = "<data>")]
pub fn capsule_options(
    db: Database,
    user: User,
    id: i32,
    data: Json<ApiProductionChoices>,
) -> Result<()> {
    let capsule = user.get_capsule_by_id(id, &db)?;
    let capsule_production_choices = data.into_inner().to_edition_options();

    use crate::schema::capsules::dsl;
    diesel::update(capsules::table)
        .filter(dsl::id.eq(capsule.id))
        .set(dsl::edition_options.eq(serde_json!(capsule_production_choices)))
        .execute(&db.0)?;

    Ok(())
}

/// Posted data for capsule edition
#[derive(Serialize, Deserialize, Debug)]
pub struct PostCapsuleEdition {
    /// Video and audio or audio only
    pub capsule_production_choices: ApiProductionChoices,

    /// Goss structure
    pub goss: Vec<GosStructure>,
}

/// order capsule gos and slide
#[post("/capsule/<id>/edition", data = "<post_data>")]
pub fn capsule_edition(
    config: State<Config>,
    db: Database,
    user: User,
    id: i32,
    socks: State<WebSockets>,
    post_data: Json<PostCapsuleEdition>,
) -> Result<JsonValue> {
    let capsule = user.get_capsule_by_id(id, &db)?;

    match capsule.edited {
        TaskStatus::Running => return Err(Error::NotFound),
        TaskStatus::Done => (),
        _ => (),
    }

    let mut reset = TaskStatusReset::edition(&db, capsule.id)?;

    // save Vec og Gos structrure
    let data = post_data.into_inner();
    let mut goss = data.goss;

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

    debug!("gos_ortder structure: {:#?}", goss);
    // Perform the update
    use crate::schema::capsules::dsl::{id as cid, structure};
    diesel::update(capsules::table)
        .filter(cid.eq(id))
        .set(structure.eq(serde_json!(goss)))
        .execute(&db.0)?;

    let capsule = user.get_capsule_by_id(id, &db)?;

    let capsule_production_choices = data.capsule_production_choices.to_edition_options();

    let mut workdir = config.data_path.clone();
    workdir.push(PathBuf::from(&user.username));
    workdir.push("tmp");
    create_dir(&workdir).ok();
    workdir.push(format!("capsule{}", capsule.id));
    info!("capsule workdir = {:#?}", workdir);
    create_dir(&workdir).ok();
    let pip_path = workdir.join(format!("pipList_{}.txt", capsule.id));
    let mut pip_file = File::create(&pip_path)?;

    let capsule_structure: Vec<GosStructure> = serde_json::from_value(capsule.structure).unwrap();
    let mut run_ffmpeg_command = true;
    info!(
        "capsule production choices : {:#?}",
        &capsule_production_choices
    );
    use crate::schema::capsules::dsl;
    diesel::update(capsules::table)
        .filter(dsl::id.eq(capsule.id))
        .set(dsl::edition_options.eq(serde_json!(capsule_production_choices)))
        .execute(&db.0)?;

    for (gos_index, gos) in capsule_structure.into_iter().enumerate() {
        // GoS iteration
        let mut fake_records = vec![false; gos.slides.len()];
        let timestamps: Vec<(i32, Option<String>)>;

        let mut record = config.data_path.clone();
        let transcoded_record = match &gos.record_path {
            Some(blob) => {
                let path = workdir.join(format!("record{}_g{:03}.mp4", capsule.id, gos_index));
                record.push(blob);
                let blob_duration = command::transcode_blob(&record, &path)?;
                info!("blob transcoded : {:#?} ( {:#?}s)", path, blob_duration);

                Some((path, blob_duration))
            }
            _ => None,
        };
        //TODO for robustness : check gos.transitions  == gos.slides -1
        //if not raise inconsitenscy error
        // Slide timestamps (duration, offset) of each slides accorfing user transitions
        if let Some(_) = gos.record_path {
            if (gos.transitions.len() + 1) < gos.slides.len() {
                for index in (gos.transitions.len() + 1)..gos.slides.len() {
                    fake_records[index] = true;
                }
            } else if (gos.transitions.len() + 1) > gos.slides.len() {
                // Toom many trasnsition cannot edit video
                error!(" Too many transtion for this GOS. Cannot generate video");
                return Err(Error::TranscodeError);
            }
        }

        timestamps = {
            let mut input = Vec::new();
            input.push(0);
            input.extend(gos.transitions.iter().copied());
            let mut output = Vec::new();

            for (i, x) in input.iter().enumerate() {
                if i + 1 == input.len() {
                    output.push((*x, None));
                } else {
                    output.push((*x, Some(format!("{}ms", input[i + 1] - 1 - *x))));
                }
            }
            output
        };

        // Is Production choices defined for a Gos ?
        let production_choices = match gos.production_choices {
            Some(choices) => choices.to_edition_options().clone(),
            None => capsule_production_choices.clone(),
        };

        let GosStructure {
            slides,
            record_path,
            ..
        } = gos;

        for (slide_index, slide_id) in slides.into_iter().enumerate() {
            // Slide in GoS iteration
            let slide = SlideWithAsset::get_by_id(slide_id, &db)?;

            record = config.data_path.clone();
            match slide.extra {
                Some(asset) => {
                    info!(
                        " On Gos {}; in slide {} merging with extra data = {:#?}",
                        gos_index, slide_id, asset.asset_path
                    );
                    let mut extra_path = config.data_path.clone();
                    extra_path.push(asset.asset_path);

                    pip_file
                        .write(format!("file '{}'\n", extra_path.to_str().unwrap()).as_bytes())?;
                }
                None => {
                    let mut ffmpeg_command = Vec::new();

                    let mut slide_path = config.data_path.clone();
                    slide_path.push(slide.asset.asset_path);
                    let pip_out = workdir.join(format!(
                        "pip{}_g{:03}_s{:03}.mp4",
                        capsule.id, gos_index, slide_index
                    ));
                    let audio_file = workdir.join(format!(
                        "audio{}_g{:03}_s{:03}.wav",
                        capsule.id, gos_index, slide_index
                    ));

                    let filter_complex = format!(
                        "[0] scale=1920:1080 [slide] ;[1]scale={}:-1 [pip]; [slide][pip] overlay={}",
                        production_choices.size_in_pixels(),
                        production_choices.position_in_pixels(),
                    );
                    let str_duration;
                    let str_offset;
                    match (&transcoded_record, &gos.background_path) {
                        // matting case
                        (Some((record_path, _)), Some(background_path))
                            if config.matting_enabled =>
                        {
                            // TODO timstamps( offset and  duration) to be computed for
                            // matting case
                            let mut record_clone = record.clone();
                            record.push(record_path);
                            record_clone.push(background_path);

                            if production_choices.with_video {
                                run_ffmpeg_command = false;
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

                                // apply segmentation and matting on record frames
                                // path to script
                                let traiter_path = "../scripts/traiter.sh";
                                // path to background image
                                let back_ext: &str = "_back.png";
                                let background_path =
                                    format!("{}{}", record.to_str().unwrap(), back_ext);
                                // overlay position and scale
                                let pos_pixels_xy =
                                    format!("{}", production_choices.position_in_pixels());
                                let size_pixels =
                                    format!("{}", production_choices.size_in_pixels());
                                // command
                                let matting_command = vec![
                                    traiter_path,
                                    &record.to_str().unwrap(),
                                    &background_path,
                                    &slide_path.to_str().unwrap(),
                                    &pos_pixels_xy,
                                    &size_pixels,
                                    &pip_out.to_str().unwrap(),
                                ];
                                let matting_child = command::run_command(&matting_command)?;
                                if !matting_child.status.success() {
                                    return Err(Error::TranscodeError);
                                }
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

                        // video production with webcam records available
                        (Some((record_path, record_duration)), _) => {
                            if !fake_records[slide_index] {
                                str_offset = format!("{}ms", &timestamps[slide_index].0);
                                let offset = vec!["-ss", str_offset.as_str()];
                                str_duration = format!(
                                    "{}ms",
                                    ((record_duration * 1000.0) as i32)
                                        - &timestamps[slide_index].0
                                );
                                let duration: Vec<&str> = match &timestamps[slide_index].1 {
                                    Some(x) => vec!["-t", x],
                                    None => vec!["-t", str_duration.as_str()],
                                };
                                record.push(record_path);
                                //reencode input

                                if production_choices.with_video
                                    && command::has_images(record_path)?
                                {
                                    ffmpeg_command.extend(
                                        vec![
                                            "ffmpeg",
                                            "-hide_banner",
                                            "-fflags",
                                            "+genpts",
                                            "-y",
                                            "-i",
                                            &slide_path.to_str().unwrap(),
                                            "-i",
                                            &record.to_str().unwrap(),
                                        ]
                                        .into_iter(),
                                    );

                                    ffmpeg_command.extend_from_slice(&offset);
                                    ffmpeg_command.extend_from_slice(&duration);

                                    ffmpeg_command.extend(
                                        vec!["-filter_complex", &filter_complex].into_iter(),
                                    );
                                } else {
                                    //audio only
                                    command::extract_audio(&record, &audio_file)?;

                                    ffmpeg_command.extend(
                                        vec![
                                            "ffmpeg",
                                            "-hide_banner",
                                            "-y",
                                            "-fflags",
                                            "+genpts",
                                            "-loop",
                                            "1",
                                            "-i",
                                            &slide_path.to_str().unwrap(),
                                            "-i",
                                            &audio_file.to_str().unwrap(),
                                        ]
                                        .into_iter(),
                                    );
                                    ffmpeg_command.extend_from_slice(&offset);
                                    ffmpeg_command.extend_from_slice(&duration);
                                }
                            } else {
                                // generate slide only video due to missin records
                                ffmpeg_command.extend(
                                    vec![
                                        "ffmpeg",
                                        "-y",
                                        "-hide_banner",
                                        "-fflags",
                                        "+genpts",
                                        "-f",
                                        "lavfi",
                                        "-i",
                                        "anullsrc=channel_layout=stereo:sample_rate=48000",
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

                        // No record generate a video with slide only and an empty audio track.
                        (None, _) => {
                            ffmpeg_command.extend(
                                vec![
                                    "ffmpeg",
                                    "-y",
                                    "-hide_banner",
                                    "-fflags",
                                    "+genpts",
                                    "-f",
                                    "lavfi",
                                    "-i",
                                    "anullsrc=channel_layout=stereo:sample_rate=48000",
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
                            "-pix_fmt",
                            "yuv420p",
                            "-level",
                            "3.1",
                            "-ar",
                            "48000",
                            "-ab",
                            "128k",
                            "-vcodec",
                            "libx264",
                            "-crf",
                            "15",
                            "-acodec",
                            "aac",
                            "-s",
                            "hd1080",
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

                    pip_file
                        .write(format!("file '{}'\n", &pip_out.to_str().unwrap()).as_bytes())?;
                }
            }
            // join all videos
        } //end for loop slides
    }
    // concat all generated pip videos
    let file_name = format!("capsule{}.mp4", capsule.id);

    let mut server_path = PathBuf::from(&user.username);
    let uuid = Uuid::new_v4();
    server_path.push(format!("{}_{}", uuid, &file_name));

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
        "-movflags",
        "+faststart",
        output,
    ];

    let child = command::run_command(&command)?;

    if child.status.success() {
        let asset = Asset::new(
            &db,
            uuid,
            &file_name,
            server_path.to_str().unwrap(),
            Some("video"),
        )?;
        AssetsObject::new(&db, asset.id, capsule.id, AssetType::Capsule)?;

        // Add video_id to capsule
        use crate::schema::capsules::dsl;
        diesel::update(capsules::table)
            .filter(dsl::id.eq(capsule.id))
            .set((
                dsl::video_id.eq(asset.id),
                dsl::published.eq(TaskStatus::Idle),
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

    reset.ok();

    user.notify(
        socks.inner(),
        NotificationStyle::Info,
        "Production terminée !",
        &format!("La production de la capsule {} est terminée.", capsule.name),
        &db,
    )?;

    let capsule = user.get_capsule_by_id(id, &db)?;

    format_capsule_data(&db, &capsule)
}

#[allow(missing_docs)]
pub enum TaskType {
    /// Edition task.
    Edition,

    /// Publicartion task.
    Publication,

    /// Upload task
    Upload,
}
/// A struct that sets correctly the flag of a task status.
pub struct TaskStatusReset<'a> {
    /// The id of the capsule to reset
    pub capsule_id: i32,

    /// The value to which it should be reset
    pub value: TaskStatus,

    /// The database connection.
    pub db: &'a Database,

    /// Task type
    task_type: TaskType,
}

impl<'a> TaskStatusReset<'a> {
    /// Creates a new task status and sets the flag to running.
    fn new(db: &'a Database, capsule_id: i32, task_type: TaskType) -> Result<TaskStatusReset> {
        // Set the flag to running
        let reset = TaskStatusReset {
            capsule_id,
            // If the task status is dropped, the task failed and we want to set the flag back to
            // idle.
            value: TaskStatus::Idle,
            db,
            task_type,
        };

        reset.set(TaskStatus::Running)?;

        Ok(reset)
    }

    /// Creates a new edition task status reset, and sets the flag to running.
    pub fn edition(db: &'a Database, capsule_id: i32) -> Result<TaskStatusReset> {
        TaskStatusReset::new(db, capsule_id, TaskType::Edition)
    }

    /// Creates a new publication task status reset, and sets the flag to running.
    pub fn publication(db: &'a Database, capsule_id: i32) -> Result<TaskStatusReset> {
        TaskStatusReset::new(db, capsule_id, TaskType::Publication)
    }

    /// Creates a new upload task status reset, and sets the flag to running.
    pub fn upload(db: &'a Database, capsule_id: i32) -> Result<TaskStatusReset> {
        TaskStatusReset::new(db, capsule_id, TaskType::Upload)
    }

    /// Sets the flag.
    fn set(&self, value: TaskStatus) -> Result<()> {
        use crate::schema::capsules::dsl;
        match self.task_type {
            TaskType::Edition => diesel::update(capsules::table)
                .filter(dsl::id.eq(self.capsule_id))
                .set(dsl::edited.eq(value))
                .execute(&self.db.0)?,
            TaskType::Publication => diesel::update(capsules::table)
                .filter(dsl::id.eq(self.capsule_id))
                .set(dsl::published.eq(value))
                .execute(&self.db.0)?,
            TaskType::Upload => diesel::update(capsules::table)
                .filter(dsl::id.eq(self.capsule_id))
                .set(dsl::uploaded.eq(value))
                .execute(&self.db.0)?,
        };
        Ok(())
    }

    /// Sets the flag to done.
    pub fn ok(&mut self) {
        self.value = TaskStatus::Done;
    }
}

impl<'a> Drop for TaskStatusReset<'a> {
    fn drop(&mut self) {
        self.set(self.value).ok();
    }
}

/// The route to publish a video.
#[post("/capsule/<id>/publication")]
pub fn capsule_publication(
    config: State<Config>,
    db: Database,
    user: User,
    id: i32,
    socks: State<WebSockets>,
) -> Result<()> {
    let capsule = user.get_capsule_by_id(id, &db)?;

    match capsule.published {
        TaskStatus::Running => return Err(Error::NotFound),
        TaskStatus::Done => (),
        _ => (),
    }

    let mut reset = TaskStatusReset::publication(&db, capsule.id)?;

    let asset = Asset::get_by_id(capsule.video_id.ok_or(Error::NotFound)?, &db)?;
    let input_path = config.data_path.join(&asset.0.asset_path);
    let input_path = input_path.to_str().unwrap();
    let output_path = config.videos_path.join(asset.0.uuid.to_string());
    let output_path = output_path.to_str().unwrap();
    let command = vec![
        "../../hls/hls",
        input_path,
        output_path,
        "360p",
        "480p",
        "720p",
    ];

    let child = command::run_command(&command)?;

    if child.status.success() {
        reset.ok();
        user.notify(
            socks.inner(),
            NotificationStyle::Info,
            "Publication terminée !",
            &format!("La capsule {} est publiée.", capsule.name),
            &db,
        )?;
    } else {
        error!(
            "command {:?} failed:\nSTDOUT\n{}\n\nSTDERR\n{}",
            command,
            String::from_utf8(child.stdout).unwrap(),
            String::from_utf8(child.stderr).unwrap()
        );
    }

    Ok(())
}
