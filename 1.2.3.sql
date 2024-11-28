
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
