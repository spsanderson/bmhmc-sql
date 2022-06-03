/*
***********************************************************************
File: hbcs_gua_records.sql

Input Parameters:
	None

Tables/Views:
	smsdss.bmh_plm_ptacct_v
	smsdss.c_patient_demos_v
    smsdss.c_guarantor_employer_demos_v

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Gather the GAU records for HBCS on the self pay accounts

Revision History:
Date		Version		Description
----		----		----
2022-05-24	v1			Initial Creation
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
	AND PAV.FC IN ('G', 'P', 'R')
    AND PAV.TOT_CHG_AMT > 0
    AND PAV.TOT_AMT_DUE > 0
	AND PAV.prin_dx_cd IS NOT NULL
	AND PAV.unit_seq_no != '99999999';

SELECT [RECORD_IDENTIFIER] = 'GUA',
	[MEDICAL_RECORD_NUMBER] = UV.med_rec_no,
	[PATIENT_ACCOUNT_NUMBER] = UV.pt_id,
	[PATIENT_ACCOUNT_UNIT_NO] = UV.unit_seq_no,
	[PATIENT_ID_START_DTIME] = UV.pt_id_start_dtime,
	[LAST_NAME] = GUA.GuarantorLast,
	[FIRST_NAME] = GUA.GuarantorFirst,
	[STREET_ADDRESS_1] = GUA.GuarantorAddress,
	[STREET_ADDRESS_2] = GUA.GuarantoAddress2,
	[CITY] = GUA.GurantorCity,
	[STATE] = GUA.GuarantorState,
	[ZIP] = GUA.GuarantorZip,
	[BIRTH_DATE] = CAST(GUA.GuarantorDOB AS DATE),
	[PHONE] = GUA.GuarantorPhone,
	[SSN] = GUA.GuarantorSocial,
	[EMPLOYER_NAME] = GUA_EMP.GuarantorEmployer,
	[EMPLOYER_ADDRESS_1] = GUA_EMP.GuarantorEmployer_Address,
	[EMPLOYER_ADDRESS_2] = '',
	[EMPLOYER_CITY] = GUA_EMP.GurantorEmployer_City,
	[EMPLOYER_STATE] = GUA_EMP.GuarantorEmployer_State,
	[EMPLOYER_ZIP] = GUA_EMP.GuarantorEmployer_Zip,
	[EMPLOYER_PHONE] = GUA_EMP.GuarantorWorkPhone,
	[GUARANTOR_NUMBER] = ''
FROM #visits_tbl AS UV
INNER JOIN smsdss.c_guarantor_demos_v AS GUA ON UV.pt_id = GUA.pt_id
	AND UV.pt_id_start_dtime = GUA.pt_id_start_dtime
LEFT JOIN smsdss.c_guarantor_employer_demos_v AS GUA_EMP ON UV.PT_ID = GUA_EMP.pt_id
	AND UV.pt_id_start_dtime = GUA_EMP.pt_id_start_dtime
