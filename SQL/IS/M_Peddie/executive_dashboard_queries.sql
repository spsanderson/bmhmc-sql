/*
***********************************************************************
File: executive_dashboard_queries.sql

Input Parameters:
	None

Tables/Views:
	[SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit
	SMSMIR.hl7_msg_hdr
	[SQL-WS\REPORTING].[WellSoft_Reporting].[dbo].[c_Wellsoft_Rpt_tbl]
	SMSDSS.BMH_PLM_PtAcct_V

Creates Table:
	smsdss.c_exec_dashboard_tbl

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	This query gets the desired metrics for the 7am executive dashboard

Revision History:
Date		Version		Description
----		----		----
2021-06-30	v1			Initial Creation
***********************************************************************
*/

-- RESULT SET
-- LOS QUERIES
DECLARE @LOS AS TABLE (
	PatientAccountID VARCHAR(12),
	VisitStartDateTime DATETIME2,
	LOS FLOAT
	)

INSERT INTO @LOS (
	PatientAccountID,
	VisitStartDateTime,
	LOS
	)
SELECT PatientAccountID,
	VisitStartDateTime,
	DATEDIFF(DAY, VisitStartDateTime, GETDATE()) AS [LOS]
FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit AS A
WHERE A.VisitEndDateTime IS NULL
	AND A.PatientLocationName <> ''
	AND A.IsDeleted = 0
	AND VisitTypeCode = 'IP';

DECLARE @TempTbl AS TABLE (
	Metric VARCHAR(255),
	Metric_Value FLOAT
	)

INSERT INTO @TempTbl (
	Metric,
	Metric_Value
	)
-- Admissions
SELECT 'Admissions',
	COUNT(*)
FROM SMSMIR.hl7_msg_hdr AS A
WHERE A.evnt_type_cd IN ('A01', 'A47')
	AND CAST(evnt_dtime AS DATE) = CAST(GETDATE() - 1 AS DATE)

UNION ALL

SELECT 'Admissions_7day_Avg',
	ROUND(COUNT(*) / 7.0, 2)
FROM SMSMIR.hl7_msg_hdr AS A
WHERE A.evnt_type_cd IN ('A01', 'A47')
	AND CAST(evnt_dtime AS DATE) BETWEEN CAST(GETDATE() - 7 AS DATE)
		AND CAST(GETDATE() - 1 AS DATE)

UNION ALL

SELECT 'Admissions_30day_Avg',
	ROUND(COUNT(*) / 30.0, 2)
FROM SMSMIR.hl7_msg_hdr AS A
WHERE A.evnt_type_cd IN ('A01', 'A47')
	AND CAST(evnt_dtime AS DATE) BETWEEN CAST(GETDATE() - 30 AS DATE)
		AND CAST(GETDATE() - 1 AS DATE)

UNION ALL

-- ED ADMISSIONS
SELECT 'ED_Admissions',
	COUNT(*)
FROM SMSMIR.hl7_msg_hdr AS A
LEFT JOIN smsmir.pms_case AS b ON a.pt_id = b.episode_no
WHERE A.evnt_type_cd = 'A01'
	AND CAST(evnt_dtime AS DATE) = CAST(GETDATE() - 1 AS DATE)
	AND LEFT(B.preadm_pt_id, 1) IN ('8', '9')

UNION ALL

SELECT 'ED_Admissions_7day_Avg',
	ROUND(COUNT(*) / 7.0, 2)
FROM SMSMIR.hl7_msg_hdr AS A
LEFT JOIN smsmir.pms_case AS b ON a.pt_id = b.episode_no
WHERE A.evnt_type_cd = 'A01'
	AND CAST(evnt_dtime AS DATE) BETWEEN CAST(GETDATE() - 7 AS DATE)
		AND CAST(GETDATE() - 1 AS DATE)
	AND LEFT(B.preadm_pt_id, 1) IN ('8', '9')

UNION ALL

SELECT 'ED_Admissions_30day_Avg',
	ROUND(COUNT(*) / 30.0, 2)
