table! {
    sessions (id) {
        id -> Int4,
        user_id -> Int4,
        secret -> Varchar,
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

joinable!(sessions -> users (user_id));

allow_tables_to_appear_in_same_query!(
    sessions,
    users,
);
