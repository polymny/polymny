//! This module contains the structures to manipulate slides.

use diesel::pg::PgConnection;
use diesel::prelude::*;
use diesel::RunQueryDsl;

use crate::db::gos::Gos;
use crate::schema::slides;
use crate::Result;

/// A slide of preparation
#[derive(Identifiable, Queryable, PartialEq, Debug, Serialize, Associations)]
#[belongs_to(Gos)]
pub struct Slide {
    /// The id of the slide.
    pub id: i32,

    /// The position of the slide in the GOS.
    pub position_in_gos: i32,

    /// The GOS associated to slide.
    pub gos_id: i32,
}

/// A slide that isn't stored into the database yet.
#[derive(Debug, Insertable)]
#[table_name = "slides"]
pub struct NewSlide {
    /// The position of the slide in the GOS.
    pub position_in_gos: i32,

    /// The GOS associated to slide.
    pub gos_id: i32,
}

impl Slide {
    /// Creates a new slide and store i tin database
    pub fn new(db: &PgConnection, position_in_gos: i32, gos_id: i32) -> Result<Slide> {
        Ok(NewSlide {
            position_in_gos,
            gos_id,
        }
        .save(&db)?)
    }

    /// Creates a new slide.
    pub fn create(position_in_gos: i32, gos_id: i32) -> Result<NewSlide> {
        Ok(NewSlide {
            position_in_gos,
            gos_id,
        })
    }

    /// Retrieves a slide from its id.
    pub fn get(id: i32, db: &PgConnection) -> Result<Slide> {
        use crate::schema::slides::dsl;

        let slide = dsl::slides.filter(dsl::id.eq(id)).first::<Slide>(db);

        Ok(slide?)
    }

    /// Retrieves all slides
    pub fn all(db: &PgConnection) -> Result<Vec<Slide>> {
        use crate::schema::slides::dsl;

        let slides = dsl::slides.load::<Slide>(db);

        Ok(slides?)
    }

    /// Creates a new slide.
    pub fn update(&self, db: &PgConnection, position_in_gos: i32, gos_id: i32) -> Result<Slide> {
        use crate::schema::slides::dsl;
        Ok(diesel::update(slides::table)
            .set((
                dsl::position_in_gos.eq(position_in_gos),
                dsl::gos_id.eq(gos_id),
            ))
            .filter(dsl::id.eq(self.id))
            .get_result::<Slide>(db)?)
    }

    /// delete a slide.
    pub fn delete(&self, db: &PgConnection) -> Result<usize> {
        use crate::schema::slides::dsl;
        Ok(diesel::delete(slides::table)
            .filter(dsl::id.eq(self.id))
            .execute(db)
            .expect("Error deleting slide")) //TODO: expect it the good way to handle error?
    }
}

impl NewSlide {
    /// Saves the new slide into the database.
    pub fn save(&self, database: &PgConnection) -> Result<Slide> {
        Ok(diesel::insert_into(slides::table)
            .values(self)
            .get_result(database)?)
    }
}
