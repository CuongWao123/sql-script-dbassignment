-- Các hàm hỗ trợ 
-- kiem tra ma so phai du 9 ky tu va khong duoc de trong 
DELIMITER //
CREATE PROCEDURE check_ms (IN msnv VARCHAR(100))
BEGIN
	if msnv is null then 
		signal sqlstate '45000' set message_text ='Hay nhap ma so nhan vien!';
	end if ;
    IF LENGTH(msnv) != 9 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ma so nhan vien nay khong dung 9 ky tu!';
    END IF;
END //
DELIMITER ;
-- 0 . check nhan vien phai du 18 tuoi va khac null
DELIMITER //
CREATE PROCEDURE check_dob (IN dob DATE)
BEGIN
	if dob is null then
		signal sqlstate '45000' set message_text = 'Hay nhap ngay sinh !';
	end if;
    IF TIMESTAMPDIFF(YEAR, dob, CURDATE()) < 18 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Nhan vien chua du 18 tuoi!';
    END IF;
END //
DELIMITER ;
-- check cccd phai co 12 ky tu va phai toan la so
DELIMITER //
CREATE PROCEDURE check_cccd (in cccd varchar(100))
BEGIN
	if cccd is null then 
		signal sqlstate '45000' set message_text = 'Hay nhap cccd !';
	end if;
    IF length(cccd) != 12 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'CCCD chua dung 12 ky tu';
    END IF;
    IF cccd NOT REGEXP '^[0-9]{12}$' THEN
		SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'CCCD phai la cac ky tu so!';
	end if ;
END //
DELIMITER ;
##########################################################################
-- them vao nhan vien chinh thuc
-- them lich su cong viec
drop procedure if exists insert_into_ls_congviec;
DELIMITER //
CREATE PROCEDURE insert_into_ls_congviec (
    msnv CHAR(9),
    start_date DATE,
    chucvu VARCHAR(30),
    loainv VARCHAR(10),
    lcb DECIMAL(10,2),
    tenpb varchar (30)
)
BEGIN
    -- Khai báo biến
    DECLARE cur_stt INT;
    -- Kiểm tra nếu nhân viên đã có trong bảng ls_congviec
    IF EXISTS (SELECT 1 FROM lscongviec as ls WHERE ls.msnv = msnv) THEN
        -- Lấy giá trị stt cao nhất cho nhân viên
        SELECT MAX(stt) INTO cur_stt
        FROM lscongviec as ls
		WHERE ls.msnv = msnv;
        -- Thêm công việc mới cho nhân viên, tăng stt lên 1
        INSERT INTO lscongviec (msnv, stt, startdate, chucvu, loainv, luongcoban, tenphongban)
        VALUES (msnv, cur_stt + 1, start_date, chucvu, loainv, lcb, tenpb);
    ELSE
        -- Nếu nhân viên chưa có trong bảng, thêm công việc mới với stt = 1
        INSERT INTO lscongviec (msnv, stt, startdate, chucvu, loainv, luongcoban, tenphongban)
        VALUES (msnv, 1, start_date, chucvu, loainv, lcb, tenpb);
    END IF;
END //
DELIMITER ;
--              procedure Them 1 nhan vien chinh thuc 
DROP PROCEDURE IF EXISTS insert_nvchinhthuc;
DELIMITER //
CREATE PROCEDURE insert_nvchinhthuc (
    msnv CHAR(9),   
    hovaten VARCHAR(20), 
    ngaysinh DATE, 
    gioitinh VARCHAR(4), 
    cccd CHAR(12), 
    masophongban CHAR(9), -- check khoa ngoai
    bhxh VARCHAR(20),
    nguoiquanly CHAR(9), -- check khoa ngoai
    startdate DATE,
    chucvu VARCHAR(20),
    lcb DECIMAL(10,2),
    sogiotoithieu INT
)
BEGIN
	CALL check_ms(msnv);
    IF hovaten IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Hay nhap ten!';
    END IF;
    CALL check_dob(ngaysinh);
    CALL check_cccd(cccd);
    IF gioitinh IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Hay nhap gioi tinh!';
    END IF;
	IF gioitinh not in ('nam' , 'nu' ,'khac') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Gioi tinh khong hop le!';
    END IF;
    
    IF bhxh IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Hay them BHXH!';
    END IF;
    IF startdate IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Hãy thêm ngày bắt đầu!';
    END IF;
    IF chucvu IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Hãy thêm chức vụ!';
    END IF;
    IF lcb IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Hãy thêm lương cơ bản!';
    END IF;
	-- check khoa ngoai 
      IF NOT EXISTS (SELECT 1 FROM phongban WHERE mspb = masophongban) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ma phong ban khong ton tai!';
     END IF;
     IF nguoiquanly is not null and  NOT EXISTS (SELECT 1 FROM nvchinhthuc as nvct WHERE nvct.msnv = nguoiquanly) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nguoi quan ly khong ton tai!';
     END IF;
    
    -- insert vao bang nhan vien
	INSERT INTO nhanvien (msnv, hoten, ngaysinh, gioitinh, cccd, loainhanvien, mspb) 
    VALUES (msnv, hovaten, ngaysinh, gioitinh, cccd, 'chinh thuc', masophongban);

    INSERT INTO nvchinhthuc (msnv, bhxh, nguoiquanly) 
    VALUES (msnv, bhxh, nguoiquanly);

    -- Truy vấn tên phòng ban trực tiếp khi thêm vào lịch sử công việc
    CALL insert_into_ls_congviec(
        msnv, 
        startdate, 
        chucvu, 
        'chinh thuc', 
        lcb, 
        (SELECT tenphongban FROM phongban WHERE mspb = masophongban)
    );
    INSERT INTO bangluong(msnv, thang, nam, luongcoban) 
    VALUES (msnv, MONTH(startdate), YEAR(startdate), lcb);
    INSERT INTO bangchamcong (msnv, thang, nam, sogiohientai, sogiotoithieu, sogiolamthem) 
    VALUES (msnv, MONTH(startdate), YEAR(startdate), 0, sogiotoithieu, 0);
	
	select 'Thanh cong';
