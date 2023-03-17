//! This module contains the routes to manage the capsules.

use std::path::Path;
use std::process::Stdio;
use std::sync::Arc;

use uuid::Uuid;

use serde::{Deserialize, Serialize};

use tokio::fs::{copy, create_dir_all, read_dir, remove_dir_all, remove_file};
use tokio::io::{AsyncBufReadExt, AsyncWriteExt, BufReader};
use tokio::process::Command;
use tokio::sync::Semaphore;

use ergol::tokio_postgres::types::Json as EJson;

use rocket::data::ToByteUnit;
use rocket::http::{ContentType, Status};
use rocket::serde::json::{json, Json, Value};
use rocket::{Data, State as S};

use crate::command::{export_slides, run_command};
use crate::config::Config;
use crate::db::capsule::{
    Capsule, Fade, Gos, Privacy, Record, Role, Slide, SoundTrack, WebcamSettings,
};
use crate::db::task_status::TaskStatus;
use crate::db::user::{Plan, User};
use crate::websockets::WebSockets;
use crate::{Db, Error, HashId, Result};

/// The route that gives the capsule information.
#[get("/capsule/<capsule_id>")]
pub async fn get_capsule(user: User, capsule_id: HashId, db: Db) -> Result<Value> {
    let (capsule, role) = user
        .get_capsule_with_permission(*capsule_id, Role::Read, &db)
        .await?;

    capsule.to_json(role, &db).await
}

/// The route that creates an empty capsule.
#[post("/empty-capsule/<project_name>/<capsule_name>")]
pub async fn empty_capsule(
    user: User,
    project_name: String,
    capsule_name: String,
    config: &S<Config>,
    db: Db,
) -> Result<Value> {
    let capsule = Capsule::new(project_name, capsule_name, &user, &db).await?;

    let path = config
        .data_path
        .join(format!("{}", capsule.id))
        .join("assets");

    create_dir_all(&path).await?;

    Ok(capsule.to_json(Role::Owner, &db).await?)
}

/// The route that creates a capsule from PDF slides.
#[post("/new-capsule/<project_name>/<capsule_name>", data = "<data>")]
pub async fn new_capsule(
    user: User,
    project_name: String,
    capsule_name: String,
    db: Db,
    config: &S<Config>,
    data: Data<'_>,
) -> Result<Value> {
    let mut capsule = Capsule::new(project_name, &capsule_name, &user, &db).await?;

    let path = config
        .data_path
        .join(format!("{}", capsule.id))
        .join("assets");

    create_dir_all(&path).await?;

    let tmp = path.join(format!("{}.pdf", Uuid::new_v4()));

    data.open(1_i32.gibibytes()).into_file(&tmp).await?;

    let gos = export_slides(&config, tmp, path, None)?
        .into_iter()
        .map(|x| Gos {
            record: None,
            slides: vec![Slide {
                uuid: x,
                extra: None,
                prompt: String::new(),
            }],
            events: vec![],
            webcam_settings: None,
            fade: Fade::none(),
        })
        .collect::<Vec<_>>();

    capsule.structure = EJson(gos);
    capsule.set_changed();
    capsule.save(&db).await?;

    Ok(capsule.to_json(Role::Owner, &db).await?)
}

/// The json format to edit the content of a capsule.
#[derive(Serialize, Deserialize)]
pub struct CapsuleEdit {
    /// The id of the capsule to edit.
    pub id: HashId,

    /// The new name of the project.
    pub project: String,

    /// The new name of the capsule.
    pub name: String,

    /// The privacy of the capsule.
    pub privacy: Privacy,

    /// Whether the subtitles should be generated from the prompt.
    pub prompt_subtitles: bool,

    /// The new structure of the capsule.
    pub structure: Vec<Gos>,

    /// The new webcam settings.
    pub webcam_settings: WebcamSettings,

    /// The new soundtrack.
    pub sound_track: Option<SoundTrack>,
}

/// The route that updates a capsule structure.
#[post("/update-capsule", data = "<data>")]
pub async fn edit_capsule(
    user: User,
    db: Db,
    data: Json<CapsuleEdit>,
    socks: &S<WebSockets>,
) -> Result<()> {
    let CapsuleEdit {
        id,
        project,
        name,
        structure,
        webcam_settings,
        sound_track,
        privacy,
        prompt_subtitles,
    } = data.0;

    let (mut capsule, _) = user
        .get_capsule_with_permission(*id, Role::Write, &db)
        .await?;

    capsule.project = project;
    capsule.name = name;
    capsule.privacy = privacy;
    capsule.prompt_subtitles = prompt_subtitles;
    capsule.structure = EJson(structure);
    capsule.webcam_settings = EJson(webcam_settings);
    capsule.sound_track = EJson(sound_track);
    capsule.set_changed();
    capsule.save(&db).await?;

    capsule.notify_change(&db, &socks).await?;

    Ok(())
}

