table! {
    use diesel::sql_types::*;
    use crate::db::asset::*;
    use crate::db::capsule::*;

    assets (id) {
        id -> Int4,
        uuid -> Uuid,
        name -> Varchar,
        asset_path -> Varchar,
        asset_type -> Varchar,
        upload_date -> Timestamp,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::db::asset::*;
    use crate::db::capsule::*;

    assets_objects (id) {
        id -> Int4,
        asset_id -> Int4,
        object_id -> Int4,
        object_type -> Asset_type,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::db::asset::*;
    use crate::db::capsule::*;

    capsules (id) {
        id -> Int4,
        name -> Varchar,
        title -> Varchar,
        slide_show_id -> Nullable<Int4>,
        description -> Text,
        background_id -> Nullable<Int4>,
        logo_id -> Nullable<Int4>,
        video_id -> Nullable<Int4>,
        structure -> Json,
        published -> Published_type,
        edition_options -> Json,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::db::asset::*;
    use crate::db::capsule::*;

    capsules_projects (id) {
        id -> Int4,
        capsule_id -> Int4,
        project_id -> Int4,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::db::asset::*;
    use crate::db::capsule::*;

    projects (id) {
        id -> Int4,
        user_id -> Int4,
        project_name -> Varchar,
        last_visited -> Timestamp,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::db::asset::*;
    use crate::db::capsule::*;

    sessions (id) {
        id -> Int4,
        user_id -> Int4,
        secret -> Varchar,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::db::asset::*;
    use crate::db::capsule::*;

    slides (id) {
        id -> Int4,
        asset_id -> Int4,
        capsule_id -> Int4,
        prompt -> Text,
    }
}

table! {
    use diesel::sql_types::*;
    use crate::db::asset::*;
    use crate::db::capsule::*;

    users (id) {
        id -> Int4,
        username -> Varchar,
        email -> Varchar,
        secondary_email -> Nullable<Varchar>,
        hashed_password -> Varchar,
        activated -> Bool,
        activation_key -> Nullable<Varchar>,
        reset_password_key -> Nullable<Varchar>,
        edition_options -> Json,
    }
}

joinable!(assets_objects -> assets (asset_id));
joinable!(capsules_projects -> capsules (capsule_id));
joinable!(capsules_projects -> projects (project_id));
joinable!(projects -> users (user_id));
joinable!(sessions -> users (user_id));
joinable!(slides -> assets (asset_id));
joinable!(slides -> capsules (capsule_id));

allow_tables_to_appear_in_same_query!(
    assets,
    assets_objects,
    capsules,
    capsules_projects,
    projects,
    sessions,
    slides,
    users,
);
