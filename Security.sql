USE SmartHomeDB;

-- Security stuff
-- Role based access seems most fitting for this kind of database

CREATE USER IF NOT EXISTS 'admin_user'@'localhost' IDENTIFIED BY 'password_for_admin_user';
CREATE USER IF NOT EXISTS 'owner_user'@'localhost' IDENTIFIED BY 'password_for_owner_user';
CREATE USER IF NOT EXISTS 'family_user'@'localhost' IDENTIFIED BY 'password_for_family_user';
CREATE USER IF NOT EXISTS 'guest_user'@'localhost' IDENTIFIED BY 'password_for_guest_user';


CREATE ROLE 'admin_role';
CREATE ROLE 'owner_role';
CREATE ROLE 'family_role';
CREATE ROLE 'guest_role';

GRANT 'admin_role' TO 'admin_user'@'localhost';
GRANT 'owner_role' TO 'owner_user'@'localhost';
GRANT 'family_role' TO 'family_user'@'localhost';
GRANT 'guest_role' TO 'guest_user'@'localhost';



-- Manipulation of the database will be handled by procedures alone
REVOKE INSERT ON SmartHomeDB.* FROM 'admin_role', 'owner_role', 'family_role', 'guest_role';
REVOKE INSERT, UPDATE, DELETE ON SmartHomeDB.* FROM  'family_role', 'guest_role';

REVOKE INSERT ON SmartHomeDB.Device FROM  'admin_role', 'owner_role';
GRANT EXECUTE ON PROCEDURE SmartHomeDB.Insert_Light TO 'admin_role', 'owner_role';
GRANT EXECUTE ON PROCEDURE SmartHomeDB.Insert_Camera TO 'admin_role', 'owner_role';
GRANT EXECUTE ON PROCEDURE SmartHomeDB.Insert_Thermostat TO 'admin_role', 'owner_role';
GRANT EXECUTE ON PROCEDURE SmartHomeDB.Insert_DoorLock TO 'admin_role', 'owner_role';
GRANT EXECUTE ON PROCEDURE SmartHomeDB.Insert_TV TO 'admin_role', 'owner_role';
GRANT EXECUTE ON PROCEDURE SmartHomeDB.Insert_User TO 'owner_role';

GRANT EXECUTE ON PROCEDURE SmartHomeDB.Change_Device_Status TO 'admin_role', 'owner_role', 'family_role', 'guest_role';

GRANT EXECUTE ON PROCEDURE SmartHomeDB.Insert_Energy_Logs TO 'admin_role', 'owner_role';
GRANT EXECUTE ON PROCEDURE SmartHomeDB.Insert_Maintenance_Schedules TO 'admin_role', 'owner_role';
GRANT EXECUTE ON PROCEDURE SmartHomeDB.Change_User_Role TO 'admin_role', 'owner_role';




-- Block for granting permission to use certain procedures to specific roles

-- Note apparently even if the user isn't allowed to insert, if they're allowed to call
-- a procedure that uses insert, that's allowed. Apparently because stored procedures are created with
-- SQL security definer, which invokes the privilege of the creator of the procesure as opposed to the caller.alter


