-- Nhân viên quản lý phải có  trên 6 năm làm việc tại công ty 
DROP TRIGGER IF EXISTS exp_over_6years_onINSERT;
DELIMITER $$
CREATE TRIGGER exp_over_6years_onINSERT
BEFORE INSERT ON phongban
FOR EACH ROW
BEGIN
    DECLARE emp_exp INT;
    SELECT TIMESTAMPDIFF(YEAR, MIN(startdate), CURDATE())
    INTO emp_exp
    FROM lscongviec
    WHERE msnv = NEW.nv_quanly;
    IF emp_exp IS NULL OR emp_exp < 6 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Nhân viên quản lý chưa có ít nhất 6 năm kinh nghiệm tại công ty!';
    END IF;
END$$
DELIMITER ;
DROP TRIGGER IF EXISTS exp_over_6years_onUPDATE;
DELIMITER $$
CREATE TRIGGER exp_over_6years_onUPDATE
BEFORE UPDATE ON phongban
FOR EACH ROW
BEGIN
    DECLARE emp_exp INT;
    SELECT TIMESTAMPDIFF(YEAR, MIN(startdate), CURDATE())
    INTO emp_exp
    FROM lscongviec
    WHERE msnv = NEW.nv_quanly;
    IF emp_exp IS NULL OR emp_exp < 6 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Nhân viên quản lý chưa có ít nhất 6 năm kinh nghiệm tại công ty!';
    END IF;
END$$
DELIMITER ;
#######################################################################################
