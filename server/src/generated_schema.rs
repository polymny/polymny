table! {
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
    }
}

table! {
    capsules_projects (id) {
        id -> Int4,
        capsule_id -> Int4,
        project_id -> Int4,
    }
}

table! {
    projects (id) {
        id -> Int4,
        user_id -> Int4,
        project_name -> Varchar,
        last_visited -> Timestamp,
    }
}

table! {
    sessions (id) {
        id -> Int4,
        user_id -> Int4,
        secret -> Varchar,
    }
}

table! {
    slides (id) {
        id -> Int4,
        asset_id -> Int4,
        capsule_id -> Int4,
        prompt -> Text,
    }
}

table! {
    users (id) {
        id -> Int4,
        username -> Varchar,
        email -> Varchar,
        hashed_password -> Varchar,
        activated -> Bool,
        activation_key -> Nullable<Varchar>,
    }
}

joinable!(capsules_projects -> capsules (capsule_id));
joinable!(capsules_projects -> projects (project_id));
joinable!(projects -> users (user_id));
joinable!(sessions -> users (user_id));
joinable!(slides -> assets (asset_id));
joinable!(slides -> capsules (capsule_id));

allow_tables_to_appear_in_same_query!(
    assets,
    capsules,
    capsules_projects,
    projects,
    sessions,
    slides,
    users,
);
