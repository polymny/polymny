//! This module contains all the routes related to GOS (Group of slides).

use diesel::ExpressionMethods;
use diesel::RunQueryDsl;

use rocket::http::Cookies;
use rocket::request::Form;

use rocket_contrib::json::JsonValue;

use crate::db::gos::Gos;
use crate::db::user::User;
use crate::schema::goss;
use crate::{Database, Result};

/// A struct for GOS update
#[derive(FromForm, AsChangeset, Debug)]
#[table_name = "goss"]
pub struct UpdateGosForm {
    /// The position of the gos in capsule.
    pub position: Option<i32>,

    /// The capsule associated to gos.
    pub capsule_id: Option<i32>,
}

/// The route to get a asset.
#[get("/gos/<id>")]
pub fn get_gos(db: Database, mut cookies: Cookies, id: i32) -> Result<JsonValue> {
    let cookie = cookies.get_private("EXAUTH");
    let _user = User::from_session(cookie.unwrap().value(), &db)?;
    let gos = Gos::get(id, &db)?;
    Ok(json!(gos))
}

/// Update a  GOS
#[put("/gos/<gos_id>", data = "<gos_form>")]
pub fn update_gos(
    db: Database,
    mut cookies: Cookies,
    gos_id: i32,
    gos_form: Form<UpdateGosForm>,
) -> Result<JsonValue> {
    let cookie = cookies.get_private("EXAUTH");
    let _user = User::from_session(cookie.unwrap().value(), &db)?;

    use crate::schema::goss::dsl::id;
    diesel::update(goss::table)
        .filter(id.eq(gos_id))
        .set(&gos_form.into_inner())
        .execute(&db.0)?;

    Ok(json!({ "gos": Gos::get(gos_id, &db)? }))
}

/// Delete a GOS
#[delete("/gos/<id>")]
pub fn delete_gos(db: Database, mut cookies: Cookies, id: i32) -> Result<JsonValue> {
    let cookie = cookies.get_private("EXAUTH");
    let _user = User::from_session(cookie.unwrap().value(), &db)?;
    let gos = Gos::get(id, &db)?;
    Ok(json!({ "nb GOS deleted":
        gos.delete(&db)?}))
}
