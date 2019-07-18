select *
, LEFT([reference number], 8) as [encounter]

into #temp1

from smsdss.c_HCRA_FMS_Rpt_Tbl_2016

where [Medical Service Code] in (
	'opd', 'pst'
)
;

-----

select substring(pt_id, 5, 8) as [encounter]
, case
	when left(actv_cd, 3) != '004'
		then 1
		else 0
  end as non_lab_flag

into #temp2

from smsmir.actv

where SUBSTRING(pt_id, 5, 8) in (
	select distinct(a.encounter)
	from #temp1 as a
)
;

-----

select *

from #temp1 as a

where encounter not in (
	select encounter
	from #temp2
	where non_lab_flag = 1
)
;

-----

drop table #temp1, #temp2;