-- Your SQL goes here

CREATE TYPE notification_style AS ENUM ('info', 'warning', 'error');

CREATE TABLE notifications (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users (id),
    title VARCHAR NOT NULL,
    content VARCHAR NOT NULL,
    style notification_style NOT NULL,
    read BOOLEAN NOT NULL DEFAULT false
)
