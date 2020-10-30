DECLARE @START_DATE DATE;

SET @START_DATE = '2020-09-01';

-- INHOUSE PATIENTS FLU ORDERS
DECLARE @FluOrders TABLE (
	id_num INT IDENTITY(1, 1),
	PatientVisitOID VARCHAR(50),
	OrderID INT,
	OrderAbbreviation VARCHAR(50),
	CreationTime DATETIME2,
	ObjectID INT, -- links to HOrderOccurrence.Order_OID
	LastCngDtime SMALLDATETIME
	);

INSERT INTO @FluOrders
SELECT PatientVisit_oid,
	OrderId,
	OrderAbbreviation,
	CreationTime,
	ObjectID,
	LastCngDtime
FROM smsmir.sc_Order
WHERE OrderAbbreviation = '00424762'
	AND CreationTime >= @START_DATE
	AND OrderStatusModifier NOT IN ('Cancelled', 'Discontinue', 'Invalid-DC Order')
ORDER BY PatientVisit_oid,
	CreationTime DESC;

-- INHOUSE PATIENT FLU LATEST ORDER OCCURRENCE
-- ORDER OCCURRENCE
DECLARE @FluOrderOcc TABLE (
	id_num INT,
	-- links to HOrder.ObjectID
	Order_OID INT,
	CreationTime DATETIME2,
	OrderOccurrenceStatus VARCHAR(500),
	StatusEnteredDatetime DATETIME2,
	ObjectID INT, -- Links to HInvestigationResults.Occurence_OID
	LastCngDtime SMALLDATETIME
	)

INSERT INTO @FluOrderOcc
SELECT [RN] = ROW_NUMBER() OVER (
		PARTITION BY A.ORDER_OID ORDER BY A.STATUSENTEREDDATETIME DESC
		),
	A.Order_oid,
	A.CreationTime,
	A.OrderOccurrenceStatus,
	A.StatusEnteredDatetime,
	A.ObjectID,
	A.LastCngDtime
FROM smsmir.sc_OccurrenceOrder AS A
INNER JOIN @FluOrders AS B ON A.Order_oid = B.ObjectID
	AND A.CreationTime = B.CreationTime
WHERE A.OrderOccurrenceStatus NOT IN ('DISCONTINUE', 'CANCEL')
ORDER BY A.Order_oid,
	A.ObjectID;

-- DE-DUPE
DELETE
FROM @FluOrderOcc
WHERE id_num != 1;

-- GET ORER RESULTS
DECLARE @FluResults TABLE (
	id_num INT,
	-- Links to HOccurrence.ObjectID
	OccurrenceOID INT,
	FindingAbbreviation VARCHAR(10),
	ResultDateTime DATETIME2,
	ResultValue VARCHAR(500),
	PatientVisitOID INT,
	LastCngDtime SMALLDATETIME
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
	PatientVisit_OID,
	LastCngDtime
FROM smsmir.sc_InvestigationResult
WHERE FindingAbbreviation IN ('00424721', '00424739')
	AND ResultValue IS NOT NULL
	AND CreationTime >= @START_DATE
ORDER BY PatientVisit_oid,
	ResultDateTime DESC;

DELETE
FROM @FluResults
WHERE id_num != 1;

-- PULL TOGETHER
SELECT A.PatientVisitOID,
	A.OrderID,
	A.OrderAbbreviation,
	A.CreationTime AS [FluOrders_CreationTime],
	A.ObjectID AS [FluOrders_ObjectID],
	B.Order_OID,
	B.CreationTime AS [FluOrdersOccurrence_CreationTime],
	B.OrderOccurrenceStatus,
	B.StatusEnteredDatetime,
	B.ObjectID AS [FluOrdersOccurrence_ObjectID],
	C.OccurrenceOID,
	C.FindingAbbreviation,
	C.ResultDateTime,
	C.ResultValue,
	A.LastCngDtime
INTO #TEMPA
FROM @FluOrders AS A
LEFT OUTER JOIN @FluOrderOcc AS B ON A.ObjectID = B.Order_OID
LEFT OUTER JOIN @FluResults AS C ON B.ObjectID = C.OccurrenceOID
	AND A.PatientVisitOID = C.PatientVisitOID
WHERE C.ResultValue IS NOT NULL
ORDER BY A.PatientVisitOID,
	C.ResultDateTime DESC;

-- RECORD PIVOT
SELECT PVT.PatientVisitOID,
	PVT.OrderID,
	PVT.OrderAbbreviation,
	PVT.ResultDateTime,
	PVT.LastCngDtime,
	PVT.[00424721] AS [Flu_A],
	PVT.[00424739] AS [Flu_B]
INTO #TEMPB
FROM (
	SELECT PatientVisitOID,
		OrderID,
		OrderAbbreviation,
		FindingAbbreviation,
		ResultDateTime,
		LastCngDtime,
		ResultValue
	FROM #TEMPA
	) A
PIVOT(MAX(RESULTVALUE) FOR FINDINGABBREVIATION IN ("00424721", "00424739")) AS PVT;

SELECT A.PatientVisitOID,
	A.OrderID,
	A.OrderAbbreviation,
	A.ResultDateTime,
	A.LastCngDtime,
	A.Flu_A,
	A.Flu_B
INTO SMSDSS.c_covid_flu_results_tbl
FROM #TEMPB AS A

DROP TABLE #TEMPA;

DROP TABLE #TEMPB;
