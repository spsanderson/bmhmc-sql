/*
***********************************************************************
File: covid_hhs_expired_query.sql

Input Parameters:
	None

Tables/Views:
	smsdss.c_covid_extract_tbl
    smsdss.c_covid_patient_visit_data_tbl
    smsdss.c_covid_flu_results_tbl

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get the HHS newly expired records

Revision History:
Date		Version		Description
----		----		----
2021-02-04	v1			Initial Creation
***********************************************************************
*/

DECLARE @START DATETIME2;
DECLARE @END   DATETIME2;

SET @START = DATEADD(HOUR, 9, CONVERT(VARCHAR(10), GETDATE() - 1, 110));
SET @END   = DATEADD(HOUR, 9, CONVERT(VARCHAR(10), GETDATE(), 110));

SELECT a.Pt_Name,
	[pt_initals] = SUBSTRING(A.PT_NAME, CHARINDEX(', ', A.PT_NAME) + 2, 1) + LEFT(A.PT_NAME, 1),
	[county_of_residence] = '',
	a.Adm_Dtime,
	a.Race_Cd_Desc,
	a.Pt_Gender,
	a.Pt_Age,
	a.DC_DTime,
	a.PT_Comorbidities,
	[flu_results] = CASE
		WHEN (
			PATINDEX('%positive%', c.Flu_A) != 0
			OR PATINDEX('%positive%', c.Flu_B) != 0
		)
			THEN 'Positive'
		WHEN (
			C.Flu_A IS NULL
			AND C.Flu_B IS NULL
		)
			THEN NULL
		ELSE 'Negative'
		END,
	--c.Flu_A AS [Flu_A_result],
	--c.Flu_B AS [Flu_B_Result],
	c.ResultDateTime AS [Flue_Result_DateTime],
	[positive_suspect_noncovid] = CASE 
				WHEN a.Distinct_Visit_Flag = 1
					AND a.RESULT_CLEAN = 'detected'
					AND a.Order_Status = 'result signed'
					THEN 'positive'
				WHEN a.Distinct_Visit_Flag = '1'
					AND a.pt_last_test_positive = '1'
					AND datediff(day, a.Last_Positive_Result_DTime, cast(getdate() AS DATE)) <= 30
					AND a.PatientReasonforSeekingHC NOT LIKE '%non covid%'
					AND (
						a.PatientReasonforSeekingHC LIKE '%Sepsis%'
						OR a.PatientReasonforSeekingHC LIKE '%SEPS%'
						OR a.PatientReasonforSeekingHC LIKE '%PNEUM%'
						OR a.PatientReasonforSeekingHC LIKE '%PNA%'
						OR a.PatientReasonforSeekingHC LIKE '%FEVER%'
						OR a.PatientReasonforSeekingHC LIKE '%CHILLS%'
						OR a.PatientReasonforSeekingHC LIKE '%SOB%'
						OR a.PatientReasonforSeekingHC LIKE '%SHORTNESS OF BREATH%'
						OR a.PatientReasonforSeekingHC LIKE '%SHORT OF BREATH%'
						OR a.PatientReasonforSeekingHC LIKE '%RESPIRATO%FAIL%'
						OR a.PatientReasonforSeekingHC LIKE '%RESP%FAIL%'
						OR a.PatientReasonforSeekingHC LIKE '%COUGH%'
						OR a.PatientReasonforSeekingHC LIKE '%WEAKNESS%'
						OR a.PatientReasonforSeekingHC LIKE '%PN%'
						OR a.PatientReasonforSeekingHC LIKE '%COVID%'
						)
					THEN 'positive'
				WHEN a.RESULT_CLEAN = 'detected'
					AND a.Order_Status != 'result signed'
					THEN 'suspect'
				WHEN a.Covid_Indicator = 'covid 19 or r/o covid 19 patient'
					THEN 'suspect'
				ELSE 'non_covid'
				END
INTO #TEMPA
FROM smsdss.c_covid_extract_tbl AS a
LEFT OUTER JOIN smsdss.c_covid_patient_visit_data_tbl AS b ON a.PTNO_NUM = b.PatientAccountID
LEFT OUTER JOIN smsdss.c_covid_flu_results_tbl AS c ON b.PatientVisitOID = c.PatientVisitOID
WHERE a.Pt_ADT = 'expired'
	AND a.Distinct_Visit_Flag = '1'
	AND A.DC_DTime BETWEEN @START AND @END;

SELECT *
FROM #TEMPA
WHERE positive_suspect_noncovid = 'positive';

DROP TABLE #TEMPA;