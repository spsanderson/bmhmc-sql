select *

from smsdss.BMH_PLM_PtAcct_V

where Adm_Date >= '2017-02-01'
and Adm_Date < '2017-03-01'
and tot_chg_amt > 0
and LEFT(ptno_num, 1) = '1'
and Plm_Pt_Acct_Type = 'i'
and LEFT(ptno_num, 4) != '1999'
--and DATEPART(hour, vst_start_dtime) >= 7
