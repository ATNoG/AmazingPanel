CREATE TABLE `device_kinds` (
  `id` int(11) NOT NULL COMMENT 'universally unique id for device',
  `inventory_id` int(11) NOT NULL COMMENT 'the inventory when we caught this device type',
  `bus` varchar(16) DEFAULT NULL COMMENT 'e.g. pci or usb',
  `vendor` int(11) NOT NULL COMMENT 'id of vendor from /sys',
  `device` int(11) NOT NULL COMMENT 'id of device from /sys',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `device_ouis` (
  `oui` char(8) NOT NULL COMMENT 'OUI as string XX:XX:XX',
  `device_kind_id` int(11) NOT NULL COMMENT 'link to corresponding entry in device_kinds',
  `inventory_id` int(11) DEFAULT NULL COMMENT 'if generated automatically, id of inventory run, otherwise NULL'
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `device_tags` (
  `tag` varchar(64) NOT NULL COMMENT 'name for this tag',
  `device_kind_id` int(11) NOT NULL COMMENT 'link to corresponding entry in device_kinds',
  `inventory_id` int(11) DEFAULT NULL COMMENT 'if generated automatically, id of inventory run, otherwise NULL'
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `devices` (
  `id` int(11) NOT NULL COMMENT 'universally unique id for device',
  `device_kind_id` int(11) NOT NULL COMMENT 'link to corresponding entry in device_kinds',
  `motherboard_id` int(11) DEFAULT NULL COMMENT 'link to corresponding entry in motherboards',
  `inventory_id` int(11) NOT NULL COMMENT 'link to corresponding entry in inventories',
  `address` varchar(18) NOT NULL COMMENT 'bus address of this device.  MUST sort lexically by bus',
  `mac` varchar(17) DEFAULT NULL COMMENT 'MAC address of this device, if it is a network device',
  `canonical_name` varchar(64) DEFAULT NULL COMMENT 'a good guess as to the name Linux will give to this device',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `eds` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=latin1;

CREATE TABLE `experiments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ed_id` int(11) DEFAULT NULL,
  `resources_map_id` int(11) DEFAULT NULL,
  `start_at` datetime DEFAULT NULL,
  `duration` int(11) DEFAULT NULL,
  `status` int(11) DEFAULT NULL,
  `user_id` varchar(255) DEFAULT NULL,
  `phase_id` int(11) DEFAULT NULL,
  `project_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=latin1;

CREATE TABLE `inventories` (
  `id` int(11) NOT NULL COMMENT 'obligatiory unique id',
  `opened` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'start of inventory run',
  `closed` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' COMMENT 'end of inventory run, or 0000-etc. if not done yet',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `locations` (
  `id` int(11) NOT NULL COMMENT 'universally unique id for location',
  `name` varchar(64) DEFAULT NULL,
  `x` int(11) NOT NULL DEFAULT '0' COMMENT 'logical x address of location',
  `y` int(11) NOT NULL DEFAULT '0' COMMENT 'logical y address of location',
  `z` int(11) NOT NULL DEFAULT '0' COMMENT 'logical z address of location',
  `latitude` float DEFAULT NULL COMMENT 'latitude of this location or NULL',
  `longitude` float DEFAULT NULL COMMENT 'longitude of this location or NULL',
  `elevation` float DEFAULT NULL COMMENT 'elevation of this location or NULL',
  `testbed_id` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `motherboards` (
  `id` int(11) NOT NULL COMMENT 'universally unique id for motherboard',
  `inventory_id` int(11) NOT NULL COMMENT 'link to corresponding entry in inventories',
  `mfr_sn` varchar(128) DEFAULT NULL COMMENT 'manufacturer serial number of the motherboard',
  `cpu_type` varchar(64) DEFAULT NULL COMMENT 'name of CPU as given by vendor',
  `cpu_n` int(11) DEFAULT NULL COMMENT 'number of CPUs',
  `cpu_hz` float DEFAULT NULL COMMENT 'CPU speed in MHz',
  `hd_sn` varchar(64) DEFAULT NULL COMMENT 'hard drive serial number, NULL if no hd',
  `hd_size` int(11) DEFAULT NULL COMMENT 'hard disk size in bytes',
  `hd_status` tinyint(1) DEFAULT '1' COMMENT 'true means drive probably okay',
  `memory` int(11) DEFAULT NULL COMMENT 'memory size in bytes',
  PRIMARY KEY (`id`),
  UNIQUE KEY `mfr_sn` (`mfr_sn`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `nodes` (
  `id` int(11) NOT NULL COMMENT 'universally unique id for nodes',
  `control_ip` varchar(15) DEFAULT NULL,
  `control_mac` varchar(17) DEFAULT NULL,
  `hostname` varchar(64) DEFAULT NULL,
  `hrn` varchar(128) DEFAULT NULL,
  `inventory_id` int(11) NOT NULL COMMENT 'link to corresponding entry in inventories',
  `chassis_sn` varchar(64) DEFAULT NULL COMMENT 'manufacturer serial number of the chassis of the node; optionally null',
  `motherboard_id` int(11) NOT NULL COMMENT 'the motherboard in this node',
  `location_id` int(11) DEFAULT NULL COMMENT 'the location of this node',
  `pxeimage_id` int(11) DEFAULT NULL,
  `disk` varchar(32) DEFAULT '/dev/hdd',
  PRIMARY KEY (`id`),
  UNIQUE KEY `location_id` (`location_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `phases` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `number` int(11) DEFAULT NULL,
  `label` varchar(255) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=latin1;

CREATE TABLE `projects` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=latin1;

CREATE TABLE `projects_users` (
  `project_id` int(11) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `leader` tinyint(1) DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `pxeimages` (
  `id` int(11) DEFAULT NULL,
  `image_name` varchar(64) DEFAULT NULL,
  `short_description` varchar(128) DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `resources_maps` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `experiment_id` int(11) DEFAULT NULL,
  `node_id` int(11) DEFAULT NULL,
  `sys_image_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `testbed_id` int(11) DEFAULT NULL,
  `progress` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=28 DEFAULT CHARSET=latin1;

CREATE TABLE `schema_migrations` (
  `version` varchar(255) NOT NULL,
  UNIQUE KEY `unique_schema_migrations` (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `sys_images` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `sys_image_id` int(11) DEFAULT NULL,
  `size` int(11) DEFAULT NULL,
  `kernel_version_os` varchar(255) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `baseline` tinyint(1) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=latin1;

CREATE TABLE `testbeds` (
  `id` int(11) NOT NULL COMMENT 'universally unique id for testbed',
  `name` varchar(128) NOT NULL COMMENT 'example: grid',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `email` varchar(255) NOT NULL DEFAULT '',
  `encrypted_password` varchar(128) NOT NULL DEFAULT '',
  `password_salt` varchar(255) NOT NULL DEFAULT '',
  `reset_password_token` varchar(255) DEFAULT NULL,
  `remember_token` varchar(255) DEFAULT NULL,
  `remember_created_at` datetime DEFAULT NULL,
  `sign_in_count` int(11) DEFAULT '0',
  `current_sign_in_at` datetime DEFAULT NULL,
  `last_sign_in_at` datetime DEFAULT NULL,
  `current_sign_in_ip` varchar(255) DEFAULT NULL,
  `last_sign_in_ip` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `admin` tinyint(1) DEFAULT '0',
  `activated` tinyint(1) DEFAULT '0',
  `username` varchar(255) DEFAULT NULL,
  `intention` varchar(255) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_users_on_email` (`email`),
  UNIQUE KEY `index_users_on_reset_password_token` (`reset_password_token`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=latin1;

INSERT INTO schema_migrations (version) VALUES ('20101020093724');

INSERT INTO schema_migrations (version) VALUES ('20101020094826');

INSERT INTO schema_migrations (version) VALUES ('20101020161026');

INSERT INTO schema_migrations (version) VALUES ('20101024223126');

INSERT INTO schema_migrations (version) VALUES ('20101024223326');

INSERT INTO schema_migrations (version) VALUES ('20101104170029');

INSERT INTO schema_migrations (version) VALUES ('20101104171000');

INSERT INTO schema_migrations (version) VALUES ('20101109191505');

INSERT INTO schema_migrations (version) VALUES ('20101109192031');

INSERT INTO schema_migrations (version) VALUES ('20101117191554');

INSERT INTO schema_migrations (version) VALUES ('20101120171518');

INSERT INTO schema_migrations (version) VALUES ('20101122144414');

INSERT INTO schema_migrations (version) VALUES ('20101128181336');

INSERT INTO schema_migrations (version) VALUES ('20101128181523');

INSERT INTO schema_migrations (version) VALUES ('20101128185051');

INSERT INTO schema_migrations (version) VALUES ('20101206015756');

INSERT INTO schema_migrations (version) VALUES ('20101206020453');