/// The route that deletes a capsule by id.
#[delete("/capsule/<id>")]
pub async fn delete_capsule(user: User, db: Db, id: HashId, config: &S<Config>) -> Result<()> {
    let (capsule, _) = user
        .get_capsule_with_permission(*id, Role::Owner, &db)
        .await?;

    capsule.delete(&db).await?;
    let dir = config.data_path.join(format!("{}", *id));
    remove_dir_all(dir).await?;
    Ok(())
}

/// The route that deletes a whole project.
#[delete("/project/<name>")]
pub async fn delete_project(user: User, db: Db, config: &S<Config>, name: String) -> Result<()> {
    let capsules = user.capsules(&db).await?;

    for (capsule, role) in capsules {
        if role != Role::Owner {
            leave_aux(&user, HashId(capsule.id), &db).await?;
        }

        if capsule.project != name {
            continue;
        }

        // Delete the capsule
        let dir = config.data_path.join(format!("{}", capsule.id));
        remove_dir_all(dir).await?;
        capsule.delete(&db).await?;
    }

    Ok(())
}

/// The route that uploads a record to a capsule for a specific gos.
#[post("/upload-record/<id>/<gos>", data = "<data>")]
pub async fn upload_record(
    user: User,
    db: Db,
    config: &S<Config>,
    id: HashId,
    gos: i32,
    data: Data<'_>,
) -> Result<Value> {
    // Check that the user has write access to the capsule.
    let (mut capsule, role) = user
        .get_capsule_with_permission(*id, Role::Write, &db)
        .await?;

    let gos = capsule
        .structure
        .0
        .get_mut(gos as usize)
        .ok_or(Error(Status::BadRequest))?;

    let uuid = Uuid::new_v4();
    let output = config
        .data_path
        .join(format!("{}", *id))
        .join("assets")
        .join(format!("{}.webm", uuid));

    data.open(1_i32.gibibytes()).into_file(output).await?;

    let res = run_command(&vec![
        "../scripts/psh",
        "on-record",
        &format!("{}", capsule.id),
        &format!("{}", uuid),
    ])?;

    let size = if let Some([Ok(width), Ok(height)]) = std::str::from_utf8(&res.stdout)?
        .trim()
        .split("x")
        .map(|x| x.parse::<u32>())
        .collect::<Vec<_>>()
        .get(0..2)
    {
        Some((*width, *height))
    } else {
        None
    };

    gos.record = Some(Record {
        uuid,
        size,
        pointer_uuid: None,
    });

    if size.is_none() {
        gos.webcam_settings = Some(WebcamSettings::Disabled);
    }
    capsule.set_changed();
    capsule.save(&db).await?;

    Ok(capsule.to_json(role, &db).await?)
}

/// The route that deletes a record from a capsule for a specific gos.
#[delete("/delete-record/<id>/<gos>")]
pub async fn delete_record(user: User, db: Db, id: HashId, gos: i32) -> Result<Value> {
    // Check that the user has write access to the capsule.
    let (mut capsule, role) = user
        .get_capsule_with_permission(*id, Role::Write, &db)
        .await?;

    let gos = capsule
        .structure
        .0
        .get_mut(gos as usize)
        .ok_or(Error(Status::BadRequest))?;

    gos.record = None;
    capsule.set_changed();
    capsule.save(&db).await?;

    Ok(capsule.to_json(role, &db).await?)
}

/// The route that uploads a pointer to a capsule for a specific gos.
#[post("/upload-pointer/<id>/<gos>", data = "<data>")]
pub async fn upload_pointer(
    user: User,
    db: Db,
    config: &S<Config>,
    id: HashId,
    gos: i32,
    data: Data<'_>,
) -> Result<Value> {
    // Check that the user has write access to the capsule.
    let (mut capsule, role) = user
        .get_capsule_with_permission(*id, Role::Write, &db)
        .await?;

    let gos = capsule
        .structure
        .0
        .get_mut(gos as usize)
        .ok_or(Error(Status::BadRequest))?;

    if gos.record.is_none() {
        return Err(Error(Status::BadRequest));
    }

    let pointer_uuid = Uuid::new_v4();
    let output = config
        .data_path
        .join(format!("{}", *id))
        .join("assets")
        .join(format!("{}.webm", pointer_uuid));

    data.open(1_i32.gibibytes()).into_file(output).await?;

    gos.record.as_mut().unwrap().pointer_uuid = Some(pointer_uuid);

    capsule.set_changed();
    capsule.save(&db).await?;

    Ok(capsule.to_json(role, &db).await?)
}

