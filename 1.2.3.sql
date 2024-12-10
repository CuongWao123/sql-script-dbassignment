
-- 1 Tìm tên , luong thuc te của nhân viên có lương thực tế cao nhất trong tháng a va nam b cua phong ban c co luong thuc te < d
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
    GROUP BY nv.hoten, nv.msnv, bl2.luongthucte -- nên bỏ
    HAVING bl2.luongthucte <  d -- nên sửa
    ORDER BY bl2.luongthucte;
END // 
DELIMITER ;

select * from bangluong;
call tim_maxluong_withinPhongban_inMonth(1,2000 ,99999999.99);
##############################################################################
#######################################
-- Hiển thị tổng số giờ làm thêm và tổng số lương làm thêm mà công ty đã chi trả trong 
-- mọi tháng của năm input_year sắp xếp giảm dần theo tổng lương chi trả từng tháng
drop procedure if exists SUM_lam_them;
DELIMITER $$
CREATE PROCEDURE SUM_lam_them(input_year int) 
BEGIN 
	DECLARE year_temp YEAR;
	SET year_temp = input_year;
	SELECT L.thang,
		   SUM(L.luonglamthem) AS tong_luong_lam_them,
		   SUM(C.sogiolamthem) AS tong_gio_lam_them
	FROM bangluong L
	JOIN bangchamcong C ON L.msnv = C.msnv
		AND L.thang = C.thang
		AND L.nam = C.nam
	WHERE L.nam = input_year
	GROUP BY L.thang
	ORDER BY tong_luong_lam_them DESC; 
END
$$
DELIMITER ;
-- test
CALL SUM_lam_them(2024);
##############################################################################

-- ############################################################
DROP PROCEDURE IF EXISTS xem_lichsu_cv;

DELIMITER //

CREATE PROCEDURE xem_lichsu_cv(nv CHAR(9))
BEGIN
    SELECT 
		n.msnv,
        l.stt, 
		l.startdate, 
        l.chucvu, 
        l.loainv,
        l.luongcoban,
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

##############################
-- new verse
drop PROCEDURE if exists tim_maxluong_withinPhongban_inMonth ;
DELIMITER //
CREATE PROCEDURE tim_maxluong_withinPhongban_inMonth ( t int , n int  , d dec(10,2) )
BEGIN
    select distinct nv.hoten, nv.msnv , bl2.luongthucte, nv.mspb
    from (
        select max(T.luongthucte) as maxluong, T.masophongban as mspb
		from 	(select bl.luongthucte as luongthucte, nv.mspb as masophongban 
				from bangluong as bl, nhanvien as nv
				where bl.thang =  t and bl.nam =  n and nv.msnv = bl.msnv
				group by bl.luongthucte, masophongban
				having bl.luongthucte <  d) as T
		group by T.masophongban
    ) as m , nhanvien as nv, bangluong as bl2 
    where   nv.mspb = m.mspb and bl2.luongthucte = m.maxluong and nv.msnv = bl2.msnv
    ORDER BY bl2.luongthucte;
END // 
DELIMITER ;


CALL tim_maxluong_withinPhongban_inMonth(6,2024 ,10.00);
select * from bangluong;