FROM SMSMIR.hl7_msg_hdr AS A
LEFT JOIN smsmir.pms_case AS b ON a.pt_id = b.episode_no
WHERE A.evnt_type_cd = 'A01'
	AND CAST(evnt_dtime AS DATE) BETWEEN CAST(GETDATE() - 30 AS DATE)
		AND CAST(GETDATE() - 1 AS DATE)
	AND LEFT(B.preadm_pt_id, 1) IN ('8', '9')

UNION ALL

-- ED VISITS
SELECT 'ED_Visits',
	COUNT(*)
FROM [SQL-WS\REPORTING].[WellSoft_Reporting].[dbo].[c_Wellsoft_Rpt_tbl] AS A
WHERE CAST(ARRIVAL AS DATE) = CAST(GETDATE() - 1 AS DATE)

UNION ALL

SELECT 'ED_Visits_7day_Avg',
	ROUND(COUNT(*) / 7.0, 2)
FROM [SQL-WS\REPORTING].[WellSoft_Reporting].[dbo].[c_Wellsoft_Rpt_tbl] AS A
WHERE CAST(ARRIVAL AS DATE) BETWEEN CAST(GETDATE() - 7 AS DATE)
		AND CAST(GETDATE() - 1 AS DATE)

UNION ALL

SELECT 'ED_Visits_30day_Avg',
	ROUND(COUNT(*) / 30.0, 2)
FROM [SQL-WS\REPORTING].[WellSoft_Reporting].[dbo].[c_Wellsoft_Rpt_tbl] AS A
WHERE CAST(ARRIVAL AS DATE) BETWEEN CAST(GETDATE() - 30 AS DATE)
		AND CAST(GETDATE() - 1 AS DATE)

UNION ALL

-- lwbs ed
SELECT 'ED_LWBS',
	COUNT(*)
FROM [SQL-WS\REPORTING].[WellSoft_Reporting].[dbo].[c_Wellsoft_Rpt_tbl] AS A
WHERE CAST(ARRIVAL AS DATE) = CAST(GETDATE() - 1 AS DATE)
	AND DISPOSITION = 'LWBS'

UNION ALL

-- DISCHARGES
SELECT 'Discharges',
	COUNT(*)
FROM SMSDSS.BMH_PLM_PtAcct_V
WHERE Plm_Pt_Acct_Type = 'I'
	AND tot_chg_amt > 0
	AND LEFT(PTNO_NUM, 1) = '1'
	AND CAST(DSCH_DATE AS DATE) = CAST(GETDATE() - 1 AS DATE)

UNION ALL

SELECT 'Discharges_7day_Avg',
	ROUND(COUNT(*) / 7.0, 2)
FROM SMSDSS.BMH_PLM_PtAcct_V
WHERE Plm_Pt_Acct_Type = 'I'
	AND tot_chg_amt > 0
	AND LEFT(PTNO_NUM, 1) = '1'
	AND CAST(DSCH_DATE AS DATE) BETWEEN CAST(GETDATE() - 7 AS DATE)
		AND CAST(GETDATE() - 1 AS DATE)

UNION ALL

SELECT 'Discharges_30day_Avg',
	ROUND(COUNT(*) / 30.0, 2)
FROM SMSDSS.BMH_PLM_PtAcct_V
WHERE Plm_Pt_Acct_Type = 'I'
	AND tot_chg_amt > 0
	AND LEFT(PTNO_NUM, 1) = '1'
	AND CAST(DSCH_DATE AS DATE) BETWEEN CAST(GETDATE() - 30 AS DATE)
		AND CAST(GETDATE() - 1 AS DATE)

UNION ALL

-- INPATIENTS
SELECT 'Inpatients',
	COUNT(*)
FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit AS A
WHERE A.VisitEndDateTime IS NULL
	AND A.PatientLocationName <> ''
	AND A.IsDeleted = 0
	AND VisitTypeCode = 'IP'

UNION ALL

