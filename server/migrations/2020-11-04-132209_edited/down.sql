-- This file should undo anything in `up.sql`
ALTER TYPE task_status RENAME TO published_type;
ALTER TYPE published_type RENAME VALUE 'idle' TO 'not_published';
ALTER TYPE published_type RENAME VALUE 'running' TO 'publishing';
ALTER TYPE published_type RENAME VALUE 'done' TO 'published';
