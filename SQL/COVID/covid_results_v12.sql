/*
***********************************************************************
File: covid_results.sql

Input Parameters:
	None

Tables/Views:
	[SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit
	[SC_server].[Soarian_Clin_Prd_1].DBO.HOrder
	[SC_server].[Soarian_Clin_Prd_1].DBO.HOccurrenceOrder
	[SC_server].[Soarian_Clin_Prd_1].DBO.HInvestigationResult
	smsmir.HL7_PT
	smsmir.HL7_VST
    smsmir.obsv
    smsmir.pms_user_episo
	smsdss.c_soarian_real_time_census_CDI_v
	smsdss.BMH_PLM_PTACCT_V
	smsdss.RACE_CD_DIM_V
	smsdss.c_Covid_MiscRefRslt_tbl
	smsdss.c_positive_results_tbl
	smsdss.c_covid_external_positive_tbl

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get patients that have had a covid test and the result if it exists

Revision History:
Date		Version		Description
----		----		----
2020-04-07	v1			Initial Creation
2020-04-08	v2			Add pt_race and VisitEndDatetime
						Add vent information from DOH Denom SP
2020-04-09	v3			Add additional Detected Not Detect Logic
						Fix Race Code Description Column
2020-04-13	v4			Move DSCH_Date column and add isnull() columns
						look for A_BMH_VFSTART 
						Added subsequent visits for patients the previously
						tested positive for COVID-19
2020-04-14	v5			Add Misc Ref Labs, fix Nurs_Sta and Bed to be blank
						when A.VisitEndDateTime IS NULL
2020-04-15	v6			Fix bed issue - bed number showing when pt is discharged
						and null when in house
						Fix subsequent visits to include IP and ED only
						Fix subsequent visits to drop duplicates
						Add Chief Complaint
2020-04-16	v7			UNION realtime census to report
						ADD hosp_svc
						Add results from smsdss.c_Covid_MiscRefRslt_tbl
2020-04-20	v8			Exclude test accounts
2020-4-21	v9			Add ED results with covid fields
2020-04-30	v10			Large performance increase - time cut about 75%.
						Reduce code base by 86 lines
						Query all tables only once.
						Cosmetic changes to Covid_Order field to leave no nulls
						Get MAX result dt and order occurrence dt
						Add Subsequent Visit Column
						Add Order_Flag binary 0/1
						Add Result_Flag binary 0/1
2020-05-05  v11         Add comorbidities, occupation, address, city,
                        state, and zip code, dob, height, weight
2020-05-06  v12         Get comorbidities etc in one query, make pivot table
                        Replace CHAR(13, 10, 43, 45) with ' ' to fix export issues
                        Wrap Order_No and Covid_Order in single quotes to 
                        fix Crystal import
                        Add Labs A1c, HDL, LDL, Trig, Chol
2020-05-06  v13         Change DELETE FROM logic to go by ROW_NUMBER
                        and not NOT IN MAX(ID_NUM)
                        Add OrderStatusModifier NOT IN (
                            'Cancelled','Discontinue','Invalid-DC Order'
                            ) 
                        to @CovidOrders as sometimes cx/dc OrdOcc does
                        not always make it to the order
                        Add Pos_MRN column to demarcate positive persons
                        not just visits
2020-05-11	v14			Drop UNION
						Change vent to use 'A_BMH_VFinIntbtn'
2020-05-13	v15			Fix In_House to:
						Vst_end_date is null and  ( left(pvd.patientAccountID,1) = ‘1’  OR hosp_svc = OBV)
						Fix Vent FindingAbbr to the following:
						where FindingAbbr in ('A_BMH_VFAirway', 'A_BMH_VFInIntbtn')
						Add: REPLACE(
							REPLACE(
								REPLACE(
									REPLACE(A.PatientReasonforSeekingHC, CHAR(43), ' ')
									, CHAR(45), ' ')
								, CHAR(13), ' ')
							, CHAR(10), ' ') AS [PatientReasonforSeekingHC]
2020-05-14  v16         Add FormUsage = 'Ventilator Flow Sheet'
						SET @dtStartDate = DATEADD(HOUR, -12, @dtEndDate)
2020-05-18  v17			Changed Vent FindingAbbr to the following:
						WHERE FindingAbbr IN ('A_BMH_VFMode') and value not in ('Non invasive mode (BiPAP/CPAP)', 'CPAP')
2020-05-22	v18			Modified @SCRTCensus to use HPatientVisit in order to include OP's in beds
2020-05-28  v19         Add some columns:
                        State_Age_Group
                        PT_ADT
2020-06-02	v20			Add the following columns:
						pt_last_test_positive: 1/0 was the last resulted test positive
						Last_Positive_Result_DTime the date time of the last positive result
						first_positive_flag_dtime
						CHANGE 'NOT DETECTED%' TO '%NOT DETECTED%'
						DROP NOT <> D23 FROM IN_HOUSE FLAG
						DROP EOR FROM DISCHARGED CASE STATEMENT
						GET HOSP SVC FORM HHealthCareUnit
***********************************************************************
*/

