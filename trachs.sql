select a.pt_id
, a.proc_eff_date
, a.proc_cd
, b.proc_cd_desc
, DATEPART(year, a.proc_eff_date) as [svc_yr]
, DATEPART(month, a.proc_eff_date) as [svc_month]
from smsmir.sproc as a
left join smsdss.proc_dim_v as b
on a.proc_cd = b.proc_cd
and a.proc_cd_schm = b.proc_cd_schm
and a.orgz_cd = 's0x0'
where proc_eff_date >= '2013-01-01'
and a.proc_cd in (
'0B110F4', '31.1', '31.29'
)
and a.orgz_cd = 's0x0'
group by a.pt_id
, a.proc_eff_date
, a.proc_cd
, b.proc_cd_desc
, DATEPART(year, a.proc_eff_date)
, DATEPART(month, a.proc_eff_date)
order by a.proc_eff_date;