END //
DELIMITER ;
CALL insert_nvchinhthuc ('NV0023456','Nguyen Van A', '2000-01-01', 'nam', '123456789010', 
'PB0000001', 'BHXH123456789', 'NV0000002',  '2024-12-01', 'Nhân viên',  10000.00,  160  );
select * from nhanvien ;
select * from nvchinhthuc ;
select * from bangluong;
select * from bangchamcong;

select * from phongban;
--              Xoa 1 nhan vien 
drop procedure if exists delete_nhanvien ;
DELIMITER $$
CREATE PROCEDURE delete_nhanvien(IN p_msnv CHAR(9))
BEGIN
	
    IF EXISTS (SELECT 1 FROM nhanvien WHERE msnv = p_msnv) THEN
	begin
	if(p_msnv=(select p.nv_quanly from phongban p where p.mspb=(select n.mspb from nhanvien n where n.msnv=p_msnv))) then
	SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Khong the xoa truong phong'; end if;
        DELETE FROM nhanvien WHERE msnv = p_msnv;
	end;
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Khong co nhan vien nay';
    END IF;
    select 'Thanh cong';
END $$
DELIMITER ;
select * from nhanvien;
call delete_nhanvien ('NV0023456')
-- 				Sua ten mot nhan vien
DELIMITER $$
CREATE PROCEDURE sua_ten_nhanvien(
    IN p_msnv CHAR(9),       
    IN p_hoten_moi VARCHAR(30) 
)
BEGIN
    IF EXISTS (SELECT 1 FROM nhanvien WHERE msnv = p_msnv) THEN
        UPDATE nhanvien
        SET hoten = p_hoten_moi
        WHERE msnv = p_msnv;
    ELSE
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Khong co nhan vien nay';
    END IF;
    select 'Thanh cong';
END $$
DELIMITER ;
select * from nhanvien;
call sua_ten_nhanvien('NV0000000', "Adam Smith");
############################################################################
-- 					them du an
drop procedure if exists them_duan;
DELIMITER $$
CREATE PROCEDURE them_duan (
    IN p_maDA CHAR(9),
    IN p_tong_von_dau_tu DECIMAL(20),
    IN p_start_date DATE,
    IN p_ten_DA VARCHAR(100),
    IN p_mota VARCHAR(100),
    IN p_ma_phong_ban_quanly CHAR(9)
)
BEGIN
    IF p_maDA IS NULL OR LENGTH(p_maDA) != 9 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ma so du an khong duoc null va phai co dung 9 ky tu';
    END IF;
    IF p_tong_von_dau_tu < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Tong von dau tu lon hon hoac bang 0';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM phongban WHERE mspb = p_ma_phong_ban_quanly) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ma phong ban quan ly nay khong ton tai';
    END IF;
    INSERT INTO duan (maDA, tong_von_dau_tu, start_date, ten_DA, mota, ma_phong_ban_quanly)
    VALUES (p_maDA, p_tong_von_dau_tu, p_start_date, p_ten_DA, p_mota, p_ma_phong_ban_quanly);
	select 'Thanh cong';
END $$
DELIMITER ;
-- 					xoa du an
call them_duan('',100000 ,'2024-10-10' ,'DA manh cuong','manh cuong dep zai' ,'PB123123' );

drop procedure if exists xoa_duan;
DELIMITER $$
CREATE PROCEDURE xoa_duan (
    IN p_maDA CHAR(9)
)
BEGIN
    IF p_maDA IS NULL OR LENGTH(p_maDA) != 9 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ma du an phai co dung 9 ky tu';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM duan WHERE maDA = p_maDA) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Du an nay khong ton tai.';
    END IF;
    DELETE FROM duan WHERE maDA = p_maDA;
select 'Thanh cong';
END $$
DELIMITER ;
-- 					sua du an 
drop procedure if exists sua_ten_duan ;
DELIMITER $$
CREATE PROCEDURE sua_ten_duan (
    IN p_maDA CHAR(9),         
    IN p_ten_DA VARCHAR(100)   
)
BEGIN
    -- Kiểm tra mã dự án
    IF p_maDA IS NULL OR LENGTH(p_maDA) != 9 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ma du an phai co dung 9 ky tu va khong duoc de trong';
    END IF;

    -- Kiểm tra tên dự án mới
    IF p_ten_DA IS NULL OR LENGTH(p_ten_DA) = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ten du an khong duoc de trong ';
    END IF;

    -- Kiểm tra dự án có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM duan WHERE maDA = p_maDA) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Dự án với mã này không tồn tại.';
    END IF;

    -- Cập nhật tên dự án
    UPDATE duan
    SET ten_DA = p_ten_DA
    WHERE maDA = p_maDA;
