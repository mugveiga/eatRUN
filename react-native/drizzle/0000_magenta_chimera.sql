CREATE TABLE `foods` (
	`id` text PRIMARY KEY NOT NULL,
	`updated_at` integer NOT NULL,
	`deleted_at` integer,
	`sync_status` text DEFAULT 'pending' NOT NULL,
	`user_id` text,
	`name` text NOT NULL,
	`photo_uri` text,
	`carbs_grams` integer DEFAULT 0 NOT NULL,
	`sodium_mg` integer DEFAULT 0 NOT NULL,
	`caffeine_mg` integer DEFAULT 0 NOT NULL,
	`notes` text
);
--> statement-breakpoint
CREATE TABLE `plan_items` (
	`id` text PRIMARY KEY NOT NULL,
	`updated_at` integer NOT NULL,
	`deleted_at` integer,
	`sync_status` text DEFAULT 'pending' NOT NULL,
	`user_id` text,
	`plan_id` text NOT NULL,
	`food_id` text NOT NULL,
	`offset_length` real NOT NULL,
	`quantity` real DEFAULT 1 NOT NULL,
	FOREIGN KEY (`plan_id`) REFERENCES `plans`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`food_id`) REFERENCES `foods`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE TABLE `plans` (
	`id` text PRIMARY KEY NOT NULL,
	`updated_at` integer NOT NULL,
	`deleted_at` integer,
	`sync_status` text DEFAULT 'pending' NOT NULL,
	`user_id` text,
	`name` text NOT NULL,
	`date` integer NOT NULL,
	`activity_type` text NOT NULL,
	`distance_km` real NOT NULL,
	`duration_minutes` integer NOT NULL,
	`target_carbs_per_hour` real DEFAULT 0 NOT NULL,
	`target_sodium_per_hour` real DEFAULT 0 NOT NULL,
	`target_caffeine_per_hour` real DEFAULT 0 NOT NULL,
	`plan_type` text,
	`intake_interval` real,
	`comments` text
);