-- ICU
SELECT 'ICU',
	COUNT(*)
FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit AS A
WHERE A.VisitEndDateTime IS NULL
	AND A.PatientLocationName <> ''
	AND A.IsDeleted = 0
	AND AccommodationType = 'Intensive Care'

UNION ALL

-- ED HOLDS
SELECT 'ED_Holds',
	COUNT(*)
FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit AS A
WHERE A.VisitEndDateTime IS NULL
	AND A.PatientLocationName <> ''
	AND A.IsDeleted = 0
	AND VisitTypeCode = 'IP'
	AND PatientLocationName = 'EMER'

UNION ALL

-- ICU HELD IN ED
SELECT 'ICU_Held_In_ED',
	COUNT(*)
FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit AS A
WHERE A.VisitEndDateTime IS NULL
	AND A.PatientLocationName <> ''
	AND A.IsDeleted = 0
	AND VisitTypeCode = 'IP'
	AND PatientLocationName = 'EMER'
	AND AccommodationType = 'Intensive Care'

UNION ALL

-- OBSERVATIONS
SELECT 'Observations',
	COUNT(*)
FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit AS A
INNER JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HHealthCareUnit AS B ON A.UnitContacted_oid = B.ObjectID
WHERE A.VisitEndDateTime IS NULL
	AND A.PatientLocationName <> ''
	AND A.IsDeleted = 0
	AND SUBSTRING(LTRIM(RTRIM(B.Abbreviation)), 1, 3) = 'OBV'

UNION ALL

--OBS MORE THAN 2 MIDNIGHTS
SELECT 'Observations_Over_Two_Midnights',
	COUNT(*)
FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit AS A
INNER JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HHealthCareUnit AS B ON A.UnitContacted_oid = B.ObjectID
WHERE A.PatientLocationName <> ''
	AND A.IsDeleted = 0
	AND SUBSTRING(LTRIM(RTRIM(B.Abbreviation)), 1, 3) = 'OBV'
	AND GETDATE() >= CAST(DATEADD(HOUR, 24 + (24 - DATEPART(HOUR, A.VisitStartDateTime)), A.VisitStartDateTime) AS DATE)

UNION ALL

-- ed obs holds
SELECT 'Observation_ED_Hold',
	COUNT(*)
FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit AS A
INNER JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HHealthCareUnit AS B ON A.UnitContacted_oid = B.ObjectID
WHERE A.VisitEndDateTime IS NULL
	AND A.PatientLocationName <> ''
	AND A.IsDeleted = 0
	AND A.PatientLocationName = 'EMER'
	AND SUBSTRING(LTRIM(RTRIM(B.Abbreviation)), 1, 3) = 'OBV'

UNION ALL

-- Intubated
SELECT 'Intubated',
	COUNT(*)
FROM smsdss.c_covid_vents_tbl

UNION ALL

SELECT 'Intubated_7day_Avg',
	ROUND(COUNT(*) / 7.0, 2)
FROM SMSDSS.c_covid_hhs_tbl
WHERE CAST(SP_Run_DateTime AS DATE) BETWEEN CAST(GETDATE() - 7 AS DATE)
		AND CAST(GETDATE() - 1 AS DATE)
	AND Vented = 'Vented'

UNION ALL

SELECT 'Intubated_30day_Avg',
	ROUND(COUNT(*) / 30.0, 2)
FROM SMSDSS.c_covid_hhs_tbl
WHERE CAST(SP_Run_DateTime AS DATE) BETWEEN CAST(GETDATE() - 30 AS DATE)
		AND CAST(GETDATE() - 1 AS DATE)
	AND Vented = 'Vented'

UNION ALL

-- ED ACCESS
SELECT 'ED_Access',
	COUNT(*)
FROM [SQL-WS\REPORTING].[WellSoft_Reporting].[dbo].[c_Wellsoft_Rpt_tbl] AS A
WHERE AREAOFCARE = 'ACCESS'
	AND TIMELEFTED = '-- ::00'
	AND DISPOSITION IS NULL

