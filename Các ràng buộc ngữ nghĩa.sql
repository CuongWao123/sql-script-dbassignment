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
-- khong quan li chinh minh
drop trigger if exists k_quanli_chinhminh_insert;
delimiter //
create trigger k_quanli_chinhminh_insert
before insert 
on nvchinhthuc
for each row
begin 
IF new.msnv =new.nguoiquanly THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ma nguoi quan ly khong the trung voi ma nhan vien';
    END IF;
end //
delimiter ;
drop trigger if exists k_quanli_chinhminh_update;
delimiter //
create trigger k_quanli_chinhminh_update
before update
on nvchinhthuc
for each row
begin 
IF new.msnv =new.nguoiquanly THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ma nguoi quan ly khong the trung voi ma nhan vien';
    END IF;
end //
delimiter ;
#################################################################################################
-- khong cho cap nhat khi gio ra khac gio vao
-- drop trigger if exists vao_bang_ra;
-- delimiter ??
-- create trigger vao_bang_ra
-- before update 
-- on ngaylamviec for each row
-- begin
-- if(not(old.giovao=old.giora)) then 
-- SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Khong the cap nhat ngay lam viec';
-- end if;
-- end ??
-- delimiter ;
#############################################################################################
-- cap nhat so gio lam viec
drop function if exists tinhgiolamtrongthang;
delimiter //
create function tinhgiolamtrongthang (t int,n int,nv char(9))
returns int
deterministic
begin
declare ra time;
declare vao time;
declare raint int;
declare vaoint int;
declare gio int;
declare tt varchar(20);
DECLARE done INT DEFAULT 0;
DECLARE cur CURSOR FOR
        SELECT time(giovao), time(giora), trangthai
        FROM ngaylamviec n
        WHERE n.thang =t and n.nam = n and n.msnv=nv;

    -- Handler để thoát khi hết con trỏ
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    set gio =0;
    OPEN cur;

    read_loop: LOOP
        FETCH cur INTO vao, ra,tt ;
        IF done = 1 THEN
            LEAVE read_loop;
        END IF;
			if(vao<73000) then set vao = 73000; end if;
			if(ra>203000) then set ra = 203000; end if;
            set raint=time_to_sec(ra);
            set vaoint=time_to_sec(vao);
        -- Chỉ tính tổng giờ nếu trạng thái là "làm"
        IF tt = 'lam' THEN
            SET gio = gio + raint - vaoint;
        END IF;
    END LOOP;

    -- Đóng con trỏ
    CLOSE cur;
return gio;
 
end //
delimiter ;
-- cap nhat so gio lam viec
drop trigger if exists cap_nhat_bang_cham_cong;
DELIMITER //
CREATE  trigger cap_nhat_bang_cham_cong 
after update
on ngaylamviec
for each row
BEGIN
	
            update bangchamcong
            set sogiohientai=tinhgiolamtrongthang(new.thang,new.nam,new.msnv)
            where thang=new.thang and nam = new.nam
            and msnv = new.msnv;
		update bangchamcong
            set sogiohientai=tinhgiolamtrongthang(old.thang,old.nam,old.msnv)
            where thang=old.thang and nam = old.nam
            and msnv = old.msnv;
END // 
DELIMITER ;
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
    SELECT sogiotoithieu,sogiohientai INTO toithieu,thucte
    FROM bangchamcong
    WHERE msnv = NEW.msnv
    AND thang = NEW.thang
    AND nam = NEW.nam;
    -- set thucte=new.sogiohientai+new.sogiolamthem;
    IF thucte > toithieu THEN
		begin
        SET lamthem = thucte - toithieu;
        IF lamthem > toithieu / 2 THEN
            SET NEW.sogiolamthem = floor(toithieu / 2);
        ELSE
            SET NEW.sogiolamthem = lamthem;
        END IF;
        set new.sogiohientai = toithieu;
        end;
        else 
        set new.sogiolamthem=0;
    END IF;
    
END $$
DELIMITER ;
