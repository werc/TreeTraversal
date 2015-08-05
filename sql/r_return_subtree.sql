-- --------------------------------------------------------------------------------
-- Routine DDL
-- Note: comments before and after the routine body will not be stored by the server
-- --------------------------------------------------------------------------------
DELIMITER $$

CREATE DEFINER=`root`@`localhost` PROCEDURE `r_return_subtree`(

  IN pnode_id INT,
  IN plang CHAR(2)

)
BEGIN

  SELECT node.node_id, 
		     (COUNT(parent.node_id) - (sub_tree.depth + 1)) AS depth,
		     (SELECT name FROM tree_content WHERE node_id = node.node_id AND lang = plang) AS name
    FROM tree_map AS node,
         tree_map AS parent,
         tree_map AS sub_parent,
  (SELECT node.node_id, (COUNT(parent.node_id) - 1) AS depth
    FROM tree_map AS node,
		     tree_map AS parent
	 WHERE node.lft BETWEEN parent.lft AND parent.rgt
		 AND node.node_id = pnode_id
	 GROUP BY node.node_id
	 ORDER BY node.lft) AS sub_tree
   WHERE node.lft BETWEEN parent.lft AND parent.rgt
	   AND node.lft BETWEEN sub_parent.lft AND sub_parent.rgt
	   AND sub_parent.node_id = sub_tree.node_id
   GROUP BY node.node_id
   ORDER BY node.lft;

END