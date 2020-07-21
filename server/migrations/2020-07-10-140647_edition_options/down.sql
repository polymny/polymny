-- This file should undo anything in `up.sql`

ALTER TABLE users DROP COLUMN edition_options;

ALTER TABLE capsules DROP COLUMN edition_options;

ALTER TABLE slides DROP COLUMN extra_id;
