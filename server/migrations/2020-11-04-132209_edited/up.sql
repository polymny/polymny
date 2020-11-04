-- Your SQL goes here
ALTER TYPE published_type RENAME TO task_status;
ALTER TYPE task_status RENAME VALUE 'not_published' TO 'idle';
ALTER TYPE task_status RENAME VALUE 'publishing' TO 'running';
ALTER TYPE task_status RENAME VALUE 'published' TO 'done';
