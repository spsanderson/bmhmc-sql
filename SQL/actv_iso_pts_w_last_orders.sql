/*
***********************************************************************
File: actv_iso_pts_w_last_orders.sql

Input Parameters:
	None

Tables/Views:
	[SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit
	[SC_server].[Soarian_Clin_Prd_1].DBO.HOrder

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get active isolation patients and the last active/discontinued order
	for PCO_Iso for that visit

Revision History:
Date		Version		Description
----		----		----
2020-09-30	v1			Initial Creation
2020-10-27	v2			Drop some columns per Shan J NPD
***********************************************************************
*/
DECLARE @IsolationPatients TABLE (
	alternatevisitid INT,
	patientaccountid INT,
	PatientVisitOID INT,
	patient_oid INT,
	PatientReasonForSeekingHC VARCHAR(255),
	PatientLocationName VARCHAR(255),
	Financialclass VARCHAR(255),
	LatestBedName VARCHAR(255),
	UnitContactedName VARCHAR(255),
	IsolationIndicator VARCHAR(255),
	AccommodationType VARCHAR(255),
	PatientStatusCode VARCHAR(255),
	VisitStartDatetime VARCHAR(255)
	)

INSERT INTO @IsolationPatients
SELECT alternatevisitid,
	patientaccountid,
	objectid AS [PatientVisitOID],
	patient_oid,
	PatientReasonForSeekingHC,
	PatientLocationName,
	Financialclass,
	LatestBedName,
	UnitContactedName,
	IsolationIndicator,
	AccommodationType,
	PatientStatusCode,
	VisitStartDatetime
FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit AS A
WHERE A.VisitEndDateTime IS NULL
	AND A.PatientLocationName <> ''
	AND A.IsDeleted = 0
	AND A.ISOLATIONINDICATOR != ''
	AND A.ISOLATIONINDICATOR IS NOT NULL;

DECLARE @ActiveIsolationOrdersTbl AS TABLE (
	Patient_OID INT,
	PatientVisit_OID INT,
	OrderDescAsWritten VARCHAR(500),
	OrderStatusModifier VARCHAR(500),
	EnteredDateTime DATETIME2,
	StartDateTime DATETIME2,
	CalculatedStopDateTime DATETIME2,
	StatusEnteredDateTime DATETIME2,
	ID_NUM INT
	)

INSERT INTO @ActiveIsolationOrdersTbl
SELECT Patient_oid,
	PatientVisit_oid,
	OrderDescAsWritten,
	OrderStatusModifier,
	EnteredDateTime,
	StartDateTime,
	CalculatedStopDateTime,
	StatusEnteredDateTime,
	id_num = ROW_NUMBER() OVER (
		PARTITION BY patientvisit_oid ORDER BY entereddatetime DESC
		)
FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HOrder
WHERE OrderAbbreviation = 'pco_iso'
	AND PatientVisit_OID IN (
		SELECT PatientVisitOID
		FROM @IsolationPatients
		)
	AND OrderStatusCode IN ('2', '3', '4');

DELETE
FROM @ActiveIsolationOrdersTbl
WHERE ID_NUM != 1;

DECLARE @DiscontinuedIsolationOrdersTbl AS TABLE (
	Patient_OID INT,
	PatientVisit_OID INT,
	OrderDescAsWritten VARCHAR(500),
	OrderStatusModifier VARCHAR(500),
	EnteredDateTime DATETIME2,
	StartDateTime DATETIME2,
	CalculatedStopDateTime DATETIME2,
	StatusEnteredDatetime DATETIME2,
	ID_NUM INT
	)

INSERT INTO @DiscontinuedIsolationOrdersTbl
SELECT Patient_oid,
	PatientVisit_oid,
	OrderDescAsWritten,
	OrderStatusModifier,
	EnteredDateTime,
	StartDateTime,
	CalculatedStopDateTime,
	StatusEnteredDateTime,
	id_num = ROW_NUMBER() OVER (
		PARTITION BY patientvisit_oid ORDER BY entereddatetime DESC
		)
FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HOrder
WHERE OrderAbbreviation = 'pco_iso'
	AND PatientVisit_OID IN (
		SELECT PatientVisitOID
		FROM @IsolationPatients
		)
	AND OrderStatusCode NOT IN ('2', '3', '4');

DELETE
FROM @DiscontinuedIsolationOrdersTbl
WHERE ID_NUM != 1;

--SELECT A.alternatevisitid
--, a.patient_oid
--, a.PatientVisitOID
SELECT a.patientaccountid,
	a.VisitStartDatetime,
	a.PatientReasonForSeekingHC,
	a.PatientLocationName,
	a.LatestBedName,
	--, a.Financialclass
	a.UnitContactedName,
	a.IsolationIndicator,
	--, a.AccommodationType
	--, a.PatientStatusCode
	CASE 
		WHEN B.OrderDescAsWritten IS NULL
			THEN 'NO ACTIVE ORDER'
		ELSE B.OrderDescAsWritten
		END AS [Latest_Active_Order_Desc],
	--, B.OrderStatusModifier AS [Latest_Active_Order_Status]
	--B.EnteredDateTime AS [Latest_Active_Order_EntryDTime],
	--B.StatusEnteredDateTime AS [Latest_Active_Order_Status_DTime],
	C.OrderDescAsWritten AS [Latest_NonActive_Order_Desc],
	--, C.OrderStatusModifier AS [Latest_NonActive_Order_Status]
	C.EnteredDateTime AS [Latest_NonActive_Order_ENTryDTime],
	C.StatusEnteredDatetime AS [Latest_NonActive_Order_Status_DTime]
FROM @IsolationPatients AS A
LEFT OUTER JOIN @ActiveIsolationOrdersTbl AS B ON A.PatientVisitOID = B.PatientVisit_OID
LEFT OUTER JOIN @DiscontinuedIsolationOrdersTbl AS C ON A.PatientVisitOID = C.PatientVisit_OID;
