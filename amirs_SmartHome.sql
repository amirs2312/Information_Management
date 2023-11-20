

-- ---------------------------------------------------------------------------------------------------

-- TABLE CREATION CODE 

-- ---------------------------------------------------------------------------------------------------




-- For testing purposes
DROP DATABASE IF EXISTS SmartHomeDB;
CREATE DATABASE SmartHomeDB;
USE SmartHomeDB;






-- The device superclass. Nothing out of the ordinary.
CREATE TABLE Device (
    device_id INT AUTO_INCREMENT PRIMARY KEY,
    model VARCHAR(255) NOT NULL,
    status ENUM('On', 'Off', 'standby', 'not_responding') NOT NULL, -- Different possible statuses
    location VARCHAR(255) NOT NULL
);




-- The User entitiy.
CREATE TABLE SmartHome_User (
	user_id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE, -- No two emails should be the same
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    role ENUM('Guest', 'Family', 'Admin', 'Owner') -- Different possible roles
    );
    
    

-- Every smart device will reference the device table in the form of a primary key that also acts as a foreign key.
    
-- The light attribute is broken down into 3 components, r, g, and b.
CREATE TABLE Light (
    device_id INT PRIMARY KEY,
    red TINYINT UNSIGNED NOT NULL,
    green TINYINT UNSIGNED NOT NULL,
    blue TINYINT UNSIGNED NOT NULL,
    FOREIGN KEY (device_id) REFERENCES Device(device_id) ON DELETE CASCADE 
);

-- Note the on delete cascade. This is the case for every smart device.
-- There should never be an entry in a subclass table that refers to a no longer existent entry in the superclass table.




-- The mode attribute for thermostat will only appear in views 
CREATE TABLE Thermostat (
    device_id INT PRIMARY KEY,
    target_temp DECIMAL(5,2) NOT NULL,
    current_temp DECIMAL(5,2) NOT NULL,
    FOREIGN KEY (device_id) REFERENCES Device(device_id) ON DELETE CASCADE
);




-- Another smart device. Nothing Special to note here.
CREATE TABLE Camera (
    device_id INT PRIMARY KEY,
    resolution VARCHAR(255) NOT NULL,
    field_of_view INT NOT NULL,
    storage_capacity_gb INT NOT NULL,
    FOREIGN KEY (device_id) REFERENCES Device(device_id) ON DELETE CASCADE
);



-- Cascase delete is also implemented for non smart device tables. Referential integrity and what not.

CREATE TABLE MaintenanceSchedule (
    schedule_id INT AUTO_INCREMENT PRIMARY KEY,
    last_maintenance_date DATE , -- If the device was just newly bought, it may not have has maintenance yet. Allow this to be NULL.
    next_maintenance_date DATE NOT NULL,
    device_id INT UNIQUE NOT NULL,
    FOREIGN KEY (device_id) REFERENCES Device(device_id) ON DELETE CASCADE
);




-- Nothing Special about this table.
CREATE TABLE EnergyLog (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    log_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    energy_consumed DECIMAL(10,2) NOT NULL,
    device_id INT NOT NULL,
    FOREIGN KEY (device_id) REFERENCES Device(device_id) ON DELETE CASCADE
);




-- As a table born from an m:n relationship, it has two foregn keys.
CREATE TABLE UserDeviceControl (
    user_id INT NOT NULL,
    device_id INT NOT NULL,
    PRIMARY KEY (user_id, device_id), -- Composite primary key.
    FOREIGN KEY (user_id) REFERENCES SmartHome_User(user_id) ON DELETE CASCADE,
    FOREIGN KEY (device_id) REFERENCES Device(device_id) ON DELETE CASCADE
);




-- SmartDoor Subclass
CREATE TABLE DoorLock (
    device_id INT PRIMARY KEY,
    door_code VARCHAR(255) , -- A NULL value occurs when lock_type isn't keypad. This isn't a functional dependancy and the table is still BCNF.
    lock_type ENUM('keypad', 'biometric', 'key', 'app') NOT NULL,
    FOREIGN KEY (device_id) REFERENCES Device(device_id) ON DELETE CASCADE
);


-- Smart TV subclass
CREATE TABLE TV (
    device_id INT PRIMARY KEY,
    screen_size INT NOT NULL,
    resolution VARCHAR(255) NOT NULL,
    FOREIGN KEY (device_id) REFERENCES Device(device_id) ON DELETE CASCADE
);


-- The Automation Rule table. Describes a rule that devices automatically follow, like lights off at nightime.
CREATE TABLE AutomationRule (
    rule_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT, -- Allowing a lengthy description of the rule.
    trigger_condition ENUM('daytime', 'evening', 'nightime', 'morning', 'away', 'maintenance') NOT NULL, -- On what event this rule activates
    trigger_type ENUM('On', 'Off'), -- Whether to turn a device on or off
    fk_creator_id INT NOT NULL, -- The user that created this rule.
    FOREIGN KEY (fk_creator_id) REFERENCES SmartHome_User(user_id) ON DELETE CASCADE
);



-- Another table from an m:n relationship.
CREATE TABLE DeviceAutomation (
    rule_id INT NOT NULL,
    device_id INT NOT NULL,
    PRIMARY KEY (rule_id, device_id), -- composite primary key.
    FOREIGN KEY (rule_id) REFERENCES AutomationRule(rule_id) ON DELETE CASCADE, -- Two foreign keys.
    FOREIGN KEY (device_id) REFERENCES Device(device_id) ON DELETE CASCADE
);








