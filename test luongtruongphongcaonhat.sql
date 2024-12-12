-- luc dau chua co bang luong nao thuoc thang 5 nam 2024
select* from bangluong
where thang =5 and nam =2024;
-- chua co truong phong nen them khong thanh cong
insert into bangluong(msnv,thang,nam,luongcoban) values ('NV9900011',5,2024,10000000);
-- insert vao se co 2 dong, nv 9900001 cao hon nen set bang truong phong
insert into bangluong(msnv,thang,nam,luongcoban) values ('NV0000001',5,2024,7000000);
insert into bangluong(msnv,thang,nam,luongcoban) values ('NV9900011',5,2024,10000000);
select* from bangluong
where thang =5 and nam =2024;
-- update luong cao hon truong phong set bang truong phong
UPDATE `db_assignment`.`bangluong` SET `luongcoban` = '11000000.00'
WHERE (`msnv` = 'NV9900011') and (`thang` = '5') and (`nam` = 2024);
select* from bangluong
where thang =5 and nam =2024;
-- delete truong phong nen khong duoc
delete from bangluong where msnv ='NV0000001'and thang =5 and nam =2024;
-- sau khi xoa het nv trong phong thi moi xoa truong phong duoc
delete from bangluong where msnv ='NV9900011'and thang =5 and nam =2024;
delete from bangluong where msnv ='NV0000001'and thang =5 and nam =2024;
select* from bangluong
where thang =5 and nam =2024;