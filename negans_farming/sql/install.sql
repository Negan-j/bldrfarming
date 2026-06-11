CREATE TABLE IF NOT EXISTS `negans_farming_xp` (
    `citizenid` varchar(64) NOT NULL,
    `xp` int(11) NOT NULL DEFAULT 0,
    `reputation` int(11) NOT NULL DEFAULT 0,
    `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
    PRIMARY KEY (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `negans_farming_recipes` (
    `citizenid` varchar(64) NOT NULL,
    `recipe` varchar(64) NOT NULL,
    `discovered_at` timestamp NOT NULL DEFAULT current_timestamp(),
    PRIMARY KEY (`citizenid`, `recipe`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `negans_farming_order_progress` (
    `citizenid` varchar(64) NOT NULL,
    `order_key` varchar(96) NOT NULL,
    `sold` int(11) NOT NULL DEFAULT 0,
    `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
    PRIMARY KEY (`citizenid`, `order_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
