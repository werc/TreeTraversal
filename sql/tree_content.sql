CREATE TABLE `tree_content` (
  `id` mediumint(8) unsigned NOT NULL AUTO_INCREMENT,
  `node_id` smallint(5) unsigned NOT NULL,
  `lang` char(2) NOT NULL DEFAULT 'en',
  `name` varchar(45) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO `tree_content` (`node_id`,`name`) VALUES (1,'Home');
