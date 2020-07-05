//! This module contains the structures to manipulate slides.

use diesel::pg::PgConnection;
use diesel::prelude::*;
use diesel::RunQueryDsl;

use crate::db::asset::{Asset, AssetType, AssetsObject};
use crate::db::capsule::Capsule;
use crate::schema::slides;
use crate::Result;

/// A slide of preparation
#[derive(Identifiable, Queryable, PartialEq, Debug, Serialize, Associations)]
#[belongs_to(Capsule)]
pub struct Slide {
    /// The id of the slide.
    pub id: i32,

    /// The asset associated to slide.
    pub asset_id: i32,

    /// The capsule id
    pub capsule_id: i32,

    /// The prompt text
    pub prompt: String,
}

/// A slide that isn't stored into the database yet.
#[derive(Debug, Insertable)]
#[table_name = "slides"]
pub struct NewSlide {
    /// The asset associated to slide.
    pub asset_id: i32,

    /// capsule id
    pub capsule_id: i32,

    /// The prompt text
    pub prompt: String,
}

impl Slide {
    /// Creates a new slide and store i tin database
    pub fn new(db: &PgConnection, asset_id: i32, capsule_id: i32, prompt: &str) -> Result<Slide> {
        Ok(NewSlide {
            asset_id,
            capsule_id,
            prompt: String::from(prompt),
        }
        .save(&db)?)
    }

    /// Creates a new slide.
    pub fn create(asset_id: i32, capsule_id: i32, prompt: &str) -> Result<NewSlide> {
        Ok(NewSlide {
            asset_id,
            capsule_id,
            prompt: String::from(prompt),
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

    /// get assets associated to this Slide
    pub fn get_assets(&self, db: &PgConnection) -> Result<Vec<Asset>> {
        Ok(AssetsObject::get_by_object(&db, self.id, AssetType::Slide)?)
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

    /// The asset associated to slide.
    pub asset: Asset,

    /// capsule id
    pub capsule_id: i32,

    /// The prompt text
    pub prompt: String,
}

impl SlideWithAsset {
    /// new Slide with associated asset
    pub fn new(slide: &Slide, db: &PgConnection) -> Result<SlideWithAsset> {
        Ok(SlideWithAsset {
            id: slide.id,
            asset: Asset::get(slide.asset_id, &db)?,
            capsule_id: slide.capsule_id,
            prompt: slide.prompt.clone(),
        })
    }

    /// getter function
    pub fn get_by_id(id: i32, db: &PgConnection) -> Result<SlideWithAsset> {
        use crate::schema::slides::dsl;

        let slide = dsl::slides.filter(dsl::id.eq(id)).first::<Slide>(db)?;

        Ok(SlideWithAsset {
            id: slide.id,
            asset: Asset::get(slide.asset_id, &db)?,
            capsule_id: slide.capsule_id,
            prompt: slide.prompt.clone(),
        })
    }

    /// delete a slide.
    /// TODO : Delete also linked asset ?
    pub fn delete(&self, db: &PgConnection) -> Result<usize> {
        let slide = Slide::get(self.id, &db)?;
        slide.delete(&db)
    }
}
