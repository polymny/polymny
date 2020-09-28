//! This module contains the structures to manipulate capsules.

use serde_json::{json, Value as Json};

use diesel::pg::PgConnection;
use diesel::prelude::*;

use crate::db::asset::Asset;
use crate::db::project::{Project, ProjectWithCapsules};
use crate::db::slide::{Slide, SlideWithAsset};
use crate::schema::{capsules, capsules_projects};
use crate::webcam::{
    str_to_webcam_position, str_to_webcam_size, ProductionChoices, WebcamPosition, WebcamSize,
};
use crate::Result;

#[allow(missing_docs)]
mod published_type {
    /// The different published states possible.
    #[derive(Debug, PartialEq, Eq, DbEnum, Serialize, Copy, Clone)]
    pub enum PublishedType {
        /// Not published at all.
        NotPublished,

        /// In publication.
        Publishing,

        /// Published.
        Published,
    }
}

pub use published_type::PublishedTypeMapping as Published_type;
pub use published_type::{PublishedType, PublishedTypeMapping};

/// A capsule of preparation
#[derive(Identifiable, Queryable, Associations, PartialEq, Debug, Serialize)]
#[belongs_to(Asset, foreign_key=slide_show_id)]
pub struct Capsule {
    /// The id of the capsule.
    pub id: i32,

    /// The (unique) name of the capsule.
    pub name: String,

    /// The title the capsule.
    pub title: String,

    /// Reference to slide show in asset table
    pub slide_show_id: Option<i32>,

    /// The description of the capsule.
    pub description: String,

    /// Reference to capsule backgound image
    pub background_id: Option<i32>,

    /// Reference to capsule logo
    pub logo_id: Option<i32>,

    /// Reference to generated video for this capsule
    pub video_id: Option<i32>,

    /// The structure of the capsule.
    ///
    /// This json should be of the form
    /// ```
    /// [ {
    ///     record_path: Option<String>,
    ///     background_path: Option<String>,
    ///     slides: Vec<i32>,
    ///     locked: bool,
    /// } ]
    /// ```
    pub structure: Json,

    /// Whether the capsule video is published.
    pub published: PublishedType,

    /// The structure of the editions options.
    ///
    /// This json should be of the form
    /// ```
    ///  {
    ///     with_video: bool,
    ///     webcam_size:  WebcamSize,
    ///     webcam_position: WebcamPosition,
    ///  ]
    /// ```
    pub edition_options: Json,

    /// Whether the capsule is active or not.
    pub active: bool,
}

/// The capsule with the video as an asset.
#[derive(PartialEq, Debug, Serialize)]
pub struct CapsuleWithVideo {
    /// The id of the capsule.
    pub id: i32,

    /// The (unique) name of the capsule.
    pub name: String,

    /// The title the capsule.
    pub title: String,

    /// Reference to slide show in asset table
    pub slide_show_id: Option<i32>,

    /// The description of the capsule.
    pub description: String,

    /// Reference to capsule backgound image
    pub background_id: Option<i32>,

    /// Reference to capsule logo
    pub logo_id: Option<i32>,

    /// Reference to generated video for this capsule
    pub video: Option<Asset>,

    /// The structure of the capsule.
    ///
    /// This json should be of the form
    /// ```
    /// [ {
    ///     record_path: Option<String>,
    ///     background_path: Option<String>,
    ///     slides: Vec<i32>,
    ///     locked: bool,
    /// } ]
    /// ```
    pub structure: Json,

    /// Whether the capsule video is published.
    pub published: PublishedType,

    /// The structure of the editions options.
    ///
    /// This json should be of the form
    /// ```
    ///  {
    ///     with_video: bool,
    ///     webcam_size:  WebcamSize,
    ///     webcam_position: WebcamPosition,
    ///  ]
    /// ```
    pub edition_options: Json,

    /// Whether the capsule is active or not.
    pub active: bool,
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

    /// Production option
    pub production_choices: Option<ApiProductionChoices>,
}

/// Production choices for video Generation
#[derive(Serialize, Deserialize, Debug)]
pub struct ApiProductionChoices {
    /// Video and audio or audio only
    pub with_video: Option<bool>,

    /// Webcam size
    pub webcam_size: Option<WebcamSize>,

    /// Webcam  Position
    pub webcam_position: Option<WebcamPosition>,
}

impl ApiProductionChoices {
    /// Convert received production choices
    pub fn to_edition_options(&self) -> ProductionChoices {
        ProductionChoices {
            with_video: self.with_video.unwrap_or(true),
            webcam_size: self.webcam_size.unwrap_or_default(),
            webcam_position: self.webcam_position.unwrap_or_default(),
        }
    }
}

