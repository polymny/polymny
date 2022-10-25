CREATE TYPE plan AS ENUM ('free', 'premium_lvl1', 'admin');

CREATE TYPE task_status AS ENUM ('idle', 'running', 'done');

CREATE TYPE role AS ENUM ('read', 'write', 'owner');

CREATE TYPE privacy AS ENUM ('public', 'unlisted', 'private');

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR NOT NULL UNIQUE,
    email VARCHAR NOT NULL UNIQUE,
    secondary_email VARCHAR,
    hashed_password VARCHAR NOT NULL,
    activated BOOL NOT NULL,
    activation_key VARCHAR UNIQUE,
    secondary_email_key VARCHAR UNIQUE,
    reset_password_key VARCHAR UNIQUE,
    unsubscribe_key VARCHAR UNIQUE,
    plan plan NOT NULL,
    disk_quota INT NOT NULL
);

CREATE TABLE capsules (
    id SERIAL PRIMARY KEY,
    project VARCHAR NOT NULL,
    name VARCHAR NOT NULL,
    video_uploaded task_status NOT NULL,
    video_uploaded_pid INT,
    produced task_status NOT NULL,
    production_pid INT,
    published task_status NOT NULL,
    publication_pid INT,
    privacy privacy NOT NULL,
    prompt_subtitles BOOL NOT NULL,
    structure JSON NOT NULL,
    last_modified TIMESTAMP NOT NULL,
    disk_usage INT NOT NULL
);

CREATE TABLE capsules_users_join (
    id SERIAL PRIMARY KEY,
    capsules_id INT NOT NULL REFERENCES capsules (id) ON DELETE CASCADE,
    users_id INT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    role role NOT NULL
);

CREATE TABLE notifications (
    id SERIAL PRIMARY KEY,
    title VARCHAR NOT NULL,
    content VARCHAR NOT NULL,
    read BOOL NOT NULL,
    owner INT NOT NULL REFERENCES users (id) ON DELETE CASCADE
);

CREATE TABLE sessions (
    id SERIAL PRIMARY KEY,
    secret VARCHAR NOT NULL UNIQUE,
    owner INT NOT NULL REFERENCES users (id) ON DELETE CASCADE
);