/// The route that replaces a slide with another slide or an extra resource.
#[post("/replace-slide/<id>/<old_uuid>/<page>", data = "<data>")]
pub async fn replace_slide(
    user: User,
    db: Db,
    config: &S<Config>,
    id: HashId,
    old_uuid: String,
    page: i32,
    data: Data<'_>,
    content_type: &ContentType,
    socks: &S<WebSockets>,
    sem: &S<Arc<Semaphore>>,
) -> Result<Value> {
    let (mut capsule, role) = user
        .get_capsule_with_permission(*id, Role::Write, &db)
        .await?;

    // Find the slide to update
    let mut slide_found = None;
    for gos in &mut capsule.structure.0 {
        for slide in &mut gos.slides {
            if format!("{}", slide.uuid) == old_uuid {
                slide_found = Some(slide);
            }
        }
    }

    let slide_found = slide_found.ok_or(Error(Status::BadRequest))?;

    let path = config
        .data_path
        .join(format!("{}", capsule.id))
        .join("assets")
        .join(format!("{}", Uuid::new_v4()));

    data.open(1_i32.gibibytes()).into_file(&path).await?;

    let path = path
        .to_str()
        .ok_or(Error(Status::InternalServerError))?
        .to_string();

    let output_uuid = Uuid::new_v4();
    let output = config
        .data_path
        .join(format!("{}", *id))
        .join("assets")
        .join(format!("{}", output_uuid));

    let output = output
        .to_str()
        .ok_or(Error(Status::InternalServerError))?
        .to_string();

    if content_type.media_type().top() != "video" {
        slide_found.uuid = output_uuid;
    }

    let res = if content_type.media_type().top() == "image" {
        // Not very clean but working
        run_command(&vec![
            "../scripts/psh",
            "pdf-to-png",
            &path,
            &format!("{}.png", output),
            &config.pdf_target_density,
            &config.pdf_target_size,
        ])?;

        capsule.set_changed();
        capsule.save(&db).await?;
        capsule.to_json(role, &db).await?
    } else if *content_type == ContentType::PDF {
        // Not very clean either, but should work too
        run_command(&vec![
            "../scripts/psh",
            "pdf-to-png",
            &format!("{}[{}]", path, page),
            &format!("{}.png", output),
            &config.pdf_target_density,
            &config.pdf_target_size,
        ])?;

        capsule.set_changed();
        capsule.save(&db).await?;
        capsule.to_json(role, &db).await?
    } else if content_type.media_type().top() == "video" {
        capsule.set_changed();
        capsule.save(&db).await?;
        let res = capsule.to_json(role, &db).await?;

        let socks = socks.inner().clone();
        let sem = sem.inner().clone();

        tokio::spawn(async move {
            let child = Command::new("../scripts/psh")
                .arg("on-video-upload")
                .arg(&path)
                .arg(&format!("{}.mp4", output))
                .stdin(Stdio::piped())
                .stdout(Stdio::piped())
                .spawn();

            let succeed = if let Ok(mut child) = child {
                capsule.video_uploaded = TaskStatus::Running;
                capsule.video_uploaded_pid = child.id().map(|x| x as i32);
                capsule.save(&db).await.ok();

                if let Some(stdin) = child.stdin.as_mut() {
                    stdin
                        .write_all(json!(capsule.structure.0).to_string().as_bytes())
                        .await
                        .unwrap();

                    if let Ok(_) = sem.acquire().await {
                        let stdout = child.stdout.take().unwrap();
                        let reader = BufReader::new(stdout);

                        let mut lines = reader.lines();
                        while let Some(line) = lines.next_line().await.unwrap() {
                            capsule
                                .notify_video_upload_progress(
                                    &old_uuid,
                                    &id.hash(),
                                    &format!("{}", line),
                                    &db,
                                    &socks,
                                )
                                .await
                                .ok();
                        }

                        if let Ok(res) = child.wait().await {
                            res.success()
                        } else {
                            false
                        }
                    } else {
                        false
                    }
                } else {
                    false
                }
            } else {
                false
            };

            let mut capsule = match user
                .get_capsule_with_permission(*id, Role::Write, &db)
                .await
            {
                Ok((capsule, _)) => capsule,
                _ => return (),
            };

            capsule.video_uploaded = if succeed {
                TaskStatus::Done
            } else {
                TaskStatus::Idle
            };
            capsule.video_uploaded_pid = None;

            // Find the slide to update
            let mut slide_found = None;
            for gos in &mut capsule.structure.0 {
                for slide in &mut gos.slides {
                    if format!("{}", slide.uuid) == old_uuid {
                        slide_found = Some(slide);
                    }
                }
            }

            let slide_found = slide_found.unwrap();

            if !succeed {
                slide_found.extra = None;
            } else {
                slide_found.extra = Some(output_uuid);
            }

            capsule.set_changed();
            capsule.save(&db).await.ok();
            capsule.notify_change(&db, &socks).await.ok();

            capsule
                .notify_video_upload(&old_uuid, &id.hash(), &db, &socks)
                .await
                .ok();

            if succeed {
                user.notify(
                    &socks,
                    "Production terminée",
                    &format!(
                        "La vidéo\"{}\" a été correctement transférér sur le serveur.",
                        capsule.name
                    ),
                    &db,
                )
                .await
                .ok();
            } else {
                user.notify(
                    &socks,
                    "Production terminée",
                    &format!("La production de la capsule \"{}\" a échoué.", capsule.name),
                    &db,
                )
                .await
                .ok();
            };
        });

        res
    } else {
        return Err(Error(Status::UnsupportedMediaType));
    };

    Ok(res)
}