-- ---------------------------------

-- PROCEDURE CREATION CODE

-- ---------------------------------









-- We're going to have a list of transactions at the beginning for inserting devices and making sure the subclass is defined at the same time
-- Completeness will be forced.

-- I don't need this Drop block anymore since everything is one file,
-- but this acts as a nice way to quickly see all the procedures right?
DROP PROCEDURE IF EXISTS Insert_Energy_Logs;
DROP PROCEDURE IF EXISTS Insert_Multiple_Energy_Logs;
DROP PROCEDURE IF EXISTS Insert_Maintenance_Schedules;
DROP PROCEDURE IF EXISTS Insert_Light;
DROP PROCEDURE IF EXISTS Insert_Camera;
DROP PROCEDURE IF EXISTS Insert_TV;
DROP PROCEDURE IF EXISTS Insert_Thermostat;
DROP PROCEDURE IF EXISTS Insert_DoorLock;
DROP PROCEDURE IF EXISTS Insert_User;
DROP PROCEDURE IF EXISTS Create_Rule_And_Apply_To_Devices;
DROP PROCEDURE IF EXISTS Assign_Device_To_User; -- These two procedures are named poorly.
DROP PROCEDURE IF EXISTS Assign_Devices_To_User; -- I apologise for how similarly they're named. 
DROP PROCEDURE IF EXISTS Assign_Devices_To_ALL_Users;
DROP PROCEDURE IF EXISTS Change_Device_Status;
DROP PROCEDURE IF EXISTS Transfer_Ownership;


DELIMITER //

-- Procedure for inserting a smart light into the subclass and super class table at the same time.
CREATE PROCEDURE Insert_Light(
    IN _model VARCHAR(255),
    IN _status ENUM('On', 'Off', 'standby', 'not_responding'),
    IN _location VARCHAR(255),
    IN _red TINYINT UNSIGNED,
    IN _green TINYINT UNSIGNED,
    IN _blue TINYINT UNSIGNED
)
BEGIN
    DECLARE _device_id INT;

    START TRANSACTION; -- Ensure both entries are entered, or neither of them.
    
    INSERT INTO Device (model, status, location) VALUES (_model, _status, _location);
    SET _device_id = LAST_INSERT_ID(); -- Sets local variable device_id to the last primary key we inserted.
    INSERT INTO Light (device_id, red, green, blue) VALUES (_device_id, _red, _green, _blue);
    
    COMMIT; -- End transaction
END;
//


-- Procedure for inserting a smart camera into the subclass and super class table at the same time.
-- All of the smart device procedures are pretty much iddentical, except for the parameters they take in.
CREATE PROCEDURE Insert_Camera(
    IN _model VARCHAR(255),
    IN _status ENUM('On', 'Off', 'standby', 'not_responding'),
    IN _location VARCHAR(255),
    IN _resolution VARCHAR(255),
    IN _field_of_view INT,
    IN _storage_capacity_gb INT
)
BEGIN
    DECLARE _device_id INT;

    START TRANSACTION;
    
    INSERT INTO Device (model, status, location) VALUES (_model, _status, _location);
    SET _device_id = LAST_INSERT_ID();
    INSERT INTO Camera (device_id, resolution, field_of_view, storage_capacity_gb) VALUES (_device_id, _resolution, _field_of_view, _storage_capacity_gb);
    
    COMMIT;
END;
//

-- Procedure for inserting Tvs
CREATE PROCEDURE Insert_TV(
    IN _model VARCHAR(255),
    IN _status ENUM('On', 'Off', 'standby', 'not_responding'),
    IN _location VARCHAR(255),
    IN _screen_size INT,
    IN _resolution VARCHAR(255)
)
BEGIN
    DECLARE _device_id INT;

    START TRANSACTION;
    
    INSERT INTO Device (model, status, location) VALUES (_model, _status, _location);
    SET _device_id = LAST_INSERT_ID();
    INSERT INTO TV (device_id, screen_size, resolution) VALUES (_device_id, _screen_size, _resolution);
    
    COMMIT;
END;
//


-- Procedure for inserting thermostats
CREATE PROCEDURE Insert_Thermostat(
    IN _model VARCHAR(255),
    IN _status ENUM('On', 'Off', 'standby', 'not_responding'),
    IN _location VARCHAR(255),
    IN _target_temp DECIMAL(5,2),
    IN _current_temp DECIMAL(5,2)
)
BEGIN
    DECLARE _device_id INT;

    START TRANSACTION;
    
    INSERT INTO Device (model, status, location) VALUES (_model, _status, _location);
    SET _device_id = LAST_INSERT_ID();
    INSERT INTO Thermostat (device_id, target_temp, current_temp) VALUES (_device_id, _target_temp, _current_temp);
    
    COMMIT;
END;
//


-- Smart Door procedure, a little different to the rest
CREATE PROCEDURE Insert_DoorLock(
    IN _model VARCHAR(255),
    IN _location VARCHAR(255),
    IN _lock_type ENUM('keypad', 'biometric', 'key', 'app'),
    IN _door_code VARCHAR(255)  -- Adjusted parameter name to match the column name
)
BEGIN
    DECLARE _device_id INT;

    START TRANSACTION;
    
    INSERT INTO Device (model, location) VALUES (_model, _location);
    SET _device_id = LAST_INSERT_ID();
    
    
    IF _lock_type = 'keypad' AND _door_code IS NOT NULL THEN -- Check what type of foor lock we have. If its keypad then there must be an associated code.
        INSERT INTO DoorLock (device_id, lock_type, door_code) VALUES (_device_id, _lock_type, _door_code);
    ELSEIF _lock_type != 'keypad' THEN -- If its not a keypad insert the relevant information
        INSERT INTO DoorLock (device_id, lock_type) VALUES (_device_id, _lock_type);
    ELSE
    -- Keypad doors must have non-null door codes
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Keycode must be provided for keypad locks';
    END IF;
    
    COMMIT;
