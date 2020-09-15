-- Your SQL goes here
ALTER TABLE capsules ADD active BOOLEAN NOT NULL DEFAULT true;

ALTER TABLE projects DROP CONSTRAINT projects_project_name_key;
ALTER TABLE capsules DROP CONSTRAINT capsules_name_key;
