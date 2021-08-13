USE [SMSPHDSSS0X0]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
***********************************************************************
File: c_exec_dashboard_sp.sql

Input Parameters:
	None

Tables/Views:
	[SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit
	smsmir.hl7_msg_hdr
	[SQL-WS\REPORTING].[WellSoft_Reporting].[dbo].[c_Wellsoft_Rpt_tbl]
	smsdss.BMH_PLM_PtAcct_V
	SMSDSS.c_covid_hhs_tbl

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
2021-07-07	v1			Initial Creation
2021-07-08	v2			Change metrics that look at the table to
						ROUND(AVG(metric_value), 2)
2021-07-22	v3			Change ED_LWBS to look at both Disposition and
						Status fields
							AND (
								DISPOSITION = 'LWBS'
								OR [Status] LIKE 'LWBS%'
							)
2021-08-12	v4			Add 6 metrics IP and OP OR Yesterday 7day Avg and
						30day_Avg
2021-08-13  v5			Added 7 and 30 Day Avg for OR Today
***********************************************************************
*/

ALTER PROCEDURE [dbo].[c_exec_dashboard_sp]
AS
SET ANSI_NULLS ON
SET ANSI_WARNINGS ON
SET QUOTED_IDENTIFIER ON

-- CREATE TABLE IF NOT EXISTS ELSE INSERT RECORDS
IF NOT EXISTS (
		SELECT TOP 1 *
		FROM SYSOBJECTS
		WHERE NAME = 'c_exec_dashboard_tbl'
			AND XTYPE = 'U'
		)
BEGIN
	SET NOCOUNT ON;

	-- create table if not exists
	CREATE TABLE smsdss.c_exec_dashboard_tbl (
		c_exec_dashboard_tblId INT IDENTITY(1, 1) NOT NULL PRIMARY KEY,
		metric VARCHAR(255),
		metric_value FLOAT,
		rundate DATE
		)

	-- insert records into table
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
		AND (
			DISPOSITION = 'LWBS'
			OR [Status] LIKE 'LWBS%'
		)
	
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

	SELECT 'IP_OR_Yesterday',
		COUNT(*)
	FROM [BMH-ORSOS].[ORSPROD].[ORSPROD].[Pre_CASE] AS A
	INNER JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[CLINICAL] AS B ON A.ACCOUNT_NO = B.ACCOUNT_NO
	WHERE CAST(A.[start_date] AS DATE) = CAST(GETDATE() - 1 AS DATE)
		AND A.account_no IS NOT NULL
		AND (
			A.DELETE_FLAG IS NULL
			OR A.DELETE_FLAG = ''
			OR A.DELETE_FLAG = 'Z'
			)
		AND (
			B.PATIENT_TYPE IN ('4','5','8')
			OR (
				B.Patient_Type IS NULL
				AND LEFT(B.FACILITY_ACCOUNT_NO, 1) = '1'
			)
		)

		UNION ALL

	SELECT 'IP_OR_7day_Avg',
		ROUND(COUNT(*) / 7.0, 2)
	FROM [BMH-ORSOS].[ORSPROD].[ORSPROD].[Pre_CASE] AS A
	INNER JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[CLINICAL] AS B ON A.ACCOUNT_NO = B.ACCOUNT_NO
	WHERE CAST(A.[start_date] AS DATE) BETWEEN CAST(GETDATE() - 7 AS DATE)
			AND CAST(GETDATE() -1 AS DATE)
		AND A.account_no IS NOT NULL
		AND (
			A.DELETE_FLAG IS NULL
			OR A.DELETE_FLAG = ''
			OR A.DELETE_FLAG = 'Z'
			)
		AND (
			B.PATIENT_TYPE IN ('4','5','8')
			OR (
				B.Patient_Type IS NULL
				AND LEFT(B.FACILITY_ACCOUNT_NO, 1) = '1'
			)
		)

		UNION ALL

	SELECT 'IP_OR_30day_Avg',
		ROUND(COUNT(*) / 30.0, 2)
	FROM [BMH-ORSOS].[ORSPROD].[ORSPROD].[Pre_CASE] AS A
	INNER JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[CLINICAL] AS B ON A.ACCOUNT_NO = B.ACCOUNT_NO
	WHERE CAST(A.[start_date] AS DATE) BETWEEN CAST(GETDATE() - 30 AS DATE)
		AND CAST(GETDATE() - 1 AS DATE)
		AND A.account_no IS NOT NULL
		AND (
			A.DELETE_FLAG IS NULL
			OR A.DELETE_FLAG = ''
			OR A.DELETE_FLAG = 'Z'
			)
		AND (
			B.PATIENT_TYPE IN ('4','5','8')
			OR (
				B.Patient_Type IS NULL
				AND LEFT(B.FACILITY_ACCOUNT_NO, 1) = '1'
			)
		)

		UNION ALL

	SELECT 'OP_OR_Yesterday',
		COUNT(*)
	FROM [BMH-ORSOS].[ORSPROD].[ORSPROD].[Pre_CASE] AS A
	INNER JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[CLINICAL] AS B ON A.ACCOUNT_NO = B.ACCOUNT_NO
	WHERE CAST(A.[start_date] AS DATE) = CAST(GETDATE() - 1 AS DATE)
		AND A.account_no IS NOT NULL
		AND (
			A.DELETE_FLAG IS NULL
			OR A.DELETE_FLAG = ''
			OR A.DELETE_FLAG = 'Z'
			)
		AND B.PATIENT_TYPE NOT IN ('4','5','8')

		UNION ALL

	SELECT 'OP_OR_7day_Avg',
		ROUND(COUNT(*) / 7.0, 2)
	FROM [BMH-ORSOS].[ORSPROD].[ORSPROD].[Pre_CASE] AS A
	INNER JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[CLINICAL] AS B ON A.ACCOUNT_NO = B.ACCOUNT_NO
	WHERE CAST(A.[start_date] AS DATE) BETWEEN CAST(GETDATE() - 7 AS DATE)
			AND CAST(GETDATE() -1 AS DATE)
		AND A.account_no IS NOT NULL
		AND (
			A.DELETE_FLAG IS NULL
			OR A.DELETE_FLAG = ''
			OR A.DELETE_FLAG = 'Z'
			)
		AND B.PATIENT_TYPE NOT IN ('4','5','8')

		UNION ALL

	SELECT 'OP_OR_30day_Avg',
		ROUND(COUNT(*) / 30.0, 2)
	FROM [BMH-ORSOS].[ORSPROD].[ORSPROD].[Pre_CASE] AS A
	INNER JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[CLINICAL] AS B ON A.ACCOUNT_NO = B.ACCOUNT_NO
	WHERE CAST(A.[start_date] AS DATE) BETWEEN CAST(GETDATE() - 30 AS DATE)
		AND CAST(GETDATE() - 1 AS DATE)
		AND A.account_no IS NOT NULL
		AND (
			A.DELETE_FLAG IS NULL
			OR A.DELETE_FLAG = ''
			OR A.DELETE_FLAG = 'Z'
			)
		AND B.PATIENT_TYPE NOT IN ('4','5','8')

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

	INSERT INTO SMSDSS.c_exec_dashboard_tbl (
		metric,
		metric_value,
		rundate
		)
	SELECT [Metric],
		[Metric_Value],
		[RunDate] = CAST(GETDATE() AS DATE)
	FROM @TempTbl
END

ELSE BEGIN

	-- LOS QUERIES
	DECLARE @LOSTbl AS TABLE (
		PatientAccountID VARCHAR(12),
		VisitStartDateTime DATETIME2,
		LOS FLOAT
		)

	INSERT INTO @LOSTbl (
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

	DECLARE @TempTblB AS TABLE (
		Metric VARCHAR(255),
		Metric_Value FLOAT
		)

	INSERT INTO @TempTblB (
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
	
	-- Admissions 7 Day Avg
	SELECT 'Admissions_7day_Avg',
		ROUND(COUNT(*) / 7.0, 2)
	FROM SMSMIR.hl7_msg_hdr AS A
	WHERE A.evnt_type_cd IN ('A01', 'A47')
		AND CAST(evnt_dtime AS DATE) BETWEEN CAST(GETDATE() - 7 AS DATE)
			AND CAST(GETDATE() - 1 AS DATE)
	
	UNION ALL
	
	-- Admissions 30 Day Avg
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
	
	-- ED Admissions 7 Day Avg
	SELECT 'ED_Admissions_7day_Avg',
		ROUND(COUNT(*) / 7.0, 2)
	FROM SMSMIR.hl7_msg_hdr AS A
	LEFT JOIN smsmir.pms_case AS b ON a.pt_id = b.episode_no
	WHERE A.evnt_type_cd = 'A01'
		AND CAST(evnt_dtime AS DATE) BETWEEN CAST(GETDATE() - 7 AS DATE)
			AND CAST(GETDATE() - 1 AS DATE)
		AND LEFT(B.preadm_pt_id, 1) IN ('8', '9')
	
	UNION ALL
	
	-- ED Admissions 30 Day Avg
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
	
	-- ED Visits 7 Day Avg
	SELECT 'ED_Visits_7day_Avg',
		ROUND(COUNT(*) / 7.0, 2)
	FROM [SQL-WS\REPORTING].[WellSoft_Reporting].[dbo].[c_Wellsoft_Rpt_tbl] AS A
	WHERE CAST(ARRIVAL AS DATE) BETWEEN CAST(GETDATE() - 7 AS DATE)
			AND CAST(GETDATE() - 1 AS DATE)
	
	UNION ALL
	
	-- ED Visits 30 Day Avg
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
		AND (
			DISPOSITION = 'LWBS'
			OR [Status] LIKE 'LWBS%'
		)

	UNION ALL

	-- LWBS 7 DAY AVG
	SELECT 'ED_LWBS_7day_Avg',
		ROUND(AVG(metric_value), 2)
		--ROUND(SUM(metric_value) / 7.0, 2)
	FROM SMSDSS.c_exec_dashboard_tbl
	WHERE metric = 'ED_LWBS'
	AND  rundate >= CAST(GETDATE() - 7 AS DATE)

	UNION ALL

	-- LWBS 30 DAY AVG
	SELECT 'ED_LWBS_30day_Avg',
		ROUND(AVG(metric_value), 2)
		--ROUND(SUM(metric_value) / 30.0, 2)
	FROM SMSDSS.c_exec_dashboard_tbl
	WHERE metric = 'ED_LWBS'
	AND  rundate >= CAST(GETDATE() - 30 AS DATE)
	
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
	
	-- Discharges 7 Day Avg
	SELECT 'Discharges_7day_Avg',
		ROUND(COUNT(*) / 7.0, 2)
	FROM SMSDSS.BMH_PLM_PtAcct_V
	WHERE Plm_Pt_Acct_Type = 'I'
		AND tot_chg_amt > 0
		AND LEFT(PTNO_NUM, 1) = '1'
		AND CAST(DSCH_DATE AS DATE) BETWEEN CAST(GETDATE() - 7 AS DATE)
			AND CAST(GETDATE() - 1 AS DATE)
	
	UNION ALL
	
	-- Discharges 30 Day Avg
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

	-- Inpatients 7 DAY AVG
	SELECT 'Inpatients_7day_Avg',
		ROUND(AVG(metric_value), 2)
		--ROUND(SUM(metric_value) / 7.0, 2)
	FROM SMSDSS.c_exec_dashboard_tbl
	WHERE metric = 'Inpatients'
	AND  rundate >= CAST(GETDATE() - 7 AS DATE)

	UNION ALL

	-- Inpatients 30 DAY AVG
	SELECT 'Inpatients_30day_Avg',
		ROUND(AVG(metric_value), 2)
		--ROUND(SUM(metric_value) / 30.0, 2)
	FROM SMSDSS.c_exec_dashboard_tbl
	WHERE metric = 'Inpatients'
	AND  rundate >= CAST(GETDATE() - 30 AS DATE)

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

	-- ICU 7 DAY AVG
	SELECT 'ICU_7day_Avg',
		ROUND(AVG(metric_value), 2)
		--ROUND(SUM(metric_value) / 7.0, 2)
	FROM SMSDSS.c_exec_dashboard_tbl
	WHERE metric = 'ICU'
	AND  rundate >= CAST(GETDATE() - 7 AS DATE)

	UNION ALL

	-- ICU 30 DAY AVG
	SELECT 'ICU_30day_Avg',
		ROUND(AVG(metric_value), 2)
		--ROUND(SUM(metric_value) / 30.0, 2)
	FROM SMSDSS.c_exec_dashboard_tbl
	WHERE metric = 'ICU'
	AND  rundate >= CAST(GETDATE() - 30 AS DATE)
	
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

	-- ED_Holds 7 DAY AVG
	SELECT 'ED_Holds_7day_Avg',
		ROUND(AVG(metric_value), 2)
		--ROUND(SUM(metric_value) / 7.0, 2)
	FROM SMSDSS.c_exec_dashboard_tbl
	WHERE metric = 'ED_Holds'
	AND  rundate >= CAST(GETDATE() - 7 AS DATE)

	UNION ALL

	-- ED_Holds 30 DAY AVG
	SELECT 'ED_Holds_30day_Avg',
		ROUND(AVG(metric_value), 2)
		--ROUND(SUM(metric_value) / 30.0, 2)
	FROM SMSDSS.c_exec_dashboard_tbl
	WHERE metric = 'ED_Holds'
	AND  rundate >= CAST(GETDATE() - 30 AS DATE)
	
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

	-- ICU_Held_In_ED 7 DAY AVG
	SELECT 'ICU_Held_In_ED_7day_Avg',
		ROUND(AVG(metric_value), 2)
		--ROUND(SUM(metric_value) / 7.0, 2)
	FROM SMSDSS.c_exec_dashboard_tbl
	WHERE metric = 'ICU_Held_In_ED'
	AND  rundate >= CAST(GETDATE() - 7 AS DATE)

	UNION ALL

	-- ICU_Held_In_ED 30 DAY AVG
	SELECT 'ICU_Held_In_ED_30day_Avg',
		ROUND(AVG(metric_value), 2)
		--ROUND(SUM(metric_value) / 30.0, 2)
	FROM SMSDSS.c_exec_dashboard_tbl
	WHERE metric = 'ICU_Held_In_ED'
	AND  rundate >= CAST(GETDATE() - 30 AS DATE)

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

	-- Observations 7 DAY AVG
	SELECT 'Observations_7day_Avg',
		ROUND(AVG(metric_value), 2)
		--ROUND(SUM(metric_value) / 7.0, 2)
	FROM SMSDSS.c_exec_dashboard_tbl
	WHERE metric = 'Observations'
	AND  rundate >= CAST(GETDATE() - 7 AS DATE)

	UNION ALL

	-- Observations 30 DAY AVG
	SELECT 'Observations_30day_Avg',
		ROUND(AVG(metric_value), 2)
		--ROUND(SUM(metric_value) / 30.0, 2)
	FROM SMSDSS.c_exec_dashboard_tbl
	WHERE metric = 'Observations'
	AND  rundate >= CAST(GETDATE() - 30 AS DATE)

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

	-- Observations_Over_Two_Midnights 7 DAY AVG
	SELECT 'Observations_Over_Two_Midnights_7day_Avg',
		ROUND(AVG(metric_value), 2)
		--ROUND(SUM(metric_value) / 7.0, 2)
	FROM SMSDSS.c_exec_dashboard_tbl
	WHERE metric = 'Observations_Over_Two_Midnights'
	AND  rundate >= CAST(GETDATE() - 7 AS DATE)

	UNION ALL

	-- Observations_Over_Two_Midnights 30 DAY AVG
	SELECT 'Observations_Over_Two_Midnights_30day_Avg',
		ROUND(AVG(metric_value), 2)
		--ROUND(SUM(metric_value) / 30.0, 2)
	FROM SMSDSS.c_exec_dashboard_tbl
	WHERE metric = 'Observations_Over_Two_Midnights'
	AND  rundate >= CAST(GETDATE() - 30 AS DATE)

	UNION ALL
	
	-- Observation ED Holds
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

	-- Observation_ED_Hold 7 DAY AVG
	SELECT 'Observation_ED_Hold_7day_Avg',
		ROUND(AVG(metric_value), 2)
		--ROUND(SUM(metric_value) / 7.0, 2)
	FROM SMSDSS.c_exec_dashboard_tbl
	WHERE metric = 'Observation_ED_Hold'
	AND  rundate >= CAST(GETDATE() - 7 AS DATE)

	UNION ALL

	-- Observation_ED_Hold 30 DAY AVG
	SELECT 'Observation_ED_Hold_30day_Avg',
		ROUND(AVG(metric_value), 2)
		--ROUND(SUM(metric_value) / 30.0, 2)
	FROM SMSDSS.c_exec_dashboard_tbl
	WHERE metric = 'Observation_ED_Hold'
	AND  rundate >= CAST(GETDATE() - 30 AS DATE)
	
	UNION ALL
	
	-- Intubated
	SELECT 'Intubated',
		COUNT(*)
	FROM smsdss.c_covid_vents_tbl
	
	UNION ALL
	
	-- Intubated 7 Day Avg
	SELECT 'Intubated_7day_Avg',
		ROUND(COUNT(*) / 7.0, 2)
	FROM SMSDSS.c_covid_hhs_tbl
	WHERE CAST(SP_Run_DateTime AS DATE) BETWEEN CAST(GETDATE() - 7 AS DATE)
			AND CAST(GETDATE() - 1 AS DATE)
		AND Vented = 'Vented'
	
	UNION ALL
	
	-- Intubated 30 Day Avg
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

	SELECT 'IP_OR_Yesterday',
		COUNT(*)
	FROM [BMH-ORSOS].[ORSPROD].[ORSPROD].[Pre_CASE] AS A
	INNER JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[CLINICAL] AS B ON A.ACCOUNT_NO = B.ACCOUNT_NO
	WHERE CAST(A.[start_date] AS DATE) = CAST(GETDATE() - 1 AS DATE)
		AND A.account_no IS NOT NULL
		AND (
			A.DELETE_FLAG IS NULL
			OR A.DELETE_FLAG = ''
			OR A.DELETE_FLAG = 'Z'
			)
		AND (
			B.PATIENT_TYPE IN ('4','5','8')
			OR (
				B.Patient_Type IS NULL
				AND LEFT(B.FACILITY_ACCOUNT_NO, 1) = '1'
			)
		)

		UNION ALL

	SELECT 'IP_OR_7day_Avg',
		ROUND(COUNT(*) / 7.0, 2)
	FROM [BMH-ORSOS].[ORSPROD].[ORSPROD].[Pre_CASE] AS A
	INNER JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[CLINICAL] AS B ON A.ACCOUNT_NO = B.ACCOUNT_NO
	WHERE CAST(A.[start_date] AS DATE) BETWEEN CAST(GETDATE() - 7 AS DATE)
			AND CAST(GETDATE() -1 AS DATE)
		AND A.account_no IS NOT NULL
		AND (
			A.DELETE_FLAG IS NULL
			OR A.DELETE_FLAG = ''
			OR A.DELETE_FLAG = 'Z'
			)
		AND (
			B.PATIENT_TYPE IN ('4','5','8')
			OR (
				B.Patient_Type IS NULL
				AND LEFT(B.FACILITY_ACCOUNT_NO, 1) = '1'
			)
		)

		UNION ALL

	SELECT 'IP_OR_30day_Avg',
		ROUND(COUNT(*) / 30.0, 2)
	FROM [BMH-ORSOS].[ORSPROD].[ORSPROD].[Pre_CASE] AS A
	INNER JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[CLINICAL] AS B ON A.ACCOUNT_NO = B.ACCOUNT_NO
	WHERE CAST(A.[start_date] AS DATE) BETWEEN CAST(GETDATE() - 30 AS DATE)
		AND CAST(GETDATE() - 1 AS DATE)
		AND A.account_no IS NOT NULL
		AND (
			A.DELETE_FLAG IS NULL
			OR A.DELETE_FLAG = ''
			OR A.DELETE_FLAG = 'Z'
			)
		AND (
			B.PATIENT_TYPE IN ('4','5','8')
			OR (
				B.Patient_Type IS NULL
				AND LEFT(B.FACILITY_ACCOUNT_NO, 1) = '1'
			)
		)

		UNION ALL

	SELECT 'OP_OR_Yesterday',
		COUNT(*)
	FROM [BMH-ORSOS].[ORSPROD].[ORSPROD].[Pre_CASE] AS A
	INNER JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[CLINICAL] AS B ON A.ACCOUNT_NO = B.ACCOUNT_NO
	WHERE CAST(A.[start_date] AS DATE) = CAST(GETDATE() - 1 AS DATE)
		AND A.account_no IS NOT NULL
		AND (
			A.DELETE_FLAG IS NULL
			OR A.DELETE_FLAG = ''
			OR A.DELETE_FLAG = 'Z'
			)
		AND (
			B.PATIENT_TYPE NOT IN ('4','5','8')
			OR (
				B.Patient_Type IS NULL
				AND LEFT(B.FACILITY_ACCOUNT_NO, 1) != '1'
			)
		)

		UNION ALL

	SELECT 'OP_OR_7day_Avg',
		ROUND(COUNT(*) / 7.0, 2)
	FROM [BMH-ORSOS].[ORSPROD].[ORSPROD].[Pre_CASE] AS A
	INNER JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[CLINICAL] AS B ON A.ACCOUNT_NO = B.ACCOUNT_NO
	WHERE CAST(A.[start_date] AS DATE) BETWEEN CAST(GETDATE() - 7 AS DATE)
			AND CAST(GETDATE() -1 AS DATE)
		AND A.account_no IS NOT NULL
		AND (
			A.DELETE_FLAG IS NULL
			OR A.DELETE_FLAG = ''
			OR A.DELETE_FLAG = 'Z'
			)
		AND (
			B.PATIENT_TYPE NOT IN ('4','5','8')
			OR (
				B.Patient_Type IS NULL
				AND LEFT(B.FACILITY_ACCOUNT_NO, 1) != '1'
			)
		)

		UNION ALL

	SELECT 'OP_OR_30day_Avg',
		ROUND(COUNT(*) / 30.0, 2)
	FROM [BMH-ORSOS].[ORSPROD].[ORSPROD].[Pre_CASE] AS A
	INNER JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[CLINICAL] AS B ON A.ACCOUNT_NO = B.ACCOUNT_NO
	WHERE CAST(A.[start_date] AS DATE) BETWEEN CAST(GETDATE() - 30 AS DATE)
		AND CAST(GETDATE() - 1 AS DATE)
		AND A.account_no IS NOT NULL
		AND (
			A.DELETE_FLAG IS NULL
			OR A.DELETE_FLAG = ''
			OR A.DELETE_FLAG = 'Z'
			)
		AND (
			B.PATIENT_TYPE NOT IN ('4','5','8')
			OR (
				B.Patient_Type IS NULL
				AND LEFT(B.FACILITY_ACCOUNT_NO, 1) != '1'
			)
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
	FROM @LOSTbl

	UNION ALL

	-- ALOS 7 DAY AVG
	SELECT 'ALOS_7day_Avg',
		ROUND(AVG(metric_value), 2)
		---ROUND(SUM(metric_value) / 7.0, 2)
	FROM SMSDSS.c_exec_dashboard_tbl
	WHERE metric = 'ALOS'
	AND  rundate >= CAST(GETDATE() - 7 AS DATE)

	UNION ALL

	-- ALOS 30 DAY AVG
	SELECT 'ALOS_30day_Avg',
		ROUND(AVG(metric_value), 2)
		--ROUND(SUM(metric_value) / 30.0, 2)
	FROM SMSDSS.c_exec_dashboard_tbl
	WHERE metric = 'ALOS'
	AND  rundate >= CAST(GETDATE() - 30 AS DATE)
	
	UNION ALL
	
	-- LOS BETWEEN 10 AND 20
	SELECT 'LOS_Between_11_and_19',
		COUNT(*)
	FROM @LOSTbl
	WHERE LOS BETWEEN 11
			AND 19
	
	UNION ALL

	-- LOS_Between_11_and_19 7 DAY AVG
	SELECT 'LOS_Between_11_and_19_7day_Avg',
		ROUND(AVG(metric_value), 2)
		--ROUND(SUM(metric_value) / 7.0, 2)
	FROM SMSDSS.c_exec_dashboard_tbl
	WHERE metric = 'LOS_Between_11_and_19'
	AND  rundate >= CAST(GETDATE() - 7 AS DATE)

	UNION ALL

	-- LOS_Between_11_and_19 30 DAY AVG
	SELECT 'LOS_Between_11_and_19_30day_Avg',
		ROUND(AVG(metric_value), 2)
		--ROUND(SUM(metric_value) / 30.0, 2)
	FROM SMSDSS.c_exec_dashboard_tbl
	WHERE metric = 'LOS_Between_11_and_19'
	AND  rundate >= CAST(GETDATE() - 30 AS DATE)

	UNION ALL
	
	-- LOS GTE 20
	SELECT 'LOS_gte_20',
		COUNT(*)
	FROM @LOSTbl
	WHERE LOS >= 20

	UNION ALL

	-- LOS_gte_20 7 DAY AVG
	SELECT 'LOS_gte_20_7day_Avg',
		ROUND(AVG(metric_value), 2)
		--ROUND(SUM(metric_value) / 7.0, 2)
	FROM SMSDSS.c_exec_dashboard_tbl
	WHERE metric = 'LOS_gte_20'
	AND  rundate >= CAST(GETDATE() - 7 AS DATE)

	UNION ALL

	-- LOS_gte_20 30 DAY AVG
	SELECT 'LOS_gte_20_30day_Avg',
		ROUND(AVG(metric_value), 2)
		--ROUND(SUM(metric_value) / 30.0, 2)
	FROM SMSDSS.c_exec_dashboard_tbl
	WHERE metric = 'LOS_gte_20'
	AND  rundate >= CAST(GETDATE() - 30 AS DATE)

	-- OR Today 7 and 30 Day Averages
	SELECT 'OR_Today_7day_Avg',
		ROUND(AVG(metric_value), 2)
	FROM SMSDSS.c_exec_dashboard_tbl
	WHERE metric = 'OR_Today'
	AND rundate >= CAST(GETDATE() - 7 AS DATE)

	SELECT 'OR_Today_30day_Avg',
		ROUND(AVG(metric_value), 2)
	FROM smsdss.c_exec_dashboard_tbl
	WHERE metric = 'OR_Today'
	AND rundate >= CAST(GETDATE() - 30 AS DATE)

	INSERT INTO SMSDSS.c_exec_dashboard_tbl (
		metric,
		metric_value,
		rundate
		)
	SELECT [Metric],
		[Metric_Value],
		[RunDate] = CAST(GETDATE() AS DATE)
	FROM @TempTblB
	WHERE CAST(GETDATE() AS DATE) NOT IN (
		SELECT rundate 
		FROM SMSDSS.c_exec_dashboard_tbl 
		GROUP BY rundate
	)

END;