/// Route to add a slide to a specific gos of a capsule.
#[post("/add-slide/<id>/<gos>/<page>", data = "<data>")]
pub async fn add_slide(
    user: User,
    id: HashId,
    gos: i32,
    page: i32,
    db: Db,
    data: Data<'_>,
    config: &S<Config>,
    content_type: &ContentType,
) -> Result<Value> {
    let (mut capsule, role) = user
        .get_capsule_with_permission(*id, Role::Write, &db)
        .await?;

    let gos = if gos >= 0 {
        capsule
            .structure
            .0
            .get_mut(gos as usize)
            .ok_or(Error(Status::BadRequest))?
    } else {
        capsule.structure.0.push(Gos::new());
        capsule
            .structure
            .0
            .last_mut()
            .ok_or(Error(Status::InternalServerError))?
    };

    let path = config
        .data_path
        .join(format!("{}", capsule.id))
        .join("assets")
        .join(format!("{}", Uuid::new_v4()));

    data.open(1_i32.gibibytes()).into_file(&path).await?;

    let path = path.to_str().ok_or(Error(Status::InternalServerError))?;

    let output_uuid = Uuid::new_v4();
    let output = config
        .data_path
        .join(format!("{}", *id))
        .join("assets")
        .join(format!("{}", output_uuid));

    let output = output.to_str().ok_or(Error(Status::InternalServerError))?;

    let _extra = if content_type.media_type().top() == "image" {
        // Not very clean but working

        run_command(&vec![
            "../scripts/psh",
            "pdf-to-png",
            &path,
            &format!("{}.png", output),
            &config.pdf_target_density,
            &config.pdf_target_size,
        ])?;

        false
    } else if *content_type == ContentType::PDF {
        // Not very clean either, but should work too

        run_command(&vec![
            "../scripts/psh",
            "pdf-to-png",
            &format!("{}[{}]", path, page),
            &format!("{}.png", output),
            &config.pdf_target_density,
            &config.pdf_target_size,
        ])?;

        false
    } else if content_type.media_type().top() == "video" {
        return Err(Error(Status::UnsupportedMediaType));

        // run_command_with_output(&vec![
        //     "../scripts/psh",
        //     "on-video-upload",
        //     &path,
        //     &format!("{}.mp4", output),
        // ])?;

        // true
    } else {
        return Err(Error(Status::UnsupportedMediaType));
    };

    gos.slides.push(Slide {
        uuid: output_uuid,
        extra: None,
        prompt: String::new(),
    });

    capsule.set_changed();
    capsule.save(&db).await?;

    Ok(capsule.to_json(role, &db).await?)
}

/// Route to create a gos at a specific place in the capsule.
#[post("/add-gos/<id>/<gos>/<page>", data = "<data>")]
pub async fn add_gos(
    user: User,
    id: HashId,
    gos: i32,
    page: i32,
    db: Db,
    data: Data<'_>,
    config: &S<Config>,
    content_type: &ContentType,
) -> Result<Value> {
    let (mut capsule, role) = user
        .get_capsule_with_permission(*id, Role::Write, &db)
        .await?;

    if gos < 0 || gos as usize > capsule.structure.0.len() {
        return Err(Error(Status::BadRequest));
    }

    capsule.structure.0.insert(gos as usize, Gos::new());
    let gos = capsule
        .structure
        .0
        .get_mut(gos as usize)
        .ok_or(Error(Status::BadRequest))?;

    let path = config
        .data_path
        .join(format!("{}", capsule.id))
        .join("assets")
        .join(format!("{}", Uuid::new_v4()));

    data.open(1_i32.gibibytes()).into_file(&path).await?;

    let path = path.to_str().ok_or(Error(Status::InternalServerError))?;

    let output_uuid = Uuid::new_v4();
    let output = config
        .data_path
        .join(format!("{}", *id))
        .join("assets")
        .join(format!("{}", output_uuid));

    let output = output.to_str().ok_or(Error(Status::InternalServerError))?;

    let _extra = if content_type.media_type().top() == "image" {
        // Not very clean but working

        run_command(&vec![
            "../scripts/psh",
            "pdf-to-png",
            &path,
            &format!("{}.png", output),
            &config.pdf_target_density,
            &config.pdf_target_size,
        ])?;

        false
    } else if *content_type == ContentType::PDF {
        // Not very clean either, but should work too

        run_command(&vec![
            "../scripts/psh",
            "pdf-to-png",
            &format!("{}[{}]", path, page),
            &format!("{}.png", output),
            &config.pdf_target_density,
            &config.pdf_target_size,
        ])?;

        false
    } else if content_type.media_type().top() == "video" {
        return Err(Error(Status::UnsupportedMediaType));

        // run_command_with_output(&vec![
        //     "../scripts/psh",
        //     "on-video-upload",
        //     &path,
        //     &format!("{}.mp4", output),
        // ])?;

        // true
    } else {
        return Err(Error(Status::UnsupportedMediaType));
    };

    gos.slides.push(Slide {
        uuid: output_uuid,
        extra: None,
        prompt: String::new(),
    });

    capsule.set_changed();
    capsule.save(&db).await?;

    Ok(capsule.to_json(role, &db).await?)
}

