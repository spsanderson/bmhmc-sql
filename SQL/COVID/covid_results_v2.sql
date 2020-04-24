/*
Creat tables to get the Latest Covid Order for an encounter

First Get all Orders
Second Get latest order by PatientVisitOID, CreationTime DESC

*/
DECLARE @CovidOrders TABLE (
	id_num INT IDENTITY(1, 1)
	, PatientVisitOID VARCHAR(50)
	, OrderID INT
	, OrderAbbreviation VARCHAR(50)
	, CreationTime DATETIME2
	, ObjectID INT -- links to HOrderOccurrence.Order_OID
);

INSERT INTO @CovidOrders
SELECT PatientVisit_OID
, Orderid
, OrderAbbreviation
, CreationTime
, ObjectID
FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HORDER 
WHERE OrderAbbreviation = '00425421'
ORDER BY PatientVisit_OID
, CreationTime DESC;

--SELECT * FROM @CovidOrders;

/*
Creat tables to get the Latest Covid Order Occurrence for an encounter

First Get all Order Occurrences
Second Get latest Result by PatientVisitOID, CreationTime DESC

*/

DECLARE @CovidOrderOcc TABLE (
	id_num INT IDENTITY(1, 1)
	, Order_OID INT -- links to HOrder.ObjectID
	, CreationTime DATETIME2
	, OrderOccurrenceStatus VARCHAR(500)
	, StatusEnteredDatetime DATETIME2
	, ObjectID INT -- Links to HInvestigationResults.Occurence_OID
)

INSERT INTO @CovidOrderOcc
SELECT A.Order_OID
, A.CreationTime
, A.OrderOccurrenceStatus
, A.StatusEnteredDateTime 
, A.ObjectID

FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HOCCURRENCEORDER AS A
INNER JOIN @CovidOrders AS B
ON A.ORDER_OID = B.ObjectID
AND A.CreationTime = B.CreationTime

WHERE A.OrderOccurrenceStatus NOT IN ('DISCONTINUE', 'Cancel');

-- de duplicate
DELETE
FROM @CovidOrderOcc
WHERE id_num NOT IN (
		SELECT MIN(id_num)
		FROM @CovidOrderOcc
		GROUP BY Order_OID
		)

--SELECT * FROM @CovidOrderOcc

/*
Create table to get results to latest order occurrence
*/

DECLARE @CovidResults TABLE (
	id_num INT IDENTITY(1, 1)
	, OccurrenceOID INT -- links to HOccurrence.ObjectID
	, FindingAbbreviation VARCHAR(10)
	, ResultDateTime DATETIME2
	, ResultValue VARCHAR(500)
	, PatientVisitOID INT
)

INSERT INTO @CovidResults
SELECT Occurrence_OID
, FindingAbbreviation
, ResultDateTime
, REPLACE(REPLACE(ResultValue, CHAR(13), ' '), CHAR(10), ' ') AS [ResultValue]
, PatientVisit_OID
FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HInvestigationResult
WHERE FindingAbbreviation = '9782'
ORDER BY  PatientVisit_OID
, ResultDateTime DESC;

DELETE
FROM @CovidResults
WHERE id_num NOT IN (
		SELECT MIN(id_num)
		FROM @CovidResults
		GROUP BY PatientVisitOID, OccurrenceOID
		)

/*
MISC REF TABLE
*/
DECLARE @CovidMiscRefResults TABLE (
	id_num INT IDENTITY(1, 1)
	, OccurrenceOID INT -- links to HOccurrence.ObjectID
	, FindingAbbreviation VARCHAR(10)
	, ResultDateTime DATETIME2
	, ResultValue VARCHAR(500)
	, PatientVisitOID INT
)

INSERT INTO @CovidMiscRefResults
SELECT F.Occurrence_OID
, F.FindingAbbreviation
, F.ResultDateTime
, REPLACE(REPLACE(F.ResultValue, CHAR(13), ' '), CHAR(10), ' ') AS [ResultValue]
, F.PatientVisit_OID
FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HORDER AS D
INNER JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HOCCURRENCEORDER AS E ON D.OBJECTID = E.ORDER_OID
	AND D.CREATIONTIME = E.CREATIONTIME
	AND E.ORDEROCCURRENCESTATUS NOT IN ('DISCONTINUE', 'Cancel')
INNER JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HInvestigationResult AS F ON E.OBJECTID = F.OCCURRENCE_OID

WHERE F.RESULTVALUE LIKE '%COVID%' -- COVID MISC REF VALUE
AND D.orderabbreviation = '00410001'

ORDER BY  F.PatientVisit_OID
, F.ResultDateTime DESC;

/*
ED Table Information
*/
DECLARE @WellSoft TABLE (
	PatientVisitOID INT
	, Covid_Test_Outside_Hosp VARCHAR(50)
	, Order_Status VARCHAR(250)
	, Result VARCHAR(50)
	, Account VARCHAR(50)
);