END;
//


-- A function to create n data logs for device i. Not for the user to use, purely for database population.
CREATE PROCEDURE Insert_Energy_Logs(
    IN _device_id INT, -- The id of the device that be linked to these logs
    IN _log_count INT  -- The amount of logs we wish to create
)
BEGIN
    DECLARE i INT DEFAULT 1; -- looping variable
    DECLARE _log_time TIMESTAMP;
    DECLARE _energy_consumed DECIMAL(5,2);
   

    WHILE i <= _log_count DO
        -- Generate a log_time within the last 3 ish months (
        SET _log_time = NOW() - INTERVAL FLOOR(RAND() * 90) DAY;
        -- Generate some random energy consumed value
        SET _energy_consumed = FLOOR(RAND() * 100) + 1; 
        

        INSERT INTO EnergyLog (device_id, log_time, energy_consumed) VALUES (_device_id, _log_time, _energy_consumed);

        SET i = i + 1;
    END WHILE;
END;
//


-- A procedure for populating the database, loops over wach device and creates a number of energy logs for them
CREATE PROCEDURE Insert_Multiple_Energy_Logs()
BEGIN
    DECLARE done INT DEFAULT FALSE; -- Termination bool
    DECLARE _device_id INT;
    DECLARE cur CURSOR FOR SELECT device_id FROM Device; -- Declaring a cursor for iterating over the device_ids from the rows of the device table.
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE; -- This sets the termination variable to true on the NOT FOUND confition, ie the end of the tabel

    OPEN cur;

    read_loop: LOOP
        FETCH cur INTO _device_id; -- Moving the row found by cursor into our local variable
        IF done THEN
            LEAVE read_loop;
        END IF;

        CALL Insert_Energy_Logs(_device_id, 5); -- Generate 5 energy logs for each device in the database.
    END LOOP;

    CLOSE cur; -- release the resources associated with the cursor
    END;

//


-- A Procedure for pupulating the database with schedules
-- Loops over devices that would need maintenance and reandomly assigns them last and next dates.
-- Again, not for the users, purely for population purposees.
CREATE PROCEDURE Insert_Maintenance_Schedules()
BEGIN
    DECLARE done INT DEFAULT FALSE; -- Termination variable
    DECLARE _device_id INT;
    DECLARE _last_maintenance_date DATE;
    DECLARE _next_maintenance_date DATE;
    DECLARE cur CURSOR FOR  -- A cursor for iterating over the device id from the rows of the device table where its a camera or thermostat
        SELECT device_id 
        FROM Device 
        WHERE model LIKE '%Camera%' OR model LIKE '%Thermostat%';
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;  -- Again termination variable is true once we've gone through the whole table.

    OPEN cur;

    read_loop: LOOP
        FETCH cur INTO _device_id;
        IF done THEN
            LEAVE read_loop;
        END IF;

        -- Generate a last_maintenance_date within the last 30 days
        SET _last_maintenance_date = CURDATE() - INTERVAL FLOOR(RAND() * 30) DAY;
        -- Generate the next_maintenance_date, 30, 60, 90, or 120 days from the last date
        SET _next_maintenance_date = _last_maintenance_date + INTERVAL (FLOOR(RAND() * 4) * 30 + 30) DAY;

        INSERT INTO MaintenanceSchedule (device_id, last_maintenance_date, next_maintenance_date)
        VALUES (_device_id, _last_maintenance_date, _next_maintenance_date);
    END LOOP;

    CLOSE cur; -- Release cursors resources
END;
//

-- Procedure for populating both the AutomationRule table and the DeviceAutomation table
CREATE PROCEDURE Create_Rule_And_Apply_To_Devices(
    IN _name VARCHAR(255),
    IN _description TEXT,
    IN _trigger_condition ENUM('daytime', 'evening', 'nightime', 'morning', 'away', 'maintenance'),
    IN _trigger_type ENUM('On', 'Off'),
    IN _creator_id INT,
    IN _device_ids TEXT -- A comma-separated list of device IDs
)
BEGIN
    DECLARE _rule_id INT;
    DECLARE _device_id INT;
    DECLARE _index INT;
    DECLARE _next_comma INT;
    DECLARE _sub_str_length INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        -- Roll back the transaction if any error occurs
        ROLLBACK;
    END;

    -- Start the transaction
    START TRANSACTION;

    -- Insert the rule into the AutomationRule table with trigger_type
    INSERT INTO AutomationRule (name, description, trigger_condition, trigger_type, fk_creator_id)
    VALUES (_name, _description, _trigger_condition, _trigger_type, _creator_id);
    SET _rule_id = LAST_INSERT_ID(); -- Keep the rule id as a local variable for now

    -- Initialize loop variables for device IDs
    SET _device_ids = CONCAT(_device_ids, ','); -- Adding a comma to give the loop a consistent way to recognise the end of the string.
    SET _index = 1;

    -- Loop through the comma-separated list of device IDs and apply the rule
    WHILE _index < CHAR_LENGTH(_device_ids) DO
        SET _next_comma = LOCATE(',', _device_ids, _index); -- Find the next comma
        SET _sub_str_length = _next_comma - _index; -- Find the difference in length between where index is and where the next comma is.
        
		-- From the position index in the device ids text field, obtain the substring that starts at
        -- index and is as long as the difference calculated above. This is a device_id.
        -- Finally, Cast it as an unsigned int.
        SET _device_id = CAST(SUBSTRING(_device_ids, _index, _sub_str_length) AS UNSIGNED); 
        
        INSERT INTO DeviceAutomation (rule_id, device_id) VALUES (_rule_id, _device_id); -- Apply the rule to the device
        SET _index = _next_comma + 1; -- Move the index to the position after the next comma
    END WHILE;

    -- Commit the transaction if all operations are successful
    COMMIT;
END;
//



-- Used in a trigger to automatically decide what entries to make in the userdevice table upon the insetion of a new device.
CREATE PROCEDURE Assign_Device_To_User(IN _user_id INT, IN _device_id INT, IN _device_model VARCHAR(255))
BEGIN
    DECLARE _role VARCHAR(255);


    SELECT role INTO _role FROM SmartHome_User WHERE user_id = _user_id; -- retrieve user role

    -- Based on the role, assign the device if it matches the criteria
    IF _role = 'Guest' AND (_device_model LIKE '%TV%' OR _device_model LIKE '%Light%') THEN
        INSERT INTO UserDeviceControl (user_id, device_id)
        VALUES (_user_id, _device_id)
        ON DUPLICATE KEY UPDATE device_id = VALUES(device_id);
    ELSEIF _role = 'Family' AND (_device_model LIKE '%TV%' OR _device_model LIKE '%Light%' OR _device_model LIKE '%Thermostat%' OR _device_model LIKE '%Lock%') THEN
        INSERT INTO UserDeviceControl (user_id, device_id)
        VALUES (_user_id, _device_id)
        ON DUPLICATE KEY UPDATE device_id = VALUES(device_id);
    ELSEIF _role IN ('Admin', 'Owner') THEN
        -- Admins and Owners get access to all devices
        INSERT INTO UserDeviceControl (user_id, device_id)
        VALUES (_user_id, _device_id)
        ON DUPLICATE KEY UPDATE device_id = VALUES(device_id);
    END IF;
END;
//

-- Only to be called by the owner
CREATE PROCEDURE Transfer_Ownership(
    IN current_owner_id INT,
    IN new_owner_id INT
)
BEGIN
        START TRANSACTION;

        -- Demote the current owner to an admin
        UPDATE SmartHome_User SET role = 'Admin' WHERE user_id = current_owner_id;

        -- Promote the new owner
        UPDATE SmartHome_User SET role = 'Owner' WHERE user_id = new_owner_id;

        COMMIT; -- If all goes well commit the transaction
END;

//


-- Create the relevant entries in the userdevice table given a users role.
CREATE PROCEDURE Assign_Devices_To_User(IN _user_id INT)
BEGIN
    DECLARE _role VARCHAR(255);

    -- Retrieve the role of the user
    SELECT role INTO _role FROM SmartHome_User WHERE user_id = _user_id;

    -- Based on the role, assign different devices
    CASE _role
        WHEN 'Guest' THEN
            -- Guests get TVs and Lights
            INSERT INTO UserDeviceControl (user_id, device_id)
            SELECT _user_id, device_id FROM Device
            WHERE model LIKE '%TV%' OR model LIKE '%Light%'
            ON DUPLICATE KEY UPDATE device_id = VALUES(device_id);
        
        WHEN 'Family' THEN
            -- Family gets TVs, Lights, Thermostats, and Locks
            INSERT INTO UserDeviceControl (user_id, device_id)
            SELECT _user_id, device_id FROM Device
            WHERE model LIKE '%TV%' OR model LIKE '%Light%' OR model LIKE '%Thermostat%' OR model LIKE '%Lock%'
            ON DUPLICATE KEY UPDATE device_id = VALUES(device_id);
        
        WHEN 'Admin' THEN
            -- Admins get access to all devices
            INSERT INTO UserDeviceControl (user_id, device_id)
            SELECT _user_id, device_id FROM Device
            ON DUPLICATE KEY UPDATE device_id = VALUES(device_id);

        WHEN 'Owner' THEN
            -- Owners get access to all devices
            INSERT INTO UserDeviceControl (user_id, device_id)
            SELECT _user_id, device_id FROM Device
            ON DUPLICATE KEY UPDATE device_id = VALUES(device_id); -- Repeated in all of the cases, just to deal with duplicate errors.
        
        ELSE
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid user role for device assignment.';
	END CASE;
    
END;
//

-- Procedure for creating a user.
CREATE PROCEDURE Create_User_With_Devices(
    IN _email VARCHAR(255),
    IN _password_hash VARCHAR(255),
    IN _first_name VARCHAR(255),
    IN _last_name VARCHAR(255),
    IN _role ENUM('Guest', 'Family', 'Admin', 'Owner')
)
BEGIN
    DECLARE _user_id INT;

    -- Insert the new user into the SmartHome_User table
    INSERT INTO SmartHome_User (email, password_hash, first_name, last_name, role) 
    VALUES (_email, _password_hash, _first_name, _last_name, _role);

    -- Get the ID of the newly inserted user
    SET _user_id = LAST_INSERT_ID();

    -- Call the Assign_Devices_To_User procedure to assign devices to the new user in the userdevice table
    CALL Assign_Devices_To_User(_user_id);
END;
//


DELIMITER ;







-- -------------------------------------------------------------------------------------------------------------------------

-- TRIGGER CREATION CODE

-- -------------------------------------------------------------------------------------------------------------------------







-- Again pointless drop block, but acts as an easy way to see all the triggers quickly so I'll leave it in.
DROP TRIGGER IF EXISTS Owner_Delete_Check;
DROP TRIGGER IF EXISTS Owner_Insert_Check;
DROP TRIGGER IF EXISTS Prevent_Conflicting_Rules;
DROP TRIGGER IF EXISTS After_Device_Insert;

DELIMITER //

-- On the insertion of a new user, ensure that we do not break the "only one owner" rule.
CREATE TRIGGER Owner_Insert_Check
AFTER INSERT ON SmartHome_User		
FOR EACH ROW
BEGIN
    -- If a new owner is being added, check that it's the only one
    IF NEW.role = 'Owner' AND (SELECT COUNT(*) FROM SmartHome_User WHERE role = 'Owner') > 1 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot insert multiple owners.';
    END IF;
END;
//

-- Same as above, except on the deletion of an owner.
CREATE TRIGGER Owner_Delete_Check
AFTER DELETE ON SmartHome_User
FOR EACH ROW
BEGIN
    -- If an owner is being deleted, check that at least one owner still exists
    IF OLD.role = 'Owner' AND (SELECT COUNT(*) FROM SmartHome_User WHERE role = 'Owner') = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'There must always be one owner.';
    END IF;
END;
//

-- Made to prevent two rules being applied to the same device 
DELIMITER //

CREATE TRIGGER Prevent_Conflicting_Rules
BEFORE INSERT ON DeviceAutomation
FOR EACH ROW
BEGIN
    DECLARE conflicting_rule_count INT; -- How many rules conflict (We could instead have this as a bool as I don't use the information on how many conflicts there are, but I might eventually)

    SELECT COUNT(*) -- Return how mant tuples meet the select condition.
    INTO conflicting_rule_count
    FROM DeviceAutomation da
    JOIN AutomationRule ar ON da.rule_id = ar.rule_id -- Join AutomationRule to DeviceAutomation where,
    WHERE da.device_id = NEW.device_id -- device ids match
    
    -- The trigger condition of the rule matches the trigger condition of the new rule being inserted
      AND ar.trigger_condition = (SELECT trigger_condition FROM AutomationRule WHERE rule_id = NEW.rule_id )
	-- The trigger tpye of the rule does not match the trigger type of the new rule (A conflict)
      AND ar.trigger_type != (SELECT trigger_type FROM AutomationRule WHERE rule_id = NEW.rule_id);

    -- If there is a conflicting rule with an opposite action, signal an error
    IF conflicting_rule_count > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Conflicting automation rules detected: cannot have opposite actions for the same device and condition.';
    END IF;
END;



-- When a device is inserted, the relevant entires in the userdevice table are made.
-- This is done in a trigger as opposed to in the procedures as there is five seperate procedures
-- for inserting a device. It seems a bit overkill to include this logic at the bottom of every one.
CREATE TRIGGER After_Device_Insert
AFTER INSERT ON Device
FOR EACH ROW
BEGIN
    DECLARE _user_id INT;
    DECLARE done INT DEFAULT FALSE; -- Termination bool
    DECLARE cur CURSOR FOR SELECT user_id FROM SmartHome_User; -- Cursor for iterating over user_ids from the user table.
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE; -- When we reach the end of the table set the termination bool to true.

    OPEN cur;
    -- All the loop is doing is calling the procedure to create relevant entires in the userdevice table
    -- for a given user. And then repeating this over every user.
    assign_loop: LOOP
        FETCH cur INTO _user_id;
        IF done THEN
            LEAVE assign_loop;
        END IF;

        
        CALL Assign_Device_To_User(_user_id, NEW.device_id, NEW.model); 
    END LOOP;

    CLOSE cur; -- Release resources (again)
END;
//



DELIMITER ;





-- -------------------------------------------------------------------------------------------------------------------------

-- POPULATION CODE

-- -------------------------------------------------------------------------------------------------------------------------










-- Code for actually populating my database

-- Insertion Block.... For devices
CALL Insert_Light('Smart Light', 'On', 'Living Room', 255, 255, 255);
CALL Insert_Light('Smarter Light', 'Off', 'Bedroom', 0, 0, 0);
CALL Insert_Light('Smartest Light', 'On', 'Kitchen', 255, 255, 255);
CALL Insert_Light('Light', 'Off', 'Bathroom', 0, 0, 0);
CALL Insert_Light('Smart Light V1', 'On', 'Dining Room', 255, 255, 255);
CALL Insert_Light('Smart Light V3', 'Off', 'Garage', 0, 0, 0);
CALL Insert_Light('Smart Light V2', 'On', 'Office', 255, 255, 255);
-- I'm very clearly running out of unique names

CALL Insert_Camera('Security Camera V5', 'Off', 'Front Gate', '1080p', 120, 64);
CALL Insert_Camera('Security Camera V5', 'On', 'Backyard', '720p', 90, 32);
CALL Insert_Camera('Security Camera V5', 'Off', 'Garage', '1080p', 120, 128);
CALL Insert_Camera('Security Camera V1', 'On', 'Living Room', '4K', 180, 256);
CALL Insert_Camera('Security Camera V5', 'Off', 'Front Door', '1080p', 120, 64);
CALL Insert_Camera('Security Camera V3', 'On', 'Patio', '720p', 90, 32);
CALL Insert_Camera('Security Camera V4', 'Off', 'Balcony', '4K', 180, 256);

CALL Insert_Thermostat('EcoThermostat T100', 'On', 'Living Room', 72.0, 71.0);
CALL Insert_Thermostat('EcoThermostat T200', 'Off', 'Bedroom', 69.0, 69.0);
CALL Insert_Thermostat('EcoThermostat T300', 'On', 'Kitchen', 70.0, 70.5);
CALL Insert_Thermostat('EcoThermostat T400', 'Off', 'Basement', 67.0, 66.5);
CALL Insert_Thermostat('EcoThermostat T500', 'On', 'Office', 71.0, 70.0);


CALL Insert_TV('SuperView 4K TV', 'Off', 'Living Room', 55, '4K');
CALL Insert_TV('SuperView 4K TV', 'Off', 'Master Bedroom', 50, '1080p');
CALL Insert_TV('SuperView 4K TV', 'Off', 'Guest Room', 42, '720p');
CALL Insert_TV('SuperView 4K TV', 'Off', 'Kitchen', 32, '720p');
CALL Insert_TV('SuperView 4K TV', 'Off', 'Basement', 65, '4K');
CALL Insert_TV('SuperView 4K TV', 'Off', 'Office', 55, '4K');

CALL Insert_DoorLock('TimLock',  'Front Door', 'keypad', '1923'); -- 
CALL Insert_DoorLock('KeypadLock 3000',  'Back Door', 'keypad', '1824');
CALL Insert_DoorLock('BioLock 4000',  'Garage Door', 'biometric', NULL);
CALL Insert_DoorLock('KeyLock 5000',  'Patio Door', 'key', NULL);
CALL Insert_DoorLock('AppLock 6000',  'Office Door', 'app', NULL);
CALL Insert_DoorLock('KeypadLock 3000', 'Side Door', 'keypad', '7782');
CALL Insert_DoorLock('BioLock 4000',  'Basement Door', 'biometric', NULL);
CALL Insert_DoorLock('KeyLock 5000',  'Balcony Door', 'key', NULL);
CALL Insert_DoorLock('AppLock 6000',  'Bedroom Door', 'app', NULL);
CALL Insert_DoorLock('KeypadLock 3000',  'Roof Access', 'keypad', '4432');


CALL Insert_Multiple_Energy_Logs();	-- Creating some energy logs for each device 
CALL Insert_Maintenance_Schedules(); -- Giving the devices that need maintenance a schedule



-- User Insertion Block

-- The Ownner 
CALL Create_User_With_Devices('jj@example.com', 'hashed_password', 'John', 'Johnson', 'Owner');

CALL Create_User_With_Devices('pf@example.com', 'sjdfjsgidf', 'Patrick', 'Farmer', 'Admin');
CALL Create_User_With_Devices('dh2@example.com', 'okyaokay', 'Donnacha', 'haplin', 'Admin');
CALL Create_User_With_Devices('dat@example.com', 'fejrgngr', 'David', 'at', 'Family');
CALL Create_User_With_Devices('family2@example.com', '2fiun293', 'Eve', 'Evans', 'Family');
CALL Create_User_With_Devices('NM@example.com', 'f4ifen0', 'Nollaig', 'McHugh', 'Admin'); -- I got Nollaig's permission to use his likeness
CALL Create_User_With_Devices('TF1@example.com', 'feonf', 'Tim', 'Farrelly', 'Guest'); -- I got Tim's permission too
CALL Create_User_With_Devices('guest2@example.com', 'eofjn', 'Henry', 'Hill', 'Guest');
CALL Create_User_With_Devices('guest3@example.com', 'fevofwf', 'Ivy', 'Irons', 'Guest');
CALL Create_User_With_Devices('admin3@example.com', 'feofw', 'John', 'Johnson', 'Admin');
CALL Create_User_With_Devices('family4@example.com', 'wefeoinf', 'Koola', 'Kadaraan', 'Family');
CALL Create_User_With_Devices('bowied@example.com', 'feoef', 'David', 'Bowie', 'Guest');

-- Creates a single rule and applies it to all the listed devices
CALL Create_Rule_And_Apply_To_Devices('Evening Routine', 'Turn off lights and lock doors in the evening', 'nightime', 'On','1', '2,3,5,8,10');





-- -------------------------------------------------------------------------------------------------------------------------

-- VIEW CODE

-- -------------------------------------------------------------------------------------------------------------------------







-- Pointless drop block thats only still here to see as it acts as a quick way to see all the views.
DROP VIEW IF EXISTS View_Device_Energy_Usage;
DROP VIEW IF EXISTS View_Upcoming_Maintenance;
DROP VIEW IF EXISTS View_Automation_Rules_Summary;
DROP VIEW IF EXISTS View_device_night_status;
DROP VIEW IF EXISTS View_device_morning_status;
DROP VIEW IF EXISTS View_device_evening_status;
DROP VIEW IF EXISTS View_device_maintenance_status;
DROP VIEW IF EXISTS View_device_away_status;
DROP VIEW IF EXISTS View_device_daytime_status;
DROP VIEW IF EXISTS View_Thermostat_Mode;


-- A view that shows how much a device costs. Shows the derived attribute cost.
CREATE VIEW View_Device_Energy_Usage AS
SELECT 
    d.device_id, 
    d.model, 
    SUM(el.energy_consumed) AS total_energy,
    SUM(el.energy_consumed) * 0.67 AS total_cost, 
    COUNT(el.log_id) AS number_of_logs
FROM 
    Device d
JOIN 
    EnergyLog el ON d.device_id = el.device_id -- Joining energy log to Device
WHERE 
    el.log_time BETWEEN NOW() - INTERVAL 1 YEAR AND NOW()
GROUP BY 
    d.device_id;


-- Self explanatory. Creates a view that shows upcoming maintenances.
CREATE VIEW View_Upcoming_Maintenance AS
SELECT 
    d.device_id, 
    d.model, 
    ms.next_maintenance_date
FROM 
    Device d
JOIN 
    MaintenanceSchedule ms ON d.device_id = ms.device_id
WHERE 
    ms.next_maintenance_date > NOW();
    
    

    
    
    
-- Shows a rule and its effected devices as a comma serpeated list.
CREATE VIEW View_Automation_Rules_Summary AS
SELECT 
    ar.rule_id, 
    ar.name AS rule_name, 
    ar.description, 
    ar.trigger_condition, 
    ar.trigger_type,
    GROUP_CONCAT(da.device_id SEPARATOR ', ') AS affected_devices -- Concatenates all the device ids and seperates them with commas
FROM 
    AutomationRule ar
JOIN 
    DeviceAutomation da ON ar.rule_id = da.rule_id
GROUP BY 
    ar.rule_id; -- Groups all the tuples with the same rule id into one

    
-- A lot of the views shown from here on are the same thing copy and pasted with a difference only in condition.
CREATE VIEW View_device_night_status AS
SELECT 
    d.model,
    d.location,
    -- The Coalesce function returns the first non-null column from a list of columns. 
    -- This will be used to return the status from a night rule first if it exists,
    -- and then if not from the the device tables default status.
    COALESCE(night_rules.trigger_type, d.status) AS night_status,
     CASE -- Case statement to determine if the given status came from a rule or not.
        WHEN night_rules.trigger_type IS NOT NULL THEN 'Rule'
        ELSE 'Default'
    END AS status_source
FROM 
    Device d
LEFT JOIN -- Left joins indicating every device will have a corresponding row.
    (SELECT 
        da.device_id, 
       
        ar.trigger_type  
     FROM 
        DeviceAutomation da
     JOIN 
        AutomationRule ar ON da.rule_id = ar.rule_id
     WHERE 
        ar.trigger_condition = 'nightime') AS night_rules ON d.device_id = night_rules.device_id;
        
        
        
        
CREATE VIEW View_device_evening_status AS
SELECT 
    d.model,
    d.location,
    -- Use the trigger_type as night_status if a nighttime rule applies, else use the default status
    COALESCE(evening_rules.trigger_type, d.status) AS evening_status,
	CASE
    WHEN evening_rules.trigger_type IS NOT NULL THEN 'Rule'
    ELSE 'Default'
END AS evening_status_source
FROM 
    Device d
LEFT JOIN 
    (SELECT 
        da.device_id, 
        -- Assuming a column that determines what the rule does (e.g., turns device 'On' or 'Off')
        ar.trigger_type  -- Include this column to determine the status effect of the rule
     FROM 
        DeviceAutomation da
     JOIN 
        AutomationRule ar ON da.rule_id = ar.rule_id
     WHERE 
        ar.trigger_condition = 'evening') AS evening_rules ON d.device_id = evening_rules.device_id;
        



CREATE VIEW View_device_away_status AS
SELECT 
    d.model,
    d.location,
    -- Use the trigger_type as night_status if a nighttime rule applies, else use the default status
    COALESCE(away_rules.trigger_type, d.status) AS away_status,
	CASE
    WHEN away_rules.trigger_type IS NOT NULL THEN 'Rule'
    ELSE 'Default'
END AS away_status_source
FROM 
    Device d
LEFT JOIN 
    (SELECT 
        da.device_id, 
        -- Assuming a column that determines what the rule does (e.g., turns device 'On' or 'Off')
        ar.trigger_type  -- Include this column to determine the status effect of the rule
     FROM 
        DeviceAutomation da
     JOIN 
        AutomationRule ar ON da.rule_id = ar.rule_id
     WHERE 
        ar.trigger_condition = 'away') AS away_rules ON d.device_id = away_rules.device_id;




CREATE VIEW View_device_daytime_status AS
SELECT 
    d.model,
    d.location,
    -- Use the trigger_type as night_status if a nighttime rule applies, else use the default status
    COALESCE(daytime_rules.trigger_type, d.status) AS daytime_status,
    CASE
    WHEN daytime_rules.trigger_type IS NOT NULL THEN 'Rule'
    ELSE 'Default'
END AS daytime_status_source
FROM 
    Device d
LEFT JOIN 
    (SELECT 
        da.device_id, 
        -- Assuming a column that determines what the rule does (e.g., turns device 'On' or 'Off')
        ar.trigger_type  -- Include this column to determine the status effect of the rule
     FROM 
        DeviceAutomation da
     JOIN 
        AutomationRule ar ON da.rule_id = ar.rule_id
     WHERE 
        ar.trigger_condition = 'daytime') AS daytime_rules ON d.device_id = daytime_rules.device_id;	
   
   
   
   CREATE VIEW View_device_morning_status AS
SELECT 
    d.model,
    d.location,
    -- Use the trigger_type as night_status if a nighttime rule applies, else use the default status
    COALESCE(morning_rules.trigger_type, d.status) AS morning_status,
    CASE
    WHEN morning_rules.trigger_type IS NOT NULL THEN 'Rule'
    ELSE 'Default'
END AS morning_status_source
FROM 
    Device d
LEFT JOIN 
    (SELECT 
        da.device_id, 
        -- Assuming a column that determines what the rule does 
        ar.trigger_type  -- Include this column to determine the status effect of the rule
     FROM 
        DeviceAutomation da
     JOIN 
        AutomationRule ar ON da.rule_id = ar.rule_id
     WHERE 
        ar.trigger_condition = 'morning') AS morning_rules ON d.device_id = morning_rules.device_id;
        
        
        
        
CREATE VIEW View_device_maintenance_status AS
SELECT 
    d.model,
    d.location,
    -- Use the trigger_type as night_status if a nighttime rule applies, else use the default status
    COALESCE(maintenance_rules.trigger_type, d.status) AS maintenance_status,
    CASE
    WHEN maintenance_rules.trigger_type IS NOT NULL THEN 'Rule'
    ELSE 'Default'
END AS maintenance_status_source
FROM 
    Device d
LEFT JOIN 
    (SELECT 
        da.device_id, 
        -- Assuming a column that determines what the rule does (e.g., turns device 'On' or 'Off')
        ar.trigger_type  -- Include this column to determine the status effect of the rule
     FROM 
        DeviceAutomation da
     JOIN 
        AutomationRule ar ON da.rule_id = ar.rule_id
     WHERE 
        ar.trigger_condition = 'maintenance') AS maintenance_rules ON d.device_id = maintenance_rules.device_id;


-- Straightfoward. Determine whether we're heating, cooling, or neutral based on two checks.
CREATE VIEW View_Thermostat_Mode AS
SELECT 
    t.device_id,
    t.target_temp,
    t.current_temp,
    CASE
        WHEN t.current_temp < t.target_temp THEN 'heating'
        WHEN t.current_temp > t.target_temp THEN 'cooling'
        ELSE 'neutral'
    END AS mode
FROM 
    Thermostat t;
    
    
    
    
    
    
-- ----------------------------------------------------------------------------------------------------------------------

-- SECURITY CODE

-- -------------------------------------------------------------------------------------------------------------------------








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
GRANT EXECUTE ON PROCEDURE SmartHomeDB.Transfer_Ownership TO  'owner_role';
GRANT EXECUTE ON PROCEDURE SmartHomeDB.Create_User_With_Devices TO  'owner_role';

GRANT INSERT ON TABLE EnergyLog TO 'owner_role', 'admin_role';
GRANT INSERT ON TABLE MaintenanceSchedule TO 'owner_role', 'admin_role';

GRANT UPDATE ON TABLE EnergyLog TO 'owner_role', 'admin_role';
GRANT UPDATE ON TABLE MaintenanceSchedule TO 'owner_role', 'admin_role';

GRANT DELETE ON TABLE Device TO 'owner_role', 'admin_role';
GRANT DELETE ON TABLE SmartHome_User TO 'owner_role', 'admin_role';

GRANT UPDATE (status, location) ON SmartHomeDB.Device TO 'admin_role', 'owner_role';

GRANT UPDATE (target_temp, current_temp) ON SmartHomeDB.Thermostat TO 'admin_role', 'owner_role','family_role';


GRANT UPDATE (role) ON SmartHomeDB.SmartHome_User TO 'owner_role';

GRANT UPDATE ON SmartHomeDB.EnergyLog TO 'admin_role', 'owner_role';





-- View allocation block
GRANT SELECT ON View_Device_Energy_Usage TO 'admin_role', 'owner_role';
GRANT SELECT ON View_Upcoming_Maintenance TO 'admin_role', 'owner_role';
GRANT SELECT ON View_Automation_Rules_Summary TO 'admin_role', 'owner_role', 'family_role';
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





-- ----------------------------------------------------------------------------------------------------------------------

-- ALTERING TABLE CODE

-- -------------------------------------------------------------------------------------------------------------------------




-- None of this code is actually used in the database, this is purely for the report.
-- ALTER TABLE Light
-- ADD luminance DECIMAL(5, 2) AFTER blue;
-- UPDATE Light
-- SET luminance = (red + green + blue) / 3;
-- UPDATE Light
-- SET luminance = (red + green + blue) / 3;


-- ALTER TABLE EnergyLog
-- ADD cost DECIMAL(10,2);
-- UPDATE EnergyLog
-- SET cost = energy_consumed * 0.15;






-- ----------------------------------------------------------------------------------------------------------------------

-- QUERYING CODE

-- -------------------------------------------------------------------------------------------------------------------------



-- SELECT device_id, model, location
-- FROM Device
-- WHERE status = 'On';


-- SELECT role, COUNT(*) AS user_count
-- FROM SmartHome_User
-- GROUP BY role;

-- SELECT 
  --  Device.model,
  --  Device.location,
  --  AVG(EnergyLog.energy_consumed) AS average_energy_consumed,
   -- MAX(EnergyLog.energy_consumed) AS peak_energy_consumed,
  --  MIN(EnergyLog.energy_consumed) AS low_energy_consumed,
  --  COUNT(EnergyLog.log_id) AS log_count
-- FROM 
  --  Device
-- JOIN 
   -- EnergyLog ON Device.device_id = EnergyLog.device_id
-- GROUP BY 
   --  Device.device_id
-- HAVING 
   --  log_count > 10 AND (MAX(EnergyLog.energy_consumed) > 1.5 * AVG(EnergyLog.energy_consumed) OR
    -- MIN(EnergyLog.energy_consumed) < 0.5 * AVG(EnergyLog.energy_consumed))
-- ORDER BY 
   -- average_energy_consumed DESC;


