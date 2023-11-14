USE SmartHomeDB;

-- Triggers start here:
-- What other triggers I need that arent done yet
-- Trigger to check that two rules dont apply to same device under the same condition with opposite status setting
-- Trigger to check
DROP TRIGGER IF EXISTS Owner_Delete_Check;
DROP TRIGGER IF EXISTS Owner_Insert_Check;
DROP TRIGGER IF EXISTS Prevent_Conflicting_Rules;

DELIMITER //

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
    DECLARE conflicting_rule_count INT;
    DECLARE existing_action ENUM('On', 'Off');

    -- Find if there is an existing opposite action for the same device and condition
    SELECT trigger_type INTO existing_action
    FROM DeviceAutomation da
    JOIN AutomationRule ar ON da.rule_id = ar.rule_id
    WHERE da.device_id = NEW.device_id 
      AND ar.trigger_condition = (SELECT trigger_condition FROM AutomationRule WHERE rule_id = NEW.rule_id)
    LIMIT 1;

    -- Count the existing rules that have the same condition but opposite action
    SELECT COUNT(*)
    INTO conflicting_rule_count
    FROM DeviceAutomation da
    JOIN AutomationRule ar ON da.rule_id = ar.rule_id
    WHERE da.device_id = NEW.device_id 
      AND ar.trigger_condition = (SELECT trigger_condition FROM AutomationRule WHERE rule_id = NEW.rule_id)
      AND ar.trigger_type != existing_action;

    -- If there is a conflicting rule with an opposite action, signal an error
    IF existing_action IS NOT NULL AND conflicting_rule_count > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Conflicting automation rules detected: cannot have opposite actions for the same device and condition.';
    END IF;
END;

//
DELIMITER ;
