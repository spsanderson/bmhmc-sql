/*
***********************************************************************
File: cigna_rate_sheet_abmulatory_surgery_query.sql

Input Parameters:
	None

Tables/Views:
	SMSDSS.BMH_PLM_PtAcct_Clasf_Proc_V_New
	SMSDSS.BMH_PLM_PtAcct_V
	smsdss.c_cigna_2018_asc_grouped

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get Cigna Ambulatory Surgery Volume by Cigna ASC Grouper

Revision History:
Date		Version		Description
----		----		----
2019-06-26	v1			Initial Creation
***********************************************************************
*/

DECLARE @STARTDATE DATETIME;
DECLARE @ENDDATE DATETIME;

SET @STARTDATE = '2018-01-01';
SET @ENDDATE = '2019-01-01';

SELECT PAV.med_rec_no,
	PAV.PtNo_Num,
	pvn.ClasfCd,
	pvn.ClasfPrio,
	ASCG.[Grouper],
	CAST(PAV.Adm_Date AS DATE) AS [Adm_Date],
	CAST(PAV.Dsch_Date AS DATE) AS [Dsch_Date],
	YEAR(PAV.DSCH_DATE) AS [Dsch_YR],
	MONTH(PAV.DSCH_DATE) AS [Dsch_MO],
	pav.hosp_svc,
	pav.tot_chg_amt,
	pav.tot_pay_amt,
	pav.tot_amt_due,
	[RN] = ROW_NUMBER() OVER(PARTITION BY PAV.PTNO_NUM ORDER BY PAV.PTNO_NUM, PVN.CLASFPRIO)

INTO #TEMPA

FROM smsdss.BMH_PLM_PtAcct_V AS PAV
INNER JOIN SMSDSS.BMH_PLM_PtAcct_Clasf_Proc_V_New AS PVN
ON PAV.PT_NO = PVN.Pt_No
INNER JOIN SMSDSS.C_CIGNA_2018_ASC_GROUPED AS ASCG
ON PVN.ClasfCd = ASCG.[CPT CODE]

WHERE PAV.Dsch_Date >= @STARTDATE
	AND PAV.Dsch_Date < @ENDDATE
	AND PAV.tot_chg_amt > 0
	AND PAV.Pyr1_Co_Plan_Cd IN ('K11', 'X01', 'E01', 'K55')
	AND Clasf_Eff_Date >= '2018-01-01'
	AND Clasf_Eff_Date < '2019-01-01'
;

SELECT A.Med_Rec_No
, A.PtNo_Num
, A.ClasfCd
, A.ClasfPrio
, A.Grouper
, A.Adm_Date
, A.Dsch_Date
, A.Dsch_YR
, A.Dsch_MO
, A.hosp_svc
, A.tot_chg_amt
, A.tot_pay_amt
, A.Tot_Amt_Due
, A.RN
, PAY.RATE
, ASU.GROUPER_RATE
, CAST((PAY.RATE * ASU.GROUPER_RATE) AS money) AS [INS_PAY_AMT]

FROM #TEMPA AS A

CROSS APPLY (
	SELECT
		CASE
			WHEN A.RN = 1
				THEN 1.00
			WHEN A.RN = 2
				THEN 0.50
			WHEN A.RN > 2
				THEN 0.25
		END AS RATE
) AS PAY

CROSS APPLY (
	SELECT
		CASE
			WHEN A.Grouper = '1'
				THEN 2703.00
			WHEN A.GROUPER = '2'
				THEN 2958.00
			WHEN A.GROUPER = '3'
				THEN 3672.00
			WHEN A.GROUPER IN ('4', '5')
				THEN 3927.00
			WHEN A.GROUPER = '6'
				THEN 4437.00
			WHEN A.GROUPER = '7'
				THEN 4559.00
			WHEN A.GROUPER = '8'
				THEN 4692.00
			WHEN A.GROUPER = '9'
				THEN 4871.00
			WHEN A.GROUPER = '79'
				THEN 0
			WHEN A.GROUPER = 'Lam'
				THEN 18085.00
			WHEN A.GROUPER = 'Lap Chole'
				THEN 4559.00
		END AS GROUPER_RATE
) AS ASU
;

DROP TABLE #TEMPA
;