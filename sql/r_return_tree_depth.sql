-- --------------------------------------------------------------------------------
-- Routine DDL
-- Note: comments before and after the routine body will not be stored by the server
-- --------------------------------------------------------------------------------
DELIMITER $$

CREATE DEFINER=`root`@`localhost` PROCEDURE `r_return_tree_depth`(

  IN plang CHAR(2)

)
BEGIN

  SELECT node.node_id, (COUNT(parent.node_id) - 1) AS depth,
 (SELECT name FROM tree_content WHERE node_id = node.node_id AND lang = plang) AS name
    FROM tree_map AS node, tree_map AS parent
   WHERE node.lft BETWEEN parent.lft AND parent.rgt
   GROUP BY node.node_id
   ORDER BY node.lft;

END