/// The route that triggers the production of a capsule.
#[post("/produce/<id>")]
pub async fn produce(
    user: User,
    id: HashId,
    socks: &S<WebSockets>,
    sem: &S<Arc<Semaphore>>,
    config: &S<Config>,
    db: Db,
) -> Result<()> {
    let (mut capsule, _) = user
        .get_capsule_with_permission(*id, Role::Write, &db)
        .await?;

    if capsule.produced == TaskStatus::Running {
        return Err(Error(Status::Conflict));
    }

    let socks = socks.inner().clone();
    let sem = sem.inner().clone();

    let output_path = config.data_path.join(format!("{}", *id)).join("output.mp4");

    tokio::spawn(async move {
        let sound_track_info = if let Some(sound_track) = &capsule.sound_track.0 {
            format!("{}:{}", sound_track.uuid, sound_track.volume)
        } else {
            "null".to_string()
        };
        let child = Command::new("../scripts/psh")
            .arg("on-produce")
            .arg(format!("{}", capsule.id))
            .arg("-1")
            .arg(sound_track_info)
            .stdin(Stdio::piped())
            .stdout(Stdio::piped())
            .spawn();

        let succeed = if let Ok(mut child) = child {
            capsule.produced = TaskStatus::Running;
            capsule.published = TaskStatus::Idle;
            capsule.production_pid = child.id().map(|x| x as i32);
            capsule.save(&db).await.ok();

            if let Some(stdin) = child.stdin.as_mut() {
                // replace null webcamsteeings with default webcam settings
                for gos in &mut capsule.structure.0 {
                    if gos.webcam_settings.is_none() {
                        gos.webcam_settings = Some(capsule.webcam_settings.0.clone());
                    }
                }
                stdin
                    .write_all(json!(capsule.structure.0).to_string().as_bytes())
                    .await
                    .unwrap();

                if let Ok(_) = sem.acquire().await {
                    child.stdin.unwrap();
                    let stdout = child.stdout.take().unwrap();
                    let reader = BufReader::new(stdout);

                    let mut lines = reader.lines();
                    while let Some(line) = lines.next_line().await.unwrap() {
                        capsule
                            .notify_production_progress(
                                &id.hash(),
                                &format!("{}", line),
                                &db,
                                &socks,
                            )
                            .await
                            .ok();
                    }
                    true
                } else {
                    false
                }
            } else {
                false
            }
        } else {
            false
        };

        capsule.produced = if succeed {
            TaskStatus::Done
        } else {
            TaskStatus::Idle
        };

        let output = run_command(&vec![
            "../scripts/psh",
            "duration",
            output_path.to_str().unwrap(),
        ]);

        match &output {
            Ok(o) => {
                let line = ((std::str::from_utf8(&o.stdout)
                    .map_err(|_| Error(Status::InternalServerError))
                    .unwrap()
                    .trim()
                    .parse::<f32>()
                    .unwrap())
                    * 1000.) as i32;

                capsule.duration_ms = line;
                capsule.save(&db).await.ok();
            }
            Err(_) => error!("Impossible to get duration"),
        };

        capsule.production_pid = None;
        capsule.save(&db).await.ok();

        if succeed {
            capsule
                .notify_production(&id.hash(), &db, &socks)
                .await
                .ok();

            user.notify(
                &socks,
                "Production terminée",
                &format!(
                    "La capsule \"{}\" a été correctement produite.",
                    capsule.name
                ),
                &db,
            )
            .await
            .ok();
        } else {
            user.notify(
                &socks,
                "Production terminée",
                &format!("La production de la capsule \"{}\" a échoué.", capsule.name),
                &db,
            )
            .await
            .ok();
        };
    });

    Ok(())
}

