CREATE TABLE `assets` (
	`id` text PRIMARY KEY NOT NULL,
	`record_json` text NOT NULL,
	`updated_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL
);
