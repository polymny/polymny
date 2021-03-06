//! This module contains the structures to manipulate assets.
use std::result;

use serde::Serializer;

use uuid::Uuid;

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
#[derive(Identifiable, Queryable, Associations, PartialEq, Debug, Serialize)]
pub struct Asset {
    /// The id of the asset.
    pub id: i32,

    /// The uuid of the asset.
    pub uuid: Uuid,

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
    /// The uuid of the asset.
    pub uuid: Uuid,

    /// The (unique) name of the asset.
    pub name: String,

    /// The path to the asset.
    pub asset_path: String,

    /// The asset type.
    pub asset_type: String,

    /// Asset upload date
    pub upload_date: NaiveDateTime,
}

// This module is only here to allow missing docs on the generated type AssetTypeMapping.
#[allow(missing_docs)]
mod asset_type {
    /// The different possible types of assets.
    #[derive(Debug, PartialEq, Eq, DbEnum, Serialize)]
    pub enum AssetType {
        /// A project.
        Project,

        /// A capsule.
        Capsule,

        /// A group of slides.
        Gos,

        /// A slide.
        Slide,
    }
}

pub use asset_type::AssetTypeMapping as Asset_type;
pub use asset_type::{AssetType, AssetTypeMapping};

/// A link between a asset and an object.
#[derive(Identifiable, Queryable, Associations, PartialEq, Debug, Serialize)]
#[table_name = "assets_objects"]
#[belongs_to(Asset, foreign_key = "asset_id")]
pub struct AssetsObject {
    /// Id of the association.
    pub id: i32,

    /// Id of the associated asset.
    pub asset_id: i32,

    /// Id of the associated object
    pub object_id: i32,

    /// type of object (ie project, capsule, slide, etc ...)
    pub object_type: AssetType,
}

/// New link between an asset and an onhect.
#[derive(Insertable, Debug)]
#[table_name = "assets_objects"]
pub struct NewAssetsObject {
    /// Id of the associated asset.
    pub asset_id: i32,

    /// Id of the associated object.
    pub object_id: i32,

    /// type of object (ie project, capsule, slide, etc ...)
    pub object_type: AssetType,
}

impl Asset {
    /// Creates a new asset and stores it in the database.
    pub fn new(
        database: &PgConnection,
        uuid: Uuid,
        name: &str,
        asset_path: &str,
        asset_type: Option<&str>,
    ) -> Result<Asset> {
        let asset = NewAsset {
            uuid,
            name: String::from(name),
            asset_path: String::from(asset_path),
            asset_type: asset_type.unwrap_or("file").to_string(),
            upload_date: Utc::now().naive_utc(),
        }
        .save(&database)?;

        Ok(asset)
    }
    /// Creates a new asset.
    pub fn create(uuid: Uuid, name: &str, asset_path: &str) -> Result<NewAsset> {
        Ok(NewAsset {
            uuid,
            name: String::from(name),
            asset_path: String::from(asset_path),
            asset_type: "file".to_string(), //TODO: extact asse type from asset_path extension
            upload_date: Utc::now().naive_utc(),
        })
    }

    /// Gets a asset from its id.
    pub fn get_by_id(id: i32, db: &PgConnection) -> Result<(Asset, Vec<AssetsObject>)> {
        use crate::schema::assets::dsl;
        let asset = dsl::assets.filter(dsl::id.eq(id)).first::<Asset>(db)?;
        let refs = AssetsObject::belonging_to(&asset).load::<AssetsObject>(db)?;
        Ok((asset, refs))
    }

    /// Gets a asset from its id.
    pub fn get(id: i32, db: &PgConnection) -> Result<Asset> {
        use crate::schema::assets::dsl;
        let asset = dsl::assets.filter(dsl::id.eq(id)).first::<Asset>(db)?;
        Ok(asset)
    }

