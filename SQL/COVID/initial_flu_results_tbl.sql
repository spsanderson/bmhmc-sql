DECLARE @START_DATE DATE;

SET @START_DATE = '2020-09-01';

-- GET ORER RESULTS
DECLARE @FluResults TABLE (
	id_num INT,
	-- Links to HOccurrence.ObjectID
	OccurrenceOID INT,
	FindingAbbreviation VARCHAR(10),
	ResultDateTime DATETIME2,
	ResultValue VARCHAR(500),
	PatientVisitOID INT
	--LastCngDtime SMALLDATETIME
	)

INSERT INTO @FluResults
SELECT [RN] = ROW_NUMBER() OVER (
		PARTITION BY PatientVisit_OID,
		Occurrence_OID,
		FindingAbbreviation ORDER BY ResultDateTime DESC
		),
	Occurrence_oid,
	FindingAbbreviation,
	ResultDateTime,
	REPLACE(REPLACE(ResultValue, CHAR(13), ' '), CHAR(10), ' ') AS [ResultValue],
	PatientVisit_OID
	--LastCngDtime
FROM smsmir.sc_InvestigationResult
WHERE FindingAbbreviation IN ('00424721', '00424739')
	AND ResultValue IS NOT NULL
	AND CreationTime >= @START_DATE
ORDER BY PatientVisit_oid,
	ResultDateTime DESC;

DELETE
FROM @FluResults
WHERE id_num != 1;

-- Pivot Records
SELECT PVT.PatientVisitOID
, PVT.ResultDateTime
--, PVT.LastCngDtime
, PVT.[00424721] AS [Flu_A]
, PVT.[00424739] AS [Flu_B]
, RN = ROW_NUMBER() OVER(PARTITION BY PVT.PatientVisitOID ORDER BY PVT.ResultDateTime)
INTO #TEMPA
FROM (
	SELECT PatientVisitOID
	, FindingAbbreviation
	, ResultValue
	, ResultDateTime
	--, LastCngDtime
	FROM @FluResults
) AS A
PIVOT(
	MAX(ResultValue)
	FOR FindingAbbreviation IN ("00424721","00424739")
) AS PVT
ORDER BY PVT.PatientVisitOID,
PVT.ResultDateTime
--, PVT.LastCngDtime DESC;

DELETE
FROM #TEMPA
WHERE RN != 1
;

SELECT PatientVisitOID
, ResultDateTime
--, LastCngDtime
, Flu_A
, Flu_B
INTO smsdss.c_covid_flu_results_tbl
FROM #TEMPA;

DROP TABLE #TEMPA