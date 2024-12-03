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
drop trigger if exists vao_bang_ra;
delimiter ??
create trigger vao_bang_ra
before update 
on ngaylamviec for each row
begin
if(not(old.giovao=old.giora)) then 
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Khong the cap nhat ngay lam viec';
end if;
end ??
delimiter ;
#############################################################################################
-- cap nhat so gio lam viec
drop trigger if exists cap_nhat_bang_cham_cong;
DELIMITER //
CREATE  trigger cap_nhat_bang_cham_cong 
after update
on ngaylamviec
for each row
BEGIN
	declare raint int;
    declare vaoint int;
	declare ra time;
    declare vao time;
    if((select trangthai 
		from ngaylamviec ng
        where ng.ngay=new.ngay and ng.thang = new.thang 
        and ng.nam = new.nam and new.msnv = ng.msnv)='lam')
        then 
			select time(new.giovao) into vao;
			select time(new.giora) into ra;
			
			if(vao<73000) then set vao = 73000; end if;
			if(ra>203000) then set ra = 203000; end if;
            set raint=time_to_sec(ra);
            set vaoint=time_to_sec(vao);
            update bangchamcong
            set sogiohientai=sogiohientai+raint-vaoint
            where thang=new.thang and nam = new.nam
            and msnv = new.msnv;
		end if;
END // 
DELIMITER ;
