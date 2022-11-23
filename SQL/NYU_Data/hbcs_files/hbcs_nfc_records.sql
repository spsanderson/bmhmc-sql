/*
***********************************************************************
File: hbcs_nfc_records.sql

Input Parameters:
	None

Tables/Views:
	smsdss.bmh_plm_ptacct_v
	smsmir.acct_hist
	
Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Gather the NFC records for HBCS on the self pay accounts

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

SELECT [RECORD_IDENTIFIER] = 'NFC',
	[MEDICAL_RECORD_NUMBER] = UV.med_rec_no,
	[PATIENT_ACCOUNT_NUMBER] = UV.pt_id,
	[PATIENT_ACCOUNT_UNIT_NO] = UV.unit_seq_no,
	[PATIENT_ID_START_DTIME] = UV.pt_id_start_dtime,
	[DATE_NOTE_POSTD_TO_ACCOUNT] = CAST(CMNT.cmnt_dtime AS DATE),
	[ACTUAL_COMMENT] = CMNT.acct_hist_cmnt
FROM #visits_tbl AS UV
INNER JOIN smsdss.BMH_PLM_PTACCT_V AS PAV ON UV.med_rec_no = PAV.Med_Rec_No
	AND UV.pt_id = PAV.Pt_No
	AND UV.unit_seq_no = PAV.unit_seq_no
INNER JOIN smsmir.acct_hist AS CMNT ON PAV.PT_no = CMNT.pt_id
	AND PAV.pt_id_start_dtime = CMNT.pt_id_start_dtime