/// The route that triggers the production of one gos.
#[post("/produce-gos/<id>/<gos>")]
pub async fn produce_gos(
    user: User,
    id: HashId,
    gos: i32,
    socks: &S<WebSockets>,
    sem: &S<Arc<Semaphore>>,
    db: Db,
) -> Result<()> {
    let (mut capsule, _) = user
        .get_capsule_with_permission(*id, Role::Write, &db)
        .await?;

    if capsule.produced == TaskStatus::Running {
        return Err(Error(Status::Conflict));
    }

    let socks = socks.inner().clone();
    let sem = sem.inner().clone();

    tokio::spawn(async move {
        let child = Command::new("../scripts/psh")
            .arg("on-produce")
            .arg(format!("{}", capsule.id))
            .arg(format!("{}", gos))
            .stdin(Stdio::piped())
            .stdout(Stdio::piped())
            .spawn();

        let succeed = if let Ok(mut child) = child {
            capsule.produced = TaskStatus::Running;
            capsule.published = TaskStatus::Idle;
            capsule.production_pid = child.id().map(|x| x as i32);
            capsule.save(&db).await.ok();

            if let Some(stdin) = child.stdin.as_mut() {
                stdin
                    .write_all(json!(capsule.structure.0).to_string().as_bytes())
                    .await
                    .unwrap();

                if let Ok(_) = sem.acquire().await {
                    child.stdin.unwrap();
                    let stdout = child.stdout.take().unwrap();
                    let reader = BufReader::new(stdout);

                    let mut lines = reader.lines();
                    while let Some(line) = lines.next_line().await.unwrap() {
                        capsule
                            .notify_production_progress(
                                &id.hash(),
                                &format!("{}", line),
                                &db,
                                &socks,
                            )
                            .await
                            .ok();
                    }
                    true
                } else {
                    false
                }
            } else {
                false
            }
        } else {
            false
        };

        capsule.produced = if succeed {
            TaskStatus::Done
        } else {
            TaskStatus::Idle
        };

        capsule.production_pid = None;
        capsule.save(&db).await.ok();

        if succeed {
            capsule
                .notify_production(&id.hash(), &db, &socks)
                .await
                .ok();

            user.notify(
                &socks,
                "Production terminée",
                &format!(
                    "La capsule \"{}\" a été correctement produite.",
                    capsule.name
                ),
                &db,
            )
            .await
            .ok();
        } else {
            user.notify(
                &socks,
                "Production terminée",
                &format!("La production de la capsule \"{}\" a échoué.", capsule.name),
                &db,
            )
            .await
            .ok();
        };
    });

    Ok(())
}
/// The route that cancels the production of a capsule.
#[post("/cancel-production/<id>")]
pub async fn cancel_production(user: User, id: HashId, db: Db) -> Result<()> {
    let (capsule, _) = user
        .get_capsule_with_permission(*id, Role::Write, &db)
        .await?;

    if capsule.produced != TaskStatus::Running {
        return Err(Error(Status::Conflict));
    }

    let pid = if let Some(pid) = capsule.production_pid {
        pid
    } else {
        return Err(Error(Status::Conflict));
    };

    Command::new("kill")
        .arg(format!("{}", pid))
        .output()
        .await
        .map_err(|_| Error(Status::InternalServerError))?;

    Ok(())
}

/// The route that publishes a capsule.
#[post("/publish/<id>")]
pub async fn publish(
    user: User,
    id: HashId,
    config: &S<Config>,
    db: Db,
    socks: &S<WebSockets>,
    sem: &S<Arc<Semaphore>>,
) -> Result<()> {
    let (mut capsule, _) = user
        .get_capsule_with_permission(*id, Role::Write, &db)
        .await?;

    if capsule.produced != TaskStatus::Done || capsule.published != TaskStatus::Idle {
        return Err(Error(Status::Conflict));
    }

    let input = config.data_path.join(format!("{}", *id)).join("output.mp4");
    let output = config.data_path.join(format!("{}", *id)).join("output");

    let socks = socks.inner().clone();
    let sem = sem.inner().clone();

    tokio::spawn(async move {
        remove_dir_all(&output).await.ok();

        let child = Command::new("../scripts/psh")
            .arg("on-publish")
            .arg(input)
            .arg(output)
            .arg(format!("{}", capsule.prompt_subtitles))
            .stdin(Stdio::piped())
            .spawn();

        let succeed = if let Ok(mut child) = child {
            if let Some(stdin) = child.stdin.as_mut() {
                stdin
                    .write_all(json!(capsule.structure.0).to_string().as_bytes())
                    .await
                    .unwrap();

                capsule.published = TaskStatus::Running;
                capsule.publication_pid = child.id().map(|x| x as i32);
                capsule.save(&db).await.ok();

                if let Ok(_) = sem.acquire().await {
                    let res = child.wait().await;
                    res.map(|x| x.success()).unwrap_or_else(|_| false)
                } else {
                    false
                }
            } else {
                false
            }
        } else {
            false
        };

        capsule.published = if succeed {
            TaskStatus::Done
        } else {
            TaskStatus::Idle
        };

        capsule.publication_pid = None;
        capsule.save(&db).await.ok();

        if succeed {
            capsule
                .notify_publication(&id.hash(), &db, &socks)
                .await
                .ok();

            user.notify(
                &socks,
                "Publication terminée",
                &format!(
                    "La capsule \"{}\" a été correctement publiée.",
                    capsule.name
                ),
                &db,
            )
            .await
            .ok();
        } else {
            user.notify(
                &socks,
                "Publication échouée",
                &format!(
                    "La publication de la capsule \"{}\" a échoué.",
                    capsule.name
                ),
                &db,
            )
            .await
            .ok();
        }
    });

    Ok(())
}