select 'Thanh cong';
END $$
DELIMITER ;
###############################################################
-- 				them phong ban
select * from lscongviec where msnv= 'NV9900002';
call THEM_PHONGBAN ('PB0000009' ,'Quản lý các dự án trong công ty','Phong ban quản lý dự án' ,  'NV9900002'  );
DROP PROCEDURE IF EXISTS THEM_PHONGBAN;
DELIMITER $$
CREATE PROCEDURE them_phongban (
    IN p_mspb CHAR(9),
    IN p_mota VARCHAR(100),
    IN p_tenphongban VARCHAR(30),
    IN p_nv_quanly CHAR(9)
)
BEGIN
    IF p_mspb IS NULL OR LENGTH(p_mspb) != 9 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ma phong ban phai co dung 9 ky tu';
    END IF;
    IF p_tenphongban IS NULL OR LENGTH(p_tenphongban) = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ten phong ban khong duoc de trong';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM nhanvien WHERE msnv = p_nv_quanly) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Nhan vien khong ton tai !';
    END IF;

    -- Thêm phòng ban
    INSERT INTO phongban (mspb, mota, tenphongban, ngaythanhlap, nv_quanly)
    VALUES (p_mspb, p_mota, p_tenphongban,curdate(), p_nv_quanly);
select 'Thanh cong';
END $$
DELIMITER ;
-- call them_phongban('PB0000009','phong ban oi','cuong dep zai' , 'NV0000011');
-- 				sua phong ban
DROP PROCEDURE IF EXISTS update_tenphongban;
DELIMITER //
CREATE PROCEDURE update_tenphongban (
    in_mspb CHAR(9),         
    in_tenphongban VARCHAR(50) 
)
BEGIN
    -- Cập nhật tên phòng ban trong bảng phongban
    UPDATE phongban
    SET tenphongban = in_tenphongban
    WHERE mspb = in_mspb;

    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ma phong ban nay khong ton tai';
    END IF;select 'Thanh cong';
END //
DELIMITER ;
-- CALL update_tenphongban('PB0000009', 'Cuong dep zaiiiiii');
-- select * from phongban;
-- 				xoa phong ban phai co nguoi thay the
DROP PROCEDURE IF EXISTS delete_phongban;
DELIMITER //
CREATE PROCEDURE delete_phongban(
    in_mspb CHAR(9)  
)
BEGIN
    DECLARE phongban_count INT;
    SELECT COUNT(*) INTO phongban_count
    FROM phongban
    WHERE mspb = in_mspb;
    
    IF phongban_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Phong ban nay khong ton tai';
    ELSE
        DELETE FROM phongban
        WHERE mspb = in_mspb;
    END IF;select 'Thanh cong';
END //
DELIMITER ;
###############################################################
-- insert bang luong
drop procedure if exists insert_bangluong;
DELIMITER $$
create procedure insert_bangluong(
	in in_msnv char(9),
    in in_thang int,
    in in_nam int,
    in in_luongcoban decimal(10,2)
)
begin
	if not exists (select 1 from nhanvien where msnv = in_msnv) then
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Khong co nhan vien nay'; 
    end if;
    
    if (in_thang < 1 or in_thang > 12) then
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Thang khong hop le'; 
    end if;
    
    if (in_nam < 0) then
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nam khong hop le'; 
    end if;
    
    if (in_luongcoban < 0) then
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Luong co ban khong hop le'; 
    end if;
    
    if exists (select 1 from bangluong 
					where msnv = in_msnv and thang = in_thang and nam = in_nam) 
    then
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ban ghi da ton tai'; 
    end if;
    
    insert bangluong (msnv,thang,nam,luongcoban)
    values (in_msnv,in_thang,in_nam,in_luongcoban);
    
    
end $$
DELIMITER ;

-- ----------------------------------------------------
-- update bangluong 
-- nếu có lương >15tr thì thuế = 15%, ngược lại là 0%
-- lương 1 giờ = lương cơ bản / số giờ làm tối thiểu
-- lương làm thêm = lương 1 giờ x 2 x số giờ làm thêm
-- update xăng xe, ăn trưa, hỗ trợ khác trong hàm tính lương
-- Bảo hiểm xã hội (bhxh) 5% lương cơ bản
-- Bảo hiểm y tế (bhyt) 1% lương cơ bản  
-- khấu trừ 0% cho nhân viên thử việc và 5% cho nhân viên (% so với lương cơ bản)
-- -- tính lương trừ không làm đủ giờ tối thiểu
-- -- lương ko đủ nếu làm không đủ giờ tối thiểu thì TRỪ (số giờ thiếu x lương 1 giờ)
-- lương thực tế = lương làm thêm + lương cơ bản + xăng xe + ăn trưa + hỗ trợ khác - bhyt - bhxh - thuế - khấu trừ - lương làm không đủ giờ

