-- Your SQL goes here
ALTER TABLE slides
ADD extra_id INT REFERENCES assets(id);


