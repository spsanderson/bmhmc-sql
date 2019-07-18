select *
into #tempa
from smsdss.c_guarantor_demos_v
where (
	GuarantorFirst like '%cancer%'
	or
	GuarantorFirst like '%csp%'
	or
	GuarantorLast like '%csp%'
	or
	GuarantorFirst like '%women%'
	or
	GuarantorLast like '%partnership%'
	or
	GuarantorLast like '%women%'
	or
	GuarantorFirst like '%breas%'
	or
	GuarantorLast like '%sc b%'
	or
	GuarantorFirst like '%health%'
	or
	GuarantorFirst like '%helth%'
	or
	GuarantorLast like '%health%'
)
and left(ltrim(GuarantorLast), 10) != 'BROOKHAVEN'
and LTRIM(rtrim(guarantorlast)) != 'BROOKAHVEN HEALTH CARE FACILITY'
and GuarantorLast not like 'acpi c%'
and GuarantorLast not like 'south brookh%'
and GuarantorLast not like 'st james%'
and GuarantorLast not like 'suffolk county de%'
and GuarantorLast not like 'sc dep%'
and GuarantorLast not like 'so brookha%'
and GuarantorLast not like 'ross%'
and left(ltrim(rtrim(GuarantorAddress)), 11) != '801 GAZZOLA'

order by GuarantorFirst;

-----

select a.*
, CONCAT(ltrim(rtrim(a.guarantorfirst)), ' ', ltrim(rtrim(a.guarantorlast))) as [cat_name]
into #tempb
from #tempa as a
where SUBSTRING(a.pt_id, 5, 8) in (
	select distinct(LEFT(zzz.[Reference Number],8))
	from smsdss.c_HCRA_FMS_Rpt_Tbl_2016 as zzz
)
and a.pt_id not in (
	'000060229853', '000084379049'
)

order by GuarantorLast
;
-----

select *
from smsdss.c_HCRA_FMS_Rpt_Tbl_2016
where LEFT([reference number], 8) in (
	select SUBSTRING(zzz.pt_id, 5, 8)
	from #tempb as zzz
)
;
-----

drop table #tempa, #tempb
;