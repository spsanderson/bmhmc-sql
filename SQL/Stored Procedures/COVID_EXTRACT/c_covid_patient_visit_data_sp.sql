USE [SMSPHDSSS0X0]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*
***********************************************************************
File: c_covid_patient_visit_data_sp.sql

Input Parameters:
	None

Tables/Views:
	smsdss.c_covid_ptvisitoid_tbl
	SMSMIR.mir_sc_PatientVisit
	smsmir.mir_sc_HealthCareUnit
	SMSMIR.HL7_PT AS B ON A.PATIENTACCOUNTID
	SMSDSS.RACE_CD_DIM_V
	[SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit
	[SC_server].[Soarian_Clin_Prd_1].DBO.HHealthCareUnit

Creates Table:
	smsdss.c_covid_patient_visit_data_tbl

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get patient visit data

Revision History:
Date		Version		Description
----		----		----
2020-07-07	v1			Initial Creation
2020-08-04	v2			Add Isolation_Indicator
						Add Isolation_Indicator_Abbr
2021-02-23	v3			Complete re-write
2021-03-03	v4			Use LastCngDtime
2021-08-05	v5			Add PT_Phone_Number
***********************************************************************
*/
ALTER PROCEDURE [dbo].[c_covid_patient_visit_data_sp]
AS
SET ANSI_NULLS ON
SET ANSI_WARNINGS ON
SET QUOTED_IDENTIFIER ON

BEGIN
	SET NOCOUNT ON;

	-- Create a new table called 'c_covid_patient_visit_data_tbl' in schema 'smsdss'
	-- Drop the table if it already exists
	IF OBJECT_ID('smsdss.c_covid_patient_visit_data_tbl', 'U') IS NOT NULL
		DROP TABLE smsdss.c_covid_patient_visit_data_tbl;

	-- Get all of the PatientVisitOID for which we want data
	DECLARE @VisitOID TABLE (PatientVisitOID INT)

	INSERT INTO @VisitOID
	SELECT DISTINCT PatientVisitOID
	FROM SMSDSS.c_covid_ptvisitoid_tbl

	DECLARE @START DATE;

	SET @START = DATEADD(DAY, DATEDIFF(DAY, 0, GETDATE()) - 1, 0)

	-- Get data from DSS first
	DECLARE @PatientVisitDataDSS TABLE (
		MRN INT,
		PatientAccountID INT,
		Pt_Name VARCHAR(250),
		Pt_Age INT,
		Pt_Gender VARCHAR(5),
		Race_Cd_Desc VARCHAR(100),
		Adm_Dtime DATETIME2,
		Pt_Accomodation VARCHAR(50),
		PatientReasonforSeekingHC VARCHAR(MAX),
		DC_DTime DATETIME2,
		DC_Disp VARCHAR(MAX),
		Mortality_Flag CHAR(1),
		PatientVisitOID INT,
		Hosp_Svc VARCHAR(10),
		PT_Phone_Number VARCHAR(255),
		PT_Street_Address VARCHAR(100),
		PT_City VARCHAR(100),
		PT_State VARCHAR(50),
		PT_Zip_CD VARCHAR(10),
		PT_DOB DATETIME2,
		Isolation_Indicator VARCHAR(500),
		Isolation_Indicator_Abbr VARCHAR(500)
		);

	INSERT INTO @PatientVisitDataDSS
	SELECT B.pt_med_rec_no AS [MRN],
		A.PATIENTACCOUNTID AS [PTNO_NUM],
		CAST(B.PT_LAST_NAME AS VARCHAR) + ', ' + CAST(B.PT_FIRST_NAME AS VARCHAR) AS [PT_NAME],
		ROUND((DATEDIFF(MONTH, B.pt_birth_date, A.VisitStartDateTime) / 12), 0) AS [PT_AGE],
		B.pt_gender,
		SUBSTRING(RACECD.RACE_CD_DESC, 1, CHARINDEX('  ', RACECD.RACE_CD_DESC, 1)) AS RACE_CD_DESC,
		A.VISITSTARTDATETIME AS [ADM_DTIME],
		A.ACCOMMODATIONTYPE AS [PT_Accomodation],
		REPLACE(REPLACE(REPLACE(REPLACE(A.PatientReasonforSeekingHC, CHAR(43), ' '), CHAR(45), ' '), CHAR(13), ' '), CHAR(10), ' ') AS [PatientReasonforSeekingHC],
		A.VisitEndDateTime,
		A.DischargeDisposition,
		[Mortality_Flag] = CASE 
			WHEN LEFT(A.DischargeDisposition, 1) IN ('C', 'D')
				THEN 1
			ELSE 0
			END,
		A.ObjectID,
		SUBSTRING(LTRIM(RTRIM(HCUNIT.Abbreviation)), 1, 3),
		[pt_phone] = '(' 
			+ CAST(B.pt_phone_area_city_cd AS varchar) 
			+ ')' 
			+ ' ' 
			+ CAST(LEFT(B.PT_PHONE_NO, 3) AS varchar) 
			+ '-' 
			+ CAST(RIGHT(B.PT_PHONE_NO, 4) AS VARCHAR),
		B.pt_street_addr,
		B.pt_city,
		B.pt_state,
		B.pt_zip_cd,
		B.pt_birth_date,
		ISNULL(A.IsolationIndicator, '') AS [IsolationIndicator],
		CASE 
			WHEN PATINDEX('%/%', A.IsolationIndicator) != 0
				THEN CAST(UPPER(SUBSTRING(A.IsolationIndicator, 1, 1)) AS VARCHAR) + CAST(UPPER(SUBSTRING(A.IsolationIndicator, PATINDEX('%/%', A.IsolationIndicator) + 1, 1)) AS VARCHAR)
			ELSE CAST(UPPER(SUBSTRING(A.IsolationIndicator, 1, 1)) AS VARCHAR)
			END AS [Isolation_Indicator_Abbr]
	FROM SMSMIR.mir_sc_PatientVisit AS A
	LEFT OUTER JOIN SMSMIR.HL7_PT AS B ON A.PatientAccountID = B.pt_id
	LEFT OUTER JOIN SMSDSS.race_cd_dim_v AS RACECD ON B.pt_race = RACECD.src_race_cd
		AND RACECD.src_sys_id = '#PMSNTX0'
	INNER JOIN smsmir.mir_sc_HealthCareUnit AS HCUNIT ON A.UnitContacted_oid = HCUNIT.ObjectID
	WHERE A.ObjectID IN (
			SELECT PatientVisitOID
			FROM @VisitOID
			)

	-- Get Data from PRD
	DECLARE @PatientVisitDataPRD TABLE (
		MRN INT,
		PatientAccountID INT,
		Pt_Name VARCHAR(250),
		Pt_Age INT,
		Pt_Gender VARCHAR(5),
		Race_Cd_Desc VARCHAR(100),
		Adm_Dtime DATETIME2,
		Pt_Accomodation VARCHAR(50),
		PatientReasonforSeekingHC VARCHAR(MAX),
		DC_DTime DATETIME2,
		DC_Disp VARCHAR(MAX),
		Mortality_Flag CHAR(1),
		PatientVisitOID INT,
		Hosp_Svc VARCHAR(10),
		PT_Phone_Number VARCHAR(255),
		PT_Street_Address VARCHAR(100),
		PT_City VARCHAR(100),
		PT_State VARCHAR(50),
		PT_Zip_CD VARCHAR(10),
		PT_DOB DATETIME2,
		Isolation_Indicator VARCHAR(500),
		Isolation_Indicator_Abbr VARCHAR(500)
		);

	INSERT INTO @PatientVisitDataPRD
	SELECT B.pt_med_rec_no AS [MRN],
		A.PATIENTACCOUNTID AS [PTNO_NUM],
		CAST(B.PT_LAST_NAME AS VARCHAR) + ', ' + CAST(B.PT_FIRST_NAME AS VARCHAR) AS [PT_NAME],
		ROUND((DATEDIFF(MONTH, B.pt_birth_date, A.VisitStartDateTime) / 12), 0) AS [PT_AGE],
		B.pt_gender,
		SUBSTRING(RACECD.RACE_CD_DESC, 1, CHARINDEX('  ', RACECD.RACE_CD_DESC, 1)) AS RACE_CD_DESC,
		A.VISITSTARTDATETIME AS [ADM_DTIME],
		A.ACCOMMODATIONTYPE AS [PT_Accomodation],
		REPLACE(REPLACE(REPLACE(REPLACE(A.PatientReasonforSeekingHC, CHAR(43), ' '), CHAR(45), ' '), CHAR(13), ' '), CHAR(10), ' ') AS [PatientReasonforSeekingHC],
		A.VisitEndDateTime,
		A.DischargeDisposition,
		[Mortality_Flag] = CASE 
			WHEN LEFT(A.DischargeDisposition, 1) IN ('C', 'D')
				THEN 1
			ELSE 0
			END,
		A.ObjectID,
		SUBSTRING(LTRIM(RTRIM(HCUNIT.Abbreviation)), 1, 3),
		[pt_phone] = '(' 
			+ CAST(B.pt_phone_area_city_cd AS varchar) 
			+ ')' 
			+ ' ' 
			+ CAST(LEFT(B.PT_PHONE_NO, 3) AS varchar) 
			+ '-' 
			+ CAST(RIGHT(B.PT_PHONE_NO, 4) AS VARCHAR),
		B.pt_street_addr,
		B.pt_city,
		B.pt_state,
		B.pt_zip_cd,
		B.pt_birth_date,
		ISNULL(A.IsolationIndicator, '') AS [IsolationIndicator],
		CASE 
			WHEN PATINDEX('%/%', A.IsolationIndicator) != 0
				THEN CAST(UPPER(SUBSTRING(A.IsolationIndicator, 1, 1)) AS VARCHAR) + CAST(UPPER(SUBSTRING(A.IsolationIndicator, PATINDEX('%/%', A.IsolationIndicator) + 1, 1)) AS VARCHAR)
			ELSE CAST(UPPER(SUBSTRING(A.IsolationIndicator, 1, 1)) AS VARCHAR)
			END AS [Isolation_Indicator_Abbr]
	FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit AS A
	LEFT OUTER JOIN SMSMIR.HL7_PT AS B ON A.PATIENTACCOUNTID = B.pt_id
	LEFT OUTER JOIN SMSDSS.RACE_CD_DIM_V AS RACECD ON B.pt_race = RACECD.src_race_cd
		AND RACECD.src_sys_id = '#PMSNTX0'
	INNER JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HHealthCareUnit AS HCUNIT ON A.UnitContacted_OID = HCUNIT.objectid
	WHERE CAST(A.LastCngDtime AS DATE) >= @START

	-- Delete records from DSS table if they are in the PRD table
	DELETE pvdss
	FROM @PatientVisitDataDSS pvdss
	WHERE EXISTS (
			SELECT 1
			FROM @PatientVisitDataPRD AS V
			WHERE V.PatientVisitOID = PVDSS.PatientVisitOID
			)

	-- Delete records from the PRD table if they are not in the original VisitOID table
	DELETE pvprd
	FROM @PatientVisitDataPRD pvprd
	WHERE NOT EXISTS (
			SELECT 1
			FROM @VisitOID AS V
			WHERE v.PatientVisitOID = pvprd.PatientVisitOID
			)

	-- Insert records into smsdss.c_covid_patient_visit_data_tbl
	SELECT A.MRN,
		A.PatientAccountID,
		A.Pt_Name,
		A.Pt_Age,
		A.Pt_Gender,
		A.Race_Cd_Desc,
		A.Adm_Dtime,
		A.Pt_Accomodation,
		A.PatientReasonforSeekingHC,
		A.DC_DTime,
		A.DC_Disp,
		A.Mortality_Flag,
		A.PatientVisitOID,
		A.Hosp_Svc,
		A.PT_Phone_Number,
		A.PT_Street_Address,
		A.PT_City,
		A.PT_State,
		A.PT_Zip_CD,
		A.PT_DOB,
		A.Isolation_Indicator,
		A.Isolation_Indicator_Abbr
	INTO smsdss.c_covid_patient_visit_data_tbl
	FROM (
		SELECT MRN,
			PatientAccountID,
			Pt_Name,
			Pt_Age,
			Pt_Gender,
			Race_Cd_Desc,
			Adm_Dtime,
			Pt_Accomodation,
			PatientReasonforSeekingHC,
			DC_DTime,
			DC_Disp,
			Mortality_Flag,
			PatientVisitOID,
			Hosp_Svc,
			PT_Phone_Number,
			PT_Street_Address,
			PT_City,
			PT_State,
			PT_Zip_CD,
			PT_DOB,
			Isolation_Indicator,
			Isolation_Indicator_Abbr
		FROM @PatientVisitDataDSS
		
		UNION ALL
		
		SELECT MRN,
			PatientAccountID,
			Pt_Name,
			Pt_Age,
			Pt_Gender,
			Race_Cd_Desc,
			Adm_Dtime,
			Pt_Accomodation,
			PatientReasonforSeekingHC,
			DC_DTime,
			DC_Disp,
			Mortality_Flag,
			PatientVisitOID,
			Hosp_Svc,
			PT_Phone_Number,
			PT_Street_Address,
			PT_City,
			PT_State,
			PT_Zip_CD,
			PT_DOB,
			Isolation_Indicator,
			Isolation_Indicator_Abbr
		FROM @PatientVisitDataPRD
		) AS A;
END;
