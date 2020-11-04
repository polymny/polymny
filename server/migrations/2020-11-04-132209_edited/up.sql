-- Your SQL goes here
ALTER TYPE published_type RENAME TO task_status;
ALTER TYPE task_status RENAME VALUE 'not_published' TO 'idle';
ALTER TYPE task_status RENAME VALUE 'publishing' TO 'running';
ALTER TYPE task_status RENAME VALUE 'published' TO 'done';

ALTER TABLE capsules ADD edited task_status NOT NULL DEFAULT 'idle';

UPDATE capsules SET edited = 'done' WHERE video_id IS NOT NULL;
