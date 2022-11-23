/*
***********************************************************************
File: hbcs_trl_records.sql

Input Parameters:
	None

Tables/Views:
	smsdss.bmh_plm_ptacct_v
		
Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Gather the TRL record for HBCS on the self pay accounts

Revision History:
Date		Version		Description
----		----		----
2022-05-27	v1			Initial Creation
***********************************************************************
*/

DROP TABLE IF EXISTS #visits_tbl
CREATE TABLE #visits_tbl (
	med_rec_no VARCHAR(12),
	pt_id VARCHAR(12),
	unit_seq_no VARCHAR(12),
	pt_id_start_dtime DATE
)

INSERT INTO #visits_tbl
SELECT DISTINCT PAV.Med_Rec_No,
	PAV.Pt_No,
	PAV.unit_seq_no,
	PAV.pt_id_start_dtime
FROM SMSDSS.BMH_PLM_PtAcct_V AS PAV
WHERE PAV.Tot_Amt_Due > 0
AND PAV.FC IN ('G','P','R')
AND PAV.tot_chg_amt > 0
AND PAV.Tot_Amt_Due > 0
AND PAV.prin_dx_cd IS NOT NULL
AND PAV.unit_seq_no != '99999999';

SELECT [RECORD_IDENTIFIER] = 'TRL',
	[DATE_FILE_WAS_CREATED] = CAST(GETDATE() AS DATE),
	[NUMBER_OF_ACCOUNTS] = COUNT(*),
	[PLACEMENT_VALUE] = SUM(TOT_AMT_DUE)
FROM #visits_tbl AS UV
INNER JOIN smsdss.BMH_PLM_PTACCT_V AS PAV ON UV.med_rec_no = PAV.Med_Rec_No
	AND UV.pt_id = PAV.Pt_No
	AND UV.unit_seq_no = PAV.unit_seq_no
