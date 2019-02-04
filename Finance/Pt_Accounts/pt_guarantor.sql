select a.pt_id
, a.acct_hist_cmnt
, a.cmnt_cre_dtime
, case
when LEFT(a.acct_hist_cmnt, 12) = 'pt name addr'
then 'pt_name_addr'
when LEFT(a.acct_hist_cmnt, 14) = 'guar name addr'
then 'guar_name_addr'
  end as [pt_guar_flag]

into #test

from smsmir.acct_hist as a

--where a.pt_id = ''
where (
LEFT(a.acct_hist_cmnt, 12) = 'pt name addr'
or
LEFT(a.acct_hist_cmnt, 14) = 'guar name addr'
)
and substring(pt_id, 5, 8) in (
select distinct(pt_id)
from smsmir.hl7_vst as vst
where vst.adm_date >= '2018-10-01'
and vst.adm_date < '2018-11-01'
)
;

select a.pt_id
, a.acct_hist_cmnt
, a.pt_guar_flag
, rn = ROW_NUMBER() over(
partition by pt_id, pt_guar_flag
order by pt_id, cmnt_cre_dtime
)

into #test2

from #test as a
;

select distinct(A.pt_id)
into #test3
from #test2 as a
where a.rn > 1
;

select distinct(a.pt_id)
, b.UserDataText
from #test3 as a
left outer join smsdss.BMH_UserTwoFact_V as b
on a.pt_id = b.PtNo_Num
inner join smsdss.BMH_UserTwoField_Dim_V as c
on b.UserDataKey = c.UserTwoKey
and c.UserDataCd in (
'2INADMBY'
, '2ERFRGBY'
, '2ERREGBY'
, '2OPPREBY'
, '2OPREGBY'
)

;

drop table #test, #test2, #test3
;
