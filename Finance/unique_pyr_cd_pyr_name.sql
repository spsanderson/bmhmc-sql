select a.PtNo_Num
, a.User_Pyr1_Cat
, a.Pyr1_Co_Plan_Cd
, isnull(b.Ins_Name, '') ins_name_override
, b.Ins_City
, b.Ins_State
, b.Ins_Zip
, c.pyr_name
, a.Pyr1_Co_Plan_Cd +',' + ISNULL(b.ins_name, '') + ',' + c.pyr_name as [insurance names]
, SUM(d.tot_pay_adj_amt) as [tot pay ins1]

into #temp_a

from smsdss.BMH_PLM_PtAcct_V as a
left join smsdss.c_ins_user_fields_v as b
on a.Pt_No = b.pt_id
	and a.Pyr1_Co_Plan_Cd = b.pyr_cd
left join smsmir.pyr_mstr as c
on a.Pyr1_Co_Plan_Cd = c.pyr_cd
left join smsmir.pay as d
on a.Pyr1_Co_Plan_Cd = d.pyr_cd
	and a.Pt_No = d.pt_id
	--and pay_seq_no = 1
	
--where a.PtNo_Num = '10755791'
where d.pay_date >= '2012-01-01'
and d.pay_date < '2016-01-01'
and (pay_cd BETWEEN '09600000' AND '09699999'
OR pay_cd BETWEEN '00990000' AND '00999999'
OR pay_cd BETWEEN '09900000' AND '09999999'
OR pay_cd IN (
	'00980300','00980409','00980508','00980607','00980656','00980706',
	'00980755','00980805','00980813','00980821','09800095','09800277',
	'09800301','09800400','09800459','09800509','09800558','09800608',
	'09800707','09800715','09800806','09800814','09800905','09800913',
	'09800921','09800939','09800947','09800962','09800970','09800988',
	'09800996','09801002','09801010','09801028','09801036','09801044',
	'09801051','09801069','09801077','09801085','09801093','09801101',
	'09801119'
	)
)
and LEFT(a.ptno_num, 1) != '7'

group by a.PtNo_Num
, a.User_Pyr1_Cat
, a.Pyr1_Co_Plan_Cd
, isnull(b.Ins_Name, '')
, b.Ins_City
, b.Ins_State
, b.Ins_Zip
, c.pyr_name
, a.Pyr1_Co_Plan_Cd +',' + ISNULL(b.ins_name, '') + ',' + c.pyr_name

option(force order);

---------------------------------------------------------------------------------------------------

select a.PtNo_Num
, a.User_Pyr1_Cat
, a.Pyr2_Co_Plan_Cd
, isnull(b.Ins_Name, '') ins_name_override
, b.Ins_City
, b.Ins_State
, b.Ins_Zip
, c.pyr_name
, a.Pyr2_Co_Plan_Cd +',' + ISNULL(b.ins_name, '') + ',' + c.pyr_name as [insurance names]
, SUM(d.tot_pay_adj_amt) as [tot pay ins1]

into #temp_b

from smsdss.BMH_PLM_PtAcct_V as a
left join smsdss.c_ins_user_fields_v as b
on a.Pt_No = b.pt_id
	and a.Pyr2_Co_Plan_Cd = b.pyr_cd
left join smsmir.pyr_mstr as c
on a.Pyr2_Co_Plan_Cd = c.pyr_cd
left join smsmir.pay as d
on a.Pyr2_Co_Plan_Cd = d.pyr_cd
	and a.Pt_No = d.pt_id
	--and pay_seq_no = 1
	
--where a.PtNo_Num = '10755791'
where d.pay_date >= '2012-01-01'
and d.pay_date < '2016-01-01'
and (pay_cd BETWEEN '09600000' AND '09699999'
OR pay_cd BETWEEN '00990000' AND '00999999'
OR pay_cd BETWEEN '09900000' AND '09999999'
OR pay_cd IN (
	'00980300','00980409','00980508','00980607','00980656','00980706',
	'00980755','00980805','00980813','00980821','09800095','09800277',
	'09800301','09800400','09800459','09800509','09800558','09800608',
	'09800707','09800715','09800806','09800814','09800905','09800913',
	'09800921','09800939','09800947','09800962','09800970','09800988',
	'09800996','09801002','09801010','09801028','09801036','09801044',
	'09801051','09801069','09801077','09801085','09801093','09801101',
	'09801119'
	)
)
and LEFT(a.ptno_num, 1) != '7'

group by a.PtNo_Num
, a.User_Pyr1_Cat
, a.Pyr2_Co_Plan_Cd
, isnull(b.Ins_Name, '')
, b.Ins_City
, b.Ins_State
, b.Ins_Zip
, c.pyr_name
, a.Pyr2_Co_Plan_Cd +',' + ISNULL(b.ins_name, '') + ',' + c.pyr_name

option(force order);

