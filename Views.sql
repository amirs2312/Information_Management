USE SmartHomeDB;

-- The view file. All views are defined here.


-- Classic Drop Block

DROP VIEW IF EXISTS View_Device_Energy_Usage;
DROP VIEW IF EXISTS View_Upcoming_Maintenance;
DROP VIEW IF EXISTS View_Automation_Rules_Summary;
DROP VIEW IF EXISTS View_Automation_Rules_Summary;
DROP VIEW IF EXISTS View_User_Roles;

-- A view that shows how much a device costs
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
    EnergyLog el ON d.device_id = el.device_id
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
    
    
    
-- A simple view that shows all users names next to their roles
CREATE VIEW View_User_Roles AS
SELECT
	u.user_id,
	u.first_name,
    u.last_name,
    u.role
FROM
	SmartHome_User u;
    
    
    
-- Shows a rule and its effected devices as a comma serpeated list.
CREATE VIEW View_Automation_Rules_Summary AS
SELECT 
    ar.rule_id, 
    ar.name AS rule_name, 
    ar.description, 
    ar.trigger_condition, 
    GROUP_CONCAT(d.device_id SEPARATOR ', ') AS affected_devices
FROM 
    AutomationRule ar
JOIN 
    DeviceAutomation da ON ar.rule_id = da.rule_id
JOIN 
    Device d ON da.device_id = d.device_id
GROUP BY 
    ar.rule_id;

    


    
