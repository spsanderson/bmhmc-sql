/*
***********************************************************************
File: ar_runout_query.sql

Input Parameters:
	None

Tables/Views:
	smsdss.c_2009_ar_runout AS A
	smsmir.mir_vst as b
	smsdss.BMH_PLM_PtAcct_V AS PAV

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get AR Runout
-
Revision History:
Date		Version		Description
----		----		----
2019-03-19	v1			Initial Creation
***********************************************************************
*/

DECLARE @AGE_AT_DATE DATE;

SET @AGE_AT_DATE = '2018-12-31';

--

SELECT pt_number
, a.pt_id
, a.unit_seq_no
, yr_end_fc
--, Current_Status
, PAV.User_Pyr1_Cat as 'Ins1_Category'
, pyr_cd as 'Ins1'
, a.adm_full_Date as 'Admit_Date'
, b.vst_end_dtime as 'Dsch_Date'
, CASE 
	WHEN DATEDIFF(dd, b.vst_end_dtime, @AGE_AT_DATE) BETWEEN '0' AND '30' 
		THEN '1_0-30'
	WHEN DATEDIFF(dd, b.vst_end_dtime, @AGE_AT_DATE) BETWEEN '31' AND '60' 
		THEN '2_31-60'
	WHEN DATEDIFF(dd, b.vst_end_dtime, @AGE_AT_DATE) BETWEEN '61' AND '90' 
		THEN '3_61-90'
	WHEN DATEDIFF(dd, b.vst_end_dtime, @AGE_AT_DATE) BETWEEN '91' AND '180' 
		THEN '4_91-180'
	WHEN DATEDIFF(dd, b.vst_end_dtime, @AGE_AT_DATE) BETWEEN '181' AND '270' 
		THEN '5_181-270'
	WHEN DATEDIFF(dd, b.vst_end_Dtime, @AGE_AT_DATE) BETWEEN '271' AND '365' 
		THEN '6_271-365'
	WHEN DATEDIFF(dd, b.vst_end_dtime, @AGE_AT_DATE) > '365'		
		THEN '7_365+'
		ELSE '1_0-30'
END AS 'Age_At_12312018'
, a.pt_type
, a.vst_type_cd as 'IP/OP'
, a.tot_bal_amt
, a.tot_chg_amt
--Subsequent_Chgs
--, prior_yr_chgs
--, prior_yr_chgs-subsequent_chgs-tot_chg_amt as 'Prior_yr_posted_in_C_Yr'
, CASE
	WHEN Prior_Yr_Chgs<>a.tot_chg_amt 
		THEN Prior_Yr_Chgs-a.tot_chg_amt
		Else 0
  END AS 'Prior_Yr_Chgs'
, CASE 
	WHEN Prior_Yr_Chgs<>a.tot_chg_amt 
		THEN Subsequent_Chgs-(Prior_Yr_Chgs-a.tot_chg_amt)
		ELSE Subsequent_Chgs 
  END AS 'Current_Yr_Chgs'
, ro_paymts as 'Payments'
, RO_Allow as 'Allowances'
, RO_Charity_Care as 'Charity_Care'
, RO_BD_Recover as 'Bad_Debt_Recoveries'
, RO_Bad_Dbt_Xfr as 'Bad_Debt_Xfr_Amt'
, bd_wo_dtime as 'Bad_Debt_Writeoff_Date'
, AR_Balance
, BD_Balance as 'Bad_Debt_Balance'
, Current_Balance
, (tot_bal_amt + subsequent_chgs + ro_paymts + RO_Allow + RO_Charity_Care + RO_BD_Recover + RO_Bad_Dbt_Xfr) as 'Sum'
, chk_var as 'Variance'

--FROM smsdss.c_ar_runout_on_Demand as a 
FROM smsdss.c_2009_ar_runout AS A
LEFT OUTER JOIN smsmir.mir_vst as b
ON a.pt_id = b.pt_id 
AND a.unit_Seq_no = b.unit_seq_no
LEFT OUTER JOIN smsdss.BMH_PLM_PtAcct_V AS PAV
ON A.PT_ID = PAV.PT_NO
	AND A.unit_seq_no = PAV.unit_seq_no

--WHERE Subsequent_Chgs <> 0
--WHERE ro_paymts <>0 OR ro_bd_Recover <>0

--WHERE pt_type='E'

ORDER BY  pt_id, unit_seq_no--chk_var,