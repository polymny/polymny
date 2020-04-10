//! This module contains the structures to manipulate slides.

use diesel::pg::PgConnection;
use diesel::prelude::*;
use diesel::RunQueryDsl;

use crate::db::asset::Asset;
use crate::db::capsule::Capsule;
use crate::schema::slides;
use crate::Result;

/// A slide of preparation
#[derive(Identifiable, Queryable, PartialEq, Debug, Serialize, Associations)]
#[belongs_to(Capsule)]
pub struct Slide {
    /// The id of the slide.
    pub id: i32,

    /// The position of the slide in the slide show
    pub position: i32,

    /// The position of the slide in the GOS.
    pub position_in_gos: i32,

    /// The GOS associated to slide.
    pub gos: i32,

    /// The asset associated to slide.
    pub asset_id: i32,

    /// capsule id
    pub capsule_id: i32,
}

/// A slide that isn't stored into the database yet.
#[derive(Debug, Insertable)]
#[table_name = "slides"]
pub struct NewSlide {
    /// The position of the slide in the slide show
    pub position: i32,

    /// The position of the slide in the GOS.
    pub position_in_gos: i32,

    /// The GOS associated to slide.
    pub gos: i32,

    /// The asset associated to slide.
    pub asset_id: i32,

    /// capsule id
    pub capsule_id: i32,
}

impl Slide {
    /// Creates a new slide and store i tin database
    pub fn new(
        db: &PgConnection,
        position: i32,
        position_in_gos: i32,
        gos: i32,
        asset_id: i32,
        capsule_id: i32,
    ) -> Result<Slide> {
        Ok(NewSlide {
            position,
            position_in_gos,
            gos,
            asset_id,
            capsule_id,
        }
        .save(&db)?)
    }

    /// Creates a new slide.
    pub fn create(
        position: i32,
        position_in_gos: i32,
        gos: i32,
        asset_id: i32,
        capsule_id: i32,
    ) -> Result<NewSlide> {
        Ok(NewSlide {
            position,
            position_in_gos,
            gos,
            asset_id,
            capsule_id,
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

/// Slide respresantation with asset as struture (not asset_id)
#[derive(Debug, Serialize)]
pub struct SlideWithAsset {
    /// The id of the slide.
    pub id: i32,

    /// The position of the slide in the slide show
    pub position: i32,

    /// The position of the slide in the GOS.
    pub position_in_gos: i32,

    /// The GOS associated to slide.
    pub gos: i32,

    /// The asset associated to slide.
    pub asset: Asset,

    /// capsule id
    pub capsule_id: i32,
}

impl SlideWithAsset {
    /// new Slide with associated asset
    pub fn new(slide: &Slide, db: &PgConnection) -> Result<SlideWithAsset> {
        Ok(SlideWithAsset {
            id: slide.id,
            position: slide.position,
            position_in_gos: slide.position_in_gos,
            gos: slide.gos,
            asset: Asset::get(slide.asset_id, &db)?,
            capsule_id: slide.capsule_id,
        })
    }
    /// delete a slide.
    /// TODO : Delete also linked asset ?
    pub fn delete(&self, db: &PgConnection) -> Result<usize> {
        let slide = Slide::get(self.id, &db)?;
        slide.delete(&db)
    }
}
