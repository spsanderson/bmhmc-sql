CREATE TABLE smsdss.c_HCRA_Full_Address_Unitized (
	pk int not null identity(1, 1) primary key
	, pt_id varchar(15)
	, ptno_num varchar(15)
	, pt_id_start_dtime datetime
	, pyr_cd char(3)
	, ins_addr1 varchar(100)
	, city varchar(100)
	, [state] varchar(100)
)

insert into smsdss.c_HCRA_Full_Address_Unitized

select a.*
from (
	select a.PT_ID
	, a.PtNo_Num
	, a.pt_id_start_dtime
	, a.pyr_cd
	, a.[ins_addr1]
	, b.city
	, c.[State]


	from smsdss.c_HCRA_ins_addr1_unitized as a
	left join smsdss.c_HCRA_ins_city_unitized as b
	on a.PT_ID = b.pt_id
		and a.pyr_cd = b.pyr_cd
	left join smsdss.c_HCRA_ins_state_unitized as c
	on a.pt_id = c.pt_id
		and a.pyr_cd = c.pyr_cd

	group by a.PT_ID
	, a.PtNo_Num
	, a.pt_id_start_dtime
	, a.pyr_cd
	, a.[ins_addr1]
	, b.city
	, c.[State]
) A
;