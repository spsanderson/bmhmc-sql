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
                        state, and zip code, dob
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
SET @dtStartDate = @dtEndDate - 1

INSERT INTO @CensusVisitOIDs
SELECT DISTINCT HPatientVisit.ObjectID,
	HPatientVisit.Patient_OID,
	HPatientVisit.PatientAccountID
FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit HPatientVisit WITH (NOLOCK)
WHERE HPatientVisit.IsDeleted = 0
	AND HpatientVisit.VisitStatus IN (0, 4)

----------------------------------------------------------------------------------------  
-- Get all the assessments within the last 24 hours that contain  
-- A_BMH_VFSTART NO LONGER A_02 Del Method and sort them by Collected Date.    
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
WHERE FindingAbbr = 'A_BMH_VFSTART'
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
WHERE FindingAbbr = 'A_BMH_VFSTART'
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
ORDER BY PatientVisit_OID,
	CreationTime DESC;

--SELECT * FROM @CovidOrders WHERE PatientVisitOID = '2282294';
/*
Creat tables to get the Latest Covid Order Occurrence for an encounter

First Get all Order Occurrences
Second Get latest Result by PatientVisitOID, CreationTime DESC

*/
DECLARE @CovidOrderOcc TABLE (
	id_num INT IDENTITY(1, 1),
	Order_OID INT -- links to HOrder.ObjectID
	,
	CreationTime DATETIME2,
	OrderOccurrenceStatus VARCHAR(500),
	StatusEnteredDatetime DATETIME2,
	ObjectID INT -- Links to HInvestigationResults.Occurence_OID
	)

INSERT INTO @CovidOrderOcc
SELECT A.Order_OID,
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
WHERE id_num NOT IN (
		SELECT MAX(id_num)
		FROM @CovidOrderOcc
		GROUP BY Order_OID
		)

--SELECT * FROM @CovidOrderOcc
/*
Create table to get results to latest order occurrence
*/
DECLARE @CovidResults TABLE (
	id_num INT IDENTITY(1, 1),
	OccurrenceOID INT -- links to HOccurrence.ObjectID
	,
	FindingAbbreviation VARCHAR(10),
	ResultDateTime DATETIME2,
	ResultValue VARCHAR(500),
	PatientVisitOID INT
	)

INSERT INTO @CovidResults
SELECT Occurrence_OID,
	FindingAbbreviation,
	ResultDateTime,
	REPLACE(REPLACE(ResultValue, CHAR(13), ' '), CHAR(10), ' ') AS [ResultValue],
	PatientVisit_OID
FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HInvestigationResult
WHERE FindingAbbreviation = '9782'
ORDER BY PatientVisit_OID,
	ResultDateTime DESC;

--SELECT * FROM @CovidResults ORDER BY ResultDateTime
DELETE
FROM @CovidResults
WHERE id_num NOT IN (
		SELECT MAX(id_num)
		FROM @CovidResults
		GROUP BY PatientVisitOID,
			OccurrenceOID
		)

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
SELECT B.ObjectID,
	A.nurse_sta,
	A.bed,
	A.pt_no_num
FROM smsdss.c_soarian_real_time_census_CDI_v AS A
LEFT OUTER JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit AS B ON A.pt_no_num = B.PatientAccountID

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
	Nurs_Sta VARCHAR(10),
	Bed VARCHAR(10),
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
	A.PatientReasonforSeekingHC,
	A.VisitEndDateTime,
	A.DischargeDisposition,
	[Mortality_Flag] = CASE 
		WHEN LEFT(A.DischargeDisposition, 1) IN ('C', 'D')
			THEN 1
		ELSE 0
		END,
	A.ObjectID,
	vst.hosp_svc,
	vst.nurse_sta,
	vst.bed,
	B.pt_street_addr, 
	B.pt_city, 
	B.pt_state, 
	B.pt_zip_cd,
	B.pt_birth_date
	--EMP.UserDataText AS [PT_Occupation]
FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit AS A
LEFT OUTER JOIN SMSMIR.HL7_PT AS B ON A.PATIENTACCOUNTID = B.pt_id
LEFT OUTER JOIN SMSDSS.RACE_CD_DIM_V AS RACECD ON B.pt_race = RACECD.src_race_cd
	AND RACECD.src_sys_id = '#PMSNTX0'
LEFT OUTER JOIN SMSMIR.hl7_vst AS VST ON A.PatientAccountID = VST.pt_id
--LEFT OUTER JOIN SMSDSS.BMH_UserTwoFact_V AS EMP ON vst.pt_id = EMP.PtNo_Num
--	AND EMP.UserDataKey = '559'
WHERE A.ObjectID IN (
		SELECT PatientVisitOID
		FROM @PatientVisit
		)

