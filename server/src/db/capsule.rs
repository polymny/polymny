//! This module contains everything that manage the capsule in the database.
use chrono::{NaiveDateTime, Utc};
use std::default::Default;

use ergol::prelude::*;
use ergol::tokio_postgres::types::Json;

use uuid::Uuid;

use serde::{Deserialize, Serialize};

use tungstenite::Message;

use rocket::http::Status;
use rocket::serde::json::{json, Value};

use crate::db::task_status::TaskStatus;
use crate::db::user::User;
use crate::websockets::WebSockets;
use crate::{Db, Error, Result, HARSH};

/// The different roles a user can have for a capsule.
#[derive(Debug, Copy, Clone, PgEnum, Serialize, Deserialize, PartialEq, Eq, PartialOrd, Ord)]
#[serde(rename_all = "snake_case")]
pub enum Role {
    /// The user has read access to the capsule.
    Read,

    /// The user has write access to the capsule.
    Write,

    /// The user owns the capsule.
    Owner,
}

/// A slide with its prompt.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Slide {
    /// The uuid of the file.
    pub uuid: Uuid,

    /// The uuid of the extra resource if any.
    pub extra: Option<Uuid>,

    /// The prompt associated to the slide.
    pub prompt: String,
}

/// The anchor of the webcam.
#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum Anchor {
    /// The top left corner.
    TopLeft,

    /// The top right corner.
    TopRight,

    /// The bottom left corner.
    BottomLeft,

    /// The bottom right corner.
    BottomRight,
}

impl Default for Anchor {
    fn default() -> Anchor {
        Anchor::BottomLeft
    }
}

impl Anchor {
    /// Returns true if the anchor is top.
    pub fn is_top(self) -> bool {
        match self {
            Anchor::TopLeft | Anchor::TopRight => true,
            _ => false,
        }
    }

    /// Returns true if the anchor is left.
    pub fn is_left(self) -> bool {
        match self {
            Anchor::TopLeft | Anchor::BottomLeft => true,
            _ => false,
        }
    }
}

/// The webcam settings for a gos.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
#[serde(tag = "type")]
pub enum WebcamSettings {
    /// The webcam is disabled.
    Disabled,

    /// The webcam is in fullscreen mode.
    Fullscreen {
        /// The opacity of the webcam.
        opacity: f32,

        /// Keying color
        keycolor: Option<String>,
    },

    /// The webcam is at a corner of the screen.
    Pip {
        /// The corner to which the webcam is attached.
        anchor: Anchor,

        /// The opacity of the webcam, between 0 and 1.
        opacity: f32,

        /// The offset from the corner in pixels.
        position: (i32, i32),

        /// The size of the webcam.
        size: (i32, i32),

        /// Keying color
        keycolor: Option<String>,
    },
}

impl Default for WebcamSettings {
    fn default() -> WebcamSettings {
        WebcamSettings::Pip {
            anchor: Anchor::default(),
            size: (533, 300),
            position: (4, 4),
            opacity: 1.0,
            keycolor: None,
        }
    }
}

/// The sound track for a capsule.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub struct SoundTrack {
    /// The uuid of the file.
    pub uuid: Uuid,

    /// The name of the file.
    pub name: String,

    /// The volume of the sound track.
    pub volume: f32,
}

/// A record, with an uuid, a resolution and a duration.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Record {
    /// The uuid of the record.
    pub uuid: Uuid,

    /// The uuid of the pointer of the record.
    pub pointer_uuid: Option<Uuid>,

    /// The size of the record, if it contains video.
    pub size: Option<(u32, u32)>,
}

/// The type of a record event.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum EventType {
    /// The record started
    Start,

    /// Go to the next slide.
    NextSlide,

    /// Go to the previous slide.
    PreviousSlide,

    /// Go to the next sentence.
    NextSentence,

    /// Start to play extra media.
    Play,

    /// Stop the extra media.
    Stop,

    /// The record ended.
    End,
}

/// A record event.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub struct Event {
    /// The type of the event.
    pub ty: EventType,

    /// The time of the event in ms.
    pub time: i32,
}