/*
GET VENT RESULTS
*/
DECLARE @dtEndDate AS DATETIME;
DECLARE @dtStartDate AS DATETIME;
-- Table Variable declaration area  
--  
DECLARE @CensusVisitOIDs TABLE (
	VisitOID INT,
	PatientOID INT,
	PatientAccountID VARCHAR(20)
	)
-- Table to vent assessments  
DECLARE @VentAssessments TABLE (
	id_num INT IDENTITY(1, 1),
	AssessmentID INTEGER,
	CollectedDT DATETIME,
	PatientVisitOID INTEGER
	)
DECLARE @VentPatients TABLE (PatientVisit_oid INT)

SET @dtEndDate = getdate()
SET @dtStartDate = DATEADD(HOUR, - 12, @dtEndDate)

INSERT INTO @CensusVisitOIDs
SELECT DISTINCT HPatientVisit.ObjectID,
	HPatientVisit.Patient_OID,
	HPatientVisit.PatientAccountID
FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit HPatientVisit WITH (NOLOCK)
WHERE HPatientVisit.IsDeleted = 0
	AND HpatientVisit.VisitStatus IN (0, 4)

----------------------------------------------------------------------------------------  
-- Get all the assessments within the last 12 hours that contain  
-- A_BMH_VFMode NO LONGER A_02 Del Method and sort them by Collected Date.    
INSERT INTO @VentAssessments (
	AssessmentID,
	CollectedDT,
	PatientVisitOID
	)
SELECT ha.AssessmentID,
	ha.CollectedDT,
	cv.VisitOID
FROM [SC_server].[Soarian_Clin_Prd_1].DBO.hobservation ho WITH (NOLOCK)
INNER JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.hassessment ha WITH (NOLOCK) ON ho.assessmentid = ha.assessmentid
INNER JOIN @CensusVisitOIDs cv ON ha.PatientVisit_OID = cv.VisitOID
	AND ha.Patient_OID = cv.PatientOID -- Performance Improvement
WHERE HA.FormUsage IN ('Ventilator Flow Sheet')
	AND ha.AssessmentStatusCode IN (1, 3)
	AND ho.EndDT IS NULL
	AND ha.EndDt IS NULL
	AND CollectedDT BETWEEN @dtStartDate
		AND @dtEndDate
ORDER BY VisitOID,
	CollectedDT DESC

--Delete everything but the last assessment for each location, patient  
DELETE
FROM @VentAssessments
WHERE id_num NOT IN (
		SELECT MIN(id_num)
		FROM @VentAssessments
		GROUP BY PatientVisitOID
		)

INSERT INTO @VentPatients
SELECT DISTINCT va.PatientVisitOID
FROM [SC_server].[Soarian_Clin_Prd_1].DBO.hobservation ho WITH (NOLOCK)
INNER JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.hassessment ha WITH (NOLOCK) ON ho.assessmentid = ha.assessmentid
INNER JOIN @VentAssessments va ON ha.PatientVisit_OID = va.PatientVisitOID
	AND ha.AssessmentID = va.AssessmentID
WHERE FindingAbbr IN ('A_BMH_VFMode')
	AND value NOT IN ('Non invasive mode (BiPAP/CPAP)', 'CPAP')
	AND HA.FormUsage IN ('Ventilator Flow Sheet')
	AND ha.AssessmentStatusCode IN (1, 3)
	AND ho.EndDT IS NULL
	AND ha.EndDt IS NULL
	AND ha.CollectedDT BETWEEN @dtStartDate
		AND @dtEndDate

DECLARE @Vented TABLE (
	VisitOID INT,
	PatientOID INT,
	PatientAccountID INT,
	PatientVisit_OID INT,
	id_num INT,
	AssessmentID INT,
	CollectedDT DATETIME2,
	PatientVisitOID INT
	)

INSERT INTO @Vented
SELECT VisitOID,
	PatientOID,
	PatientAccountID,
	PatientVisit_oid,
	id_num,
	AssessmentID,
	CAST(CollectedDT AS DATETIME2) AS [CollectedDT],
	PatientVisitOID
FROM @VentPatients AS PTS
INNER JOIN @VentAssessments AS VAS ON PTS.PatientVisit_oid = VAS.PatientVisitOID
INNER JOIN @CensusVisitOIDs AS CEN ON PTS.PatientVisit_oid = CEN.VisitOID;

/*
Creat tables to get the Latest Covid Order for an encounter

First Get all Orders
Second Get latest order by PatientVisitOID, CreationTime DESC

*/
DECLARE @CovidOrders TABLE (
	id_num INT IDENTITY(1, 1),
	PatientVisitOID VARCHAR(50),
	OrderID INT,
	OrderAbbreviation VARCHAR(50),
	CreationTime DATETIME2,
	ObjectID INT -- links to HOrderOccurrence.Order_OID
	);

INSERT INTO @CovidOrders
SELECT PatientVisit_OID,
	Orderid,
	OrderAbbreviation,
	CreationTime,
	ObjectID
FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HORDER
WHERE OrderAbbreviation = '00425421'
	AND OrderStatusModifier NOT IN ('Cancelled', 'Discontinue', 'Invalid-DC Order')
