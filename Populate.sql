USE SmartHomeDB;

-- Code for actually populating my database

-- Insertion Block.... For devices
CALL Insert_Light('Smart Bulb V4', 'on', 'Living Room', 255, 255, 255);
CALL Insert_Light('Smart Bulb V4', 'off', 'Bedroom', 0, 0, 0);
CALL Insert_Light('Smart Bulb V4', 'on', 'Kitchen', 255, 255, 255);
CALL Insert_Light('Smart Bulb V4', 'off', 'Bathroom', 0, 0, 0);
CALL Insert_Light('Smart Bulb V4', 'on', 'Dining Room', 255, 255, 255);
CALL Insert_Light('Smart Bulb V4', 'off', 'Garage', 0, 0, 0);
CALL Insert_Light('Smart Bulb V4', 'on', 'Office', 255, 255, 255);

CALL Insert_Camera('Security Camera V5', 'off', 'Front Gate', '1080p', 120, 64);
CALL Insert_Camera('Security Camera V5', 'on', 'Backyard', '720p', 90, 32);
CALL Insert_Camera('Security Camera V5', 'off', 'Garage', '1080p', 120, 128);
CALL Insert_Camera('Security Camera V5', 'on', 'Living Room', '4K', 180, 256);
CALL Insert_Camera('Security Camera V5', 'off', 'Front Door', '1080p', 120, 64);
CALL Insert_Camera('Security Camera V5', 'on', 'Patio', '720p', 90, 32);
CALL Insert_Camera('Security Camera V5', 'off', 'Balcony', '4K', 180, 256);

CALL Insert_Thermostat('EcoThermostat T200', 'on', 'Living Room', 72.0, 71.0);
CALL Insert_Thermostat('EcoThermostat T200', 'off', 'Bedroom', 69.0, 69.0);
CALL Insert_Thermostat('EcoThermostat T200', 'on', 'Kitchen', 70.0, 70.5);
CALL Insert_Thermostat('EcoThermostat T200', 'off', 'Basement', 67.0, 66.5);
CALL Insert_Thermostat('EcoThermostat T200', 'on', 'Office', 71.0, 70.0);

CALL Insert_TV('SuperView 4K', 'off', 'Living Room', 55, '4K');
CALL Insert_TV('SuperView 4K', 'off', 'Master Bedroom', 50, '1080p');
CALL Insert_TV('SuperView 4K', 'off', 'Guest Room', 42, '720p');
CALL Insert_TV('SuperView 4K', 'off', 'Kitchen', 32, '720p');
CALL Insert_TV('SuperView 4K', 'off', 'Basement', 65, '4K');
CALL Insert_TV('SuperView 4K', 'off', 'Office', 55, '4K');

CALL Insert_DoorLock('KeypadLock 3000',  'Front Door', 'keypad', '1923');
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
INSERT INTO SmartHome_User (email, password_hash, first_name, last_name, role) VALUES ('owner@example.com', 'hashed_password', 'Alice', 'Anderson', 'Owner');

INSERT INTO SmartHome_User (email, password_hash, first_name, last_name, role) VALUES ('admin1@example.com', 'sjdfjsgidf', 'Bob', 'Baker', 'Admin');
INSERT INTO SmartHome_User (email, password_hash, first_name, last_name, role) VALUES ('admin2@example.com', 'okyaokay', 'krnhfbd', 'Chaplin', 'Admin');
INSERT INTO SmartHome_User (email, password_hash, first_name, last_name, role) VALUES ('family1@example.com', 'fejrgngr', 'David', 'Doe', 'Family');
INSERT INTO SmartHome_User (email, password_hash, first_name, last_name, role) VALUES ('family2@example.com', '2fiun293', 'Eve', 'Evans', 'Family');
INSERT INTO SmartHome_User (email, password_hash, first_name, last_name, role) VALUES ('family3@example.com', 'f4ifen0', 'Frank', 'Foster', 'Family');
INSERT INTO SmartHome_User (email, password_hash, first_name, last_name, role) VALUES ('guest1@example.com', 'feonf', 'Grace', 'Green', 'Guest');
INSERT INTO SmartHome_User (email, password_hash, first_name, last_name, role) VALUES ('guest2@example.com', 'eofjn', 'Henry', 'Hill', 'Guest');
INSERT INTO SmartHome_User (email, password_hash, first_name, last_name, role) VALUES ('guest3@example.com', 'fevofwf', 'Ivy', 'Irons', 'Guest');
INSERT INTO SmartHome_User (email, password_hash, first_name, last_name, role) VALUES ('admin3@example.com', 'feofw', 'John', 'Johnson', 'Admin');
INSERT INTO SmartHome_User (email, password_hash, first_name, last_name, role) VALUES ('family4@example.com', 'wefeoinf', 'Koola', 'Kadaraan', 'Family');
INSERT INTO SmartHome_User (email, password_hash, first_name, last_name, role) VALUES ('bowied@example.com', 'feoef', 'David', 'Bowie', 'Guest');

-- Creates a single rule and applies it to all the listed devices
CALL Create_Rule_And_Apply_To_Devices('Evening Routine', 'Turn off lights and lock doors in the evening', 'evening', 'On','1', '2,3,5,8,10');


