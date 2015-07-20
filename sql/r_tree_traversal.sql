-- --------------------------------------------------------------------------------
-- Routine DDL
-- Note: comments before and after the routine body will not be stored by the server
-- --------------------------------------------------------------------------------
DELIMITER $$

CREATE PROCEDURE `r_tree_traversal`(

  IN ptask_type VARCHAR(10),
  IN pnode_id INT,
  IN pparent_id INT

)
BEGIN

/*The MIT License (MIT)

Copyright (c) 2015 Tomas Stryja

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

  DECLARE new_lft, new_rgt, width, has_leafs, superior, superior_parent, old_lft, old_rgt, parent_rgt, subtree_size SMALLINT;

  CASE ptask_type

    WHEN 'insert' THEN

        SELECT rgt INTO new_lft FROM tree_map WHERE node_id = pparent_id;
        UPDATE tree_map SET rgt = rgt + 2 WHERE rgt >= new_lft;
        UPDATE tree_map SET lft = lft + 2 WHERE lft > new_lft;
        INSERT INTO tree_map (lft, rgt, parent_id) VALUES (new_lft, (new_lft + 1), pparent_id);
		SELECT LAST_INSERT_ID();

    WHEN 'delete' THEN

        SELECT lft, rgt, (rgt - lft), (rgt - lft + 1), parent_id 
		  INTO new_lft, new_rgt, has_leafs, width, superior_parent 
		  FROM tree_map WHERE node_id = pnode_id;

		DELETE FROM tree_content WHERE node_id = pnode_id;

        IF (has_leafs = 1) THEN
          DELETE FROM tree_map WHERE lft BETWEEN new_lft AND new_rgt;
          UPDATE tree_map SET rgt = rgt - width WHERE rgt > new_rgt;
          UPDATE tree_map SET lft = lft - width WHERE lft > new_rgt;
        ELSE
          DELETE FROM tree_map WHERE lft = new_lft;
          UPDATE tree_map SET rgt = rgt - 1, lft = lft - 1, parent_id = superior_parent 
		   WHERE lft BETWEEN new_lft AND new_rgt;
          UPDATE tree_map SET rgt = rgt - 2 WHERE rgt > new_rgt;
          UPDATE tree_map SET lft = lft - 2 WHERE lft > new_rgt;
        END IF;

    WHEN 'move' THEN
    
		IF (pnode_id != pparent_id) THEN
        CREATE TEMPORARY TABLE IF NOT EXISTS working_tree_map
        (
          `node_id` smallint(5) unsigned NOT NULL AUTO_INCREMENT,
          `lft` smallint(5) unsigned DEFAULT NULL,
          `rgt` smallint(5) unsigned DEFAULT NULL,
          `parent_id` smallint(5) unsigned NOT NULL,
          PRIMARY KEY (`node_id`)
        );
        
		-- put subtree into temporary table
        INSERT INTO working_tree_map (node_id, lft, rgt, parent_id)
			 SELECT t1.node_id, 
					(t1.lft - (SELECT MIN(lft) FROM tree_map WHERE node_id = pnode_id)) AS lft,
					(t1.rgt - (SELECT MIN(lft) FROM tree_map WHERE node_id = pnode_id)) AS rgt,
					t1.parent_id
			   FROM tree_map AS t1, tree_map AS t2
			  WHERE t1.lft BETWEEN t2.lft AND t2.rgt 
				AND t2.node_id = pnode_id;

        DELETE FROM tree_map WHERE node_id IN (SELECT node_id FROM working_tree_map);

        SELECT rgt INTO parent_rgt FROM tree_map WHERE node_id = pparent_id;
        SET subtree_size = (SELECT (MAX(rgt) + 1) FROM working_tree_map);
		
		-- make a gap in the tree
        UPDATE tree_map
          SET lft = (CASE WHEN lft > parent_rgt THEN lft + subtree_size ELSE lft END),
              rgt = (CASE WHEN rgt >= parent_rgt THEN rgt + subtree_size ELSE rgt END)
        WHERE rgt >= parent_rgt;

        INSERT INTO tree_map (node_id, lft, rgt, parent_id)
             SELECT node_id, lft + parent_rgt, rgt + parent_rgt, parent_id
               FROM working_tree_map;
        
		-- close gaps in tree
        UPDATE tree_map
           SET lft = (SELECT COUNT(*) FROM vw_lftrgt AS v WHERE v.lft <= tree_map.lft),
               rgt = (SELECT COUNT(*) FROM vw_lftrgt AS v WHERE v.lft <= tree_map.rgt);
        
        DELETE FROM working_tree_map;
        UPDATE tree_map SET parent_id = pparent_id WHERE node_id = pnode_id;
		END IF;

    WHEN 'order' THEN

        SELECT lft, rgt, (rgt - lft + 1), parent_id INTO old_lft, old_rgt, width, superior
          FROM tree_map WHERE node_id = pnode_id;

        -- is parent 
        SELECT parent_id INTO superior_parent FROM tree_map WHERE node_id = pparent_id;

        IF (superior = superior_parent) THEN
          SELECT (rgt + 1) INTO new_lft FROM tree_map WHERE node_id = pparent_id;
        ELSE
          SELECT (lft + 1) INTO new_lft FROM tree_map WHERE node_id = pparent_id;
        END IF;

	    IF (new_lft != old_lft) THEN
		  CREATE TEMPORARY TABLE IF NOT EXISTS working_tree_map
        (
          `node_id` smallint(5) unsigned NOT NULL AUTO_INCREMENT,
          `lft` smallint(5) unsigned DEFAULT NULL,
          `rgt` smallint(5) unsigned DEFAULT NULL,
          `parent_id` smallint(5) unsigned NOT NULL,
          PRIMARY KEY (`node_id`)
        );

	     INSERT INTO working_tree_map (node_id, lft, rgt, parent_id)
            SELECT t1.node_id,
			  	   (t1.lft - (SELECT MIN(lft) FROM tree_map WHERE node_id = pnode_id)) AS lft,
				   (t1.rgt - (SELECT MIN(lft) FROM tree_map WHERE node_id = pnode_id)) AS rgt,
				   t1.parent_id
			  FROM tree_map AS t1, tree_map AS t2
			 WHERE t1.lft BETWEEN t2.lft AND t2.rgt AND t2.node_id = pnode_id;
            
       DELETE FROM tree_map WHERE node_id IN (SELECT node_id FROM working_tree_map);

       IF(new_lft < old_lft) THEN -- move up
          UPDATE tree_map SET lft = lft + width WHERE lft >= new_lft AND lft < old_lft;
          UPDATE tree_map SET rgt = rgt + width WHERE rgt > new_lft AND rgt < old_rgt;
          UPDATE working_tree_map SET lft = new_lft + lft, rgt = new_lft + rgt;
       END IF;

       IF(new_lft > old_lft) THEN -- move down
            UPDATE tree_map SET lft = lft - width WHERE lft > old_lft AND lft < new_lft;
            UPDATE tree_map SET rgt = rgt - width WHERE rgt > old_rgt AND rgt < new_lft;
            UPDATE working_tree_map SET lft = (new_lft - width) + lft, rgt = (new_lft - width) + rgt;
       END IF;

       INSERT INTO tree_map (node_id, lft, rgt, parent_id)
            SELECT node_id, lft, rgt, parent_id
              FROM working_tree_map;
            
       DELETE FROM working_tree_map;
	   END IF;
  END CASE;

END