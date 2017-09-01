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

into #pay_cd_table

from #temp4 as a

where a.rn = 1

order by a.[Reference Number]
;


---------------------------------------------------------------------------------------------------
/*
Step 1 - Remove payments with a date of service (DOS) prior to January 1, 1997
use [Discharge Date]
*/
select *
into #early_discharge_date
from smsdss.c_HCRA_FMS_Rpt_Tbl_2016
where [Discharge Date] < '1997-01-01'
;

--

select *
into #good_discharge_dates
from smsdss.c_HCRA_FMS_Rpt_Tbl_2016
where [Reference Number] not in (
	select [Reference Number]
	from #early_discharge_date
)
;

/*
Step 2 - Not applicable

Step 3 - Not applicable
*/

/*
Step 4 - Remove payments for Medicare-eligible beneficiareis IP and OP Line 2(a)
*/
select *
--into #step4
from #good_discharge_dates
where (
	[Payor Code] in (
		'a01', 'a02', 'a03', 'a04', 'a05',
		'a06', 'a07', 'a08', 'a09', 'a10',
		'a11', 'a12', 'a13', 'a14', 'a15',
		'a50', 'a51', 'a52', 'a53', 'a54',
		'a55', 'a59', 'a65', 'a76', 'a78',
		'a79', 'a94', 'a95', 'e01', 'e02',
		'e07', 'e08', 'e10', 'e12', 'e13',
		'e18', 'e19', 'e27', 'e28', 'e29',
		'e36', 'e361', 'e3610', 'e3611',
		'e3612', 'e3613', 'e3614',
		'e3615', 'e3616', 'e3617',
		'e3618', 'e3619', 'e362',
		'e3620', 'e3621', 'e3622',
		'e3623', 'e3624', 'e3625',
		'e3626', 'e3627', 'e3628',
		'e3629', 'e363', 'e3630',
		'e3631', 'e3632', 'e3633',
		'e3637', 'e3638', 'e3639',
		'e364', 'e3635', 'e3636',
		'e3637', 'e3638', 'e3639',
		'e364', 'e3640', 'e3641',
		'e3642', 'e3643', 'e3644',
		'e365', 'e366', 'e367', 'e368',
		'e369', 'z28', 'z79', 'z80', 'z91',
		'z92', 'z98', 'z985', 'z99'
	)
	or
	left([Primary Payor], 1) in ('a', 'e', 'z')
	or
	LEFT([Secondary Payor], 1) in ('a', 'e', 'z')
	or
	LEFT([Tertiary Payor], 1) in ('a', 'e', 'z')
	or
	LEFT([Quaternary Payor], 1) in ('a', 'e', 'z')

)