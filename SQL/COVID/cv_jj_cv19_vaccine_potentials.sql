/*
***********************************************************************
File: cv_jj_cv19_vaccine_potentials.sql

Input Parameters:
	None

Tables/Views:
	[smsdss].[c_covid_extract_tbl]
    [SC_server].[Soarian_Clin_Prd_1].dbo.HPatientVisit
    [SC_server].[Soarian_Clin_Prd_1].dbo.HOrder
    [SC_server].[Soarian_Clin_Prd_1].DBO.HOCCURRENCEORDER
    [SC_server].[Soarian_Clin_Prd_1].[dbo].[HMedAdministration]
    [SC_server].[Soarian_Clin_Prd_1].[dbo].[HMedDispOrderComponent]
	SMSMIR.MIR_PHM_DRUGMSTR

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get the patients that are eligible for the J&J CV-19 Vaccine

Revision History:
Date		Version		Description
----		----		----
2021-04-12	v1			Initial Creation
***********************************************************************
*/

DROP TABLE IF EXISTS #covid_pos_dtime

CREATE TABLE #covid_pos_dtime (
	ptno_num VARCHAR(12),
	last_positive_result_dtime DATETIME
	)

INSERT INTO #covid_pos_dtime (
	ptno_num,
	last_positive_result_dtime
	)
SELECT DISTINCT PTNO_NUM,
	MAX(Last_Positive_Result_DTime) AS Last_Positive_Result_DTime
FROM SMSDSS.c_covid_extract_tbl
WHERE Last_Positive_Result_DTime IS NOT NULL
GROUP BY PTNO_NUM
ORDER BY PTNO_NUM

DROP TABLE IF EXISTS #TEMP

SELECT DISTINCT PV.PATIENTACCOUNTID,
	PV.VISITSTARTDATETIME,
	PV.PATIENTLOCATIONNAME,
	PV.PATIENTREASONFORSEEKINGHC,
	PV.FINANCIALCLASS,
	PV.LATESTBEDNAME,
	HO.PatientVisit_OID,
	HO.OrderID,
	HO.OrderAbbreviation,
	HO.CreationTime AS [Order_Creation_DTime],
	--HO.ObjectID, -- links to HorderOccurrence.Order_OID
	HO.OrderDescAsWritten,
	HO.OrderStatusModifier,
	HO.OrderStatusModifierCode,
	--OCC.ORDER_OID,
	--OCC.CREATIONTIME,
	OCC.ORDEROCCURRENCESTATUS,
	OCC.STATUSENTEREDDATETIME,
	--OCC.OBJECTID,
	--OCC.LASTCNGDTIME,
	Z.last_positive_result_dtime,
	MDOC.GenericDrugName,
	PDM.CVXCd,
	MA.ActualDateTime,
	PDM.Ther1Mne,
	[Days_Since_Antibiotic] = CASE 
		WHEN LEFT(PDM.Ther1Mne, 5) = '08:12'
			THEN DATEDIFF(DAY, MA.ACTUALDATETIME, CAST(GETDATE() AS DATE))
		ELSE NULL
		END
INTO #TEMP
FROM [SC_server].[Soarian_Clin_Prd_1].dbo.HPatientVisit AS PV
INNER JOIN [SC_server].[Soarian_Clin_Prd_1].dbo.HOrder AS HO ON PV.OBJECTID = HO.PATIENTVISIT_OID
INNER JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HOCCURRENCEORDER AS OCC ON HO.OBJECTID = OCC.ORDER_OID
	AND OCC.ORDEROCCURRENCESTATUS NOT IN ('DISCONTINUE', 'CANCEL')
INNER JOIN [SC_server].[Soarian_Clin_Prd_1].[dbo].[HMedAdministration] AS MA ON PV.OBJECTID = MA.VISIT_OID
	AND MA.AdministrationStatus = '1'
INNER JOIN [SC_server].[Soarian_Clin_Prd_1].[dbo].[HMedDispOrderComponent] AS MDOC ON MA.MedDispOrder_oid = MDOC.MedDispOrder_oid
LEFT JOIN #covid_pos_dtime AS Z ON PV.PATIENTACCOUNTID = Z.ptno_num
INNER JOIN SMSMIR.MIR_PHM_DRUGMSTR AS PDM ON MDOC.GENERICDRUGNAME = PDM.GNRCNAME
WHERE HO.OrderAbbreviation = 'ADT09'
	AND PV.VISITENDDATETIME IS NULL
	AND PV.PATIENTLOCATIONNAME <> ''
	AND PV.ISDELETED = 0
	AND HO.OrderStatusModifierCode = '10'
	AND (
		DATEDIFF(day, Z.Last_Positive_Result_DTime, CAST(getdate() AS DATE)) > 10
		OR Z.last_positive_result_dtime IS NULL
		)
	AND (
		PDM.CvxCd IS NULL
		OR (
			PDM.CVXCd = 'YES'
			AND MA.ActualDateTime > CAST(GETDATE() - 14 AS DATE)
			OR MA.ActualDateTime IS NULL
			)
		)
ORDER BY PV.PATIENTACCOUNTID,
	MDOC.GenericDrugName,
	MA.ACTUALDATETIME;

DROP TABLE IF EXISTS #ANTIBIOTICS

SELECT DISTINCT PatientAccountID
INTO #ANTIBIOTICS
FROM #TEMP
WHERE (
		PatientAccountID IN (
			SELECT DISTINCT AAA.PatientAccountID
			FROM #TEMP AS AAA
			WHERE aaa.Days_Since_Antibiotic = 3
			)
		AND PatientAccountID IN (
			SELECT DISTINCT AAA.PatientAccountID
			FROM #TEMP AS AAA
			WHERE aaa.Days_Since_Antibiotic = 2
			)
		AND PatientAccountID IN (
			SELECT DISTINCT AAA.PatientAccountID
			FROM #TEMP AS AAA
			WHERE aaa.Days_Since_Antibiotic = 1
			)
		AND PatientAccountID IN (
			SELECT DISTINCT AAA.PatientAccountID
			FROM #TEMP AS AAA
			WHERE aaa.Days_Since_Antibiotic = 0
			)
		)
	AND Days_Since_Antibiotic IS NOT NULL

SELECT DISTINCT PatientAccountID,
	PatientLocationName,
	LatestBedName,
	VisitStartDateTime,
	OrderDescAsWritten,
	Order_Creation_DTime
FROM #TEMP A
WHERE NOT EXISTS (
		SELECT 1
		FROM #ANTIBIOTICS AS ZZZ
		WHERE A.PatientAccountID = zzz.PatientAccountID
		)
