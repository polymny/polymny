-- This file should undo anything in `up.sql`
ALTER TABLE capsules DROP COLUMN active;

ALTER TABLE projects ADD CONSTRAINT projects_project_name_key UNIQUE (project_name);
ALTER TABLE capsules ADD CONSTRAINT capsules_name_key UNIQUE (name);
