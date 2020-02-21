//! This module contains the structures to manipulate capsules.

use diesel::pg::PgConnection;
use diesel::prelude::*;

use crate::db::gos::Gos;
use crate::db::project::Project;
use crate::db::slide::Slide;
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
    pub title: String,

    /// Reference to pdf file of caspusle
    // TODO: add reference to asset table
    pub slides: String,

    /// The description of the capsule.
    pub description: String,
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
    pub slides: String,

    /// The description of the capsule.
    pub description: String,
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
        slides: &str,
        description: &str,
        project: Option<Project>,
    ) -> Result<Capsule> {
        let capsule = NewCapsule {
            name: String::from(name),
            title: String::from(title),
            slides: String::from(slides),
            description: String::from(description),
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
    pub fn create(name: &str, title: &str, slides: &str, description: &str) -> Result<NewCapsule> {
        Ok(NewCapsule {
            name: String::from(name),
            title: String::from(title),
            slides: String::from(slides),
            description: String::from(description),
        })
    }

    /// Gets a capsule from its id.
    pub fn get(id: i32, db: &PgConnection) -> Result<(Capsule, Vec<Project>)> {
        use crate::schema::capsules::dsl;
        let capsule = dsl::capsules.filter(dsl::id.eq(id)).first::<Capsule>(db)?;

        let cap_p = CapsulesProject::belonging_to(&capsule).load::<CapsulesProject>(db)?;

        let projects = cap_p
            .into_iter()
            .map(|x| Project::get(x.project_id, &db))
            .collect::<Result<Vec<Project>>>()?;

        Ok((capsule, projects))
    }

    /// Gets a capsule from its name.
    pub fn get_by_name(name: &str, db: &PgConnection) -> Result<Capsule> {
        use crate::schema::capsules::dsl;
        let capsule = dsl::capsules
            .filter(dsl::name.eq(name))
            .first::<Capsule>(db);
        Ok(capsule?)
    }

    /// Gets a capsule from its id.
    pub fn get_by_id(
        id: i32,
        db: &PgConnection,
    ) -> Result<(Capsule, Vec<Project>, Vec<(Gos, Vec<Slide>)>)> {
        use crate::schema::capsules::dsl;
        let capsule = dsl::capsules.filter(dsl::id.eq(id)).first::<Capsule>(db)?;

        let cap_p = CapsulesProject::belonging_to(&capsule).load::<CapsulesProject>(db)?;

        let projects = cap_p
            .into_iter()
            .map(|x| Project::get(x.project_id, &db))
            .collect::<Result<Vec<Project>>>()?;

        use crate::schema::goss::dsl as dsl_gos;
        let goss = Gos::belonging_to(&capsule)
            .order(dsl_gos::position.asc())
            .load::<Gos>(db)?;

        use crate::schema::slides::dsl as dsl_slides;
        let slides = Slide::belonging_to(&goss)
            .order(dsl_slides::position_in_gos.asc())
            .load::<Slide>(db)?;
        let grouped_slides: Vec<Vec<Slide>> = slides.grouped_by(&goss);
        let goss_and_slides: Vec<(Gos, Vec<Slide>)> =
            goss.into_iter().zip(grouped_slides).collect::<Vec<_>>();

        println!("{:#?}", goss_and_slides);

        //let data = capsule.zip(goss).collect::<Vec<_>>();
        Ok((capsule, projects, goss_and_slides))
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
