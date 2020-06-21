-- Your SQL goes here

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR NOT NULL UNIQUE,
    email VARCHAR NOT NULL UNIQUE,
    secondary_email VARCHAR,
    hashed_password VARCHAR NOT NULL,
    activated BOOLEAN NOT NULL,
    activation_key VARCHAR,
    reset_password_key VARCHAR
);

CREATE TABLE sessions (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users (id),
    secret VARCHAR NOT NULL
);

CREATE TABLE projects (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users (id),
    project_name VARCHAR NOT NULL UNIQUE,
    last_visited TIMESTAMP NOT NULL
);

CREATE TABLE assets (
    id SERIAL PRIMARY KEY,
    uuid UUID NOT NULL UNIQUE,
    name VARCHAR NOT NULL,
    asset_path VARCHAR NOT NULL UNIQUE,
    asset_type VARCHAR NOT NULL,
    upload_date TIMESTAMP NOT NULL
);

CREATE TABLE capsules (
    id SERIAL PRIMARY KEY,
    name VARCHAR NOT NULL UNIQUE,
    title VARCHAR NOT NULL ,
    slide_show_id INT REFERENCES assets(id),
    description TEXT NOT NULL,
    background_id INT REFERENCES assets(id),
    logo_id INT REFERENCES assets(id),
    video_id INT REFERENCES assets(id),
    structure JSON NOT NULL
);

CREATE TABLE capsules_projects (
    id SERIAL PRIMARY KEY,
    capsule_id INT NOT NULL references capsules(id),
    project_id INT NOT NULL references projects(id)
);

CREATE TYPE asset_type AS ENUM ('project', 'capsule', 'slide');

CREATE TABLE assets_objects (
    id SERIAL PRIMARY KEY,
    asset_id INT NOT NULL references assets(id),
    object_id INT NOT NULL,
    object_type asset_type NOT NULL
);

CREATE TABLE slides (
    id SERIAL PRIMARY KEY,
    asset_id INT NOT NULL references assets(id),
    capsule_id INT NOT NULL references capsules(id),
    prompt TEXT NOT NULL
);
