//! This module contains the structures to manipulate assets.
use std::result;

use serde::Serializer;

use diesel::pg::PgConnection;
use diesel::prelude::*;
use diesel::RunQueryDsl;

use chrono::{NaiveDateTime, Utc};

use crate::schema::{assets, assets_objects};
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


/// A asset of preparation
#[derive(Identifiable, Queryable, PartialEq, Debug, Serialize)]
pub struct Asset {
    /// The id of the asset.
    pub id: i32,

    /// The (unique) name of the asset.
    pub name: String,

    /// The path to the asset.
    pub asset_path: String,

    /// The asset type.
    pub asset_type: String,

    /// Asset upload date
    #[serde(serialize_with = "serialize_naive_date_time")]
    pub upload_date: NaiveDateTime,

}

/// A asset that isn't stored into the database yet.
#[derive(Debug, Insertable)]
#[table_name = "assets"]
pub struct NewAsset {
    /// The (unique) name of the asset.
    pub name: String,

    /// The path to the asset.
    pub asset_path: String,

    /// The asset type.
    pub asset_type: String,

    /// Asset upload date
    pub upload_date: NaiveDateTime,

}

/// A link between a asset and an object.
#[derive(Identifiable, Queryable, Associations, Debug)]
#[table_name = "assets_objects"]
#[belongs_to(Asset)]
pub struct AssetObject {
    /// Id of the association.
    pub id: i32,

    /// Id of the associated asset.
    pub asset_id: i32,

    /// Id of the associated object
    pub object_id: i32,

    /// type of object (ie project, capsule, slide, etc ...)
    pub object: String,
}

/// New link between an asset and an onhect.
#[derive(Insertable, Debug)]
#[table_name = "assets_objects"]
pub struct NewAssetObject {
    /// Id of the associated asset.
    pub asset_id: i32,

    /// Id of the associated object.
    pub object_id: i32,

    /// type of object (ie project, capsule, slide, etc ...)
    pub object: String,
}

impl Asset {
    /// Creates a new asset and stores it in the database.
    pub fn new(
        database: &PgConnection,
        name: &str,
        asset_path: &str,
    ) -> Result<Asset> {
        let asset = NewAsset {
            name: String::from(name),
            asset_path: String::from(asset_path),
            asset_type: "file".to_string(), //TODO: extact asse type from asset_path extension
            upload_date: Utc::now().naive_utc(),
        }
        .save(&database)?;

        Ok(asset)
    }
    /// Creates a new asset.
    pub fn create(
        name: &str,
        asset_path: &str,
    ) -> Result<NewAsset> {
        Ok(NewAsset {
            name: String::from(name),
            asset_path: String::from(asset_path),
            asset_type: "file".to_string(), //TODO: extact asse type from asset_path extension
            upload_date: Utc::now().naive_utc(),
        })
    }

    /// Gets a asset from its id.
    pub fn get(id: i32, db: &PgConnection) -> Result<Asset> {
        use crate::schema::assets::dsl;
        let asset = dsl::assets.filter(dsl::id.eq(id)).first::<Asset>(db);
        Ok(asset?)
    }
    /// Gets a asset from its name.
    pub fn get_by_name(name: &str, db: &PgConnection) -> Result<Asset> {
        use crate::schema::assets::dsl;
        let asset = dsl::assets
            .filter(dsl::name.eq(name))
            .first::<Asset>(db);
        // TODO: is "?" needed
        Ok(asset?)
    }
}

impl AssetObject {
}

impl NewAsset {
    /// Saves a new asset into the database.
    pub fn save(&self, database: &PgConnection) -> Result<Asset> {
        Ok(diesel::insert_into(assets::table)
            .values(self)
            .get_result(database)?)
    }
}

impl NewAssetObject {
    /// Saves a new asset object into the database.
    pub fn save(&self, database: &PgConnection) -> Result<AssetObject> {
        Ok(diesel::insert_into(assets_objects::table)
            .values(self)
            .get_result(database)?)
    }
}
