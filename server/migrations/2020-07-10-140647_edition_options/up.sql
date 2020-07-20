-- Your SQL goes here
ALTER TABLE users
ADD edition_options JSON NOT NULL DEFAULT '{"with_video": true, "webcam_size": "Medium", "webcam_position": "BottomLeft"}';

ALTER TABLE capsules
ADD edition_options JSON NOT NULL DEFAULT '{"with_video": true, "webcam_size": "Medium", "webcam_position": "BottomLeft"}';