ORDER BY PatientVisit_OID,
	CreationTime DESC;

--SELECT * FROM @CovidOrders WHERE PatientVisitOID = '2282294';
/*
Creat tables to get the Latest Covid Order Occurrence for an encounter

First Get all Order Occurrences
Second Get latest Result by PatientVisitOID, CreationTime DESC

*/
DECLARE @CovidOrderOcc TABLE (
	id_num INT,
	-- links to HOrder.ObjectID
	Order_OID INT,
	CreationTime DATETIME2,
	OrderOccurrenceStatus VARCHAR(500),
	StatusEnteredDatetime DATETIME2,
	ObjectID INT -- Links to HInvestigationResults.Occurence_OID
	)

INSERT INTO @CovidOrderOcc
SELECT [RN] = ROW_NUMBER() OVER (
		PARTITION BY A.Order_OID ORDER BY A.StatusEnteredDateTime DESC
		),
	A.Order_OID,
	A.CreationTime,
	A.OrderOccurrenceStatus,
	A.StatusEnteredDateTime,
	A.ObjectID
FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HOCCURRENCEORDER AS A
INNER JOIN @CovidOrders AS B ON A.ORDER_OID = B.ObjectID
	AND A.CreationTime = B.CreationTime
WHERE A.OrderOccurrenceStatus NOT IN ('DISCONTINUE', 'Cancel')
ORDER BY A.Order_OID,
	A.ObjectID;

-- de duplicate
DELETE
FROM @CovidOrderOcc
WHERE id_num != 1;

--SELECT * FROM @CovidOrderOcc
/*
Create table to get results to latest order occurrence
*/
DECLARE @CovidResults TABLE (
	id_num INT,
	-- Links to HOccurrence.ObjectID
	OccurrenceOID INT,
	FindingAbbreviation VARCHAR(10),
	ResultDateTime DATETIME2,
	ResultValue VARCHAR(500),
	PatientVisitOID INT
	)

INSERT INTO @CovidResults
SELECT [RN] = ROW_NUMBER() OVER (
		PARTITION BY PatientVisit_OID,
		Occurrence_OID ORDER BY ResultDateTime DESC
		),
	Occurrence_OID,
	FindingAbbreviation,
	ResultDateTime,
	REPLACE(REPLACE(ResultValue, CHAR(13), ' '), CHAR(10), ' ') AS [ResultValue],
	PatientVisit_OID
FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HInvestigationResult
WHERE FindingAbbreviation = '9782'
ORDER BY PatientVisit_OID,
	ResultDateTime DESC;

DELETE
FROM @CovidResults
WHERE id_num != 1;

/*
MISC REF TABLE
*/
DECLARE @CovidMiscRefResults TABLE (
	id_num INT IDENTITY(1, 1),
	OccurrenceOID INT -- links to HOccurrence.ObjectID
	,
	FindingAbbreviation VARCHAR(10),
	ResultDateTime DATETIME2,
	ResultValue VARCHAR(500),
	PatientVisitOID INT,
	OrderID INT,
	OrderAbbreviation VARCHAR(50),
	OrderDTime DATETIME2,
	ObjectID INT -- links to HOrderOccurrence.Order_OID
	,
	OrderOccurrenceStatus VARCHAR(100),
	StatusEnteredDateTime DATETIME2
	)

INSERT INTO @CovidMiscRefResults
SELECT F.Occurrence_OID,
	F.FindingAbbreviation,
	F.ResultDateTime,
	REPLACE(REPLACE(F.ResultValue, CHAR(13), ' '), CHAR(10), ' ') AS [ResultValue],
	F.PatientVisit_OID,
	D.Orderid,
	D.OrderAbbreviation,
	D.CreationTime,
	D.ObjectID,
	E.OrderOccurrenceStatus,
	E.StatusEnteredDateTime
FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HORDER AS D
INNER JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HOCCURRENCEORDER AS E ON D.OBJECTID = E.ORDER_OID
	AND D.CREATIONTIME = E.CREATIONTIME
	AND E.ORDEROCCURRENCESTATUS NOT IN ('DISCONTINUE', 'Cancel')
INNER JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HInvestigationResult AS F ON E.OBJECTID = F.OCCURRENCE_OID
WHERE F.RESULTVALUE LIKE '%COVID%' -- COVID MISC REF VALUE
	AND D.orderabbreviation = '00410001'
ORDER BY F.PatientVisit_OID,
	F.ResultDateTime DESC;

--SELECT * FROM @CovidMiscRefResults ORDER BY ResultDateTime
/*
Misc Ref Results Clean table smsdss.c_Covid_MiscRefRslt_tbl
*/
DECLARE @MiscRef TABLE (
	PatientVisitOID INT,
	PatientAccountID INT,
	Test_Date DATETIME2,
	Result VARCHAR(50)
	)

INSERT INTO @MiscRef
SELECT B.ObjectID,
	[Acct No],
	[Test date],
	[Result]
FROM smsdss.c_Covid_MiscRefRslt_tbl AS A
INNER JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit AS B ON A.[Acct No] = B.PatientAccountID;

