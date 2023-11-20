USE SmartHomeDB;

-- Security stuff
-- Role based access seems most fitting for this kind of database


-- These roles here are for testing purposes
CREATE USER IF NOT EXISTS 'admin_user'@'localhost' IDENTIFIED BY 'password_for_admin_user';
CREATE USER IF NOT EXISTS 'owner_user'@'localhost' IDENTIFIED BY 'password_for_owner_user';
CREATE USER IF NOT EXISTS 'family_user'@'localhost' IDENTIFIED BY 'password_for_family_user';
CREATE USER IF NOT EXISTS 'guest_user'@'localhost' IDENTIFIED BY 'password_for_guest_user';

DROP ROLE IF EXISTS 'admin_role';
DROP ROLE IF EXISTS 'guest_role';
DROP ROLE IF EXISTS 'owner_role';
DROP ROLE IF EXISTS 'family_role';



CREATE ROLE 'admin_role';
CREATE ROLE 'owner_role';
CREATE ROLE 'family_role';
CREATE ROLE 'guest_role';

GRANT 'admin_role' TO 'admin_user'@'localhost';
GRANT 'owner_role' TO 'owner_user'@'localhost';
GRANT 'family_role' TO 'family_user'@'localhost';
GRANT 'guest_role' TO 'guest_user'@'localhost';



-- Manipulation of the database will be handled by procedures alone

GRANT EXECUTE ON PROCEDURE SmartHomeDB.Insert_Light TO 'admin_role', 'owner_role';
GRANT EXECUTE ON PROCEDURE SmartHomeDB.Insert_Camera TO 'admin_role', 'owner_role';
GRANT EXECUTE ON PROCEDURE SmartHomeDB.Insert_Thermostat TO 'admin_role', 'owner_role';
GRANT EXECUTE ON PROCEDURE SmartHomeDB.Insert_DoorLock TO 'admin_role', 'owner_role';
GRANT EXECUTE ON PROCEDURE SmartHomeDB.Insert_TV TO 'admin_role', 'owner_role';
GRANT EXECUTE ON PROCEDURE SmartHomeDB.Change_Device_Status TO 'admin_role', 'owner_role', 'family_role', 'guest_role';
GRANT EXECUTE ON PROCEDURE SmartHomeDB.Insert_Energy_Logs TO 'admin_role', 'owner_role';
GRANT EXECUTE ON PROCEDURE SmartHomeDB.Insert_Maintenance_Schedules TO 'admin_role', 'owner_role';
GRANT EXECUTE ON PROCEDURE SmartHomeDB.Transfer_Ownership TO  'owner_role';
GRANT EXECUTE ON PROCEDURE SmartHomeDB.Create_User_With_Devices TO  'owner_role';




-- View allocation block
GRANT SELECT ON View_Device_Energy_Usage TO 'admin_role', 'owner_role';
GRANT SELECT ON View_Upcoming_Maintenance TO 'admin_role', 'owner_role';
GRANT SELECT ON View_Automation_Rules_Summary TO 'admin_role', 'owner_role';
GRANT SELECT ON View_device_night_status TO 'admin_role', 'owner_role', 'family_role';
GRANT SELECT ON View_device_evening_status TO 'admin_role', 'owner_role', 'family_role';
GRANT SELECT ON View_device_away_status TO 'admin_role', 'owner_role', 'family_role';
GRANT SELECT ON View_device_daytime_status TO 'admin_role', 'owner_role', 'family_role';
GRANT SELECT ON View_device_morning_status TO 'admin_role', 'owner_role', 'family_role';
GRANT SELECT ON View_device_maintenance_status TO 'admin_role', 'owner_role';
GRANT SELECT ON View_Thermostat_Mode TO 'admin_role', 'owner_role', 'family_role', 'guest_role';



-- Block for granting permission to use certain procedures to specific roles

-- Note apparently even if the user isn't allowed to insert, if they're allowed to call
-- a procedure that uses insert, that's allowed. Apparently because stored procedures are created with
-- SQL security definer, which invokes the privilege of the creator of the procesure as opposed to the caller.alter


