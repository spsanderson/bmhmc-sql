-- Get all relevant data in order to perform the process of getting pay codes
-- and their associated description for the HCRA related payments
select '0000' + LEFT(a.[Reference Number], 8) as [Encounter]
, a.[Reference Number]
, a.[Payment Amount]
, a.[Payment Entry Date]
, case
	when a.[Payor Code] = 'MIS'
		then '*'
		else a.[Payor Code]
  end as [Payor Code]
, a.[Primary Payor]
, a.[Secondary Payor]
, a.[Tertiary Payor]
, a.[Quaternary Payor]

into #temp1

from smsdss.c_HCRA_FMS_Rpt_Tbl_2016 as a

--select * from #temp1

---------------------------------------------------------------------------------------------------
-- Get just the Self Pay records for this step
select a.[Reference Number]
, a.Encounter
, a.[Payment Amount]
, a.[Payment Entry Date]
, a.[Payor Code]
, a.[Primary Payor]
, a.[Secondary Payor]
, a.[Tertiary Payor]
, a.[Quaternary Payor]
, b.pt_id
, b.pay_cd
, c.pay_cd_name

into #temp2

from #temp1 as a
-- just get the self pay pay_cd descriptions
left join smsmir.pay as b
on a.Encounter = b.pt_id
	and a.[Payor Code] = b.pyr_cd
	and a.[Payor Code] = '*'
	and a.[Payment Amount] = b.tot_pay_adj_amt
	and a.[Payment Entry Date] = b.pay_entry_date
	and (b.pay_cd BETWEEN '09600000' AND '09699999'
	OR b.pay_cd BETWEEN '00990000' AND '00999999'
	OR b.pay_cd BETWEEN '09900000' AND '09999999'
	OR b.pay_cd IN (
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
left join smsdss.pay_cd_dim_v as c
on b.pay_cd = c.pay_cd

--where [Encounter] = ''

order by a.[Reference Number]
;

--select * from #temp2;

---------------------------------------------------------------------------------------------------
-- Use pt_id, payment amount and payment date and primary payor code to get pay codes and desc
-- for payments made by the primary payor, where the primary payor is not self pay as those
-- are obtained from the above section, do the same join for secondary, tertiary and quaternary
select a.[Reference Number]
, a.Encounter
, a.[Payment Amount]
, a.[Payment Entry Date]
, a.[Payor Code]
, a.[Primary Payor]
, a.[Secondary Payor]
, a.[Tertiary Payor]
, a.[Quaternary Payor]
, a.pt_id as [Self Pay Pt_ID]
, a.pay_cd as [Self Pay Pay Cd]
, a.pay_cd_name as [Self Pay Pay Cd Desc]
--, a.rn as [Self Pay RN]
, b.pt_id as [Primary Payor PT_ID]
, b.pay_cd as [Primary Pay Cd]
, c.pay_cd_name as [Primary Pay Cd Desc]
, d.pt_id as [Secondary Payor PT_ID]
, d.pay_cd as [Secondary Pay Cd]
, e.pay_cd_name as [Secondary Pay Cd Desc]
, f.pt_id as [Tertiary Payor PT_ID]
, f.pay_cd as [Tertiary Pay Cd]
, g.pay_cd_name as [Tertiary Pay Cd Desc]
, h.pt_id as [Quaternary Payor PT_ID]
, h.pay_cd as [Quaternary Pay Cd]
, i.pay_cd_name as [Quaternary Pay Cd Desc]
--, coalesce(a.pay_cd, b.pay_cd, d.pay_cd, f.pay_cd, h.pay_cd) as [Pay_Cd]
--, coalesce(a.pay_cd_desc, c.pay_cd_desc, e.pay_cd_desc, g.pay_cd_desc, i.pay_cd_desc) as [Pay Cd Desc]

into #temp3

from #temp2 as a
-- Get the Primary Payor Data
left join smsmir.pay as b
on a.Encounter = b.pt_id
	and a.[Primary Payor] = b.pyr_cd
	and a.[Payment Amount] = b.tot_pay_adj_amt
	and a.[Payment Entry Date] = b.pay_entry_date
	and (b.pay_cd BETWEEN '09600000' AND '09699999'
	OR b.pay_cd BETWEEN '00990000' AND '00999999'
	OR b.pay_cd BETWEEN '09900000' AND '09999999'
	OR b.pay_cd IN (
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
left join smsdss.pay_cd_dim_v as c
on b.pay_cd = c.pay_cd
-- Get the Secondary Payor Data
left join smsmir.pay as d
on a.Encounter = d.pt_id
	and a.[Secondary Payor] = d.pyr_cd
	and a.[Payment Amount] = d.tot_pay_adj_amt
	and a.[Payment Entry Date] = d.pay_entry_date
	and (d.pay_cd BETWEEN '09600000' AND '09699999'
	OR d.pay_cd BETWEEN '00990000' AND '00999999'
	OR d.pay_cd BETWEEN '09900000' AND '09999999'
	OR d.pay_cd IN (
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
left join smsdss.pay_cd_dim_v as e
on d.pay_cd = e.pay_cd
-- Get the Tertiary Payor Data
left join smsmir.pay as f
on a.Encounter = f.pt_id
	and a.[Tertiary Payor] = f.pyr_cd
	and a.[Payment Amount] = f.tot_pay_adj_amt
	and a.[Payment Entry Date] = f.pay_entry_date
	and (f.pay_cd BETWEEN '09600000' AND '09699999'
	OR f.pay_cd BETWEEN '00990000' AND '00999999'
	OR f.pay_cd BETWEEN '09900000' AND '09999999'
	OR f.pay_cd IN (
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
left join smsdss.pay_cd_dim_v as g
on f.pay_cd = g.pay_cd
-- Get the Quaternary Payor Data
left join smsmir.pay as h
on a.Encounter = h.pt_id
	and a.[Quaternary Payor] = h.pyr_cd
	and a.[Payment Amount] = h.tot_pay_adj_amt
	and a.[Payment Entry Date] = h.pay_entry_date
	and (h.pay_cd BETWEEN '09600000' AND '09699999'
	OR h.pay_cd BETWEEN '00990000' AND '00999999'
	OR h.pay_cd BETWEEN '09900000' AND '09999999'
	OR h.pay_cd IN (
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
left join smsdss.pay_cd_dim_v as i
on h.pay_cd = i.pay_cd

--where [Encounter] = ''

order by a.[Reference Number]
;

--select * from #temp3;

---------------------------------------------------------------------------------------------------
-- Make an RN partitioned and order by Reference ID so that distinct rows can be grabbed in the next
-- step
select a.*
, rn = ROW_NUMBER() over(
	partition by a.[reference number]
	order by a.[reference number]
)
into #temp4
from #temp3 as a;

---------------------------------------------------------------------------------------------------
-- Make sure only distinct reference ID's are grabbed so there are no duplicates

---------------------------------------------------------------------------------------------------
-- Get final data
select --a.Encounter
 a.[Reference Number]
, a.[Payment Amount]
, a.[Payment Entry Date]
, a.[Payor Code]
, a.[Primary Payor]
, a.[Secondary Payor]
, a.[Tertiary Payor]
, a.[Quaternary Payor]
--, a.[Self Pay Pay Cd]
--, a.[Self Pay Pay Cd Desc]
--, a.[Primary Pay Cd]
--, a.[Primary Pay Cd Desc]
--, a.[Secondary Pay Cd]
--, a.[Secondary Pay Cd Desc]
--, a.[Tertiary Pay Cd]
--, a.[Tertiary Pay Cd Desc]
--, a.[Quaternary Pay Cd]
--, a.[Quaternary Pay Cd Desc]
, coalesce(
	a.[Self Pay Pay Cd]
	, a.[primary pay cd]
	, a.[secondary pay cd]
	, a.[tertiary pay cd]
	, a.[quaternary pay cd]
) as [Pay Cd]
, coalesce(
	a.[Self Pay Pay Cd Desc]
	, a.[primary pay cd desc]
	, a.[secondary pay cd desc]
	, a.[tertiary pay cd desc]
	, a.[quaternary pay cd desc]
) as [Pay Cd Description]

from #temp4 as a

where a.rn = 1

order by a.[Reference Number];

---------------------------------------------------------------------------------------------------
----- Drop Table Statements
--drop table #temp1;
--drop table #temp2;
--drop table #temp3;
--drop table #temp4;