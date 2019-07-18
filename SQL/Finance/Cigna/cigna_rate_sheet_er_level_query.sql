/*
***********************************************************************
File: cigna_rate_sheet_er_level_query.sql

Input Parameters:
	None

Tables/Views:
	SMSDSS.c_er_tracking
	SMSDSS.BMH_PLM_PtAcct_V

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Entere Here

Revision History:
Date		Version		Description
----		----		----
2018-07-13	v1			Initial Creation
***********************************************************************
*/

DECLARE @STARTDATE DATETIME;
DECLARE @ENDDATE DATETIME;

SET @STARTDATE = '2018-01-01';
SET @ENDDATE = '2019-01-01';

SELECT A.med_rec_no,
	A.episode_no,
	CAST(PAV.Adm_Date AS DATE) AS [Adm_Date],
	CAST(PAV.Dsch_Date AS DATE) AS [Dsch_Date],
	YEAR(PAV.DSCH_DATE) AS [Dsch_YR],
	MONTH(PAV.DSCH_DATE) AS [Dsch_MO],
	A.er_level,
	A.er_vst_chgs,
	A.er_vst_qty,
	A.pt_sts_xfer_ind
FROM SMSDSS.c_er_tracking AS A
INNER JOIN SMSDSS.BMH_PLM_PtAcct_V AS PAV ON A.episode_no = PAV.PtNo_Num
	AND A.from_file_ind = PAV.from_file_ind
WHERE PAV.Dsch_Date >= @STARTDATE
	AND PAV.Dsch_Date < @ENDDATE
	AND PAV.tot_chg_amt > 0
	AND LEFT(PAV.PTNO_nUM, 1) != '2'
	AND LEFT(PAV.PTNO_NUM, 4) != '1999'
	AND PAV.Pyr1_Co_Plan_Cd IN ('K11', 'X01', 'E01', 'K55')
