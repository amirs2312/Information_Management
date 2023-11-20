USE SmartHomeDB;

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

CALL Create_User_With_Devices('admin1@example.com', 'sjdfjsgidf', 'Patrick', 'Farmer', 'Admin');
CALL Create_User_With_Devices('admin2@example.com', 'okyaokay', 'krnhfbd', 'Chaplin', 'Admin');
CALL Create_User_With_Devices('family1@example.com', 'fejrgngr', 'David', 'Doe', 'Family');
CALL Create_User_With_Devices('family2@example.com', '2fiun293', 'Eve', 'Evans', 'Family');
CALL Create_User_With_Devices('NM@example.com', 'f4ifen0', 'Nollaig', 'McHugh', 'Admin'); -- I got Nollaig's permission to use his likeness
CALL Create_User_With_Devices('TF1@example.com', 'feonf', 'Tim', 'Farrelly', 'Guest'); -- I got Tim's permission too
CALL Create_User_With_Devices('guest2@example.com', 'eofjn', 'Henry', 'Hill', 'Guest');
CALL Create_User_With_Devices('guest3@example.com', 'fevofwf', 'Ivy', 'Irons', 'Guest');
CALL Create_User_With_Devices('admin3@example.com', 'feofw', 'John', 'Johnson', 'Admin');
CALL Create_User_With_Devices('family4@example.com', 'wefeoinf', 'Koola', 'Kadaraan', 'Family');
CALL Create_User_With_Devices('bowied@example.com', 'feoef', 'David', 'Bowie', 'Guest');

-- Creates a single rule and applies it to all the listed devices
CALL Create_Rule_And_Apply_To_Devices('Evening Routine', 'Turn off lights and lock doors in the evening', 'evening', 'On','1', '2,3,5,8,10');


