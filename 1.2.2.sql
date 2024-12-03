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
-- chinh gio lam them neu qua toi thieu/2
drop trigger if exists cham_cong;
delimiter $$
CREATE TRIGGER cham_cong
BEFORE UPDATE ON bangchamcong
FOR EACH ROW
BEGIN
    DECLARE lamthem int;
    DECLARE toithieu int;
    declare thucte int;
    SELECT sogiotoithieu INTO toithieu
    FROM bangchamcong
    WHERE msnv = NEW.msnv
    AND thang = NEW.thang
    AND nam = NEW.nam;
    set thucte=new.sogiohientai+new.sogiolamthem;
    IF thucte > toithieu THEN
		
        SET lamthem = thucte - toithieu;
        IF lamthem > toithieu / 2 THEN
            SET NEW.sogiolamthem = floor(toithieu / 2);
        ELSE
            SET NEW.sogiolamthem = lamthem;
        END IF;
        set new.sogiohientai = toithieu;
    END IF;
    
END $$
DELIMITER ;
##################################################################
 
drop trigger if exists chuyen_duan;
delimiter //
create trigger chuyen_duan
before delete
on phongban
for each row
begin
if(old.mspb = 'PB0000000') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Phong quan ly khong the xoa';
    END IF;
update duan
set ma_phong_ban_quanly = 'PB0000000'
where ma_phong_ban_quanly = old.mspb;
end //
delimiter ;

drop trigger if exists chuyen_giamsat;
delimiter //
create trigger chuyen_giamsat
before delete 
on nhanvien
for each row
begin
declare quanly char(9); 
select nv_quanly into quanly
from phongban p
where p.mspb= old.mspb;
update nvthuviec t
set t.nvgiamsat = quanly
where t.nvgiamsat = old.msnv;
end //
delimiter ;

