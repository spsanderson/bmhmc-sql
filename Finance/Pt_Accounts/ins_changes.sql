with cte as (
select ins.pt_id
, ins.ins_plan_no
, ins.ins_plan_prio_no
, msg_hdr.appl_from
, msg_hdr.msg_type
, ins.last_msg_cntrl_id
, msg_hdr.msg_cntrl_id
, msg_hdr.msg_dtime
, [rn] = ROW_NUMBER() OVER(
partition by ins.pt_id, ins.ins_plan_no
order by ins.pt_id, ins.ins_plan_no, ins.ins_plan_prio_no
)

from smsmir.hl7_ins as ins
left outer join smsmir.hl7_msg_hdr as msg_hdr
on ins.pt_id = msg_hdr.pt_id
and ins.last_msg_cntrl_id = msg_hdr.msg_cntrl_id
left outer join smsmir.hl7_vst as vst
on ins.pt_id = vst.pt_id

--where ins.pt_id = '87463964'
where vst.adm_date >= '2017-05-01'
and vst.adm_date < '2017-11-01'
)
--order by ins.pt_id, ins.ins_plan_no, ins.ins_plan_prio_no
select cte1.pt_id
--, cte1.ins_plan_no
--, cte1.ins_plan_prio_no
--, cte1.rn
--, cte2.ins_plan_no
--, cte2.ins_plan_prio_no
--, cte2.rn
into #tempa
from cte as cte1
inner  join cte as cte2
on cte1.pt_id = cte2.pt_id
and cte1.rn != cte2.rn
and cte1.ins_plan_prio_no = cte2.ins_plan_prio_no
and cte1.ins_plan_no != cte2.ins_plan_no
and cte2.pt_id is not null
order by cte1.pt_id, cte1.ins_plan_no, cte1.ins_plan_prio_no
;

select distinct(a.pt_id)
, b.UserDataText
from #tempa as a
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


drop table #tempa
;
