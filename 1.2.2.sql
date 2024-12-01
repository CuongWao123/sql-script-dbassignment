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
-- trigger nhiều bảng
-- Khi số giờ làm thêm thay đổi thì cập nhật Lương làm thêm ở bảng lương
drop trigger if exists update_luong_lam_them_UPDATE;
DELIMITER $$
create trigger update_luong_lam_them_UPDATE
after update
on bangchamcong
for each row
begin
	declare luong_1_hour decimal(10,2);
    declare l_co_ban decimal(10,2);
    declare extra_salary decimal(10,2);
    
    -- lấy lương cơ bản
    select luongcoban
    into l_co_ban
    from bangluong Bang
    where NEW.msnv = Bang.msnv and NEW.thang = Bang.thang and NEW.nam = Bang.nam;
    
    set luong_1_hour = l_co_ban / NEW.sogiotoithieu;
    set extra_salary = luong_1_hour * NEW.sogiolamthem * 2;

    UPDATE bangluong
		set luonglamthem = extra_salary
	where NEW.msnv = bangluong.msnv and NEW.thang = bangluong.thang and NEW.nam = bangluong.nam;
    
end
$$
DELIMITER ;
-- insert
drop trigger if exists update_luong_lam_them_INSERT;
DELIMITER $$
create trigger update_luong_lam_them_INSERT
after insert
on bangchamcong
for each row
begin
	declare luong_1_hour decimal(10,2);
    declare l_co_ban decimal(10,2);
    declare extra_salary decimal(10,2);
    
    -- lấy lương cơ bản
    select luongcoban
    into l_co_ban
    from bangluong Bang
    where NEW.msnv = Bang.msnv and NEW.thang = Bang.thang and NEW.nam = Bang.nam;
    
    set luong_1_hour = l_co_ban / NEW.sogiotoithieu;
    set extra_salary = luong_1_hour * NEW.sogiolamthem * 2;

    UPDATE bangluong
		set luonglamthem = extra_salary
	where NEW.msnv = bangluong.msnv and NEW.thang = bangluong.thang and NEW.nam = bangluong.nam;
    
end
$$
DELIMITER ;
-- test
UPDATE bangchamcong
	set sogiolamthem = 50
where msnv = 'NV0000010';
select * from bangluong where msnv = 'NV0000010';
################################################################