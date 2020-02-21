//! This module contains the structures to manipulate GOS (GROUP OF SLIDES).

use diesel::pg::PgConnection;
use diesel::prelude::*;
use diesel::RunQueryDsl;

use crate::db::capsule::Capsule;
use crate::schema::goss;
use crate::Result;

/// A gos of preparation
#[derive(Identifiable, Queryable, PartialEq, Debug, Serialize, Associations)]
#[belongs_to(Capsule)]
pub struct Gos {
    /// The id of the gos.
    pub id: i32,

    /// The position of the gos in capsule.
    pub position: i32,

    /// The capsule associated to gos.
    pub capsule_id: i32,
}

/// A gos that isn't stored into the database yet.
#[derive(Debug, Insertable)]
#[table_name = "goss"]
pub struct NewGos {
    /// The position of the gos in capsule.
    pub position: i32,

    /// The capsule associated to gos.
    pub capsule_id: i32,
}

impl Gos {
    /// Creates a new gos.
    pub fn create(position: i32, capsule_id: i32) -> Result<NewGos> {
        Ok(NewGos {
            position,
            capsule_id,
        })
    }

    /// Retrieves a gos from its id.
    pub fn get(id: i32, db: &PgConnection) -> Result<Gos> {
        use crate::schema::goss::dsl;

        let gos = dsl::goss.filter(dsl::id.eq(id)).first::<Gos>(db);

        Ok(gos?)
    }

    /// Retrieves all goss
    pub fn all(db: &PgConnection) -> Result<Vec<Gos>> {
        use crate::schema::goss::dsl;

        let goss = dsl::goss.load::<Gos>(db);

        Ok(goss?)
    }

    /// Creates a new gos.
    pub fn update(&self, db: &PgConnection, position: i32, capsule_id: i32) -> Result<Gos> {
        use crate::schema::goss::dsl;
        Ok(diesel::update(goss::table)
            .set((dsl::position.eq(position), dsl::capsule_id.eq(capsule_id)))
            .filter(dsl::id.eq(self.id))
            .get_result::<Gos>(db)?)
    }

    /// delete a gos.
    pub fn delete(&self, db: &PgConnection) -> Result<usize> {
        use crate::schema::goss::dsl;
        Ok(diesel::delete(goss::table)
            .filter(dsl::id.eq(self.id))
            .execute(db)
            .expect("Error deleting gos")) //TODO: expect it the good way to handle error?
    }
}

impl NewGos {
    /// Saves the new gos into the database.
    pub fn save(&self, database: &PgConnection) -> Result<Gos> {
        Ok(diesel::insert_into(goss::table)
            .values(self)
            .get_result(database)?)
    }
}
