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


drop PROCEDURE if exists tim_maxluong_withinPhongban_inMonth ;
DELIMITER //
CREATE PROCEDURE tim_maxluong_withinPhongban_inMonth ( t int , n int  , d dec(10,2) )
BEGIN
    select distinct nv.hoten, nv.msnv , bl2.luongthucte
    from (
        select max(bl.luongthucte) as maxluong , nv.mspb as mspb
        from bangluong as bl , nhanvien as nv
        where bl.thang =  t and bl.nam =  n and nv.msnv = bl.msnv
        group by nv.mspb
    ) as m , nhanvien as nv, bangluong as bl2 
    where   nv.mspb = m.mspb and bl2.luongthucte = m.maxluong and nv.msnv = bl2.msnv
    GROUP BY nv.hoten, nv.msnv, bl2.luongthucte
    HAVING bl2.luongthucte >  d 
    ORDER BY bl2.luongthucte;
END // 
DELIMITER ;

select * from bangluong;
call tim_maxluong_withinPhongban_inMonth(1,2024 ,6000000.00);
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
