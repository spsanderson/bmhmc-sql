select DATEPART(MONTH, Adm_Date) as [month_number]
, COUNT(ptno_num) as [patient_count]

from smsdss.BMH_PLM_PtAcct_V

where Adm_Date >= '2017-02-01'
and Adm_Date < '2017-04-01'
and tot_chg_amt > 0
and LEFT(PtNo_Num, 4) != '1999'
and PtNo_Num < '20000000'
and Plm_Pt_Acct_Type = 'i'
and hosp_svc != 'psy'
--and Days_Stay > 2

group by DATEPART(month, adm_date)