INSERT INTO @WellSoft
SELECT B.ObjectID
, a.covid_Tested_Outside_Hosp AS [Covid_Order]
, a.covid_Where_Tested AS [Order_Status]
, a.covid_Test_Results AS [Result]
, A.Account

FROM [SQL-WS\REPORTING].[WellSoft_Reporting].[dbo].[c_Wellsoft_Rpt_tbl] AS A
LEFT OUTER JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit AS B
ON CAST(A.Account as varchar) = cast(B.PatientAccountID as varchar)
WHERE (
		A.COVID_TESTED_OUTSIDE_HOSP IS NOT NULL -- tested yes
		OR A.COVID_WHERE_TESTED IS NOT NULL
		OR A.COVID_TEST_RESULTS IS NOT NULL
		)
	AND A.COVID_TESTED_OUTSIDE_HOSP != '(((('
	AND A.Covid_Tested_Outside_Hosp = 'Yes';

/*

*/

DECLARE @SCRTCensus TABLE (
	PatientVisitOID INT
	, Nurs_Sta VARCHAR(10)
	, Bed VARCHAR(10)
	, Account VARCHAR(50)
);

INSERT INTO @SCRTCensus
SELECT B.ObjectID
, A.nurse_sta
, A.bed
, A.pt_no_num
FROM smsdss.c_soarian_real_time_census_CDI_v AS A
LEFT OUTER JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit AS B
ON A.pt_no_num = B.PatientAccountID

/*
Positive Results and their subsequent visits
*/
DECLARE @POSRES TABLE(
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

DECLARE @Subsequent TABLE (
	PatientVisitOID INT
)
INSERT INTO @Subsequent
SELECT PV.OBJECTID
FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit AS PV
WHERE PV.Patient_OID IN (
		SELECT DISTINCT ZZZ.PatientOID
		FROM @POSRES AS ZZZ
		WHERE PV.VisitStartDatetime > ZZZ.VisitStartDateTime
		AND VisitTypeCode IN ('IP-WARD','IP','EOP')
	);


/*
Distinct PatientVisitOID
*/
DECLARE @PatientVisit TABLE (
	PatientVisitOID INT
)
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
	FROM @Subsequent
) AS A

/*

HPatientVisit Data

*/
DECLARE @PatientVisitData TABLE (
	MRN INT
	, PatientAccountID INT
	, Pt_Name VARCHAR(250)
	, Pt_Age INT
	, Pt_Gender VARCHAR(5)
	, Race_Cd_Desc VARCHAR(100)
	, Adm_Dtime DATETIME2
	, Pt_Acconodation VARCHAR(50)
	, PatientReasonforSeekingHC VARCHAR(MAX)
	, DC_DTime DATETIME2
	, DS_Disp VARCHAR(MAX)
	, Mortality_Flag CHAR(1)
	, PatientVisitOID INT
);

INSERT INTO @PatientVisitData
SELECT B.pt_med_rec_no AS [MRN],
	A.PATIENTACCOUNTID AS [PTNO_NUM],
	CAST(B.PT_LAST_NAME AS VARCHAR) + ', ' + CAST(B.PT_FIRST_NAME AS VARCHAR) AS [PT_NAME],
	ROUND((DATEDIFF(MONTH, B.pt_birth_date, A.VisitStartDateTime) / 12), 0) AS [PT_AGE],
	B.pt_gender,
	SUBSTRING(RACECD.RACE_CD_DESC, 1, CHARINDEX(' ', RACECD.RACE_CD_DESC, 1)) AS RACE_CD_DESC,
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
	A.ObjectID
FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit AS A
LEFT OUTER JOIN SMSMIR.HL7_PT AS B ON A.PATIENTACCOUNTID = B.pt_id
LEFT OUTER JOIN SMSDSS.RACE_CD_DIM_V AS RACECD ON B.pt_race = RACECD.src_race_cd
	AND RACECD.src_sys_id = '#PMSNTX0'
WHERE A.ObjectID IN (
	SELECT PatientVisitOID
	FROM @PatientVisit
)

/*

Pull it all together

*/

SELECT PVD.MRN
, PVD.PatientAccountID
, PVD.Pt_Name
, PVD.Pt_Age
, PVD.Race_Cd_Desc
, PVD.Adm_Dtime
, PVD.DC_DTime
, 'cvord'
, CVORD.*
, 'CVOCC'
, CVOCC.*
, 'cvres'
, CVRES.*

FROM @PatientVisitData AS PVD
LEFT OUTER JOIN @CovidOrders AS CVORD
ON PVD.PatientVisitOID = cvord.PatientVisitOID
LEFT OUTER JOIN @CovidOrderOcc AS CVOCC
ON CVOCC.Order_OID = CVORD.ObjectID
LEFT OUTER JOIN @CovidResults AS CVRES
ON PVD.PatientVisitOID = CVRES.PatientVisitOID
AND CVOCC.ObjectID = CVRES.OccurrenceOID
--LEFT OUTER JOIN @CovidMiscRefResults AS MREF

ORDER BY PVD.Pt_Name,
CVRES.ResultDateTime DESC,
CVORD.CreationTime DESC;