/*
ED Table Information
*/
DECLARE @WellSoft TABLE (
	PatientVisitOID INT,
	Covid_Test_Outside_Hosp VARCHAR(50),
	Order_Status VARCHAR(250),
	Result VARCHAR(50),
	Account VARCHAR(50),
	MRN VARCHAR(10),
	PT_Name VARCHAR(100),
	PT_Age VARCHAR(3),
	TimeLeftED VARCHAR(100)
	);

INSERT INTO @WellSoft
SELECT B.ObjectID,
	a.covid_Tested_Outside_Hosp AS [Covid_Order],
	a.covid_Where_Tested AS [Order_Status],
	a.covid_Test_Results AS [Result],
	A.Account,
	A.MR#,
	A.Patient,
	ROUND(DATEDIFF(MONTH, A.AgeDOB, GETDATE()) / 12, 0) AS [PT_Age],
	A.TimeLeftED
FROM [SQL-WS\REPORTING].[WellSoft_Reporting].[dbo].[c_Wellsoft_Rpt_tbl] AS A
LEFT OUTER JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit AS B ON CAST(A.Account AS VARCHAR) = cast(B.PatientAccountID AS VARCHAR)
WHERE (
		A.COVID_TESTED_OUTSIDE_HOSP IS NOT NULL -- tested yes
		OR A.COVID_WHERE_TESTED IS NOT NULL
		OR A.COVID_TEST_RESULTS IS NOT NULL
		)
	AND A.COVID_TESTED_OUTSIDE_HOSP != '(((('
	AND A.Covid_Tested_Outside_Hosp = 'Yes'
	AND LEFT(A.Account, 1) = '1';

/*

*/
DECLARE @SCRTCensus TABLE (
	PatientVisitOID INT,
	Nurs_Sta VARCHAR(10),
	Bed VARCHAR(10),
	Account VARCHAR(50)
	);

INSERT INTO @SCRTCensus
SELECT A.ObjectID,
	A.PatientLocationName,
	A.LatestBedName,
	A.patientAccountId
--FROM smsdss.c_soarian_real_time_census_CDI_v AS A
FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit AS A
WHERE A.VisitEndDateTime IS NULL
	AND A.PatientLocationName <> ''
	AND A.IsDeleted = 0

/*
Positive Results and their subsequent visits
*/
DECLARE @POSRES TABLE (
	PatientOID INT,
	PatientVisitOID INT,
	VisitStartDateTime DATETIME2
	)

INSERT INTO @POSRES
SELECT A.Patient_OID,
	A.PatientVisit_OID,
	B.VisitStartDateTime AS [Adm_Date]
FROM smsdss.c_positive_covid_visits_tbl AS A
INNER JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit AS B ON A.PatientVisit_OID = B.OBJECTID;

DECLARE @Subsequent TABLE (PatientVisitOID INT)

INSERT INTO @Subsequent
SELECT PV.OBJECTID
FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit AS PV
WHERE PV.Patient_OID IN (
		SELECT DISTINCT ZZZ.PatientOID
		FROM @POSRES AS ZZZ
		WHERE PV.VisitStartDatetime > ZZZ.VisitStartDateTime
			AND VisitTypeCode IN ('IP-WARD', 'IP', 'EOP')
		);

/*
Positive External Results
*/
DECLARE @ExtPos TABLE (
	PatientVisitOID INT,
	PatientAccountID INT,
	Test_Date DATETIME2,
	Result VARCHAR(50)
	)

INSERT INTO @ExtPos
SELECT B.ObjectID,
	A.Acct#,
	A.[Test Date],
	A.[Status]
FROM smsdss.c_covid_external_positive_tbl AS A
INNER JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit AS B ON A.ACCT# = B.PatientAccountID

/*
Distinct PatientVisitOID
*/
DECLARE @PatientVisit TABLE (PatientVisitOID INT)

INSERT INTO @PatientVisit
SELECT DISTINCT A.PatientVisitOID
FROM (
	SELECT PatientVisitOID
	FROM @WellSoft
	
	UNION
	
	SELECT PatientVisitOID
	FROM @SCRTCensus
	
	UNION
	
	SELECT PatientVisitOID
	FROM @CovidResults
	
	UNION
	
	SELECT PatientVisitOID
	FROM @CovidOrders
	
	UNION
	
	SELECT PatientVisitOID
	FROM @CovidMiscRefResults
	
	UNION
	
	SELECT PatientVisitOID
	FROM @MiscRef
	
	UNION
	
	SELECT PatientVisitOID
	FROM @ExtPos
	
	UNION
	
	SELECT PatientVisitOID
	FROM @Subsequent
	) AS A

/*

HPatientVisit Data

*/
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
	PT_DOB DATETIME2
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
	B.pt_birth_date
FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit AS A
LEFT OUTER JOIN SMSMIR.HL7_PT AS B ON A.PATIENTACCOUNTID = B.pt_id
LEFT OUTER JOIN SMSDSS.RACE_CD_DIM_V AS RACECD ON B.pt_race = RACECD.src_race_cd
	AND RACECD.src_sys_id = '#PMSNTX0'