---------------------------------------------------------------------------------------------------
select a.PtNo_Num
, a.User_Pyr1_Cat
, a.Pyr3_Co_Plan_Cd
, isnull(b.Ins_Name, '') ins_name_override
, b.Ins_City
, b.Ins_State
, b.Ins_Zip
, c.pyr_name
, a.Pyr3_Co_Plan_Cd +',' + ISNULL(b.ins_name, '') + ',' + c.pyr_name as [insurance names]
, SUM(d.tot_pay_adj_amt) as [tot pay ins1]

into #temp_c

from smsdss.BMH_PLM_PtAcct_V as a
left join smsdss.c_ins_user_fields_v as b
on a.Pt_No = b.pt_id
	and a.Pyr3_Co_Plan_Cd = b.pyr_cd
left join smsmir.pyr_mstr as c
on a.Pyr3_Co_Plan_Cd = c.pyr_cd
left join smsmir.pay as d
on a.Pyr3_Co_Plan_Cd = d.pyr_cd
	and a.Pt_No = d.pt_id
	--and pay_seq_no = 1
	
--where a.PtNo_Num = '10755791'
where d.pay_date >= '2012-01-01'
and d.pay_date < '2016-01-01'
and (pay_cd BETWEEN '09600000' AND '09699999'
OR pay_cd BETWEEN '00990000' AND '00999999'
OR pay_cd BETWEEN '09900000' AND '09999999'
OR pay_cd IN (
	'00980300','00980409','00980508','00980607','00980656','00980706',
	'00980755','00980805','00980813','00980821','09800095','09800277',
	'09800301','09800400','09800459','09800509','09800558','09800608',
	'09800707','09800715','09800806','09800814','09800905','09800913',
	'09800921','09800939','09800947','09800962','09800970','09800988',
	'09800996','09801002','09801010','09801028','09801036','09801044',
	'09801051','09801069','09801077','09801085','09801093','09801101',
	'09801119'
	)
)
and LEFT(a.ptno_num, 1) != '7'

group by a.PtNo_Num
, a.User_Pyr1_Cat
, a.Pyr3_Co_Plan_Cd
, isnull(b.Ins_Name, '')
, b.Ins_City
, b.Ins_State
, b.Ins_Zip
, c.pyr_name
, a.Pyr3_Co_Plan_Cd +',' + ISNULL(b.ins_name, '') + ',' + c.pyr_name

option(force order);
---------------------------------------------------------------------------------------------------
select a.PtNo_Num
, a.User_Pyr1_Cat
, a.Pyr4_Co_Plan_Cd
, isnull(b.Ins_Name, '') ins_name_override
, b.Ins_City
, b.Ins_State
, b.Ins_Zip
, c.pyr_name
, a.Pyr4_Co_Plan_Cd +',' + ISNULL(b.ins_name, '') + ',' + c.pyr_name as [insurance names]
, SUM(d.tot_pay_adj_amt) as [tot pay ins1]

into #temp_d

from smsdss.BMH_PLM_PtAcct_V as a
left join smsdss.c_ins_user_fields_v as b
on a.Pt_No = b.pt_id
	and a.Pyr4_Co_Plan_Cd = b.pyr_cd
left join smsmir.pyr_mstr as c
on a.Pyr4_Co_Plan_Cd = c.pyr_cd
left join smsmir.pay as d
on a.Pyr4_Co_Plan_Cd = d.pyr_cd
	and a.Pt_No = d.pt_id
	--and pay_seq_no = 1
	
--where a.PtNo_Num = '10755791'
where d.pay_date >= '2012-01-01'
and d.pay_date < '2016-01-01'
and (pay_cd BETWEEN '09600000' AND '09699999'
OR pay_cd BETWEEN '00990000' AND '00999999'
OR pay_cd BETWEEN '09900000' AND '09999999'
OR pay_cd IN (
	'00980300','00980409','00980508','00980607','00980656','00980706',
	'00980755','00980805','00980813','00980821','09800095','09800277',
	'09800301','09800400','09800459','09800509','09800558','09800608',
	'09800707','09800715','09800806','09800814','09800905','09800913',
	'09800921','09800939','09800947','09800962','09800970','09800988',
	'09800996','09801002','09801010','09801028','09801036','09801044',
	'09801051','09801069','09801077','09801085','09801093','09801101',
	'09801119'
	)
)
and LEFT(a.ptno_num, 1) != '7'

group by a.PtNo_Num
, a.User_Pyr1_Cat
, a.Pyr4_Co_Plan_Cd
, isnull(b.Ins_Name, '')
, b.Ins_City
, b.Ins_State
, b.Ins_Zip
, c.pyr_name
, a.Pyr4_Co_Plan_Cd +',' + ISNULL(b.ins_name, '') + ',' + c.pyr_name

option(force order);
---------------------------------------------------------------------------------------------------
select *
from #temp_a
union
select *
from #temp_b
union
select *
from #temp_c
union
select *
from #temp_d 

drop table #temp_a, #temp_b, #temp_c, #temp_d