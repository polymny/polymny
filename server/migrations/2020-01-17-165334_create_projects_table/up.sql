-- Your SQL goes here
CREATE TABLE projects (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users (id),
    projectname VARCHAR NOT NULL UNIQUE
);