INNER JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HHealthCareUnit AS HCUNIT ON A.UnitContacted_OID = HCUNIT.objectid
WHERE A.ObjectID IN (
		SELECT PatientVisitOID
		FROM @PatientVisit
		)

/*
Height, Weight, Comorbidities and Admitted From Data all from the Admissions Assessment
*/
SELECT episode_no AS [PatientAccountID],
	obsv_cd_name,
	obsv_cd,
	perf_dtime,
	REPLACE(REPLACE(REPLACE(REPLACE(dsply_val, CHAR(43), ' '), CHAR(45), ' '), CHAR(13), ' '), CHAR(10), ' ') AS [Display_Value],
	form_usage,
	id_num = row_number() OVER (
		PARTITION BY episode_no,
		obsv_cd_name ORDER BY episode_no,
			perf_dtime DESC
		)
INTO #HWAC
FROM SMSMIR.obsv
WHERE obsv_cd IN ('ht', 'wt', 'A_Admit From', 'A_BMH_ListCoMorb')
	AND form_usage = 'Admission'
	AND LEN(EPISODE_NO) = 8
	AND episode_no IN (
		SELECT PatientAccountID
		FROM @PatientVisitData
		)
ORDER BY episode_no,
	perf_dtime DESC;

--Delete everything but the last assessment for each location, patient  
DELETE
FROM #HWAC
WHERE id_num != '1'

SELECT PVT.PatientAccountID,
	PVT.[A_Admit From],
	PVT.Ht,
	PVT.Wt,
	PVT.A_BMH_ListCoMorb,
	PVT.perf_dtime,
	PVT.form_usage
INTO #HWACPivot_Tbl
FROM (
	SELECT PatientAccountID,
		Display_Value,
		obsv_cd,
		perf_dtime,
		form_usage
	FROM #HWAC
	) AS A
PIVOT(MAX(Display_Value) FOR obsv_cd IN ([A_Admit From], [Ht], [A_BMH_ListCoMorb], [Wt])) AS PVT

/*

Labs - Cholesterol, Triglycerides, HDL, LDL

*/
SELECT CASE 
		WHEN FindingAbbreviation = '00400796'
			THEN 'CHOL'
		WHEN FindingAbbreviation = '3100'
			THEN 'TRIG'
		WHEN FindingAbbreviation = '3235'
			THEN 'HDL'
		WHEN FindingAbbreviation = '3240'
			THEN 'LDL'
		WHEN FindingAbbreviation = '00411769'
			THEN 'A1C'
		ELSE FindingAbbreviation
		END AS [Test_Name],
	FindingAbbreviation,
	PatientVisit_OID,
	ResultDateTime,
	REPLACE(REPLACE(ResultValue, CHAR(13), ' '), CHAR(10), ' ') AS [ResultValue],
	id_num = ROW_NUMBER() OVER (
		PARTITION BY PatientVisit_OID,
		FindingAbbreviation ORDER BY PatientVisit_OID,
			ResultDateTime DESC
		)
INTO #Labs
FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HInvestigationResult
WHERE FindingAbbreviation IN ('00400796', '3100', '3235', '3240', '00411769')
	AND PatientVisit_OID IN (
		SELECT PatientVisitOID
		FROM @PatientVisitData
		);

DELETE
FROM #Labs
WHERE id_num != '1';

SELECT PVT.PatientVisit_OID,
	PVT.[00411769] AS [A1c],
	PVT.[3100] AS [Trig],
	PVT.[3235] AS [HDL],
	PVT.[3240] AS [LDL],
	PVT.[00400796] AS [Chol]
INTO #LabsPivot_Tbl
FROM (
	SELECT PatientVisit_OID,
		FindingAbbreviation,
		ResultValue
	FROM #Labs
	) AS A
PIVOT(MAX(ResultValue) FOR FindingAbbreviation IN ([00400796], [3100], [3235], [3240], [00411769])) AS PVT;

