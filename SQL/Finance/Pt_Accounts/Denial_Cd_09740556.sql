select distinct(pt_id)
, [rn] = ROW_NUMBER() over(
partition by pt_id
order by pt_id
)

into #tempa

from smsmir.mir_pay

where (
pay_cd = '09740556'
)
and substring(pt_id, 5, 8) in (
select distinct(pt_id)
from smsmir.hl7_vst as vst
where vst.adm_date >= '2018-01-01'
and vst.adm_date < '2018-09-01'
)
;

select distinct(a.pt_id)
, b.UserDataText
from #tempa as a
left outer join smsdss.BMH_UserTwoFact_V as b
on SUBSTRING(a.pt_id, 5, 8) = b.PtNo_Num
INNER join smsdss.BMH_UserTwoField_Dim_V as c
on b.UserDataKey = c.UserTwoKey
and c.UserDataCd in (
'2INADMBY'
, '2ERFRGBY'
, '2ERREGBY'
, '2OPPREBY'
, '2OPREGBY'
)

;
drop table #tempa;

