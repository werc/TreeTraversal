-- --------------------------------------------------------------------------------
-- Routine DDL
-- Note: comments before and after the routine body will not be stored by the server
-- --------------------------------------------------------------------------------
DELIMITER $$

CREATE PROCEDURE `r_return_tree`(

  IN pedited INT,
  IN plang CHAR(2)

)
BEGIN
-- Mostly for HTML select boxes
	
  IF pedited IS NULL THEN

    SELECT n.node_id,
      CONCAT( REPEAT(' . . ', COUNT(CAST(p.node_id AS CHAR)) - 1), 
      (SELECT name FROM tree_content WHERE node_id = n.node_id AND lang = plang)) AS name
    FROM tree_map AS n, tree_map AS p
    WHERE (n.lft BETWEEN p.lft AND p.rgt)
    GROUP BY node_id
    ORDER BY n.lft;

  ELSE

    SELECT n.node_id,
      CONCAT( REPEAT(' . . ', COUNT(CAST(p.node_id AS CHAR)) - 1), 
      (SELECT name FROM tree_content WHERE node_id = n.node_id AND lang = plang)) AS name
    FROM tree_map AS n, tree_map AS p
    WHERE (n.lft BETWEEN p.lft AND p.rgt) AND n.node_id != pedited
    GROUP BY node_id
    ORDER BY n.lft;

  END IF;
       
END