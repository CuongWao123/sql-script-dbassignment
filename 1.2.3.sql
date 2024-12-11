
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
#############################################
-- khong hoan thanh nhieu thang
drop procedure if exists k_hoanthanh_tren_nhieu_lan;
delimiter //
create procedure k_hoanthanh_tren_nhieu_lan(namm int,solan int)
begin
select temp.msnv,temp.hoten,sum(temp.toithieu)-sum(temp.thucte) as phanthieu,count(*)as sothangthieu
from (select n.hoten as hoten, n.msnv as msnv,b.sogiotoithieu as toithieu,b.sogiohientai as thucte
from nhanvien n join bangchamcong b on n.msnv=b.msnv
where b.sogiohientai<b.sogiotoithieu and b.nam=namm 
and(year(curdate())>namm or(year(curdate())=nam and b.thang<month(curdate()))))as temp
group by temp.msnv,temp.hoten
having count(*)>=solan
order by count(*)
;
end //
delimiter ;
call k_hoanthanh_tren_nhieu_lan(2023,1);
select*from bangchamcong where nam=2023;
insert into bangchamcong(msnv,thang,nam,sogiotoithieu,sogiolamthem,sogiohientai)
values('NV0000001',1,2023,1,0,0),
('NV0000001',2,2023,1,0,0),
('NV0000001',3,2023,1,0,0),
('NV0000001',4,2023,1,0,0),
('NV0000001',5,2023,1,0,0),
('NV0000001',6,2023,1,0,0),
('NV0000001',7,2023,1,0,0),
('NV0000001',8,2023,1,0,0),
('NV0000001',9,2023,1,0,0),
('NV0000001',10,2023,1,0,0),
('NV0000001',11,2023,1,0,0),
('NV0000001',12,2023,1,0,0);
delete from bangchamcong
where msnv='NV0000001'and nam=2023;

DROP PROCEDURE IF EXISTS nv_khong_dat_chi_tieu;
DELIMITER $$

CREATE PROCEDURE nv_khong_dat_chi_tieu(
    IN input_year INT,solan int
)
BEGIN
    -- Truy vấn và hiển thị bảng kết quả
    select b1.msnv,b1.thang,b1.sogiohientai,b1.sogiotoithieu
    from bangchamcong b1
    join(select temp.msnv as msnv
from (select n.hoten as hoten, n.msnv as msnv,b.sogiotoithieu as toithieu,b.sogiohientai as thucte
from nhanvien n join bangchamcong b on n.msnv=b.msnv
where b.sogiohientai<b.sogiotoithieu and b.nam=input_year 
and(year(curdate())>input_year or(year(curdate())=b.nam and b.thang<month(curdate()))))as temp
group by temp.msnv,temp.hoten
having count(*)>=solan
order by count(*)
) as kht
    on b1.msnv=kht.msnv 
    where b1.sogiohientai<b1.sogiotoithieu and b1.nam=input_year
    and (year(curdate())>input_year or(year(curdate())=nam and b1.thang<month(curdate())));
END$$

DELIMITER ;
call k_hoanthanh_tren_nhieu_lan(2024,5);
CALL nv_khong_dat_chi_tieu(2024,1);
