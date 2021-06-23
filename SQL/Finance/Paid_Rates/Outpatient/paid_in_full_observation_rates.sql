/*
***********************************************************************
File: paid_in_full_observation_rates.sql

Input Parameters:
	None

Tables/Views:
	smsdss.vst_fct_v (updates 1st 8th and every saturday)
    smsdss.pt_type_dim_v
    smsdss.pyr_dim_v

Creates Table:
	Enter Here

Functions:
	Enter Here

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Gets counts by FC and total payments for all pt types paid in full

Revision History:
Date		Version		Description
----		----		----
2020-10-06	v1			Initial Creation
***********************************************************************
*/

-- DATE VARIABLES FOR ALL ACCOUNTS
DECLARE @START DATE
DECLARE @END DATE

-- First day of current year
SET @START = DATEADD(MONTH, DATEDIFF(MONTH, 0, CAST(GETDATE() AS DATE)) - 9, 0)
-- First day of current month
SET @END = DATEADD(MONTH, DATEDIFF(MONTH, 0, CAST(GETDATE() AS DATE)), 0)

-- PT TYPE @ TABLE
DECLARE @PTTYPE TABLE (
	PT_TYPE_CD_DESC VARCHAR(255),
	ORGZ_CD VARCHAR(255),
	PT_TYPE VARCHAR(255)
	)

INSERT INTO @PTTYPE
SELECT DISTINCT pt_type_cd_desc,
	orgz_cd,
	pt_type
FROM SMSPHDSSS0X0.smsdss.pt_type_dim_v
WHERE orgz_cd = 'S0X0'
ORDER BY pt_type_cd_desc

-- PYR GROUP @ TABLE
DECLARE @PYR_GROUP TABLE (
	PYR_GROUP_DESC VARCHAR(255),
	PYR_GROUP VARCHAR(255),
	PYR_CD VARCHAR(255),
	ORGZ_CD VARCHAR(255)
	)

INSERT INTO @PYR_GROUP
SELECT DISTINCT pyr_group2,
	pyr_group,
	pyr_cd,
	orgz_cd
FROM SMSDSS.pyr_dim_v
WHERE orgz_cd = 'S0X0'
	AND pyr_group2 NOT IN ('?', 'No Description')
ORDER BY pyr_group;

-- CROSS JOIN TBL
SELECT DISTINCT PT.PT_TYPE,
	PT.PT_TYPE_CD_DESC,
	PG.PYR_CD,
	PG.PYR_GROUP,
	PG.PYR_GROUP_DESC,
	PG.ORGZ_CD
INTO #PT_PG
FROM @PTTYPE AS PT
CROSS JOIN @PYR_GROUP AS PG

-- DATA
SELECT PTPG.pt_type_cd_desc,
	PTPG.pyr_group,
	PTPG.PYR_GROUP_DESC,
	COUNT(DISTINCT VST.PT_ID) AS [VISITS],
	ISNULL(SUM(VST.TOT_CHG_AMT), 0) AS [TOTAL_CHARGES],
	ISNULL(SUM(VST.RPT_TOT_PAY_AMT), 0) AS [TOTAL_PAYMENT_AMT],
	ISNULL(SUM(VST.TOT_BAL_AMT), 0) AS [TOTAL_AMOUNT_DUE],
	ISNULL(SUM(VST.RPT_TOT_ADJ_AMT), 0) AS [TOTAL_ALLOWANCE]
FROM #PT_PG AS PTPG
LEFT OUTER JOIN SMSDSS.VST_FCT_V AS VST ON PTPG.PT_TYPE = VST.pt_type_2
	AND PTPG.PYR_CD = VST.prim_pyr_cd
	AND PTPG.ORGZ_CD = VST.orgz_cd
	AND VST.vst_end_date >= @START
	AND VST.vst_end_date < @END
	--AND VST.pt_type_2 NOT IN ('C', 'E', 'K', 'R', 'V')
	AND VST.vst_type_cd = 'O'
	AND VST.hosp_svc = 'OBV'
	AND VST.tot_chg_amt > 0
	AND VST.tot_bal_amt >= - 50
	AND VST.tot_bal_amt <= 50
	AND VST.tot_pay_amt != 0
WHERE VST.prim_pyr_cd NOT IN ('B75','B76')
GROUP BY PTPG.pt_type_cd_desc,
	PTPG.pyr_group,
	PTPG.PYR_GROUP_DESC
ORDER BY PTPG.pt_type_cd_desc,
	PTPG.pyr_group

DROP TABLE #PT_PG
