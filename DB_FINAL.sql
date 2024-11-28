drop database if exists db_assignment;  
create database db_assignment;
use db_assignment;
create table phongban(
	mspb 			char (9) 		primary key check (mspb like '_________'),
    mota 			varchar(100)	not null,
    tenphongban 	varchar(30) 	not null,
    ngaythanhlap	date 			not null,
    soluongnhanvien int 			default 1 ,
    nv_quanly 		char(9)			not null 
);

create table nhanvien(
	msnv 		char(9) 		primary key check (msnv like '_________') ,
    hoten 		varchar(30)  	not null,
    ngaysinh 	date ,
	gioitinh 	varchar(4) 		check (gioitinh ='nam' or gioitinh ='nu' or gioitinh ='khac'),
	cccd 		char(12) 		unique 		check (cccd like '____________' and cccd regexp'[0-9]+$'),
	loainhanvien varchar(10) 	check (loainhanvien ='chinh thuc' or loainhanvien ='thu viec'), 
    mspb char(9)  
);

ALTER TABLE nhanvien
ADD CONSTRAINT fk_nhanvien_phongban
FOREIGN KEY (mspb) REFERENCES phongban(mspb)
ON DELETE set null on update cascade;

alter table phongban
add constraint fk_phongban_nhanvienquanly
foreign key (nv_quanly) references nhanvien(msnv) on update cascade ;

CREATE TABLE nvsdt (
    msnv 		CHAR(9) 	NOT NULL,
    sdt 		CHAR(10) 	NOT NULL CHECK (sdt LIKE '__________' AND sdt REGEXP '^[0-9]{10}$'),
    PRIMARY KEY (msnv, sdt),
    CONSTRAINT fk_sdt_nv FOREIGN KEY (msnv) REFERENCES nhanvien(msnv) on update cascade on delete cascade
);
create table nvdiachi (
	msnv 		char (9) 		not null,
    sonha 		varchar (30) 	not null,
    tenduong 	varchar (30) 	not null,
    phuong 		varchar(30) 	not null,
    tinhthanhpho varchar (30) 	not null,
    primary key (msnv, sonha, tenduong, phuong, tinhthanhpho),
    constraint fk_diachi_nv foreign key (msnv)  references nhanvien(msnv) on update cascade on delete cascade
);

create table nvemail (
	msnv 		char (9) 		not null,
    email		varchar(40) 	not null check (email like '%_@_%'),
    primary key (msnv , email),
    constraint fk_email_nv foreign key (msnv) references nhanvien(msnv) on update cascade on delete cascade
);


CREATE TABLE bangluong (
    msnv 			CHAR(9) 		NOT NULL,
    thang 			INT 			CHECK(thang >= 1 AND thang <= 12) NOT NULL,
    nam 			YEAR 			NOT NULL,
    luongcoban 		DECIMAL(10, 2) 	NOT NULL DEFAULT 0 CHECK (luongcoban >= 0),
    luonglamthem 	DECIMAL(10, 2) 	NOT NULL DEFAULT 0 CHECK (luonglamthem >= 0),
    xangxe 			DECIMAL(10, 2) 	NOT NULL DEFAULT 0 CHECK (xangxe >= 0),
    antrua 			DECIMAL(10, 2) 	NOT NULL DEFAULT 0 CHECK (antrua >= 0),
    hotrokhac 		DECIMAL(10, 2) 	NOT NULL DEFAULT 0 CHECK (hotrokhac >= 0),
    bhxh 			DECIMAL(10, 2) 	NOT NULL DEFAULT 0 CHECK (bhxh >= 0),
    bhyt 			DECIMAL(10, 2) 	NOT NULL DEFAULT 0 CHECK (bhyt >= 0),
    thue 			DECIMAL(10, 2) 	NOT NULL DEFAULT 0 CHECK (thue >= 0),
    khautru 		DECIMAL(10, 2)  NOT NULL DEFAULT 0 CHECK (khautru >= 0),
    luongthucte 	DECIMAL(10, 2)  NOT NULL DEFAULT 0 CHECK (luongthucte >= 0),
    primary	key (msnv, thang, nam),
    constraint fk_bangluong_nv foreign key(msnv) references nhanvien(msnv)  on update cascade on delete cascade
);
create table bangchamcong(
	msnv 			char(9) 	not null,
    thang 			int 		check (thang <=12 and thang>=1) not null,
    nam 			year 		not null,
    sogiohientai 	int  	not null check (sogiohientai >=0),
	sogiotoithieu 	int 	not null check (sogiotoithieu >=0),
    sogiolamthem 	int  	not null check (sogiolamthem >=0),
    primary key (msnv ,thang,nam),
    constraint fk_chamcong_nv foreign key (msnv) references nhanvien (msnv) on delete cascade on update cascade
);
-- INSERT DEFALT GIỜ VÔ = GIỜ RA -> VIẾT TRIGGER XỬ LÝ ON INSERT SET GIỜ VÀO = GIỜ RA  , 
-- update CẬP NHẬP SỐ GIỜ LÀM  , GIỜ VÀO KHÁC GIỜ RA THÌ KHÔNG CHO CẬP NHẬT 
-- TRUOỨC KHI VÔ LÀM INSERT VÔ NGÀY LÀM VIỆC , CHECK OUT THÌ UPDATE GIỜ RA 
create table ngaylamviec (
	msnv 		char (9) 		not null ,
    thang  		int  			not null,
    nam 		year 			not null,
    ngay 		int 			not null,
    trangthai 	varchar (20) 	not nulL	 DEFAULT 'LAM' check (trangthai = 'lam'
		or trangthai = 'nghi tru luong' or trangthai ='nghi tru phep' ),
    giovao 		timestamp 		not null 		check(time(giovao) >= 73000 and time(giovao) <= 203000  ) ,
    giora 		timestamp 		not null 		check(time(giora) >= 73000 and time(giora) <= 203000  ) ,
    primary key (msnv, thang, nam , ngay) ,
    constraint fk_ngaylamviec_bcc foreign key (msnv , thang , nam ) 
				references bangchamcong (msnv, thang, nam) 
);

