-- 					khi them nhan vien 
DROP TRIGGER IF EXISTS update_soluong_nhanvien_insert_nhanvien;
DELIMITER $$
CREATE TRIGGER update_soluong_nhanvien_insert_nhanvien
AFTER INSERT
ON nhanvien
FOR EACH ROW
BEGIN
    UPDATE phongban
    SET soluongnhanvien = (SELECT COUNT(*)
                           FROM nhanvien
                           WHERE mspb = NEW.mspb)
    WHERE mspb = NEW.mspb;
END $$
DELIMITER ;
-- 					Khi thay doi ma phong ban o bang nhan _vien
DROP TRIGGER IF EXISTS update_soluong_nhanvien_update_mspb;
DELIMITER $$
CREATE TRIGGER update_soluong_nhanvien_update_mspb
AFTER UPDATE
ON nhanvien
FOR EACH ROW
BEGIN
    -- Cập nhật số lượng nhân viên của phòng ban cũ
    UPDATE phongban
    SET soluongnhanvien = (SELECT COUNT(*)
                           FROM nhanvien
                           WHERE mspb = OLD.mspb)
    WHERE mspb = OLD.mspb;

    -- Cập nhật số lượng nhân viên của phòng ban mới
    UPDATE phongban
    SET soluongnhanvien = (SELECT COUNT(*)
                           FROM nhanvien
                           WHERE mspb = NEW.mspb)
    WHERE mspb = NEW.mspb;
END $$
DELIMITER ;
-- 						trigger khi xoa
DROP TRIGGER IF EXISTS update_soluong_nhanvien_khixoa;
DELIMITER $$
CREATE TRIGGER update_soluong_nhanvien_khixoa
AFTER DELETE
ON nhanvien
FOR EACH ROW
BEGIN
    UPDATE phongban
    SET soluongnhanvien = (SELECT COUNT(*)
                           FROM nhanvien
                           WHERE mspb = OLD.mspb)
    WHERE mspb = OLD.mspb;
END $$
DELIMITER ;
################################################################