-- sửa bảng lương + tính toán lương thực tế
-- thêm xăng xe, ăn trưa, hỗ trợ khác khi tính lương
drop procedure if exists tinh_luong;
DELIMITER $$
create procedure tinh_luong(
	in in_msnv char(9),
    in in_thang int,
    in in_nam int,
    in in_xangxe decimal(10,2),
    in in_antrua decimal(10,2),
    in in_hotrokhac decimal(10,2)
)
begin
	
	declare loai_nv varchar(10);
    declare in_luongcoban decimal(10,2);
    declare in_khautru decimal(10,2);
    declare in_thue decimal(10,2);
    declare total_luong decimal(10,2);
    declare hour_luong decimal(10,2);
    declare extra_luong decimal(10,2);
    declare luong_tru_ko_du_gio decimal(10,2);
    declare in_gio_toi_thieu int;
    declare in_gio_hien_tai int;
    declare thang_sau int;
    declare nam_sau int;
    
    -- validate
    if not exists (select 1 from nhanvien where msnv = in_msnv) then
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Khong co nhan vien nay'; 
    end if;
    
    if (in_thang < 1 or in_thang > 12) then
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Thang khong hop le'; 
    end if;
    
    if (in_xangxe < 0) then
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tien xang xe khong hop le'; 
    end if;
    
    if (in_antrua < 0) then
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tien an trua khong hop le'; 
    end if;
    
    if (in_hotrokhac < 0) then
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tien ho tro khac khong hop le'; 
    end if;
    
    if not exists (select 1 from bangluong 
					where msnv = in_msnv and thang = in_thang and nam = in_nam) 
    then
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Khong ton tai ban ghi can cap nhat'; 
    end if; 
    
    -- chọn loại nhân viên
    select loainhanvien 
    into loai_nv
    from nhanvien where in_msnv = nhanvien.msnv;
    
    -- chọn lương cơ bản
    select luongcoban
    into in_luongcoban
    from bangluong
    where in_msnv = bangluong.msnv and in_thang = bangluong.thang and in_nam = bangluong.nam;
    
    -- chọn lương làm thêm
    select luonglamthem
    into extra_luong
    from bangluong
    where in_msnv = bangluong.msnv and in_thang = bangluong.thang and in_nam = bangluong.nam;
    
    -- lấy số giờ hiện tại
    select sogiohientai
    into in_gio_hien_tai
    from bangchamcong
    where in_msnv = bangchamcong.msnv and in_thang = bangchamcong.thang and in_nam = bangchamcong.nam;
    
    -- lấy số giờ tối thiểu
    select sogiotoithieu
    into in_gio_toi_thieu
    from bangchamcong
    where in_msnv = bangchamcong.msnv and in_thang = bangchamcong.thang and in_nam = bangchamcong.nam;
    
    -- tính lương trừ không làm đủ giờ tối thiểu
    -- lương 1 giờ = lương cơ bản / số giờ
    -- lương ko đủ nếu làm không đủ giờ tối thiểu thì TRỪ (số giờ thiếu x lương 1 giờ)
    set hour_luong = in_luongcoban / in_gio_toi_thieu;
    if (in_gio_hien_tai < in_gio_toi_thieu) then
		set luong_tru_ko_du_gio = hour_luong * (in_gio_toi_thieu - in_gio_hien_tai);
    else
		set luong_tru_ko_du_gio = 0;
    end if;
    
    
    -- tính khấu trừ dựa trên loại nhân viên
    if (loai_nv = 'chinh thuc') then 
		set in_khautru = (in_luongcoban * 0.15);
	end if;
	if (loai_nv = 'thu viec') then 
		set in_khautru = 0;
	end if;
    
    -- tính thuế trên tiền lương cơ bản
    if (in_luongcoban > 15000000) then 
		set in_thue = 0.15 * in_luongcoban;
	else
		set in_thue = 0;
    end if;
    
    -- tính lương thực tế
    -- lương thực tế = lương làm thêm + lương cơ bản + xăng xe + ăn trưa + hỗ trợ khác - bhyt - bhxh - thuế - khấu trừ - lương số giờ không làm đủ
    set total_luong = extra_luong + in_luongcoban + in_xangxe + in_antrua + in_hotrokhac
     - (in_luongcoban * 0.05) - (in_luongcoban * 0.01) - in_thue - in_khautru - luong_tru_ko_du_gio;
	if (total_luong < 0) then set total_luong = 0;
    end if;
    
    update bangluong
		set xangxe = in_xangxe,
			antrua = in_antrua,
            hotrokhac = in_hotrokhac,
            bhxh = (in_luongcoban * 0.05),
            bhyt = (in_luongcoban * 0.01),
            khautru = in_khautru,
            thue = in_thue,
            luongthucte = total_luong
    where in_msnv = bangluong.msnv and in_thang = bangluong.thang and in_nam = bangluong.nam;
    
    -- tìm tháng sau
	-- tìm năm sau
    if (in_thang = 12) then
		set thang_sau = 1;
        set nam_sau = in_nam + 1;
	else
		set thang_sau = in_thang + 1;
        set nam_sau = in_nam;
    end if;
    
    
    -- tạo bảng lương cho tháng sau
	if not exists (select 1 from bangluong where msnv = in_msnv and thang = thang_sau and nam = nam_sau) then
		insert into bangluong (msnv,thang,nam, luongcoban)
        values (in_msnv, thang_sau, nam_sau, in_luongcoban);
    end if;
    -- tạo bảng chấm công cho tháng sau
    if not exists (select 1 from bangchamcong where msnv = in_msnv and thang = thang_sau and nam = nam_sau) then
		insert into bangchamcong (msnv,thang,nam, sogiohientai, sogiotoithieu, sogiolamthem)
        values (in_msnv, thang_sau, nam_sau, 0 , in_gio_toi_thieu , 0);
    end if;
    