CREATE TABLE nvchinhthuc (
    msnv 		CHAR(9) 		PRIMARY KEY,
    bhxh 		VARCHAR(20) 	NOT NULL,
    nguoiquanly CHAR(9),
    constraint fk_chinhthuc_to_nhanvien foreign key (msnv) references nhanvien(msnv) 
			on update cascade on delete cascade ,
    constraint fk_nguoiquanly foreign key (nguoiquanly) references nhanvien (msnv) 
			on update cascade on delete set null
);

-- XÓA NHÂN VIÊN CHÍNH THỨC CÓ GIÁM SÁT , PHẢI CHUYỂN QUẢN LÝ NHÂN VIÊN THỬ VIỆC CHO TRƯỞNG PHÒNG BAN HIỆN TẠI 
create table nvthuviec(
	msnv char(9) 		not null 	primary key  ,
    startdate 			date 		not null,
    enddate 			date 		not null,
    nvgiamsat 			char(9) 	not null,
    constraint fk_thuviec_to_nv foreign key (msnv) references nhanvien(msnv)
		on delete cascade on update cascade,
    constraint thu_viec_it_nhat_30day check (enddate - startdate >=30),
    constraint fk_giamsat_nv foreign key (nvgiamsat) references nvchinhthuc (msnv) on update cascade 
);
	
create table lscongviec (
	msnv 		char (9) 		not null ,
    stt 		int 			not null,
    startdate 	date 			not null,
    chucvu 		varchar(20) 	not null,
    loainv 		char(10) 		check (loainv = 'chinh thuc' or loainv ='thu viec'),
    luongcoban  decimal(10,2) 	not null,
    tenphongban varchar(30) 	,
    constraint fk_to_nvchinhthuc foreign key (msnv) references nvchinhthuc (msnv) on update cascade on delete cascade, 
    primary key (msnv , stt)
);

create table ketoan (
	msnv 		char(9) 	primary key ,
    cc_hanhnghe varchar(30) not null,
    constraint fk_ketoan_nv foreign key (msnv) references nhanvien (msnv) on delete cascade on update cascade
);
-- TẠO 1 PHÒNG BAN LÀ HEADQUATER KHÔNG BAO GIỜ ĐƯỢC XÓA , KHI XÓA THÌ SẼ CHO THẰNG NÀY BÚ DỰ ÁN
create table duan(
	maDA 			char (9) 		primary key 	check(maDA like '_________') ,
    tong_von_dau_tu decimal(20) 	not null 		default 0 	check (tong_von_dau_tu >=0),
    start_date 		date 			not null,
    ten_DA 			varchar(100) 	not null,
    mota 			varchar (100) 	not null,
    ma_phong_ban_quanly char(9)     not null ,   
    constraint fk_duAn foreign key (ma_phong_ban_quanly) references phongban(mspb) 
		on update cascade 
);

create table nhanvien_thamgia_duan(
	msda char (9) not null ,
    msnv char (9) not null ,
    primary key (msda , msnv) ,
    constraint fk_to_da foreign key (msda) references duan (mada) on delete cascade on update cascade , 
    constraint fk_to_msnv foreign key (msnv) references nhanvien (msnv) on delete cascade on update cascade 
);





