/*
***********************************************************************
File: hbcs_pat_records.sql

Input Parameters:
	None

Tables/Views:
	smsdss.bmh_plm_ptacct_v
	smsdss.c_patient_demos_v

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Gather the PAT records for HBCS on the self pay accounts

Revision History:
Date		Version		Description
----		----		----
2022-05-24	v1			Initial Creation
***********************************************************************
*/

SELECT [RECORD_IDENTIFIER] = 'PAT',
	[MEDICAL_RECORD_NUMBER] = PAV.Med_Rec_No,
	[PATIENT_ACCOUNT_NUMBER] = PAV.PtNo_Num,
	[PATIENT_ACCOUNT_UNIT_NO] = PAV.unit_seq_no,
	[PATIENT_ID_START_DTIME] = CAST(PAV.pt_id_start_dtime AS DATE),
	[LAST_NAME] = RTRIM(LTRIM(SUBSTRING(PAV.PT_NAME, 1, CHARINDEX(' ,', PAV.Pt_Name)))),
	[FIRST_NAME] = RTRIM(LTRIM(SUBSTRING(PAV.PT_NAME, CHARINDEX(',', PAV.PT_NAME) + 1, LEN(PAV.PT_NAME)))),
	[PHONE] = PT.Pt_Phone_No,
	[SSN] = PAV.Pt_SSA_No,
	[BIRTH_DATE] = CAST(PAV.Pt_Birthdate AS DATE),
	[GENDER] = PAV.Pt_Sex,
	[SERVICE_FROM_DATE] = CAST(PAV.Adm_Date AS DATE),
	[SERVICE_TO_DATE] = CAST(PAV.Dsch_Date AS DATE),
	[MORTALITY_INDICATOR] = CASE 
		WHEN LEFT(RTRIM(LTRIM(PAV.dsch_disp)), 1) IN ('C', 'D')
			THEN 'Y'
		ELSE 'N'
		END
FROM SMSDSS.BMH_PLM_PtAcct_V AS PAV
LEFT JOIN smsdss.c_patient_demos_v AS PT ON PAV.PT_NO = PT.pt_id
	AND PAV.pt_id_start_dtime = PT.pt_id_start_dtime
WHERE PAV.fc IN ('G', 'P', 'R')
	AND PAV.Tot_Amt_Due > 0
    AND PAV.Tot_Chg_Amt > 0
	AND PAV.prin_dx_cd IS NOT NULL
	AND PAV.unit_seq_no != '99999999';
