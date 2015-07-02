CREATE VIEW `vw_lftrgt` AS select `tree_map`.`lft` AS `lft` from `tree_map` union select `tree_map`.`rgt` AS `rgt` from `tree_map`;
