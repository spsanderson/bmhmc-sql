select a.*

from smsdss.c_HCRA_FMS_Rpt_Tbl_2016 as a
left join smsmir.acct as b
on left(ltrim(rtrim(a.[reference number])), 8) = SUBSTRING(b.pt_id, 5, 8)

where b.resp_cd = '9'