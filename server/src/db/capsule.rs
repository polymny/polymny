//! This module contains the structures to manipulate capsules.

use diesel::prelude::*;
use diesel::RunQueryDsl;
use diesel::pg::PgConnection;

use crate::{Result};
use crate::schema::{capsules,capsules_projects};
use crate::db::project::{Project};


/// A capsule of preparation
#[derive(Identifiable, Queryable, PartialEq, Debug)]
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
#[derive(Debug, Insertable )]
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


#[derive(Identifiable, Queryable, Associations, Debug)]
#[table_name = "capsules_projects"]
#[belongs_to(Capsule)]
#[belongs_to(Project)]
pub struct CapsuleProject {
    pub id: i32,
    pub capsule_id: i32,
    pub project_id: i32,
}

#[derive(Insertable, Debug)]
#[table_name = "capsules_projects"]
pub struct NewCapsuleProject {
    pub capsule_id: i32,
    pub project_id: i32,
}


impl Capsule {
    /// act like a concstructor for new
    pub fn new (database: &PgConnection, name: &str , title: &str, slides: &str, description: &str,
                project: &Option<Project>) -> Result<Capsule> {

        let new_capsule = NewCapsule {
            name: String::from(name),
            title: Some(String::from(title)),
            slides: Some(String::from(slides)),
            description: Some(String::from(description)),
            };

        let capsule = new_capsule.save(&database)?;

        if let Some(project) = project {
           NewCapsuleProject {
                capsule_id: capsule.id,
                project_id: project.id
            }.save(&database)?;
        }
            
        Ok(capsule)
    } 
   
    /// Creates a new capsule
    pub fn create(name: &str , title: &str, slides: &str, description: &str) -> Result<NewCapsule> {
       Ok(NewCapsule {
            name: String::from(name),
            title: Some(String::from(title)),
            slides: Some(String::from(slides)),
            description: Some(String::from(description)),
            })
    }

    pub fn get(id: i32, db: &PgConnection) -> Result<Capsule> {
        use crate::schema::capsules::dsl;
        let capsule = dsl::capsules
            .filter(dsl::id.eq(id))
            .first::<Capsule>(db);
        Ok(capsule?)
   }


}

impl NewCapsule {
    pub fn save(&self, database: &PgConnection) -> Result<Capsule> {
        Ok(diesel::insert_into(capsules::table)
                .values(self)
                .get_result(database)?)

    }
}

impl NewCapsuleProject {
    pub fn save(&self, database: &PgConnection) -> Result<CapsuleProject> {
        Ok(diesel::insert_into(capsules_projects::table)
                .values(self)
                .get_result(database)?)

    }
}

