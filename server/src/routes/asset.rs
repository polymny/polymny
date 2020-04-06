//! This module contains all the routes related to assets.

use rocket_contrib::json::JsonValue;

use crate::db::asset::Asset;
use crate::db::user::User;
use crate::{Database, Result};

/// The route to get a asset.
#[get("/asset/<id>")]
pub fn get_asset(db: Database, id: i32) -> Result<JsonValue> {
    // let (asset, projects) = Asset::get(id, &db)?;
    // Ok(json!({ "asset": asset, "projects": projects } ))
    let (asset, refs) = Asset::get_by_id(id, &db)?;
    Ok(json!({"asset": asset, "refs": refs}))
}

/// Get all the assets .
#[get("/assets")]
pub fn all_assets(db: Database, _user: User) -> Result<JsonValue> {
    Ok(json!({ "assets": Asset::all(&db)?}))
}

/// Delete a asset
#[delete("/asset/<id>")]
pub fn delete_asset(db: Database, _user: User, id: i32) -> Result<JsonValue> {
    let (asset, _) = Asset::get_by_id(id, &db)?;
    Ok(json!({ "nb assets deleted":
        asset.delete(&db)?}))
}