/*
PATIENT COMORBIDITIES
*/
DECLARE @Comorbidities_Tbl TABLE (
	id_num INT IDENTITY(1,1),
	PatientAccountID INT,
	Obsv_CD_Name VARCHAR(MAX),
	Creation_DTime DATETIME2,
	Display_Value VARCHAR(MAX),
	Form_Usage VARCHAR(200)
)
INSERT INTO @Comorbidities_Tbl
SELECT episode_no
, obsv_cd_name
, perf_dtime
, dsply_val
, form_usage
FROM SMSMIR.obsv
WHERE obsv_cd = 'A_BMH_ListCoMorb'
AND form_usage = 'Admission'
AND episode_no IN (
	SELECT PatientAccountID
	FROM @PatientVisitData
)
AND LEN(EPISODE_NO) = 8
ORDER BY episode_no,
	perf_dtime DESC;

--Delete everything but the last assessment for each location, patient  
DELETE
FROM @Comorbidities_Tbl
WHERE id_num NOT IN (
		SELECT MIN(id_num)
		FROM @Comorbidities_Tbl
		GROUP BY PatientAccountID
		)

/*
Admitted from
*/
DECLARE @AdmitFrom_Tbl TABLE (
	id_num INT IDENTITY(1,1),
	PatientAccountID INT,
	Obsv_CD_Name VARCHAR(200),
	Creation_DTime DATETIME2,
	Display_Value VARCHAR(200),
	Form_Usage VARCHAR(200)
)
INSERT INTO @AdmitFrom_Tbl
SELECT episode_no
, obsv_cd_name
, perf_dtime
, dsply_val
, form_usage
FROM SMSMIR.obsv
WHERE obsv_cd = 'A_Admit From'
--AND episode_no = '14862205'
AND form_usage = 'Admission'
AND episode_no IN (
	SELECT PatientAccountID
	FROM @PatientVisitData
)
AND LEN(EPISODE_NO) = 8
ORDER BY episode_no,
	perf_dtime DESC;

--Delete everything but the last assessment for each location, patient  
DELETE
FROM @AdmitFrom_Tbl
WHERE id_num NOT IN (
		SELECT MIN(id_num)
		FROM @AdmitFrom_Tbl
		GROUP BY PatientAccountID
		)

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
			THEN COALESCE(RT.Nurs_Sta, PVD.NURS_STA)
		ELSE ''
		END AS [Nurs_Sta],
	CASE 
		WHEN PVD.DC_DTime IS NULL
			THEN COALESCE(RT.Bed, PVD.BED)
		ELSE ''
		END AS [Bed],
	CASE 
		WHEN PVD.DC_DTime IS NULL
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
	--PVD.PT_Occupation,
	--PTHeight.Height AS [PT_Height]
	--PTWeight.Display_Value AS [PT_Weight],
	PTCmorbidities.Display_Value AS [PT_Comorbidities],
	AdmitFrom.Display_Value AS [PT_Admitted_From],
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
-- Comorbidities, Admitted From
LEFT OUTER JOIN @Comorbidities_Tbl AS PTCmorbidities ON PVD.PatientAccountID = PTCmorbidities.PatientAccountID
LEFT OUTER JOIN @AdmitFrom_Tbl AS AdmitFrom ON PVD.PatientAccountID = AdmitFrom.PatientAccountID

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
	A.Order_No,
	A.Covid_Order,
	A.Order_DTime,
	A.Order_Status,
	A.Order_Status_DTime,
	A.Result_DTime,
	A.Result,
	A.DC_Disp,
	A.Mortality_Flag,
	[RESULT_CLEAN] = CASE 
		WHEN A.RESULT LIKE 'DETECTED%'
			THEN 'DETECTED'
		WHEN A.RESULT LIKE 'DETECE%'
			THEN 'DETECTED'
		WHEN A.RESULT LIKE 'POSITIV%'
			THEN 'DETECTED'
		WHEN A.RESULT LIKE 'PRESUMP% POSITIVE%'
			THEN 'DETECTED'
		WHEN A.RESULT LIKE 'NOT DETECTED%'
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
	A.Vent_Flag,
	A.Last_Vent_Check,
	A.Subseqent_Visit_Flag,
	A.Order_Flag,
	A.Result_Flag,
	A.PT_Street_Address,
	A.PT_City,
	A.PT_State,
	A.PT_Zip_CD,
	--A.PT_Occupation,
	--A.PT_Height
	--A.PT_Weight,
	A.PT_Comorbidities,
	A.PT_Admitted_From,
	PTOcc.user_data_text AS [Occupation],
	a.PT_DOB
FROM #TEMPA AS A
-- occupation
LEFT OUTER JOIN SMSMIR.pms_user_episo AS PTOcc
ON CAST(A.PatientAccountID AS VARCHAR) = CAST(PTOcc.episode_no AS VARCHAR)
AND PTOcc.user_data_cd = '2PTEMP01'
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

DROP TABLE #TEMPA;

