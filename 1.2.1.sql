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
     IF NOT EXISTS (SELECT 1 FROM nvchinhthuc as nvct WHERE nvct.msnv = nguoiquanly) THEN
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

END //
DELIMITER ;
--              Xoa 1 nhan vien 
drop procedure if exists delete_nhanvien ;
DELIMITER $$
CREATE PROCEDURE delete_nhanvien(IN p_msnv CHAR(9))
BEGIN
    IF EXISTS (SELECT 1 FROM nhanvien WHERE msnv = p_msnv) THEN
        DELETE FROM nhanvien WHERE msnv = p_msnv;
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Khong co nhan vien nay';
    END IF;
END $$
DELIMITER ;
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
END $$
DELIMITER ;
--  ------------------- test 
select * from nhanvien as a ,nvchinhthuc as b, lscongviec as c , bangluong as d , bangchamcong as e
where a.msnv = b.msnv and b.msnv= c.msnv and c.msnv = d.msnv and d.msnv = e.msnv ;
select * from nvchinhthuc;
CALL insert_nvchinhthuc(
    'NV0000015', 
    'Le Thi Duyen', 
    '1990-12-12', 
    'nu', 
    '120400000011', 
    'PB0000001', 
    'BHXH0007', 
	'NV0000009', 
    '2000-01-01', 
    'Nhan vien', 
    7000.00 ,
    10000 
);
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
END $$
DELIMITER ;
-- 					xoa du an
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

END $$
DELIMITER ;
###############################################################
-- 				them phong ban
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
    END IF;
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
    END IF;
END //
DELIMITER ;