/// Options for audio/video fade in and fade out
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Fade {
    /// duration of video fade in
    vfadein: Option<i32>,

    /// duration of video fade out
    vfadeout: Option<i32>,

    /// duration of audio fade in
    afadein: Option<i32>,

    /// duration of audio fade out
    afadeout: Option<i32>,
}

impl Fade {
    /// Returns the default fade, which is no fade at all.
    pub fn none() -> Fade {
        Fade {
            vfadein: None,
            vfadeout: None,
            afadein: None,
            afadeout: None,
        }
    }
}

impl Default for Fade {
    fn default() -> Fade {
        Fade::none()
    }
}

/// The different pieces of information that we collect about a gos.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Gos {
    /// The path to the video recorded
    pub record: Option<Record>,

    /// The ids of the slides of the gos.
    pub slides: Vec<Slide>,

    /// The milliseconds where slides transition.
    pub events: Vec<Event>,

    /// The webcam settings of the gos.
    pub webcam_settings: Option<WebcamSettings>,

    /// Video/audio fade options
    #[serde(default)]
    pub fade: Fade,
}

impl Gos {
    /// Creates a new empty gos.
    pub fn new() -> Gos {
        Gos {
            record: None,
            slides: vec![],
            events: vec![],
            webcam_settings: None,
            fade: Fade::none(),
        }
    }
}

/// Privacy settings for a video.
#[derive(PgEnum, Serialize, Deserialize, Debug, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum Privacy {
    /// Public video.
    Public,

    /// Unlisted video.
    Unlisted,

    /// Private video.
    Private,
}

/// A video capsule.
#[ergol]
pub struct Capsule {
    /// The id of the capsule.
    #[id]
    pub id: i32,

    /// The project name.
    pub project: String,

    /// The name of the capsule.
    pub name: String,

    /// The task status of the video upload step.
    pub video_uploaded: TaskStatus,

    /// The pid of video upload transcode if any.
    pub video_uploaded_pid: Option<i32>,

    /// The task status of the edition step.
    pub produced: TaskStatus,

    /// The pid of the production task if any.
    pub production_pid: Option<i32>,

    /// The task status of the publication step.
    pub published: TaskStatus,

    /// The pid of the publication task if any.
    pub publication_pid: Option<i32>,

    /// Whether the video is public, unlisted, or private.
    pub privacy: Privacy,

    /// Whether the prompt should be use as subtitles or not.
    pub prompt_subtitles: bool,

    /// The structure of the capsule.
    pub structure: Json<Vec<Gos>>,

    /// The default webcam settings.
    pub webcam_settings: Json<WebcamSettings>,

    /// The last time the capsule was modified.
    pub last_modified: NaiveDateTime,

    /// Capsule disk usage (in MB)
    pub disk_usage: i32,

    /// duration of produced video in ms
    pub duration_ms: i32,

    /// The sound track of the capsule.
    pub sound_track: Json<Option<SoundTrack>>,

    /// The user that has rights on the capsule.
    #[many_to_many(capsules, Role)]
    pub users: User,
}

impl Capsule {
    /// Creates a new capsule.
    pub async fn new<P: Into<String>, Q: Into<String>>(
        project: P,
        name: Q,
        owner: &User,
        db: &Db,
    ) -> Result<Capsule> {
        let project = project.into();
        let name = name.into();

        let capsule = Capsule::create(
            project,
            name,
            TaskStatus::Idle,
            None,
            TaskStatus::Idle,
            None,
            TaskStatus::Idle,
            None,
            Privacy::Public,
            true,
            Json(vec![]),
            Json(WebcamSettings::default()),
            Utc::now().naive_utc(),
            0,
            0,
            Json(None),
        )
        .save(&db)
        .await?;

        capsule.add_user(owner, Role::Owner, db).await?;

        Ok(capsule)
    }

    /// Sets the last modified to now.
    pub fn set_changed(&mut self) {
        self.last_modified = Utc::now().naive_utc();
    }

