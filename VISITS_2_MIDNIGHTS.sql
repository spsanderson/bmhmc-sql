select PtNo_Num
, Med_Rec_No
, vst_start_dtime
, DATEPART(hour, vst_start_dtime)AS [ADMIT HOUR]

from smsdss.BMH_PLM_PtAcct_V
where Adm_Date > '2013-09-01'
and Plm_Pt_Acct_Type = 'I'