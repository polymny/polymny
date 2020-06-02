//! This module contains the structures to manipulate capsules.

use serde_json::{json, Value as Json};

use diesel::pg::PgConnection;
use diesel::prelude::*;

use crate::db::asset::Asset;
use crate::db::project::Project;
use crate::db::slide::{Slide, SlideWithAsset};
use crate::schema::{capsules, capsules_projects};
use crate::Result;

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

    /// The structure of the capsule.
    ///
    /// This json should be of the form
    /// [ {
    ///     record_path: Option<String>,
    ///     slides: Vec<i32>,
    /// } ]
    pub structure: Json,
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
            .map(|x| Project::get_by_id(x.project_id, &db))
            .collect::<Result<Vec<Project>>>()?)
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
