USE [SMSPHDSSS0X0]
GO
/****** Object:  StoredProcedure [dbo].[c_covid_patient_visit_data_sp]    Script Date: 8/4/2020 9:14:00 AM ******/
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
	[SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit
	SMSMIR.HL7_PT AS B ON A.PATIENTACCOUNTID
	SMSDSS.RACE_CD_DIM_V
	[SC_server].[Soarian_Clin_Prd_1].DBO.HHealthCareUnit
	smsdss.c_covid_ptvisitoid_tbl
	

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

	DECLARE @PatientVisitData TABLE (
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
		PT_Street_Address VARCHAR(100),
		PT_City VARCHAR(100),
		PT_State VARCHAR(50),
		PT_Zip_CD VARCHAR(10),
		PT_DOB DATETIME2,
		Isolation_Indicator VARCHAR(500),
		Isolation_Indicator_Abbr VARCHAR(500)
		--PT_Occupation VARCHAR(100)
		);

	INSERT INTO @PatientVisitData
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
	WHERE A.ObjectID IN (
			SELECT PatientVisitOID
			FROM smsdss.c_covid_ptvisitoid_tbl
			);

	SELECT *
	INTO smsdss.c_covid_patient_visit_data_tbl
	FROM @PatientVisitData;
END;
