
-- 1 Tìm tên , luong thuc te của nhân viên có lương thực tế cao nhất trong tháng a va nam b cua phong ban c co luong thuc te > d
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
call tim_maxluong_withinPhongban_inMonth(1,2000 ,99999999.99);
##############################################################################
-- Hiển thị tổng số giờ làm thêm và tổng số lương làm thêm mà công ty đã chi trả trong mọi tháng của năm input_year
drop procedure if exists SUM_lam_them;
DELIMITER $$
create procedure SUM_lam_them(
    input_year int
)
begin
	DECLARE year_temp YEAR;
	set year_temp = input_year;
    
	select L.thang,
		   SUM(L.luonglamthem) as tong_luong_lam_them,
           SUM(C.sogiolamthem) as tong_gio_lam_them
    from 
		bangluong L
    join
		bangchamcong C
	on
		L.msnv = C.msnv and L.thang = C.thang and L.nam = C.nam 
    where    
        L.nam = input_year
    group by 
		L.thang;
end
$$
DELIMITER ;
-- test
call SUM_lam_them(2024);
##############################################################################

-- ############################################################
DROP PROCEDURE IF EXISTS xem_lichsu_cv;

DELIMITER //

CREATE PROCEDURE xem_lichsu_cv(nv CHAR(9))
BEGIN
    SELECT 
        l.stt, 
        n.hoten, 
        n.msnv, 
        l.startdate, 
        l.chucvu, 
        l.tenphongban 
    FROM 
        nhanvien n
    JOIN 
        lscongviec l 
    ON 
        n.msnv = l.msnv
    WHERE 
        n.msnv = nv;
END //

DELIMITER ;
