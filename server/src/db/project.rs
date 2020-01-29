//! This module contains the structures to manipulate projects.

use diesel::prelude::*;
use diesel::RunQueryDsl;
use diesel::pg::PgConnection;



use crate::{Result};
use crate::schema::{projects};
//use crate::db::session::{Session, NewSession};


/// A project of preparation
#[derive(Identifiable, Queryable, PartialEq, Debug)]
pub struct Project {
    /// The id of the project.
    pub id: i32,

    /// The owner of the project.
    pub user_id: i32,

    /// The project_name of the project.
    pub project_name: String,

}

/// A project that isn't stored into the database yet.
#[derive(Debug, Insertable)]
#[table_name = "projects"]
pub struct NewProject {
    /// The owner of the project.
    pub user_id: i32,

    /// The project_name of the project.
    pub project_name: String,

}

impl Project {
    /// Creates a new project.
    pub fn create(project_name: &str , user_id: i32) -> Result<NewProject> {
        Ok(NewProject {
            user_id: user_id,
            project_name: String::from(project_name),
            })

    }

    pub fn get(id: i32, db: &PgConnection) -> Result<Project> {
        use crate::schema::projects::dsl;

        let project = dsl::projects
            .filter(dsl::id.eq(id))
            .first::<Project>(db);

        Ok(project?)

   }
}

impl NewProject {
    /// Saves the new project into the database.
    pub fn save(&self, database: &PgConnection) -> Result<Project> {
        Ok(diesel::insert_into(projects::table)
            .values(self)
            .get_result(database)?)

    }
}