end
$$
DELIMITER ;
-- test
-- NVNV0000009
call tinh_luong('NV0000009',1,2024,50000.00,50000.00,100000.00);
select * from bangluong where msnv='NV0000009';
--------------------------
drop procedure if exists delete_bangluong;
DELIMITER $$
create procedure delete_bangluong(
	in in_msnv char(9),
    in in_thang int,
    in in_nam int
)
begin
	if not exists (select 1 from nhanvien where msnv = in_msnv) then
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Khong co nhan vien nay'; 
    end if;
    
    if (in_thang < 1 or in_thang > 12) then
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Thang khong hop le'; 
    end if;
    
    if (in_nam < 0) then
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nam khong hop le'; 
    end if;
    
    if not exists (select 1 from bangluong 
					where msnv = in_msnv and thang = in_thang and nam = in_nam) 
    then
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Khong ton tai ban ghi can xoa'; 
    end if;
    
    delete from bangluong where msnv = in_msnv and thang = in_thang and nam = in_nam;
    
end $$
DELIMITER
####################################################################
 
-- lay nguoi luong cao thu 2 cua 1 phong
drop function if exists nhiluong;
delimiter //
create function nhiluong(mpban char(9))
returns char(9)
deterministic
begin
declare nhi char(9);
select msnv into nhi
from nhanvien n,bangluong b
where n.msnv=b.msnv 
order by luongcoban desc
limit 1 offset 1;
return nhi;
end //
delimiter ;
-- lay luong hien tai
drop function if exists luonghientai;
delimiter //
create function luonghientai(nv char(9))
returns decimal(10,2)
deterministic
begin
declare luong decimal(10,2);
select luongcoban into luong
from nhanvien n,bangluong b
where n.msnv=b.msnv 
and b.nam = year(now()) and b.thang =month(now())and n.msnv=nv;
return luong;
end //
delimiter ;
##########################################################################
drop procedure if exists updatemaxluong;
delimiter //
create procedure updatemaxluong(mpban char(9),qlmoi char(9))
begin
	declare maxluong decimal(10,2);
	declare phong char(9);
    IF NOT EXISTS (SELECT 1 FROM phongban WHERE mpban = phongban.mspb) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ma phong ban khong ton tai!';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM nhanvien WHERE qlmoi = nhanvien.msnv) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ma nhan vien khong ton tai!';
    END IF;
	select mspb into phong
		from nhanvien
		where msnv=qlmoi;
	select max(luongcoban) into maxluong
		from lscongviec l, phongban p
		where  p.mspb = mpban and p.tenphongban = l.tenphongban 
        ;
	if not(phong = mpban or phong is null) then 
    
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nhan vien khong thuoc phong ban nay';
	end if;
	if(maxluong < luonghientai(qlmoi)) then set maxluong = luonghientai(qlmoi); end if;


update phongban
	set nv_quanly = qlmoi
	where mspb = phong;
    CALL insert_into_ls_congviec(
        qlmoi, 
        date(now()), 
        'truong phong', 
        (select loainhanvien from nhanvien where msnv=qlmoi), 
        maxluong,
        (SELECT tenphongban FROM phongban WHERE mspb = mpban)
    );
				

end //
delimiter ;
##############################################################################
DROP PROCEDURE IF EXISTS insert_nvchinhthuc1;
DELIMITER //
CREATE PROCEDURE insert_nvchinhthuc1 (
    msnv CHAR(9), 
    hovaten VARCHAR(20), 
    ngaysinh DATE, 
    gioitinh VARCHAR(4), 
    cccd CHAR(12), 
    masophongban CHAR(9),
    bhxh VARCHAR(20),
    nguoiquanly CHAR(9),
    startdate DATE,
    chucvu VARCHAR(20),
    lcb DECIMAL(10,2),
    sogiotoithieu INT
)
BEGIN
    IF bhxh IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Hay them BHXH!';
    END IF;
   IF nguoiquanly IS NOT NULL AND nguoiquanly NOT IN (SELECT n.msnv FROM nvchinhthuc n) THEN
         SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nhan vien quan ly khong ton tai!';
     END IF;
    
    INSERT INTO nvchinhthuc (msnv, bhxh, nguoiquanly) 
    VALUES (msnv, bhxh, nguoiquanly);

    -- Truy vấn tên phòng ban trực tiếp khi thêm vào lịch sử công việc
    CALL insert_into_ls_congviec(
        msnv, 
        startdate, 
        chucvu, 
        'chinh thuc', 
        lcb, 
        (SELECT tenphongban FROM phongban WHERE mspb = masophongban)
    );
    INSERT INTO bangluong(msnv, thang, nam, luongcoban) 
    VALUES (msnv, MONTH(DATE_ADD(startdate, INTERVAL 1 MONTH)), YEAR(DATE_ADD(startdate, INTERVAL 1 MONTH)), lcb);
    INSERT INTO bangchamcong (msnv, thang, nam, sogiohientai, sogiotoithieu, sogiolamthem) 
    VALUES (msnv, MONTH(DATE_ADD(startdate, INTERVAL 1 MONTH)), YEAR(DATE_ADD(startdate, INTERVAL 1 MONTH)), 0, sogiotoithieu, 0);

END //
DELIMITER ;
#################################################################################################
drop procedure if exists thuviec_thanh_chinhthuc;
delimiter //
create procedure thuviec_thanh_chinhthuc(nv char(9),bhxh varchar(20) , luong decimal(10,2),toithieu int,hanthuviec date)
begin
declare hoten varchar(20);
declare ngaysinh date;
declare gioitinh varchar(4);
declare cccd char(12);
declare pban char(9);
declare giamsat char(9);
declare startday date;

IF NOT EXISTS (SELECT 1 FROM nhanvien WHERE nv = msnv) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ma nhan vien khong ton tai!';
    END IF;
