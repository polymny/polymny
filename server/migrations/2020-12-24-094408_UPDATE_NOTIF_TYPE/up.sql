-- Your SQL goes here


-- DROP TABLE IF EXISTS notification_style;
-- CREATE TYPE notification_style AS ENUM ('info','progress', 'warning', 'error');


-- ALTER TABLE notifications ALTER COLUMN style TYPE notification_style USING (notification_style::notification_style);

-- cf. https://stackoverflow.com/questions/1771543/adding-a-new-value-to-an-existing-enum-type
-- 1. rename the enum type you want to change
-- alter type some_enum_type rename to _some_enum_type;
-- 2. create new type
-- create type some_enum_type as enum ('old', 'values', 'and', 'new', 'ones');
-- 3. rename column(s) which uses our enum type
-- alter table some_table rename column some_column to _some_column;
-- 4. add new column of new type
-- alter table some_table add some_column some_enum_type not null default 'new';
-- 5. copy values to the new column
-- update some_table set some_column = _some_column::text::some_enum_type;
-- 6. remove old column and type
-- alter table some_table drop column _some_column;
-- drop type _some_enum_type;
-- 1. rename the enum type you want to change
alter type notification_style rename to _notification_style;
-- 2. create new type
create type notification_style as enum ('info','progress', 'warning', 'error');
-- 3. rename column(s) which uses our enum type
alter table notifications rename column style to _style;
-- 4. add new column of new type
alter table notifications add style notification_style not null default 'info';
-- 5. copy values to the new column
update notifications set style = _style::text::notification_style;
-- 6. remove old column and type
alter table notifications drop column _style;
drop type _notification_style;