/*

Pull it all together

*/
SELECT PVD.MRN,
	PVD.PatientAccountID,
	PVD.PatientVisitOID,
	PVD.Pt_Name,
	PVD.Pt_Age,
	PVD.Pt_Gender,
	PVD.Race_Cd_Desc,
	PVD.Adm_Dtime,
	PVD.DC_DTime,
	CASE 
		WHEN PVD.DC_DTime IS NULL
			--AND (LEFT(pvd.patientAccountID,1) = '1'  OR PVD.hosp_svc = 'OBV')
			THEN RT.Nurs_Sta
		ELSE ''
		END AS [Nurs_Sta],
	CASE 
		WHEN PVD.DC_DTime IS NULL
			--AND (LEFT(pvd.patientAccountID,1) = '1'  OR PVD.hosp_svc = 'OBV')
			THEN RT.Bed
		ELSE ''
		END AS [Bed],
	CASE 
		WHEN PVD.DC_DTime IS NULL
			AND RT.bed IS NOT NULL
			--AND PVD.Hosp_Svc <> 'D23'
			--AND (LEFT(pvd.patientAccountID,1) = '1'  OR PVD.hosp_svc = 'OBV' or pvd.hosp_svc = 'EOR')
			THEN 1
		ELSE 0
		END AS [In_House],
	PVD.Hosp_Svc,
	PVD.Pt_Accomodation,
	PVD.PatientReasonforSeekingHC,
	COALESCE(CAST(CVORD.OrderID AS VARCHAR), CAST(MREF.OrderID AS VARCHAR), WS.Covid_Test_Outside_Hosp) AS [Order_No],
	CASE 
		WHEN COALESCE(CAST(CVORD.OrderAbbreviation AS VARCHAR), CAST(MREF.OrderAbbreviation AS VARCHAR), WS.Covid_Test_Outside_Hosp) = 'Yes'
			THEN 'EXTERNAL'
		WHEN EXTPOS.Result IS NOT NULL
			THEN 'EXTERNAL'
		WHEN COALESCE(CAST(CVORD.OrderAbbreviation AS VARCHAR), CAST(MREF.OrderAbbreviation AS VARCHAR), WS.Covid_Test_Outside_Hosp) IS NULL
			THEN 'NO ORDER FOUND'
		ELSE COALESCE(CAST(CVORD.OrderAbbreviation AS VARCHAR), CAST(MREF.OrderAbbreviation AS VARCHAR), WS.Covid_Test_Outside_Hosp)
		END AS [Covid_Order],
	COALESCE(CVORD.CreationTime, MREF.OrderDTime) AS [Order_DTime],
	COALESCE(CVOCC.OrderOccurrenceStatus, MREF.OrderOccurrenceStatus, WS.Order_Status) AS [Order_Status],
	COALESCE(CVOCC.StatusEnteredDatetime, MREF.StatusEnteredDateTime) AS [Order_Status_DTime],
	CASE 
		WHEN EXTPOS.Test_Date IS NOT NULL
			THEN EXTPOS.Test_Date
		WHEN MISCREF.Test_Date IS NOT NULL
			THEN MISCREF.Test_Date
		ELSE COALESCE(CVRES.ResultDateTime, MREF.ResultDateTime)
		END AS [Result_DTime],
	CASE 
		WHEN EXTPOS.Result IS NOT NULL
			THEN EXTPOS.Result
		WHEN MISCREF.Result IS NOT NULL
			THEN MISCREF.Result
		ELSE COALESCE(CVRES.ResultValue, MREF.ResultValue, WS.Result)
		END AS [Result],
	PVD.DC_Disp,
	PVD.Mortality_Flag,
	CASE 
		WHEN VENT.PatientVisitOID IS NULL
			THEN ''
		ELSE 'Vented'
		END AS [Vented],
	CASE 
		WHEN VENT.PatientVisitOID IS NULL
			THEN 0
		ELSE 1
		END AS [Vent_Flag],
	VENT.CollectedDT AS [Last_Vent_Check],
	[Subseqent_Visit_Flag] = CASE 
		WHEN SUB.PatientVisitOID IS NOT NULL
			THEN 1
		ELSE 0
		END,
	[Order_Flag] = CASE 
		WHEN COALESCE(CAST(CVORD.OrderID AS VARCHAR), CAST(MREF.OrderID AS VARCHAR), WS.Covid_Test_Outside_Hosp) IS NULL
			THEN 0
		ELSE 1
		END,
	[Result_Flag] = CASE 
		WHEN EXTPOS.Result IS NOT NULL
			THEN 1
		WHEN MISCREF.Result IS NOT NULL
			THEN 1
		WHEN CVRES.ResultValue IS NOT NULL
			THEN 1
		WHEN MREF.ResultValue IS NOT NULL
			THEN 1
		WHEN WS.Result IS NOT NULL
			THEN 1
		ELSE 0
		END,
	PVD.PT_Street_Address,
	PVD.PT_City,
	PVD.PT_State,
	PVD.PT_Zip_CD,
	HWACPvt.[A_Admit From] AS [PT_Admitted_From],
	HWACPvt.A_BMH_ListCoMorb AS [PT_Comorbidities],
	HWACPvt.Ht AS [PT_Height],
	HWACPvt.Wt AS [PT_Weight],
	LABSPvt.A1c,
	LABSPvt.Chol,
	LABSPvt.HDL,
	LABSPvt.LDL,
	LABSPvt.Trig,
	pvd.PT_DOB