IF EXISTS (SELECT 1 FROM nvchinhthuc WHERE nv = msnv) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nhan vien nay da la nhan vien chinh thuc';
    END IF;
IF hanthuviec>curdate() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nhan vien nay chua hoan thanh thu viec';
    END IF;
select n.hoten, n.ngaysinh, n.gioitinh,n.cccd,n.mspb 
into hoten,ngaysinh,gioitinh,cccd,pban
from nhanvien n 
where n.msnv=nv;
select n.nvgiamsat,n.startdate into giamsat,startday
from nvthuviec n
where n.msnv= nv;
if((select enddate 
from nvthuviec
where msnv= nv) > hanthuviec)then update nvthuviec 
									set enddate= hanthuviec
									where msnv= nv; end if;
call insert_nvchinhthuc1(nv,hoten,ngaysinh,gioitinh,cccd,
pban,bhxh,giamsat,(select enddate 
from nvthuviec
where msnv= nv),'thanh vien',luong,toithieu);
CALL insert_into_ls_congviec(
        nv, 
        startday, 
        'khong', 
        'thu viec', 
        (select luongcoban from bangluong where thang=month(startday)and nam = year(startday) and msnv=nv),
        (SELECT tenphongban FROM phongban WHERE mspb = pban)
    );
update lscongviec
set stt=0 
where msnv=nv and chucvu='thanh vien';
update lscongviec
set stt=1
where msnv=nv and loainv='thu viec';
update lscongviec
set stt=2
where msnv=nv and chucvu='thanh vien';
update nhanvien
set loainhanvien ='chinh thuc'
where msnv=nv and loainhanvien='thu viec';
select "thao tac thanh cong";
end //
delimiter ;

###########################################################################################
drop procedure if exists chuyen_viec;
	delimiter //
	create procedure chuyen_viec(nv char(9),luong decimal(10,2), chuc varchar(20),pban char(9),loai varchar(10),toithieu int,sta date)
	begin
	declare laststa date;
	declare newsta date;
		IF NOT EXISTS (SELECT 1 FROM nhanvien WHERE nv = msnv) THEN
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ma nhan vien khong ton tai!';
		END IF;
		IF NOT EXISTS (SELECT 1 FROM nvchinhthuc WHERE nv = msnv) THEN
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nhan vien thu viec khong duoc phep chuyen viec';
		END IF;
	IF NOT EXISTS (SELECT 1 FROM phongban WHERE mspb = pban) THEN
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ma phong ban khong ton tai!';
		 END IF;
		 select l.startdate into laststa
		 from lscongviec l
		 where l.msnv = nv and stt>=all( select ls.stt from lscongviec ls where ls.msnv=nv);
		 IF sta-laststa<=60 THEN
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Chua du thoi gian de chuyen viec';
		 END IF;
	update nhanvien
	set mspb = pban
	where msnv=nv;
	call insert_into_ls_congviec (
		nv,
		sta,
		chuc,
		loai,
		luong,
		(SELECT tenphongban FROM phongban WHERE mspb = pban)
	);
	 SET newsta = DATE_ADD(sta, INTERVAL 1 MONTH);
	insert into bangchamcong(msnv,sogiotoithieu,thang,nam,sogiohientai,sogiolamthem) values(nv,toithieu,month(newsta),year(newsta),0,0);
	insert into bangluong(msnv,luongcoban,thang,nam) values(nv,luong,month(newsta),year(newsta));
	select "thao tac thanh cong";
	end //
	delimiter ;
###############################################################################################
DROP PROCEDURE IF EXISTS insert_nvthuviec;
DELIMITER //
CREATE PROCEDURE insert_nvthuviec (
    msnv CHAR(9), 
    hovaten VARCHAR(20), 
    ngaysinh DATE, 
    gioitinh VARCHAR(4), 
    cccd CHAR(12), 
    masophongban CHAR(9),
    nguoiquanly1 CHAR(9),
    startdate DATE,
    lcb DECIMAL(10,2),
    sogiotoithieu INT
)
BEGIN
    declare end1 date;
    IF nguoiquanly1 IS NULL  -- (nguoiquanly NOT IN (SELECT msnv FROM nvchinhthuc))
     THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nhan vien quan ly khong ton tai123!';
    END IF;
    IF NOT EXISTS (
    SELECT 1 
    FROM nvchinhthuc n
    WHERE binary TRIM(n.msnv) = binary TRIM(nguoiquanly1)
) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nhan vien quan ly khong ton tai456!';
END IF;

    SET end1 = DATE_ADD(startdate, INTERVAL 2 MONTH);
    CALL insert_into_nhanvien(msnv, hovaten, ngaysinh, gioitinh, cccd, 'thu viec', masophongban);
    INSERT INTO nvthuviec (msnv, startdate,enddate, nvgiamsat) 
    VALUES (msnv, startdate,end1,nguoiquanly1);

    -- Truy vấn tên phòng ban trực tiếp khi thêm vào lịch sử công việc
    
    INSERT INTO bangluong(msnv, thang, nam, luongcoban) 
    VALUES (msnv, MONTH(startdate), YEAR(startdate), lcb);
    INSERT INTO bangchamcong (msnv, thang, nam, sogiohientai, sogiotoithieu, sogiolamthem) 
    VALUES (msnv, MONTH(startdate), YEAR(startdate), 0, sogiotoithieu, 0);
select"them thanh cong";
END //
DELIMITER ;