/// A capsule that isn't stored into the database yet.
#[derive(Debug, Insertable)]
#[table_name = "capsules"]
pub struct NewCapsule {
    /// The (unique) name of the capsule.
    pub name: String,

    /// The title the capsule.
    pub title: String,

    /// Reference to pdf file of caspusle
    // TODO: add reference to asset table
    pub slide_show_id: Option<Option<i32>>,

    /// The description of the capsule.
    pub description: String,

    /// Reference to capsule backgound image
    pub background_id: Option<Option<i32>>,

    /// Reference to capsule logo
    pub logo_id: Option<Option<i32>>,

    /// The structure of the capsule.
    pub structure: Json,

    /// Whether the capsule video is published.
    pub published: PublishedType,

    /// The structure of the editions options.
    pub edition_options: Option<Json>,

    /// Whether the capsule is active or not.
    pub active: bool,
}

/// A link between a capsule and a project.
#[derive(Identifiable, Queryable, PartialEq, Debug, Serialize, Associations)]
#[belongs_to(Capsule)]
#[belongs_to(Project)]
pub struct CapsulesProject {
    /// Id of the association.
    pub id: i32,

    /// Id of the associated capsule.
    pub capsule_id: i32,

    /// Id of the associated project.
    pub project_id: i32,
}

/// A link between a capsule and a project.
#[derive(Insertable, Debug)]
#[table_name = "capsules_projects"]
pub struct NewCapsuleProject {
    /// Id of the associated capsule.
    pub capsule_id: i32,

    /// Id of the associated project.
    pub project_id: i32,
}

impl Capsule {
    /// Creates a new capsule and stores it in the database.
    pub fn new(
        database: &PgConnection,
        name: &str,
        title: &str,
        slide_show_id: Option<i32>,
        description: &str,
        background_id: Option<i32>,
        logo_id: Option<i32>,
        project: Option<Project>,
    ) -> Result<Capsule> {
        let capsule = NewCapsule {
            name: String::from(name),
            title: String::from(title),
            slide_show_id: Some(slide_show_id),
            description: String::from(description),
            background_id: Some(background_id),
            logo_id: Some(logo_id),
            structure: json!([]),
            published: PublishedType::NotPublished,
            edition_options: Some(json!([])),
            active: false,
        }
        .save(&database)?;

        if let Some(project) = project {
            NewCapsuleProject {
                capsule_id: capsule.id,
                project_id: project.id,
            }
            .save(&database)?;
        }
        Ok(capsule)
    }

    /// Retrieves the structure of the capsule.
    pub fn structure(&self) -> Result<Vec<GosStructure>> {
        Ok(serde_json::from_value(self.structure.clone()).unwrap())
    }

    /// Creates a new capsule.
    pub fn create(
        name: &str,
        title: &str,
        slide_show_id: Option<i32>,
        description: &str,
        background_id: Option<i32>,
        logo_id: Option<i32>,
    ) -> Result<NewCapsule> {
        Ok(NewCapsule {
            name: String::from(name),
            title: String::from(title),
            slide_show_id: Some(slide_show_id),
            description: String::from(description),
            background_id: Some(background_id),
            logo_id: Some(logo_id),
            structure: json!([]),
            published: PublishedType::NotPublished,
            edition_options: None,
            active: false,
        })
    }

    /// Adds the video to the capsule.
    pub fn with_video(&self, db: &PgConnection) -> Result<CapsuleWithVideo> {
        let v = self.get_video(&db)?;
        Ok(CapsuleWithVideo {
            id: self.id,
            name: self.name.clone(),
            title: self.title.clone(),
            slide_show_id: self.slide_show_id,
            description: self.description.clone(),
            background_id: self.background_id,
            logo_id: self.logo_id,
            video: v,
            structure: self.structure.clone(),
            published: self.published,
            edition_options: self.edition_options.clone(),
            active: self.active,
        })
    }

    /// Gets a capsule from its id.
    pub fn get_by_id(id: i32, db: &PgConnection) -> Result<Capsule> {
        use crate::schema::capsules::dsl;
        Ok(dsl::capsules.filter(dsl::id.eq(id)).first::<Capsule>(db)?)
    }

    /// Gets a capsule from its name.
    pub fn get_by_name(name: &str, db: &PgConnection) -> Result<Capsule> {
        use crate::schema::capsules::dsl;
        Ok(dsl::capsules
            .filter(dsl::name.eq(name))
            .first::<Capsule>(db)?)
    }

    /// get the projects associated to a user
    pub fn get_projects(&self, db: &PgConnection) -> Result<Vec<Project>> {
        let cap_p = CapsulesProject::belonging_to(self).load::<CapsulesProject>(db)?;
        Ok(cap_p
            .into_iter()
            .map(|x| Project::get_by_id(x.project_id, &db).map(|x| x.to_project()))
            .collect::<Result<Vec<Project>>>()?)
    }

