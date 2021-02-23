/*
***********************************************************************
File: covid_hhs_newly_diagnosed_query.sql

Input Parameters:
	None

Tables/Views:
	smsdss.c_covid_extract_tbl
    smsdss.c_covid_patient_visit_data_tbl

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get the HHS newly diagnosed records

Revision History:
Date		Version		Description
----		----		----
2021-02-04	v1			Initial Creation
***********************************************************************
*/

DECLARE @START DATETIME2;
DECLARE @END   DATETIME2;

SET @START = DATEADD(HOUR, 9, CONVERT(VARCHAR(10), GETDATE()-1, 110));
SET @END   = DATEADD(HOUR, 9, CONVERT(VARCHAR(10), GETDATE() , 110));

SELECT A.Pt_ADT,
	a.Pt_Name,
	[pt_initals] = SUBSTRING(A.PT_NAME, CHARINDEX(', ', A.PT_NAME) + 2, 1) + LEFT(A.PT_NAME, 1),
	a.ptno_num,
	a.PT_Street_Address,
	a.PT_City,
	a.PT_State,
	A.PT_Zip_CD,
	a.Pt_Gender,
	A.PT_DOB,
	a.Race_Cd_Desc,
	a.PT_Comorbidities,
	A.PT_Admitted_From,
	A.Occupation,
	'' AS [METHOD_TRAVEL_TO_WORK],
	A.Dx_Order,
	A.PatientReasonforSeekingHC

FROM smsdss.c_covid_extract_tbl AS a
LEFT OUTER JOIN smsdss.c_covid_patient_visit_data_tbl AS b ON a.PTNO_NUM = b.PatientAccountID
--LEFT OUTER JOIN smsdss.c_covid_flu_results_tbl AS c ON b.PatientVisitOID = c.PatientVisitOID
WHERE a.Distinct_Visit_Flag = '1'
       AND A.first_positive_flag_dtime BETWEEN @START AND @END
       AND DATEDIFF(HOUR, A.Result_DTime, A.first_positive_flag_dtime) BETWEEN -1 AND 1
          AND a.Pt_ADT not in ('Outpatient', 'ED Only')
