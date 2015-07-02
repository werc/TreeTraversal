CREATE TABLE `tree_map` (
  `node_id` smallint(5) unsigned NOT NULL AUTO_INCREMENT,
  `lft` smallint(5) unsigned NOT NULL,
  `rgt` smallint(5) unsigned NOT NULL,
  `parent_id` smallint(5) unsigned NOT NULL,
  PRIMARY KEY (`node_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO `tree_map` (`node_id`,`lft`,`rgt`,`parent_id`) VALUES (1, 1, 2, 0);       
