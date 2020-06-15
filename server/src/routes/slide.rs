//! This module contains all the routes related to slides.

use diesel::ExpressionMethods;
use diesel::RunQueryDsl;

use rocket_contrib::json::{Json, JsonValue};

use crate::db::slide::{Slide, SlideWithAsset};
use crate::db::user::User;
use crate::schema::slides;
use crate::{Database, Result};

/// A struct to  update Slides
#[derive(Deserialize, AsChangeset, Debug)]
#[table_name = "slides"]
pub struct UpdateSlideForm {
    /// The asset associated to slide.
    pub asset_id: Option<i32>,

    /// capsule id
    pub capsule_id: Option<i32>,

    /// The prompt text.
    pub prompt: Option<String>,
}

/// The route to get a asset.
#[get("/slide/<id>")]
pub fn get_slide(db: Database, user: User, id: i32) -> Result<JsonValue> {
    let slide = user.get_slide_by_id(id, &db)?;
    Ok(json!(slide))
}

/// The route to get a asset.
#[put("/slide/<slide_id>", data = "<slide_form>")]
pub fn update_slide(
    db: Database,
    user: User,
    slide_id: i32,
    slide_form: Json<UpdateSlideForm>,
) -> Result<JsonValue> {
    user.get_slide_by_id(slide_id, &db)?;

    println!("slide info to update : {:#?}", slide_form);

    use crate::schema::slides::dsl::id;
    diesel::update(slides::table)
        .filter(id.eq(slide_id))
        .set(&slide_form.into_inner())
        .execute(&db.0)?;

    let slide = Slide::get(slide_id, &db)?;
    Ok(json!(SlideWithAsset::new(&slide, &db)?))
}
/// The route to get a asset.
#[put("/slide/<slide_id>/move", data = "<move_slide>")]
pub fn move_slide(
    db: Database,
    user: User,
    slide_id: i32,
    move_slide: Json<UpdateSlideForm>,
) -> Result<JsonValue> {
    let slide = user.get_slide_by_id(slide_id, &db)?;
    println!("Move slide : {:#?}", move_slide);

    use crate::schema::slides::dsl::id;
    diesel::update(slides::table)
        .filter(id.eq(slide_id))
        .set(&move_slide.into_inner())
        .execute(&db.0)?;

    Ok(json!(slide))
}
