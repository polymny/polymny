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