    /// Returns a json representation of the capsule.
    pub async fn to_json(&self, role: Role, db: &Db) -> Result<Value> {
        let users = self
            .users(&db)
            .await?
            .into_iter()
            .map(|(x, role)| {
                json!({
                    "username": x.username,
                    "role": role,
                })
            })
            .collect::<Vec<_>>();

        Ok(json!({
            "id": HARSH.encode(self.id),
            "name": self.name,
            "project": self.project,
            "role": role,
            "video_uploaded": self.video_uploaded,
            "produced": self.produced,
            "published": self.published,
            "privacy": self.privacy,
            "structure": self.structure.0,
            "webcam_settings": self.webcam_settings.0,
            "last_modified": self.last_modified.timestamp(),
            "users": users,
            "prompt_subtitles": self.prompt_subtitles,
            "disk_usage": self.disk_usage,
            "duration_ms": self.duration_ms,
            "sound_track": self.sound_track.0,
        }))
    }

    /// Notify the users that a capsule has been produced.
    pub async fn notify_production(&self, id: &str, db: &Db, sock: &WebSockets) -> Result<()> {
        let text = json!({
            "type": "capsule_production_finished",
            "id": id,
        });

        for (user, _) in self.users(&db).await? {
            sock.write_message(user.id, Message::Text(text.to_string()))
                .await?;
        }

        Ok(())
    }

    /// Notify the users that a capsule has been publicated.
    pub async fn notify_publication(&self, id: &str, db: &Db, sock: &WebSockets) -> Result<()> {
        let text = json!({
            "type": "capsule_publication_finished",
            "id": id,
        });

        for (user, _) in self.users(&db).await? {
            sock.write_message(user.id, Message::Text(text.to_string()))
                .await?;
        }

        Ok(())
    }

    /// Notify the users that a capsule has been publicated.
    pub async fn notify_video_upload(&self, slide_id: &str, capsule_id: &str, db: &Db, sock: &WebSockets) -> Result<()> {
        let text = json!({
            "type": "video_upload_finished",
            "capsule_id": capsule_id,
            "slide_id": slide_id,
        });

        for (user, _) in self.users(&db).await? {
            sock.write_message(user.id, Message::Text(text.to_string()))
                .await?;
        }

        Ok(())
    }

    /// Notify the users that a capsule in under production.
    pub async fn notify_production_progress(
        &self,
        id: &str,
        msg: &str,
        db: &Db,
        sock: &WebSockets,
    ) -> Result<()> {
        let text = json!({
            "type": "capsule_production_progress",
            "msg": msg.parse::<f32>().map_err(|_|Error(Status::InternalServerError))?,
            "id": id,
        });

        for (user, _) in self.users(&db).await? {
            sock.write_message(user.id, Message::Text(text.to_string()))
                .await?;
        }

        Ok(())
    }

    /// Notify the users that a capsule in under production.
    pub async fn notify_video_upload_progress(
        &self,
        slide_id: &str,
        capsule_id: &str,
        msg: &str,
        db: &Db,
        sock: &WebSockets,
    ) -> Result<()> {
        let text = json!({
            "type": "video_upload_progress",
            "msg": msg.parse::<f32>().map_err(|_|Error(Status::InternalServerError))?,
            "capsule_id": capsule_id,
            "slide_id": slide_id,
        });

        for (user, _) in self.users(&db).await? {
            sock.write_message(user.id, Message::Text(text.to_string()))
                .await?;
        }

        Ok(())
    }

    /// Notify the users that the capsule has been changed.
    pub async fn notify_change(&self, db: &Db, sock: &WebSockets) -> Result<()> {
        let mut json = self.to_json(Role::Read, &db).await?;
        json["type"] = json!("capsule_changed");

        for (user, role) in self.users(&db).await? {
            json["role"] = json!(role);

            sock.write_message(user.id, Message::Text(json.to_string()))
                .await?;
        }

        Ok(())
    }

    /// Retrieves the owner of a capsule.
    pub async fn owner(&self, db: &Db) -> Result<User> {
        for (user, role) in self.users(db).await? {
            if role == Role::Owner {
                return Ok(user);
            }
        }

        Err(Error(Status::NotFound))
    }
}
