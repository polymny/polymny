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
    projectname VARCHAR NOT NULL UNIQUE
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
  capsule_id SERIAL references capsules(id),
  project_id SERIAL references projects(id)
)
