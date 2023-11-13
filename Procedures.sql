USE SmartHomeDB;

-- We're going to have a list of transactions at the beginning for inserting devices and making sure the subclass is defined at the same time
-- Completeness will be forced (though i really am struggling to implement it)


-- Nice little drop block for testing
DROP PROCEDURE IF EXISTS Insert_Energy_Logs;
DROP PROCEDURE IF EXISTS Insert_Multiple_Energy_Logs;
DROP PROCEDURE IF EXISTS Insert_Maintenance_Schedules;
DROP PROCEDURE IF EXISTS Insert_Light;
DROP PROCEDURE IF EXISTS Insert_Camera;
DROP PROCEDURE IF EXISTS Insert_TV;
DROP PROCEDURE IF EXISTS Insert_Thermostat;
DROP PROCEDURE IF EXISTS Insert_Door_Lock;
DROP PROCEDURE IF EXISTS Insert_User;
DROP PROCEDURE IF EXISTS Create_Rule_And_Apply_To_Devices;
DROP PROCEDURE IF EXISTS Assign_Devices_To_User;

-- Procedure for inserting lights
DELIMITER //

CREATE PROCEDURE Insert_Light(
    IN _model VARCHAR(255),
    IN _status ENUM('on', 'off', 'standby', 'not_responding'),
    IN _location VARCHAR(255),
    IN _red TINYINT UNSIGNED,
    IN _green TINYINT UNSIGNED,
    IN _blue TINYINT UNSIGNED
)
BEGIN
    DECLARE _device_id INT;

    START TRANSACTION;
    
    INSERT INTO Device (model, status, location) VALUES (_model, _status, _location);
    SET _device_id = LAST_INSERT_ID();
    INSERT INTO Light (device_id, red, green, blue) VALUES (_device_id, _red, _green, _blue);
    
    COMMIT;
END;
//


-- Procedure for inserting cameras
CREATE PROCEDURE Insert_Camera(
    IN _model VARCHAR(255),
    IN _status ENUM('on', 'off', 'standby', 'not_responding'),
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
    IN _status ENUM('on', 'off', 'standby', 'not_responding'),
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
    IN _status ENUM('on', 'off', 'standby', 'not_responding'),
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
    
    -- Insert into DoorLock table with conditional door_code
    IF _lock_type = 'keypad' AND _door_code IS NOT NULL THEN
        INSERT INTO DoorLock (device_id, lock_type, door_code) VALUES (_device_id, _lock_type, _door_code);
    ELSEIF _lock_type != 'keypad' THEN
        INSERT INTO DoorLock (device_id, lock_type) VALUES (_device_id, _lock_type);
    ELSE
    -- Keypad doors must have none null door codes
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Keycode must be provided for keypad locks';
    END IF;
    
    COMMIT;
END;
//


-- A function to create n data logs for device i
CREATE PROCEDURE Insert_Energy_Logs(
    IN _device_id INT,
    IN _log_count INT
)
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE _log_time TIMESTAMP;
    DECLARE _energy_consumed DECIMAL(5,2);
   

    WHILE i <= _log_count DO
        -- Generate a log_time within the last few months (Took to me too long to write this line)
        SET _log_time = NOW() - INTERVAL FLOOR(RAND() * 90) DAY;
        -- Generate some random energy consumed value
        SET _energy_consumed = FLOOR(RAND() * 100) + 1; 
        

        INSERT INTO EnergyLog (device_id, log_time, energy_consumed)
        VALUES (_device_id, _log_time, _energy_consumed);

        SET i = i + 1;
    END WHILE;
END;
//


-- A procedure for populating the database, loops over wach device and creates a number of energy logs for them
CREATE PROCEDURE Insert_Multiple_Energy_Logs()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE _device_id INT;
    DECLARE cur CURSOR FOR SELECT device_id FROM Device;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    OPEN cur;

    read_loop: LOOP
        FETCH cur INTO _device_id;
        IF done THEN
            LEAVE read_loop;
        END IF;

        CALL Insert_Energy_Logs(_device_id, 5);
    END LOOP;

    CLOSE cur;
    END;

//


-- A Procedure for pupulating the database with schedules
-- Loops over devices that would need maintenance and reandomly assigns them last and next dates
CREATE PROCEDURE Insert_Maintenance_Schedules()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE _device_id INT;
    DECLARE _last_maintenance_date DATE;
    DECLARE _next_maintenance_date DATE;
    DECLARE cur CURSOR FOR 
        SELECT device_id 
        FROM Device 
        WHERE model LIKE 'Camera%' OR model LIKE 'Thermostat%';
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

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

    CLOSE cur;
END;
//

-- Procedure for populating 
CREATE PROCEDURE Create_Rule_And_Apply_To_Devices(
    IN _name VARCHAR(255),
    IN _description TEXT,
    IN _trigger_condition ENUM('daytime', 'evening', 'nightime', 'morning', 'away', 'maintenance'),
    IN _creator_id INT,
    IN _device_ids TEXT -- A comma separated list of device IDs
)
BEGIN
    DECLARE _rule_id INT;
    DECLARE _device_id INT;
    DECLARE _index INT;
    DECLARE _next_comma INT;
    DECLARE _sub_str_length INT;

    -- Insert the rule into the AutomationRule table
    INSERT INTO AutomationRule (name, description, trigger_condition, fk_creator_id)
    VALUES (_name, _description, _trigger_condition, _creator_id);
    SET _rule_id = LAST_INSERT_ID();

    -- Initialize loop variables
    SET _device_ids = CONCAT(_device_ids, ',');
    SET _index = 1;

    -- Loop through the list of device IDs
    WHILE _index < CHAR_LENGTH(_device_ids) DO
        -- Find the next comma
        SET _next_comma = LOCATE(',', _device_ids, _index);
        -- Calculate the length of the substring to extract
        SET _sub_str_length = _next_comma - _index;
        -- Extract the next device ID
        SET _device_id = CAST(SUBSTRING(_device_ids, _index, _sub_str_length) AS UNSIGNED);
        -- Insert association for the device ID into DeviceAutomation
        INSERT INTO DeviceAutomation (rule_id, device_id) VALUES (_rule_id, _device_id);
        -- Move the index to the character after the next comma
        SET _index = _next_comma + 1;
    END WHILE;
END;
//


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
            WHERE model LIKE 'TV%' OR model LIKE 'Light%'
            ON DUPLICATE KEY UPDATE device_id = VALUES(device_id);
        
        WHEN 'Family' THEN
            -- Family gets TVs, Lights, Thermostats, and Locks
            INSERT INTO UserDeviceControl (user_id, device_id)
            SELECT _user_id, device_id FROM Device
            WHERE model LIKE 'TV%' OR model LIKE 'Light%' OR model LIKE 'Thermostat%' OR model LIKE 'Lock%'
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
            ON DUPLICATE KEY UPDATE device_id = VALUES(device_id);
        
        ELSE
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid user role for device assignment.';
	END CASE;
    
END;
//

CREATE PROCEDURE Assign_Devices_To_All_Users()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE _user_id INT;
    DECLARE cur CURSOR FOR SELECT user_id FROM SmartHome_User;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    OPEN cur;

    assign_loop: LOOP
        FETCH cur INTO _user_id;
        IF done THEN
            LEAVE assign_loop;
        END IF;

        CALL AssignDevicesToUser(_user_id);
    END LOOP;

    CLOSE cur;
END;
//