UNION ALL

-- ED ACCESS 7 Day Avg
SELECT 'ED_Access_7Day_Avg',
	ROUND(COUNT(*) / 7.0, 2)
FROM [SQL-WS\REPORTING].[WellSoft_Reporting].[dbo].[c_Wellsoft_Rpt_tbl] AS A
WHERE AREAOFCARE = 'ACCESS'
	AND ARRIVAL BETWEEN CAST(GETDATE() - 7 AS DATE)
		AND CAST(GETDATE() - 1 AS DATE)

UNION ALL

-- ED ACCESS 30 Day Avg
SELECT 'ED_Access_30Day_Avg',
	ROUND(COUNT(*) / 30.0, 2)
FROM [SQL-WS\REPORTING].[WellSoft_Reporting].[dbo].[c_Wellsoft_Rpt_tbl] AS A
WHERE AREAOFCARE = 'ACCESS'
	AND ARRIVAL BETWEEN CAST(GETDATE() - 30 AS DATE)
		AND CAST(GETDATE() - 1 AS DATE)

UNION ALL

-- OR YESTERDAY
SELECT 'OR_Yesterday',
	COUNT(*)
FROM [BMH-ORSOS].[ORSPROD].[ORSPROD].[Pre_CASE]
WHERE cast([start_date] AS DATE) = cast(getdate() - 1 AS DATE)
	AND account_no IS NOT NULL
	AND (
		DELETE_FLAG IS NULL
		OR DELETE_FLAG = ''
		OR DELETE_FLAG = 'Z'
		)

UNION ALL

-- OR TODAY
SELECT 'OR_Today',
	COUNT(*)
FROM [BMH-ORSOS].[ORSPROD].[ORSPROD].[Pre_CASE]
WHERE cast([start_date] AS DATE) = cast(getdate() AS DATE)
	AND account_no IS NOT NULL
	AND (
		DELETE_FLAG IS NULL
		OR DELETE_FLAG = ''
		OR DELETE_FLAG = 'Z'
		)

UNION ALL

-- OR 7 Day Avg
SELECT 'OR_7day_Avg',
	ROUND(COUNT(*) / 7.0, 2)
FROM [BMH-ORSOS].[ORSPROD].[ORSPROD].[Pre_CASE]
WHERE CAST([start_date] AS DATE) BETWEEN CAST(GETDATE() - 7 AS DATE)
		AND CAST(GETDATE() - 1 AS DATE)
	AND account_no IS NOT NULL
	AND (
		DELETE_FLAG IS NULL
		OR DELETE_FLAG = ''
		OR DELETE_FLAG = 'Z'
		)

UNION ALL

-- OR 30 Day Avg
SELECT 'OR_30day_Avg',
	ROUND(COUNT(*) / 30.0, 2)
FROM [BMH-ORSOS].[ORSPROD].[ORSPROD].[Pre_CASE]
WHERE CAST([start_date] AS DATE) BETWEEN CAST(GETDATE() - 30 AS DATE)
		AND CAST(GETDATE() - 1 AS DATE)
	AND account_no IS NOT NULL
	AND (
		DELETE_FLAG IS NULL
		OR DELETE_FLAG = ''
		OR DELETE_FLAG = 'Z'
		)

UNION ALL

-- ALOS ALL
SELECT 'ALOS',
	ROUND(AVG(LOS), 2)
FROM @LOS

UNION ALL

-- LOS BETWEEN 10 AND 20
SELECT 'LOS_Between_11_and_19',
	COUNT(*)
FROM @LOS
WHERE LOS BETWEEN 11
		AND 19

UNION ALL

-- LOS GTE 20
SELECT 'LOS_gte_20',
	COUNT(*)
FROM @LOS
WHERE LOS >= 20

INSERT INTO SMSDSS.c_exec_dashboard_tbl (metric, metric_value, rundate)
SELECT [Metric],
	[Metric_Value],
	[RunDate] = CAST(GETDATE() AS DATE)
FROM @TempTbl

