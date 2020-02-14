-- Your SQL goes here

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR NOT NULL UNIQUE,
    email VARCHAR NOT NULL UNIQUE,
    hashed_password VARCHAR NOT NULL,
    activated BOOLEAN NOT NULL,
    activation_key VARCHAR
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

CREATE TABLE capsules (
    id SERIAL PRIMARY KEY,
    name  VARCHAR NOT NULL UNIQUE,
    title VARCHAR,
    slides VARCHAR,
    description TEXT
);

CREATE TABLE capsules_projects (
  id SERIAL PRIMARY KEY,
  capsule_id INT NOT NULL references capsules(id),
  project_id INT NOT NULL references projects(id)
);

CREATE TABLE assets (
    id SERIAL PRIMARY KEY,
    uuid UUID NOT NULL UNIQUE,
    name  VARCHAR NOT NULL,
    asset_path  VARCHAR NOT NULL UNIQUE,
    asset_type  VARCHAR NOT NULL,
    upload_date TIMESTAMP NOT NULL
);

CREATE TYPE asset_type AS ENUM ('project', 'capsule', 'gos', 'slide');

CREATE TABLE assets_objects (
    id SERIAL PRIMARY KEY,
    asset_id INT NOT NULL references assets(id),
    object_id INT NOT NULL,
    asset_type asset_type NOT NULL
);
