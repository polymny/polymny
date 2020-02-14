pub use crate::generated_schema::*;

table! {
    use diesel::types::Int4;
    use crate::db::asset::AssetTypeMapping;
    assets_objects (id) {
        id -> Int4,
        asset_id -> Int4,
        object_id -> Int4,
        asset_type -> AssetTypeMapping,
    }
}
