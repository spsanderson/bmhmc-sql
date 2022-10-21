/*
***********************************************************************
File: nyu_hac_data_query.sql

Input Parameters:
	None

Tables/Views:
	smsmir.dx_grp

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get HAC data for NYU

Revision History:
Date		Version		Description
----		----		----
2022-09-28	v1			Initial Creation
***********************************************************************
*/

DECLARE @START DATE;

SET @START = '2017-01-01'

SELECT 'HAC_01' AS [hac_code],
	'FOREIGN OBJECT RETAINED AFTER SURGERY' AS [hac_description],
	PAV.Med_Rec_No,
	HAC_A.pt_id,
	HAC_A.unit_seq_no,
	CAST(PAV.Adm_Date AS DATE) AS [Adm_Date],
	CAST(PAV.Dsch_Date AS DATE) AS [Dsch_Date]
INTO #TEMP_A
FROM smsmir.dx_grp AS HAC_A
LEFT JOIN smsdss.BMH_PLM_PtAcct_V AS PAV ON HAC_A.pt_id = PAV.PT_NO
	AND HAC_A.unit_seq_no = PAV.unit_seq_no
INNER JOIN smsdss.c_nyu_hac_01_tbl AS HAC1 ON HAC1.secondary_dx = REPLACE(HAC_A.dx_cd, '.', '')
WHERE HAC_A.poa_ind IS NULL
	AND HAC_A.poa_ind = 'N'
	AND HAC_A.dx_cd_prio != '1'
	AND PAV.tot_chg_amt > 0
	AND PAV.prin_dx_cd IS NOT NULL
	AND LEFT(PAV.PtNo_Num, 1) != '2'
	AND LEFT(PAV.PtNo_Num, 4) != '1999';

SELECT 'HAC_02' AS [hac_code],
	'AIR EMBOLISM' AS [hac_description],
	PAV.Med_Rec_No,
	HAC_A.pt_id,
	HAC_A.unit_seq_no,
	CAST(PAV.Adm_Date AS DATE) AS [Adm_Date],
	CAST(PAV.Dsch_Date AS DATE) AS [Dsch_Date]
INTO #TEMP_B
FROM smsmir.dx_grp AS HAC_A
LEFT JOIN smsdss.BMH_PLM_PtAcct_V AS PAV ON HAC_A.pt_id = PAV.PT_NO
	AND HAC_A.unit_seq_no = PAV.unit_seq_no
INNER JOIN smsdss.c_nyu_hac_02_tbl AS HAC2 ON HAC2.secondary_dx = REPLACE(HAC_A.dx_cd, '.', '')
WHERE HAC_A.poa_ind = 'N'
	AND HAC_A.poa_ind = 'N'
	AND HAC_A.dx_cd_prio != '1'
	AND PAV.tot_chg_amt > 0
	AND PAV.prin_dx_cd IS NOT NULL
	AND LEFT(PAV.PtNo_Num, 1) != '2'
	AND LEFT(PAV.PtNo_Num, 4) != '1999';

SELECT 'HAC_05' AS [hac_code],
	'FALLS AND TRAUMA' AS [hac_description],
	PAV.Med_Rec_No,
	HAC_A.pt_id,
	HAC_A.unit_seq_no,
	CAST(PAV.Adm_Date AS DATE) AS [Adm_Date],
	CAST(PAV.Dsch_Date AS DATE) AS [Dsch_Date]
INTO #TEMP_C
FROM smsmir.dx_grp AS HAC_A
LEFT JOIN smsdss.BMH_PLM_PtAcct_V AS PAV ON HAC_A.pt_id = PAV.PT_NO
	AND HAC_A.unit_seq_no = PAV.unit_seq_no
INNER JOIN smsdss.c_nyu_hac_05_tbl AS HAC5 ON HAC5.secondary_dx = REPLACE(HAC_A.dx_cd, '.', '')
WHERE HAC_A.poa_ind = 'N'
	AND HAC_A.poa_ind = 'N'
	AND HAC_A.dx_cd_prio != '1'
	AND PAV.tot_chg_amt > 0
	AND PAV.prin_dx_cd IS NOT NULL
	AND LEFT(PAV.PtNo_Num, 1) != '2'
	AND LEFT(PAV.PtNo_Num, 4) != '1999';

SELECT *
FROM #TEMP_A

UNION ALL

SELECT *
FROM #TEMP_B

UNION ALL

SELECT *
FROM #TEMP_C;

DROP TABLE #TEMP_A,
	#TEMP_B,
	#TEMP_C;