-- ############################################################
select * from phongban;
insert nhanvien(msnv, hoten , ngaysinh, gioitinh , cccd , loainhanvien , mspb) values ('NV0000011' ,'Cris Phan' , '1990-12-12' , 'nam' ,'120406080000' ,'chinh thuc' , 'PB0000001');

-- phan cua lyquang
-- procedure them vao bang nvemail
DROP PROCEDURE IF EXISTS insert_into_nvemail;
DELIMITER $$
CREATE PROCEDURE insert_into_nvemail (
    IN p_msnv CHAR(9),
    IN p_email VARCHAR(40)
)
BEGIN
    DECLARE msg VARCHAR(255);
    
    -- Kiểm tra nếu email bị thiếu
    IF p_email IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Hãy thêm Email!';
    END IF;

    -- Kiểm tra nếu mã số nhân viên bị thiếu
    IF p_msnv IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Hãy nhập mã số nhân viên!';
    END IF;

    -- Kiểm tra định dạng email (phải chứa @)
    IF p_email NOT LIKE '%@%' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Email không đúng định dạng phải chứa @ !';
    END IF;

    -- Kiểm tra nếu nhân viên tồn tại trong bảng nhanvien
    IF NOT EXISTS (SELECT 1 FROM nhanvien WHERE msnv = p_msnv) THEN
        SET msg = CONCAT('Không tồn tại nhân viên với mã số: ', p_msnv);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = msg;
    END IF;

    -- Thêm email vào bảng nvEMAIL
    INSERT INTO nvEMAIL (msnv, email)
    VALUES (p_msnv, p_email);
    select 'them email thanh cong';
END$$
DELIMITER ;
select*from nvemail;

-- procedure xóa một record  nvemail
drop procedure if exists delete_nvemail;
DELIMITER $$
CREATE PROCEDURE delete_nvemail (
    IN p_msnv CHAR(9),
    IN p_email VARCHAR(40)
)
BEGIN
    DECLARE msg VARCHAR(255);
    IF p_email IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Hãy thêm Email!';
	end if;
     IF p_msnv IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Hãy nhập mã số nhân viên!';
	end if;
    -- Kiểm tra nếu email tồn tại
    IF NOT EXISTS (SELECT 1 FROM nvEMAIL WHERE msnv = p_msnv AND email = p_email) THEN
        SET msg = CONCAT('Không tồn tại email: ', p_email, ' cho nhân viên: ', p_msnv);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = msg;
    END IF;

    -- Xóa email khỏi bảng nvEMAIL
    DELETE FROM nvEMAIL
    WHERE msnv = p_msnv AND email = p_email;
     select"Xoa thanh cong";
END$$
DELIMITER ;

-- sửa email
drop procedure if exists UPDATE_NVEMAIL;
DELIMITER $$

CREATE PROCEDURE UPDATE_NVEMAIL (
    IN p_msnv CHAR(9),
    IN p_old_email VARCHAR(40),
    IN p_new_email VARCHAR(40)
)
BEGIN
    DECLARE msg VARCHAR(255);
     IF p_old_email IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Hãy thêm Email cũ !';
	end if;
     IF p_new_email IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Hãy thêm Email mới !';
	end if;
     IF p_msnv IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Hãy nhập mã số nhân viên!';
	end if;
    -- Kiểm tra nếu email cũ tồn tại
    IF NOT EXISTS (SELECT 1 FROM nvEMAIL WHERE msnv = p_msnv AND email = p_old_email) THEN
        SET msg = CONCAT('Không tồn tại email: ', p_old_email, ' cho nhân viên: ', p_msnv);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = msg;
    END IF;

    -- Sửa email
    UPDATE nvEMAIL
    SET email = p_new_email
    WHERE msnv = p_msnv AND email = p_old_email;
    select"Sua thanh cong";
END$$
DELIMITER ;


-- them nvsdt
drop procedure if exists insert_into_nvsdt;
delimiter $$
-- update insert_nvsdt
CREATE PROCEDURE insert_into_nvsdt(
    IN p_msnv CHAR(9),
    IN p_sdt CHAR(10)
)
BEGIN
  DECLARE msg VARCHAR(255);
	IF p_sdt IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Hãy thêm số điện thoại!';
	end if;
     IF p_msnv IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Hãy nhập mã số nhân viên!';
	end if;
    -- Check if the phone number is valid (10 digits)
    IF p_sdt REGEXP '^[0-9]{10}$' THEN

        IF EXISTS (SELECT 1 FROM nhanvien WHERE msnv = p_msnv) THEN
            -- Insert the phone number into nvSDT table
            INSERT INTO nvSDT (msnv, sdt) VALUES (p_msnv, p_sdt);
        ELSE
          SET msg = CONCAT('Không tồn tại nhân viên với mã số: ', p_msnv );
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = msg ;
        END IF;
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Số diện thoại bạn nhập không đúng format, Số điện thoại cần 10 số';
    END IF;
    select "Them thanh cong";
END$$
DELIMITER ;
select*from nvsdt;