    /// Gets a asset from its name.
    pub fn get_by_name(name: &str, db: &PgConnection) -> Result<Asset> {
        use crate::schema::assets::dsl;
        let asset = dsl::assets.filter(dsl::name.eq(name)).first::<Asset>(db)?;

        Ok(asset)
    }
    /*
        /// Gets a asset from its name.
        pub fn assets_by_object(
            name: &str,
            object_id: i32,
            object_type: AssetType,
            db: &PgConnection,
        ) -> Result<Vec<(Asset, AssetsObject)>> {
            use crate::schema::assets::dsl as dsl_asset;
            use crate::schema::assets_objects::dsl as dsl_objects;
            Ok(dsl_asset::assets
                .inner_join(dsl_objects::assets_objects.filter(dsl_objects::asset_id.eq(dsl_asset::id)))
                .load(db)?)
        }
    */
    /// Retrieves all assets
    pub fn all(db: &PgConnection) -> Result<Vec<Asset>> {
        use crate::schema::assets::dsl;
        let assets = dsl::assets.load::<Asset>(db);
        Ok(assets?)
    }
    /// delete an asset.
    pub fn delete(&self, db: &PgConnection) -> Result<usize> {
        use crate::schema::assets::dsl;
        Ok(diesel::delete(assets::table)
            .filter(dsl::id.eq(self.id))
            .execute(db)?)
        // TODO: suppress asset reference in  assets_objects_ table
    }
}

impl AssetsObject {
    /// Creates a new asset and stores it in the database.
    pub fn new(
        database: &PgConnection,
        asset_id: i32,
        object_id: i32,
        object_type: AssetType,
    ) -> Result<AssetsObject> {
        Ok(NewAssetsObject {
            asset_id,
            object_id,
            object_type,
        }
        .save(&database)?)
    }

    /// Get asset with the object.
    pub fn get(db: &PgConnection, id: i32) -> Result<AssetsObject> {
        use crate::schema::assets_objects::dsl;
        Ok(dsl::assets_objects
            .filter(dsl::id.eq(id))
            .first::<AssetsObject>(db)?)
    }
    /// Get asset with the object.
    pub fn get_by_asset(db: &PgConnection, id: i32) -> Result<AssetsObject> {
        use crate::schema::assets_objects::dsl;
        Ok(dsl::assets_objects
            .filter(dsl::asset_id.eq(id))
            .first::<AssetsObject>(db)?)
    }

    /// Get asset with the object.
    pub fn get_by_object(
        db: &PgConnection,
        object_id: i32,
        object_type: AssetType,
    ) -> Result<Vec<Asset>> {
        let assets_ref = {
            use crate::schema::assets_objects::dsl;
            dsl::assets_objects
                .filter(dsl::object_id.eq(object_id))
                .filter(dsl::object_type.eq(object_type))
                .load::<AssetsObject>(db)?
        };
        println!("assets_ref = {:#?}", assets_ref);
        let mut assets = assets_ref
            .into_iter()
            .map(|x| Asset::get(x.asset_id, &db))
            .collect::<Result<Vec<Asset>>>()?;

        assets.sort_by(|a, b| b.upload_date.cmp(&a.upload_date));
        Ok(assets)
    }
    /// delete an asset.
    pub fn delete(&self, db: &PgConnection) -> Result<usize> {
        use crate::schema::assets_objects::dsl;
        Ok(diesel::delete(assets_objects::table)
            .filter(dsl::id.eq(self.id))
            .execute(db)?)
        // TODO: suppress asset reference in  assets_objects_ table
    }
    /// Get asset with the object.
    pub fn delete_by_object(
        db: &PgConnection,
        object_id: i32,
        object_type: AssetType,
    ) -> Result<usize> {
        let assets_ref = {
            use crate::schema::assets_objects::dsl;
            dsl::assets_objects
                .filter(dsl::object_id.eq(object_id))
                .filter(dsl::object_type.eq(object_type))
                .load::<AssetsObject>(db)?
        };

        for aref in assets_ref {
            let asset = Asset::get(aref.asset_id, &db)?;
            aref.delete(&db)?;
            asset.delete(&db)?;
        }
        // TODO: return what ?
        Ok(0)
    }
}

impl NewAsset {
    /// Saves a new asset into the database.
    pub fn save(&self, database: &PgConnection) -> Result<Asset> {
        Ok(diesel::insert_into(assets::table)
            .values(self)
            .get_result(database)?)
    }
}

impl NewAssetsObject {
    /// Saves a new asset object into the database.
    pub fn save(&self, database: &PgConnection) -> Result<AssetsObject> {
        Ok(diesel::insert_into(assets_objects::table)
            .values(self)
            .get_result(database)?)
    }
}
