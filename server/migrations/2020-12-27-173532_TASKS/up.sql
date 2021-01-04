-- Your SQL goes here

CREATE TABLE tasks (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users (id),
    pid INT NOT NULL,
    content VARCHAR NOT NULL,
    progress float NOT NULL,
    state task_status  NOT NULL
);
