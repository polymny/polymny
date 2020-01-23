-- Your SQL goes here
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
