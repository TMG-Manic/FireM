CREATE TABLE IF NOT EXISTS `bungee_virtual_profiles` (
  `license` VARCHAR(60) NOT NULL,
  `bucket_id` INT(11) NOT NULL,
  `position` LONGTEXT DEFAULT NULL,
  `inventory` LONGTEXT DEFAULT NULL,
  `last_login` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`license`, `bucket_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;