    /// get the projects associated to a user
    pub fn get_projects_with_capsules(
        &self,
        db: &PgConnection,
    ) -> Result<Vec<ProjectWithCapsules>> {
        let cap_p = CapsulesProject::belonging_to(self).load::<CapsulesProject>(db)?;
        Ok(cap_p
            .into_iter()
            .map(|x| Project::get_by_id(x.project_id, &db).unwrap())
            .collect())
    }

    /// get the slide show associated to capsule
    pub fn get_slide_show(&self, db: &PgConnection) -> Result<Option<Asset>> {
        match self.slide_show_id {
            Some(asset_id) => Ok(Some(Asset::get(asset_id, &db)?)),
            None => Ok(None),
        }
    }

    /// get the background associated to capsule
    pub fn get_background(&self, db: &PgConnection) -> Result<Option<Asset>> {
        // TODO return default background instead of none ?
        // --> implement default backgound ?
        match self.background_id {
            Some(asset_id) => Ok(Some(Asset::get(asset_id, &db)?)),
            None => Ok(None),
        }
    }

    /// get the logo associated to capsule
    pub fn get_logo(&self, db: &PgConnection) -> Result<Option<Asset>> {
        // TODO return default logo instead of none ?
        // --> implement default logo ?
        match self.logo_id {
            Some(asset_id) => Ok(Some(Asset::get(asset_id, &db)?)),
            None => Ok(None),
        }
    }

    /// get the video associated to capsule
    pub fn get_video(&self, db: &PgConnection) -> Result<Option<Asset>> {
        match self.video_id {
            Some(asset_id) => Ok(Some(Asset::get(asset_id, &db)?)),
            None => Ok(None),
        }
    }

    /// get the slide show associated to capsule
    pub fn get_slides(&self, db: &PgConnection) -> Result<Vec<SlideWithAsset>> {
        //TODO : Verify if gest slide is correct without GOS
        //TODO : This is ugly as fuck, it would be cool to have something better
        let all_slides = self
            .structure
            .as_array()
            .unwrap()
            .into_iter()
            .map(|g| {
                g["slides"]
                    .as_array()
                    .unwrap()
                    .clone()
                    .into_iter()
                    .map(|s| s.as_i64().unwrap() as i32)
                    .collect::<Vec<i32>>()
            })
            .collect::<Vec<Vec<i32>>>()
            .into_iter()
            .flatten();

        let mut ret = vec![];

        for i in all_slides {
            ret.push(SlideWithAsset::new(&Slide::get(i, db)?, db)?);
        }

        Ok(ret)
    }

    /// Retrieves all capsules
    pub fn all(db: &PgConnection) -> Result<Vec<Capsule>> {
        use crate::schema::capsules::dsl;
        let capsules = dsl::capsules.load::<Capsule>(db);
        Ok(capsules?)
    }

    /// delete a capsule.
    pub fn delete(&self, db: &PgConnection) -> Result<usize> {
        use crate::schema::capsules::dsl;
        Ok(diesel::delete(capsules::table)
            .filter(dsl::id.eq(self.id))
            .execute(db)?)
    }

    /// Gets Webcam option in db or default values if not set
    pub fn get_edition_options(&self) -> Result<ProductionChoices> {
        let options = ProductionChoices {
            with_video: self
                .edition_options
                .get("with_video")
                .unwrap()
                .as_bool()
                .unwrap(),
            webcam_size: str_to_webcam_size(
                &self
                    .edition_options
                    .get("webcam_size")
                    .unwrap()
                    .as_str()
                    .unwrap()
                    .to_string(),
            ),
            webcam_position: str_to_webcam_position(
                &self
                    .edition_options
                    .get("webcam_position")
                    .unwrap()
                    .as_str()
                    .unwrap()
                    .to_string(),
            ),
        };
        Ok(options)
    }
}

impl CapsulesProject {
    /// Creates a new capsule project and saves it into the database.
    pub fn new(
        database: &PgConnection,
        capsule_id: i32,
        project_id: i32,
    ) -> Result<CapsulesProject> {
        Ok(NewCapsuleProject {
            capsule_id,
            project_id,
        }
        .save(&database)?)
    }
}

impl NewCapsule {
    /// Saves a new capsule into the database.
    pub fn save(&self, database: &PgConnection) -> Result<Capsule> {
        Ok(diesel::insert_into(capsules::table)
            .values(self)
            .get_result(database)?)
    }
}

impl NewCapsuleProject {
    /// Saves a new capsule project into the database.
    pub fn save(&self, database: &PgConnection) -> Result<CapsulesProject> {
        Ok(diesel::insert_into(capsules_projects::table)
            .values(self)
            .get_result(database)?)
    }
}
