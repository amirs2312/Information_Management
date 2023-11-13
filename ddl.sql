DROP DATABASE IF EXISTS SmartHomeDB;
CREATE DATABASE SmartHomeDB;
USE SmartHomeDB;

-- This part is for resetting my databse when testing new features





CREATE TABLE Device (
    device_id INT AUTO_INCREMENT PRIMARY KEY,
    model VARCHAR(255) NOT NULL,
    status ENUM('on', 'off', 'standby', 'not_responding') NOT NULL,
    location VARCHAR(255) NOT NULL
);





CREATE TABLE SmartHome_User (
	user_id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    role ENUM('Guest', 'Family', 'Admin', 'Owner')
    );
    
    
    
    
    
CREATE TABLE Light (
    device_id INT PRIMARY KEY,
    red TINYINT UNSIGNED NOT NULL,
    green TINYINT UNSIGNED NOT NULL,
    blue TINYINT UNSIGNED NOT NULL,
    FOREIGN KEY (device_id) REFERENCES Device(device_id)
);





CREATE TABLE Thermostat (
    device_id INT PRIMARY KEY,
    target_temp DECIMAL(5,2) NOT NULL,
    current_temp DECIMAL(5,2) NOT NULL,
    FOREIGN KEY (device_id) REFERENCES Device(device_id)
);





CREATE TABLE Camera (
    device_id INT PRIMARY KEY,
    resolution VARCHAR(255) NOT NULL,
    field_of_view INT NOT NULL,
    storage_capacity_gb INT NOT NULL,
    FOREIGN KEY (device_id) REFERENCES Device(device_id)
);





CREATE TABLE MaintenanceSchedule (
    schedule_id INT AUTO_INCREMENT PRIMARY KEY,
    last_maintenance_date DATE NOT NULL,
    next_maintenance_date DATE NOT NULL,
    device_id INT UNIQUE NOT NULL,
    FOREIGN KEY (device_id) REFERENCES Device(device_id)
);





CREATE TABLE EnergyLog (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    log_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    energy_consumed DECIMAL(10,2) NOT NULL,
    device_id INT NOT NULL,
    FOREIGN KEY (device_id) REFERENCES Device(device_id)
);





CREATE TABLE UserDeviceControl (
    user_id INT NOT NULL,
    device_id INT NOT NULL,
    PRIMARY KEY (user_id, device_id),
    FOREIGN KEY (user_id) REFERENCES SmartHome_User(user_id),
    FOREIGN KEY (device_id) REFERENCES Device(device_id)
);





CREATE TABLE DoorLock (
    device_id INT PRIMARY KEY,
    door_code VARCHAR(255) ,
    lock_type ENUM('keypad', 'biometric', 'key', 'app') NOT NULL,
    FOREIGN KEY (device_id) REFERENCES Device(device_id)
);


CREATE TABLE TV (
    device_id INT PRIMARY KEY,
    screen_size INT NOT NULL,
    resolution VARCHAR(255) NOT NULL,
    FOREIGN KEY (device_id) REFERENCES Device(device_id)
);


CREATE TABLE AutomationRule (
    rule_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    trigger_condition ENUM('daytime', 'evening', 'nightime', 'morning', 'away', 'maintenance') NOT NULL,
    fk_creator_id INT NOT NULL,
    FOREIGN KEY (fk_creator_id) REFERENCES SmartHome_User(user_id)
);




CREATE TABLE DeviceAutomation (
    rule_id INT NOT NULL,
    device_id INT NOT NULL,
    PRIMARY KEY (rule_id, device_id),
    FOREIGN KEY (rule_id) REFERENCES AutomationRule(rule_id),
    FOREIGN KEY (device_id) REFERENCES Device(device_id)
);