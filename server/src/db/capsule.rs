//! This module contains the structures to manipulate capsules.

use diesel::pg::PgConnection;
use diesel::prelude::*;
use diesel::RunQueryDsl;

use crate::db::project::Project;
use crate::schema::{capsules, capsules_projects};
use crate::Result;

/// A capsule of preparation
#[derive(Identifiable, Queryable, PartialEq, Debug, Serialize)]
pub struct Capsule {
    /// The id of the capsule.
    pub id: i32,

    /// The (unique) name of the capsule.
    pub name: String,

    /// The title the capsule.
    pub title: Option<String>,

    /// Reference to pdf file of caspusle
    // TODO: add reference to asset table
    pub slides: Option<String>,

    /// The description of the capsule.
    pub description: Option<String>,
}

/// A capsule that isn't stored into the database yet.
#[derive(Debug, Insertable)]
#[table_name = "capsules"]
pub struct NewCapsule {
    /// The (unique) name of the capsule.
    pub name: String,

    /// The title the capsule.
    pub title: Option<String>,

    /// Reference to pdf file of caspusle
    // TODO: add reference to asset table
    pub slides: Option<String>,

    /// The description of the capsule.
    pub description: Option<String>,
}

/// A capsule that isn't stored into the database yet.
#[derive(Debug, Insertable, AsChangeset)]
#[table_name = "capsules"]
pub struct UpdateCapsule {
    /// The (unique) name of the capsule.
    pub name: Option<String>,

    /// The title the capsule.
    pub title: Option<String>,

    /// Reference to pdf file of caspusle
    // TODO: add reference to asset table
    pub slides: Option<String>,

    /// The description of the capsule.
    pub description: Option<String>,
}

/// A link between a capsule and a project.
#[derive(Identifiable, Queryable, Associations, Debug)]
#[table_name = "capsules_projects"]
#[belongs_to(Capsule)]
#[belongs_to(Project)]
pub struct CapsuleProject {
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
        title: Option<&str>,
        slides: Option<&str>,
        description: Option<&str>,
        project: &Option<Project>,
    ) -> Result<Capsule> {
        let capsule = NewCapsule {
            name: String::from(name),
            title: title.map(String::from),
            slides: slides.map(String::from),
            description: description.map(String::from),
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
        title: Option<&str>,
        slides: Option<&str>,
        description: Option<&str>,
    ) -> Result<NewCapsule> {
        Ok(NewCapsule {
            name: String::from(name),
            title: title.map(String::from),
            slides: slides.map(String::from),
            description: description.map(String::from),
        })
    }

    /// Gets a capsule from its id.
    pub fn get(id: i32, db: &PgConnection) -> Result<Capsule> {
        use crate::schema::capsules::dsl;
        let capsule = dsl::capsules.filter(dsl::id.eq(id)).first::<Capsule>(db);
        Ok(capsule?)
    }
    /// Gets a capsule from its name.
    pub fn get_by_name(name: &str, db: &PgConnection) -> Result<Capsule> {
        use crate::schema::capsules::dsl;
        let capsule = dsl::capsules
            .filter(dsl::name.eq(name))
            .first::<Capsule>(db);
        // TODO: is "?" needed
        Ok(capsule?)
    }

    /// Retrieves all capsules
    pub fn all(db: &PgConnection) -> Result<Vec<Capsule>> {
        use crate::schema::capsules::dsl;

        let capsules = dsl::capsules.load::<Capsule>(db);

        Ok(capsules?)
    }

    /// Creates a new capsule.
    pub fn update(
        &self,
        db: &PgConnection,
        name: Option<&str>,
        title: Option<&str>,
        slides: Option<&str>,
        description: Option<&str>,
    ) -> Result<Capsule> {
        use crate::schema::capsules::dsl;

        /*
        let mut d_name = &self.name;
        let mut d_title;
        let mut d_slides = &self.slides;
        let mut d_description = &self.description;

        match name {
            Some(p) => d_name = &String::from(p),
            None => (),
        }
        match title {
            Some(p) => d_title = &String::from(p),
            None => match self.title {
            }
        }
            ,
        }
        match slides {
            Some(p) => d_slides = &String::from(p),
            None => (),
        }
        match description {
            Some(p) => d_description = &String::from(p),
            None => (),
        }
        */
        /*
                        dsl::name.eq(d_name),
                        dsl::title.eq(d_title),
                        dsl::slides.eq(d_slides),
                        dsl::description.eq(d_description),
        */
        Ok(diesel::update(capsules::table)
            .set(&UpdateCapsule {
                name: name.map(String::from),
                title: title.map(String::from),
                slides: slides.map(String::from),
                description: description.map(String::from),
            })
            .filter(dsl::id.eq(self.id))
            .get_result::<Capsule>(db)?)
    }

    /// delete a capsule.
    pub fn delete(&self, db: &PgConnection) -> Result<usize> {
        use crate::schema::capsules::dsl;
        Ok(diesel::delete(capsules::table)
            .filter(dsl::id.eq(self.id))
            .execute(db)
            .expect("Error deleting capsule")) //TODO: expect it the good way to handle error?
    }
}

impl CapsuleProject {
    /// Creates a new capsule project and saves it into the database.
    pub fn new(
        database: &PgConnection,
        capsule_id: i32,
        project_id: i32,
    ) -> Result<CapsuleProject> {
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
    pub fn save(&self, database: &PgConnection) -> Result<CapsuleProject> {
        Ok(diesel::insert_into(capsules_projects::table)
            .values(self)
            .get_result(database)?)
    }
}