-- xoa nvsdt
drop procedure if exists delete_nvsdt;
DELIMITER $$
CREATE PROCEDURE delete_nvsdt( IN p_msnv CHAR(9) , IN p_sdt CHAR(10))
BEGIN 
    DECLARE msg VARCHAR(255);
    IF p_sdt IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Hãy thêm số điện thoại!';
	end if;
     IF p_msnv IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Hãy nhập mã số nhân viên!';
	end if;
    -- kiem tra neu sdt ton tai
    IF not exists ( select 1 from nvsdt where msnv = p_msnv AND sdt = p_sdt) then
    set msg = CONCAT('Không tồn tại số điện thoại : ', p_sdt,'cho nhan vien' , p_msnv);
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = msg;
    END IF;
	DELETE FROM nvsdt
    where msnv= p_msnv and sdt = p_sdt;
    select"Xoa thanh cong";
    END$$
DELIMITER ;

-- update nvsdt
drop procedure if exists update_nvsdt;
DELIMITER $$
CREATE PROCEDURE update_nvsdt( 
						IN p_msnv CHAR(9), 
                        in p_old_sdt varchar(10),
                        in p_new_sdt varchar(10) 
)
begin
    declare msg varchar(255);
	IF p_old_sdt IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Hãy thêm số điện thoại cũ !';
	end if;
    IF p_new_sdt IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Hãy thêm số điện thoại mới !';
	end if;
     IF p_msnv IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Hãy nhập mã số nhân viên!';
	end if;
	
    if not exists (select 1 from nvsdt where msnv = p_msnv AND sdt = p_old_sdt) then
    set msg = Concat('Không tồn tại số điện thoại : ', p_old_sdt, 'cho nhan vien' , p_msnv);
    signal sqlstate '45000' set message_text = msg;
end if;
	Update nvsdt
    set sdt = p_new_sdt
    where msnv = p_msnv AND sdt = p_old_sdt;
    select"Sua thanh cong";
END$$
DELIMITER ;

-- them nvdiachi
drop procedure if exists insert_into_nvdiachi;
DELIMITER $$
CREATE PROCEDURE insert_into_nvdiachi(
    IN p_msnv CHAR(9),
    IN p_sonha VARCHAR(30),
    IN p_tenduong VARCHAR(30),
    IN p_phuong VARCHAR(30),
    IN p_tinhthanhpho VARCHAR(30)
)
BEGIN
    -- Kiểm tra mã số nhân viên có tồn tại trong bảng nhanvien
    IF EXISTS (SELECT 1 FROM nhanvien WHERE msnv = p_msnv) THEN
        -- Thêm địa chỉ vào bảng nvDIACHI
        INSERT INTO nvDIACHI (msnv, sonha, tenduong, phuong, tinhthanhpho)
        VALUES (p_msnv, p_sonha, p_tenduong, p_phuong, p_tinhthanhpho);
    ELSE
        -- Báo lỗi nếu nhân viên không tồn tại
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Khong tồn tại nhân viên đó !  ';
    END IF;
    select"Them thanh cong";
END$$
DELIMITER ;
select * from nvdiachi;

-- xoa nvdiachi
drop procedure if exists delete_nvdiachi;
DELIMITER $$
CREATE PROCEDURE delete_nvdiachi( IN p_msnv char(9), 
							in p_sonha varchar(30), 
                            in p_tenduong varchar(30),
                            in p_phuong varchar(30),
                            in p_tinhthanhpho varchar(30)
)  
begin 
	if exists ( select 1 from nvdiachi
				where msnv = p_msnv
                and sonha = p_sonha
                and tenduong = p_tenduong
                and phuong = p_phuong
                and tinhthanhpho = p_tinhthanhpho 
                ) then
                delete from nvdiachi
                where msnv = p_msnv
                and sonha = p_sonha
                and tenduong = p_tenduong
                and phuong = p_phuong
                and tinhthanhpho = p_tinhthanhpho ;
		else
        signal sqlstate '45000' set Message_text='Địa chỉ này không tồn tại ! ';
        end if;
        select"Xoa thanh cong";
end$$
DELIMITER ;

-- update nvdiachi
DROP PROCEDURE IF EXISTS update_nvdiachi;
DELIMITER $$

CREATE PROCEDURE update_nvdiachi( 
    IN p_msnv CHAR(9),
    IN p_old_sonha VARCHAR(30),
    IN p_old_tenduong VARCHAR(30),
    IN p_old_phuong VARCHAR(30),
    IN p_old_tinhthanhpho VARCHAR(30),
    IN p_new_sonha VARCHAR(30),
    IN p_new_tenduong VARCHAR(30),
    IN p_new_phuong VARCHAR(30),
    IN p_new_tinhthanhpho VARCHAR(30)
)
BEGIN
    -- Check if the old address exists for the given employee
    IF EXISTS (
        SELECT 1
        FROM nvDIACHI
        WHERE msnv = p_msnv
          AND sonha = p_old_sonha
          AND tenduong = p_old_tenduong
          AND phuong = p_old_phuong
          AND tinhthanhpho = p_old_tinhthanhpho
    ) THEN
        -- Update the address
        UPDATE nvDIACHI
        SET 
            sonha = p_new_sonha,
            tenduong = p_new_tenduong,
            phuong = p_new_phuong,
            tinhthanhpho = p_new_tinhthanhpho
        WHERE 
            msnv = p_msnv
            AND sonha = p_old_sonha
            AND tenduong = p_old_tenduong
            AND phuong = p_old_phuong
            AND tinhthanhpho = p_old_tinhthanhpho;
    ELSE
        -- Raise an error if the old address doesn't exist
        SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'Địa chỉ cũ không tìm thấy';
    END IF;
    select "Cap nhat thanh cong";
END$$
DELIMITER ;




  










select * from phongban;
delete from nhanvien where msnv  = 'NV0000011';
select * from phongban;