/// The route that cancels the publication of a capsule.
#[post("/cancel-publication/<id>")]
pub async fn cancel_publication(user: User, id: HashId, db: Db) -> Result<()> {
    let (capsule, _) = user
        .get_capsule_with_permission(*id, Role::Write, &db)
        .await?;

    if capsule.published != TaskStatus::Running {
        return Err(Error(Status::Conflict));
    }

    let pid = if let Some(pid) = capsule.publication_pid {
        pid
    } else {
        return Err(Error(Status::Conflict));
    };

    Command::new("kill")
        .arg(format!("{}", pid))
        .output()
        .await
        .map_err(|_| Error(Status::InternalServerError))?;

    Ok(())
}

/// The route that unpublishes a capsule.
#[post("/unpublish/<id>")]
pub async fn unpublish(user: User, id: HashId, db: Db, config: &S<Config>) -> Result<()> {
    let (mut capsule, _) = user
        .get_capsule_with_permission(*id, Role::Write, &db)
        .await?;

    if capsule.published != TaskStatus::Done {
        return Err(Error(Status::BadRequest));
    }

    capsule.published = TaskStatus::Idle;
    capsule.save(&db).await?;

    let output = config.data_path.join(format!("{}", *id)).join("output");
    remove_dir_all(output).await?;

    Ok(())
}

/// The route that cancels the production of a capsule.
#[post("/cancel-video-upload/<id>")]
pub async fn cancel_video_upload(user: User, id: HashId, db: Db) -> Result<()> {
    let (capsule, _) = user
        .get_capsule_with_permission(*id, Role::Write, &db)
        .await?;

    if capsule.video_uploaded != TaskStatus::Running {
        return Err(Error(Status::Conflict));
    }

    let pid = if let Some(pid) = capsule.video_uploaded_pid {
        pid
    } else {
        return Err(Error(Status::Conflict));
    };

    Command::new("kill")
        .arg(format!("{}", pid))
        .output()
        .await
        .map_err(|_| Error(Status::InternalServerError))?;

    Ok(())
}

/// Duplicates a capsule.
#[post("/duplicate/<id>")]
pub async fn duplicate(user: User, id: HashId, config: &S<Config>, db: Db) -> Result<Value> {
    let (capsule, _) = user
        .get_capsule_with_permission(*id, Role::Read, &db)
        .await?;

    let mut new = Capsule::new(
        capsule.project,
        format!("{} (copie)", capsule.name),
        &user,
        &db,
    )
    .await?;
    new.privacy = capsule.privacy;
    new.produced = capsule.produced;
    new.structure = capsule.structure;
    new.webcam_settings = capsule.webcam_settings;
    new.sound_track = capsule.sound_track;
    new.duration_ms = capsule.duration_ms;

    for dir in ["assets", "tmp", "output"] {
        let orig = config.data_path.join(&format!("{}/{}", capsule.id, dir));
        let dest = config.data_path.join(&format!("{}/{}", new.id, dir));

        if orig.is_dir() {
            create_dir_all(&dest).await?;

            let mut iter = read_dir(&orig)
                .await
                .map_err(|_| Error(Status::InternalServerError))?;

            loop {
                let next = iter
                    .next_entry()
                    .await
                    .map_err(|_| Error(Status::InternalServerError))?;

                let next = match next {
                    Some(x) => x,
                    None => break,
                };

                let path = next.path();
                let file_name = path.file_name().ok_or(Error(Status::InternalServerError))?;

                copy(orig.join(&file_name), dest.join(&file_name))
                    .await
                    .map_err(|_| Error(Status::InternalServerError))?;
            }
        }
    }

    let orig = config.data_path.join(&format!("{}/output.mp4", capsule.id));
    let dest = config.data_path.join(&format!("{}/output.mp4", new.id));

    if orig.is_file() {
        copy(orig, dest)
            .await
            .map_err(|_| Error(Status::InternalServerError))?;
    }

    new.set_changed();
    new.save(&db).await?;

    Ok(new.to_json(Role::Owner, &db).await?)
}

/// The invitation data.
#[derive(Serialize, Deserialize)]
pub struct Invite {
    /// The username or email of the invited user.
    username: String,

    /// The role to which the user would be given.
    role: Role,
}

