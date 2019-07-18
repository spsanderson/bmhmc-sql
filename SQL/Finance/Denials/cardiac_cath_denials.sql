select *

from smsdss.BMH_PLM_PtAcct_V

where Pt_No in (
	select pt_id
	from smsmir.actv
	where actv_cd = '07000433'
)
and pt_no in (
	select bill_no
	from smsdss.c_Softmed_Denials_Detail_v
)
and Adm_Date >= '2017-01-01'
and Plm_Pt_Acct_Type = 'O'