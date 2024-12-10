-- 1.2.4
-- Đếm số nhân viên không đạt chỉ tiêu số giờ tối thiểu nhiều hơn 2 tháng trong năm input_year
drop function if exists dem_nv_khong_dat_chi_tieu;
DELIMITER $$
create function dem_nv_khong_dat_chi_tieu(
	input_year int
) returns int
DETERMINISTIC
begin 
	declare count_result int;
    declare maso_nv char(9);
    declare count_in_loop int;
    declare done int default false;
    
    declare order_cursor CURSOR FOR 
        SELECT msnv FROM nhanvien;
	
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    set count_result = 0;
    
    OPEN order_cursor;
	-- loop
    read_loop: loop
		fetch order_cursor into maso_nv;
        
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        set count_in_loop = 0;
        
        select COUNT(*)
        into count_in_loop
        from bangchamcong
        where (sogiohientai < sogiotoithieu) and msnv = maso_nv and nam = input_year;
        
        -- trừ đi tháng hiện tại chưa hoàn thành;
        set count_in_loop = count_in_loop - 1;
        
        if (count_in_loop > 2) then
			set count_result = count_result + 1;
		end if;
        
    end loop;
    
    CLOSE order_cursor;
    
    return count_result;
end
$$
DELIMITER ;

-- test
insert into bangchamcong (msnv,thang,nam,sogiohientai,sogiotoithieu, sogiolamthem)
values 
('NV0000010', 2,2024, 160,150,20),
('NV0000010', 3,2024, 160,150,20),
('NV0000010', 4,2024, 160,150,20),
('NV0000009', 5,2024, 160,150,20);
insert into bangchamcong (msnv,thang,nam,sogiohientai,sogiotoithieu, sogiolamthem)
values 
('NV0000009', 2,2024, 160,150,20),
('NV0000009', 3,2024, 160,150,20),
('NV0000009', 4,2024, 160,150,20),
('NV0000009', 5,2024, 160,150,20);
select dem_nv_khong_dat_chi_tieu(2024) as ketqua;
#########################################################
drop procedure if exists listngay;
delimiter //
create procedure listngay( dau date, cuoi date , nv char(9))
begin
select * 
from ngaylamviec
where msnv=nv and date(giovao)>=dau and date(giovao)<=cuoi;
end //
delimiter ;
drop function if exists tinhgio;
delimiter //
create function tinhgio (batdau date,ketthuc date,nv char(9))
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
        WHERE date(n.giora)>=batdau and date(n.giora)<= ketthuc and n.msnv=nv;

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
select tinhgio('2024-11-01','2024-11-02', 'NV9900001');

#########################################
-- Tính tổng tiền phải trả trong tháng , năm , với các nhân viên có số giờ làm thêm ở mức tối đa thưởng 20% lương cơ bản , còn số giờ làm thêm > ½  tối đa 10%
-- Tính tổng số tiền lương phải trả trong tháng , năm  đó , với các nhân viên có số giờ làm thêm = số giờ tối đa thì thưởng thêm 50% lương cơ bản 
-- , còn số giờ làm thêm  > 1/2 số giờ tối đa thì thưởng 25% lương cơ bản 
drop function if exists caculate_salary_to_pay;
DELIMITER //

CREATE FUNCTION caculate_salary_to_pay(inp_year INT, inp_month INT)
RETURNS DECIMAL(15,2)
DETERMINISTIC
BEGIN
    -- Khai báo biến
    DECLARE done INT DEFAULT 0;
    DECLARE msnv CHAR(9);
    DECLARE sum_salary_to_pay DECIMAL(15,2) DEFAULT 0; 
    DECLARE toida int;
    DECLARE lamthem int;
    DECLARE ltt DECIMAL(10,2);
    DECLARE lcb DECIMAL(10,2);

    -- Khai báo con trỏ
    DECLARE cur CURSOR FOR 
        SELECT bl.msnv, bcc.sogiotoithieu / 2, bcc.sogiolamthem, bl.luongthucte, bl.luongcoban
        FROM bangluong AS bl
        JOIN bangchamcong AS bcc ON bl.msnv = bcc.msnv 
        WHERE bl.thang = bcc.thang 
          AND bl.nam = bcc.nam 
          AND bl.thang = inp_month 
          AND bl.nam = inp_year;

    -- Khai báo handler khi hết con trỏ
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    -- Mở con trỏ
    OPEN cur;

    -- Bắt đầu vòng lặp
    read_loop: LOOP
        FETCH cur INTO msnv, toida, lamthem, ltt, lcb;
        IF done = 1 THEN
            LEAVE read_loop;
        END IF;

        -- Gán giá trị đúng cách với :=
        IF lamthem = toida THEN
            set  sum_salary_to_pay = sum_salary_to_pay + ltt + lcb * 0.5;
        ELSEIF lamthem > toida / 2 THEN
            set sum_salary_to_pay = sum_salary_to_pay + ltt + lcb * 0.25;
        ELSE
            set sum_salary_to_pay = sum_salary_to_pay + ltt; 
        END IF;

    END LOOP;

    -- Đóng con trỏ
    CLOSE cur;

    -- Trả về tổng lương
    RETURN sum_salary_to_pay;
END //

DELIMITER ;
 SELECT bl.maso_nv, bcc.sogio_toithieu / 2, bcc.sogio_lamthem, bl.luongthucte, bl.luongcoban
        FROM bangluong AS bl
        JOIN bangchamcong AS bcc ON bl.maso_nv = bcc.maso_nv 
        WHERE bl.thang = bcc.thang 
          AND bl.nam = bcc.nam 
          AND bl.thang = 11
          AND bl.nam = 2023;
          
select * from bangchamcong where thang = 11 and nam = 2024;
select caculate_salary_to_pay ( 2024 , 11);

drop procedure if exists dem_nv_khong_dat_chi_tieu;
DELIMITER $$
create procedure dem_nv_khong_dat_chi_tieu(
	in input_year int
)
begin 
	declare count_result int;
    declare maso_nv char(9);
    declare count_in_loop int;
    declare done int default false;
    
    declare order_cursor CURSOR FOR 
        SELECT msnv FROM nhanvien;
	
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    set count_result = 0;
    
    OPEN order_cursor;
	-- loop
    read_loop: loop
		fetch order_cursor into maso_nv;
        
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        set count_in_loop = 0;
        
        select COUNT(*)
        into count_in_loop
        from bangchamcong
        where (sogiohientai < sogiotoithieu) and msnv = maso_nv and nam = input_year;
        
        -- trừ đi tháng hiện tại chưa hoàn thành;
        set count_in_loop = count_in_loop - 1;
        
        if (count_in_loop > 2) then
			set count_result = count_result + 1;
		end if;
        
    end loop;
    
    CLOSE order_cursor;
    
    return count_result;
end
$$
DELIMITER ;

DROP PROCEDURE IF EXISTS nv_khong_dat_chi_tieu;
DELIMITER $$

CREATE PROCEDURE nv_khong_dat_chi_tieu(
    IN input_year INT
)
BEGIN
    -- Truy vấn và hiển thị bảng kết quả
    SELECT DISTINCT nv.msnv
    FROM nhanvien nv
    JOIN bangchamcong bcc ON nv.msnv = bcc.msnv
    WHERE bcc.nam = input_year
    GROUP BY nv.msnv
    HAVING COUNT(CASE WHEN bcc.sogiohientai < bcc.sogiotoithieu THEN 1 END) > 3;
END$$

DELIMITER ;