INTO #TEMPA
FROM @PatientVisitData AS PVD
LEFT OUTER JOIN @SCRTCensus AS RT ON PVD.PatientVisitOID = RT.PatientVisitOID
LEFT OUTER JOIN @CovidOrders AS CVORD ON PVD.PatientVisitOID = cvord.PatientVisitOID
LEFT OUTER JOIN @CovidOrderOcc AS CVOCC ON CVOCC.Order_OID = CVORD.ObjectID
LEFT OUTER JOIN @CovidResults AS CVRES ON CVOCC.ObjectID = CVRES.OccurrenceOID
--AND PVD.PatientVisitOID = CVRES.PatientVisitOID
LEFT OUTER JOIN @CovidMiscRefResults AS MREF ON PVD.PatientVisitOID = MREF.PatientVisitOID
LEFT OUTER JOIN @MiscRef AS MISCREF ON PVD.PatientVisitOID = MISCREF.PatientVisitOID
LEFT OUTER JOIN @ExtPos AS EXTPOS ON PVD.PatientVisitOID = EXTPOS.PatientVisitOID
LEFT OUTER JOIN @WellSoft AS WS ON PVD.PatientAccountID = WS.Account
LEFT OUTER JOIN @Vented AS VENT ON PVD.PatientVisitOID = VENT.PatientVisitOID
-- SUBSEQUENT VISIT FLAG
LEFT OUTER JOIN @Subsequent AS SUB ON PVD.PatientVisitOID = SUB.PatientVisitOID
-- Comorbidities, Admitted From, Height, Weight
LEFT OUTER JOIN #HWACPivot_Tbl AS HWACPvt ON PVD.PatientAccountID = HWACPvt.PatientAccountID
-- Labs
LEFT OUTER JOIN #LabsPivot_Tbl AS LabsPvt ON PVD.PatientVisitOID = LabsPvt.PatientVisit_OID
WHERE PVD.MRN IS NOT NULL
ORDER BY PVD.Pt_Name,
	CVRES.ResultDateTime DESC,
	CVORD.CreationTime DESC;

SELECT A.MRN,
	A.PatientAccountID AS [PTNO_NUM],
	A.Pt_Name,
	A.Pt_Age,
	A.Pt_Gender,
	A.Race_Cd_Desc,
	A.Adm_Dtime,
	A.DC_DTime,
	A.Nurs_Sta,
	A.Bed,
	A.In_House,
	A.Hosp_Svc,
	A.Pt_Accomodation,
	A.PatientReasonforSeekingHC,
	A.Mortality_Flag,
	[Pos_MRN] = CASE 
		WHEN A.MRN IN (
				SELECT DISTINCT MRN
				FROM SMSDSS.c_positive_covid_visits_tbl
				)
			THEN '1'
		WHEN A.Result LIKE 'DETECTED%'
			THEN '1'
		WHEN A.Result LIKE 'DETECE%'
			THEN '1'
		WHEN A.Result LIKE 'POSITIV%'
			THEN '1'
		WHEN A.Result LIKE 'PRESUMP% POSITIVE%'
			THEN '1'
		ELSE '0'
		END,
		[Pt_ADT] = CASE
		WHEN A.Mortality_Flag = '1'
		AND ROW_NUMBER() OVER (
				PARTITION BY A.PatientAccountID ORDER BY A.RESULT_DTIME DESC,
					A.ORDER_DTIME DESC
				) = 1
			THEN 'Expired'

		WHEN (
			LEFT(A.PatientAccountID, 1) = '1'
			OR A.Hosp_Svc IN ('OBV')
		)
		AND A.DC_DTime IS NULL
		AND ROW_NUMBER() OVER (
				PARTITION BY A.PatientAccountID ORDER BY A.RESULT_DTIME DESC,
					A.ORDER_DTIME DESC
				) = 1
			THEN 'Admitted'

		WHEN (
			LEFT(A.PatientAccountID, 1) = '1'
			OR A.Hosp_Svc IN ('OBV')
		)
		AND A.DC_DTime IS NOT NULL
		AND ROW_NUMBER() OVER (
				PARTITION BY A.PatientAccountID ORDER BY A.RESULT_DTIME DESC,
					A.ORDER_DTIME DESC
				) = 1
			THEN 'Discharged'

		WHEN LEFT(A.PatientAccountID, 1) = '8'
		AND ROW_NUMBER() OVER (
				PARTITION BY A.PatientAccountID ORDER BY A.RESULT_DTIME DESC,
					A.ORDER_DTIME DESC
				) = 1
			THEN 'ED Only'
		WHEN ROW_NUMBER() OVER (
				PARTITION BY A.PatientAccountID ORDER BY A.RESULT_DTIME DESC,
					A.ORDER_DTIME DESC
				) = 1
		THEN 'Outpatient'

		ELSE 'z - Old Order'
	END,
	[pt_last_test_positive] = CASE 
		WHEN LAST_RES.Result_DTime = (
				SELECT MAX(ZZZ.Result_DTime)
				FROM #TEMPA AS ZZZ
				WHERE ZZZ.MRN = LAST_RES.MRN
				GROUP BY ZZZ.MRN
				)
			THEN 1
		ELSE 0
		END,
	[Last_Positive_Result_DTime] = LAST_RES.Result_DTime,
	[RESULT_CLEAN] = CASE 
		WHEN A.RESULT LIKE 'DETECTED%'
			THEN 'DETECTED'
		WHEN A.RESULT LIKE 'DETECE%'
			THEN 'DETECTED'
		WHEN A.RESULT LIKE 'POSITIV%'
			THEN 'DETECTED'
		WHEN A.RESULT LIKE 'PRESUMP% POSITIVE%'
			THEN 'DETECTED'
		WHEN A.RESULT LIKE '%NOT DETECTED%'
			THEN 'NOT-DETECTED'
		WHEN A.Result LIKE '%NEGATIVE%'
			THEN 'NOT-DETECTED'
		WHEN A.RESULT IS NULL
			THEN 'NO-RESULT'
		ELSE REPLACE(REPLACE(A.RESULT, CHAR(13), ' '), CHAR(10), ' ')
		END,
	[Distinct_Visit_Flag] = CASE 
		WHEN ROW_NUMBER() OVER (
				PARTITION BY A.PatientAccountID ORDER BY A.RESULT_DTIME DESC,
					A.ORDER_DTIME DESC
				) = 1
			THEN 1
		ELSE 0
		END,
	A.Vented,
	A.Last_Vent_Check,
	'''' + CAST(A.Order_NO AS VARCHAR) + '''' AS [Order_NO],
	'''' + CAST(A.Covid_Order AS VARCHAR) + '''' AS [Covid_Order],
	A.Order_DTime,
	A.Order_Status,
	A.Order_Status_DTime,
	A.Result_DTime,
	A.Result,
	A.DC_Disp,
	A.Vent_Flag,
	A.Subseqent_Visit_Flag,
	A.Order_Flag,
	A.Result_Flag,
	A.PT_Street_Address,
	A.PT_City,
	A.PT_State,
	A.PT_Zip_CD,
	A.PT_Height,
	A.PT_Weight,
	A.PT_Comorbidities,
	A.PT_Admitted_From,
	A.Chol,
	A.HDL,
	A.LDL,
	A.Trig,
	A.A1c,
	PTOcc.user_data_text AS [Occupation],
	A.PT_DOB,
	[State_Age_Group] = CASE
		WHEN A.Pt_Age < 1 
			THEN 'a - <1'
		WHEN A.Pt_Age <= 4
			THEN 'b - 1-4'
		WHEN A.Pt_Age <= 19
			THEN 'c - >4-19'
		WHEN A.Pt_Age <= 44
			THEN 'd - >19-44'
		WHEN A.Pt_Age <= 54
			THEN 'e - >44-54'
		WHEN A.Pt_Age <= 64
			THEN 'f - >54-64'
		WHEN A.Pt_Age <= 74
			THEN 'g - >64-74'
		WHEN A.PT_AGE <= 84
			THEN 'h - >74-84'
		WHEN A.PT_AGE > 84
			THEN 'i - >84'
	END,
	
	[first_positive_flag_dtime] = CASE
		WHEN FIRST_RES.Result_DTime = (
			SELECT MIN(ZZZ.RESULT_DTIME)
			FROM #TEMPA AS ZZZ
			WHERE ZZZ.MRN = FIRST_RES.MRN
			GROUP BY ZZZ.MRN
			)
			THEN FIRST_RES.Result_DTime
		ELSE NULL
		END

