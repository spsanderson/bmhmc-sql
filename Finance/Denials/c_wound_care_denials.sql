select a.PtNo_Num
, a.Med_Rec_No
, a.Plm_Pt_Acct_Type
, a.Plm_Pt_Sub_Type
, a.fc
, a.pt_type
, a.hosp_svc
, cast(a.adm_date as date) as adm_date
, cast(a.dsch_date as date) as dsch_date
, a.Atn_Dr_No
, a.Adm_Dr_No
, a.dsch_disp
, a.prin_dx_cd_schm
, a.prin_dx_cd
, a.User_Pyr1_Cat
, a.Pyr1_Co_Plan_Cd
, a.Pyr2_Co_Plan_Cd
, a.Pyr3_Co_Plan_Cd
, a.Pyr4_Co_Plan_Cd
, cast(a.days_stay as int) as days_stay
, a.tot_chg_amt
, a.tot_adj_amt
, a.reimb_amt
, a.Tot_Amt_Due
, a.last_pay_date
, a.ED_Adm
, a.Last_Billed
, a.Orig_Fc
, b.*

from smsdss.BMH_PLM_PtAcct_V as a
left merge join smsdss.c_Softmed_Denials_Detail_v as b
on a.PtNo_Num = b.bill_no

where a.hosp_svc in ('wcc', 'wch')
and Dsch_Date >= '2014-01-01'
and Dsch_Date < '2016-10-01'

option(force order);