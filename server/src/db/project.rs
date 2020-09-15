//! This module contains the structures to manipulate projects.

use std::result;

use serde::Serializer;

use diesel::pg::PgConnection;
use diesel::prelude::*;
use diesel::RunQueryDsl;

use chrono::{NaiveDateTime, Utc};

use crate::db::capsule::{Capsule, CapsulesProject};
use crate::db::user::User;
use crate::schema::projects;
use crate::Result;

fn serialize_naive_date_time<S: Serializer>(
    t: &NaiveDateTime,
    s: S,
) -> result::Result<S::Ok, S::Error>
where
    S: Serializer,
{
    s.serialize_i64(t.timestamp())
}

/// A project of preparation
#[derive(Identifiable, Queryable, PartialEq, Debug, Serialize, Associations)]
#[belongs_to(User)]
pub struct Project {
    /// The id of the project.
    pub id: i32,

    /// The owner of the project.
    pub user_id: i32,

    /// The project_name of the project.
    pub project_name: String,

    /// The last time the project was visited.
    #[serde(serialize_with = "serialize_naive_date_time")]
    pub last_visited: NaiveDateTime,
}

/// A project with its capsules.
#[derive(PartialEq, Debug, Serialize)]
pub struct ProjectWithCapsules {
    /// The id of the project.
    pub id: i32,

    /// The owner of the project.
    pub user_id: i32,

    /// The project_name of the project.
    pub project_name: String,

    /// The last time the project was visited.
    #[serde(serialize_with = "serialize_naive_date_time")]
    pub last_visited: NaiveDateTime,

    /// The capsules of the project.
    pub capsules: Vec<Capsule>,
}

impl ProjectWithCapsules {
    /// Removes the capsules from self and just returns the project.
    pub fn to_project(self) -> Project {
        Project {
            id: self.id,
            user_id: self.user_id,
            project_name: self.project_name,
            last_visited: self.last_visited,
        }
    }
}

/// A project that isn't stored into the database yet.
#[derive(Debug, Insertable)]
#[table_name = "projects"]
pub struct NewProject {
    /// The owner of the project.
    pub user_id: i32,

    /// The project_name of the project.
    pub project_name: String,

    /// The last time the project was visited.
    pub last_visited: NaiveDateTime,
}

impl Project {
    /// Creates a new project.
    pub fn create(project_name: &str, user_id: i32) -> Result<NewProject> {
        Ok(NewProject {
            user_id,
            project_name: String::from(project_name),
            last_visited: Utc::now().naive_utc(),
        })
    }

    /// Retrieves a project from its id.
    pub fn get_by_id(id: i32, db: &PgConnection) -> Result<ProjectWithCapsules> {
        use crate::schema::projects::dsl;

        let project = dsl::projects.filter(dsl::id.eq(id)).first::<Project>(db)?;
        let capsules = project.get_capsules(db)?;

        Ok(ProjectWithCapsules {
            id: project.id,
            user_id: project.user_id,
            project_name: project.project_name,
            last_visited: project.last_visited,
            capsules,
        })
    }

    /// get the projects associated to a user
    pub fn get_capsules(&self, db: &PgConnection) -> Result<Vec<Capsule>> {
        let cap_p = CapsulesProject::belonging_to(self).load::<CapsulesProject>(db)?;
        Ok(cap_p
            .into_iter()
            .filter_map(|x| {
                let c = Capsule::get_by_id(x.capsule_id, &db);
                match c {
                    Ok(c) => {
                        if c.active {
                            Some(Ok(c))
                        } else {
                            None
                        }
                    }
                    Err(e) => Some(Err(e)),
                }
            })
            .collect::<Result<Vec<Capsule>>>()?)
    }

    /// Adds the capsules to self.
    pub fn with_capsules(self, db: &PgConnection) -> Result<ProjectWithCapsules> {
        let capsules = self.get_capsules(db)?;
        Ok(ProjectWithCapsules {
            id: self.id,
            user_id: self.user_id,
            project_name: self.project_name,
            last_visited: self.last_visited,
            capsules,
        })
    }

    /// Retrieves all projects
    pub fn all(db: &PgConnection) -> Result<Vec<Project>> {
        use crate::schema::projects::dsl;

        let projects = dsl::projects.load::<Project>(db);

        Ok(projects?)
    }

    /// Creates a new project.
    pub fn update(&self, db: &PgConnection, project_name: &str, user_id: i32) -> Result<Project> {
        use crate::schema::projects::dsl;
        Ok(diesel::update(projects::table)
            .set((
                dsl::project_name.eq(project_name),
                dsl::user_id.eq(user_id),
                dsl::last_visited.eq(Utc::now().naive_utc()),
            ))
            .filter(dsl::id.eq(self.id))
            .get_result::<Project>(db)?)
    }

    /// delete a project.
    pub fn delete(&self, db: &PgConnection) -> Result<usize> {
        use crate::schema::projects::dsl;
        Ok(diesel::delete(projects::table)
            .filter(dsl::id.eq(self.id))
            .execute(db)?)
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
