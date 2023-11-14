USE SmartHomeDB;

-- Security stuff
-- Role based access seems most fitting for this kind of database

CREATE ROLE 'admin_role';
CREATE ROLE 'owner_role';
CREATE ROLE 'family_role';
CREATE ROLE 'guest_role';

GRANT 'admin_role' TO 'admin_user'@'localhost';
GRANT 'owner_role' TO 'owner_user'@'localhost';
GRANT 'family_role' TO 'family_user'@'localhost';
GRANT 'guest_role' TO 'guest_user'@'localhost';

-- Manipulation of the database will be handled by procedures alone
REVOKE INSERT, UPDATE, DELETE ON SmartHomeDB.Device FROM 'admin_role', 'owner_role', 'family_role', 'guest_role';

-- Block for granting permission to use certain procedures to specific roles

-- Note apparently even if the user isn't allowed to insert, if they're allowed to call
-- a procedure that uses insert, that's allowed. Apparently because stored procedures are created with
-- SQL security definer, which invokes the privilege of the creator of the procesure as opposed to the caller.alter