/// The route that invites a user to access a capsule.
#[post("/invite/<id>", data = "<data>")]
pub async fn invite(user: User, id: HashId, db: Db, data: Json<Invite>) -> Result<()> {
    // user must be the owner of the capsule.
    let (capsule, _) = user
        .get_capsule_with_permission(*id, Role::Owner, &db)
        .await?;

    let Invite { username, role } = data.0;
    let invited = User::get_by_username_or_email(&username, &db)
        .await?
        .ok_or(Error(Status::BadRequest))?;

    // invited must not already be invited
    if invited
        .get_capsule_with_permission(*id, Role::Read, &db)
        .await
        .is_ok()
    {
        return Err(Error(Status::BadRequest));
    }

    capsule.add_user(&invited, role, &db).await?;

    Ok(())
}

/// The route that changes the role of a user to access a capsule.
#[post("/change-role/<id>", data = "<data>")]
pub async fn change_role(user: User, id: HashId, db: Db, data: Json<Invite>) -> Result<()> {
    // user must be the owner of the capsule.
    let (capsule, _) = user
        .get_capsule_with_permission(*id, Role::Owner, &db)
        .await?;

    let Invite { username, role } = data.0;
    let invited = User::get_by_username_or_email(&username, &db)
        .await?
        .ok_or(Error(Status::BadRequest))?;

    capsule.update_role(&invited, role, &db).await?;

    Ok(())
}

/// The data for remove a user.
#[derive(Serialize, Deserialize)]
pub struct Deinvite {
    /// The username or email of user to deinvite.
    username: String,
}

/// Removes user from a capsule.
#[post("/deinvite/<id>", data = "<data>")]
pub async fn deinvite(user: User, id: HashId, db: Db, data: Json<Deinvite>) -> Result<()> {
    let (capsule, _) = user
        .get_capsule_with_permission(*id, Role::Owner, &db)
        .await?;

    let Deinvite { username } = data.0;
    let deinvited = User::get_by_username_or_email(&username, &db)
        .await?
        .ok_or(Error(Status::BadRequest))?;

    // This is a little bit overkill but hey, I've not found better for now...
    let (_, role) = deinvited
        .get_capsule_with_permission(*id, Role::Read, &db)
        .await?;

    if role == Role::Owner {
        return Err(Error(Status::BadRequest));
    }

    capsule.remove_user(&deinvited, &db).await?;

    Ok(())
}

/// Leaves a user from a capsule.
pub async fn leave_aux(user: &User, id: HashId, db: &Db) -> Result<()> {
    let (capsule, role) = user
        .get_capsule_with_permission(*id, Role::Read, &db)
        .await?;

    if role == Role::Owner && user.plan != Plan::Admin {
        return Err(Error(Status::BadRequest));
    }

    capsule.remove_user(&user, &db).await?;

    Ok(())
}

/// Routes to leave a user from a capsule.
#[post("/leave/<id>")]
pub async fn leave(user: User, id: HashId, db: Db) -> Result<()> {
    leave_aux(&user, id, &db).await
}

/// Update the capsule's track.
#[post("/sound-track/<id>/<name>", data = "<data>")]
pub async fn sound_track(
    user: User,
    id: HashId,
    name: String,
    db: Db,
    data: Data<'_>,
    config: &S<Config>,
) -> Result<Value> {
    // User must have write access to the capsule.
    let (mut capsule, role) = user
        .get_capsule_with_permission(*id, Role::Write, &db)
        .await?;

    // Get base path.
    let uuid = Uuid::new_v4();
    let path = config.data_path.join(format!("{}", *id)).join("assets");

    // Delete old track if any.
    let mut volume = 0.8;
    let old_track = capsule.sound_track;
    if let Some(old_track) = old_track.0 {
        let old_uuid = old_track.uuid;
        volume = old_track.volume;
        let old_path = path.join(format!("{}", old_uuid)).with_extension("m4a");
        remove_file(&old_path).await.ok();
    }

    // Create paths.
    let path = path.join(format!("{}", uuid));
    let tmp_path = path.with_extension("tmp.mp3");
    let m4a_path = path.with_extension("m4a");

    // Save the file.
    data.open(1_i32.gibibytes())
        .into_file(Path::new(&tmp_path))
        .await?;

    // Convert file to expected format.
    let _res = run_command(&vec![
        "../scripts/psh",
        "transcode-audio",
        &tmp_path
            .to_str()
            .ok_or(Error(Status::InternalServerError))?
            .to_string(),
        &m4a_path
            .to_str()
            .ok_or(Error(Status::InternalServerError))?
            .to_string(),
    ])?;

    // Remove the temporary file.
    remove_file(&tmp_path).await.ok();

    // Save the track in the database.
    let sound_track = SoundTrack {
        uuid: uuid,
        name: name.to_string(),
        volume: volume,
    };
    capsule.sound_track = EJson(Some(sound_track));
    capsule.save(&db).await?;

    Ok(capsule.to_json(role, &db).await?)
}