FROM #TEMPA AS A
-- occupation
LEFT OUTER JOIN SMSMIR.pms_user_episo AS PTOcc
ON CAST(A.PatientAccountID AS VARCHAR) = CAST(PTOcc.episode_no AS VARCHAR)
AND PTOcc.user_data_cd = '2PTEMP01'

OUTER APPLY (
	SELECT TOP 1 B.MRN,
	B.PatientAccountID, 
	B.RESULT,
	B.RESULT_DTIME
	FROM #TEMPA AS B
	WHERE (
			B.RESULT LIKE 'DETECTED%'
			OR B.RESULT LIKE 'DETECE%'
			OR B.RESULT LIKE 'POSITIV%'
			OR B.RESULT LIKE 'PRESUMP% POSITIVE%'
		)
	AND A.MRN = B.MRN
	ORDER BY B.Result_DTime DESC,
	B.Order_DTime DESC
) AS LAST_RES

OUTER APPLY (
	SELECT TOP 1 B.MRN,
	B.PatientAccountID, 
	B.RESULT,
	B.RESULT_DTIME
	FROM #TEMPA AS B
	WHERE (
			B.RESULT LIKE 'DETECTED%'
			OR B.RESULT LIKE 'DETECE%'
			OR B.RESULT LIKE 'POSITIV%'
			OR B.RESULT LIKE 'PRESUMP% POSITIVE%'
		)
	AND A.MRN = B.MRN
	ORDER BY B.Result_DTime ASC,
	B.Order_DTime ASC
) AS FIRST_RES

WHERE A.PatientAccountID NOT IN ('14465701', '14244479', '14862411', '88998935')
	AND (
		-- Capture all subsequent visits of previously positive patients
		A.Subseqent_Visit_Flag = '1'
		OR (
			-- capture all patients with orders and with a result
			A.Order_Flag = '1'
			AND A.Result_Flag = '1'
			)
		-- capture all patients who had a result but maybe no order
		OR A.Result_Flag = '1'
		-- captrue all currently in house patients
		OR A.In_House = '1'
		)
ORDER BY A.Pt_Name,
	A.Result_DTime DESC,
	A.Order_DTime DESC;

DROP TABLE #TEMPA,
	#HWAC,
	#HWACPivot_Tbl,
	#Labs,
	#LabsPivot_Tbl;
