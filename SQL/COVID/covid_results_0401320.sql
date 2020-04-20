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
--Get all the assessments within the last 24 hours that contain  
-- A_02 Del Method and sort them by Collected Date.    
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
WHERE FindingAbbr = 'A_O2 Del Method'
	--AND Value = 'Tracheostomy with Ventilator Precautions'  
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
WHERE (
		FindingAbbr = 'A_O2 Del Method'
		AND Value = 'Tracheostomy with Ventilator Precautions'
		OR FindingAbbr = 'A_O2 Del Method'
		AND Value = 'Endotracheal'
		)
	AND ha.AssessmentStatusCode IN (1, 3)
	AND ho.EndDT IS NULL
	AND ha.EndDt IS NULL
	AND ha.CollectedDT BETWEEN @dtStartDate
		AND @dtEndDate

SELECT *
INTO #VENTED
FROM @VentPatients AS PTS
INNER JOIN @VentAssessments AS VAS ON PTS.PatientVisit_oid = VAS.PatientVisitOID
INNER JOIN @CensusVisitOIDs AS CEN ON PTS.PatientVisit_oid = CEN.VisitOID

/*
GET COVID-19 RESULTS
*/
SELECT B.pt_med_rec_no AS [MRN],
	A.PATIENTACCOUNTID AS [PTNO_NUM],
	CAST(B.PT_LAST_NAME AS VARCHAR) + ', ' + CAST(B.PT_FIRST_NAME AS VARCHAR) AS [PT_NAME],
	ROUND((DATEDIFF(MONTH, B.pt_birth_date, A.VisitStartDateTime) / 12), 0) AS [PT_AGE],
	B.pt_gender,
	SUBSTRING(RACECD.RACE_CD_DESC, 1, CHARINDEX('  ', RACECD.RACE_CD_DESC, 1)) AS RACE_CD_DESC,
	A.VISITSTARTDATETIME AS [ADM_DTIME],
	C.nurse_sta,
	C.bed,
	[IN_HOUSE] = CASE 
		WHEN C.pt_no_num IS NOT NULL
			THEN 1
		ELSE 0
		END,
	A.ACCOMMODATIONTYPE AS [PT_Accomodation],
	d.orderid AS [Order_No],
	ISNULL(D.ORDERABBREVIATION, 'NO ORDER FOUND') AS [COVID_ORDER],
	d.creationtime AS [ORDER_DTIME],
	E.ORDEROCCURRENCESTATUS AS [Order_Status],
	E.StatusEnteredDatetime AS [Order_Status_DTime],
	F.resultdatetime AS [RESULT_DTIME],
	F.resultvalue AS [RESULT],
	A.VisitEndDateTime,
	A.DischargeDisposition,
	[Mortality_Flag] = CASE 
		WHEN LEFT(A.DischargeDisposition, 1) IN ('C', 'D')
			THEN 1
		ELSE 0
		END
INTO #TEMPA
FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit AS A
LEFT OUTER JOIN SMSMIR.HL7_PT AS B ON A.PATIENTACCOUNTID = B.pt_id
LEFT OUTER JOIN SMSDSS.c_soarian_real_time_census_CDI_v AS C ON A.PATIENTACCOUNTID = C.pt_no_num
INNER JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HORDER AS D ON A.OBJECTid = D.patientvisit_oid
	AND D.ORDERABBREVIATION = '00425421'
INNER JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HOCCURRENCEORDER AS E ON D.OBJECTID = E.ORDER_OID
	AND D.CREATIONTIME = E.CREATIONTIME
	AND E.ORDEROCCURRENCESTATUS NOT IN ('DISCONTINUE', 'Cancel')
	AND E.StatusEnteredDatetime = (
		SELECT MAX(XXX.StatusEnteredDatetime)
		FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HOCCURRENCEORDER AS XXX
		WHERE XXX.CREATIONTIME = E.CREATIONTIME
			AND XXX.ORDER_OID = E.ORDER_OID
		)
LEFT OUTER JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HInvestigationResult AS F ON E.OBJECTID = F.OCCURRENCE_OID
	AND F.FINDINGABBREVIATION = '9782'
	AND F.RESULTDATETIME = (
		SELECT MAX(ZZZ.RESULTDATETIME)
		FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HInvestigationResult AS ZZZ
		WHERE ZZZ.OCCURRENCE_OID = E.OBJECTID
			AND ZZZ.FINDINGABBREVIATION = F.FINDINGABBREVIATION
		)
LEFT OUTER JOIN SMSDSS.BMH_PLM_PTACCT_V AS PAV ON A.PATIENTACCOUNTID = PAV.PtNo_Num
LEFT OUTER JOIN SMSDSS.RACE_CD_DIM_V AS RACECD ON B.pt_race = RACECD.src_race_cd
	AND RACECD.src_sys_id = '#PMSNTX0'
	--WHERE A.patientaccountid = '14857767'
	--WHERE A.PATIENTACCOUNTID = '71007157'
	;

SELECT A.MRN,
	A.PTNO_NUM,
	A.PT_NAME,
	A.PT_AGE,
	A.pt_gender,
	A.RACE_CD_DESC,
	A.ADM_DTIME,
	A.nurse_sta,
	A.bed,
	A.IN_HOUSE,
	A.PT_Accomodation,
	A.Order_No,
	A.COVID_ORDER,
	A.ORDER_DTIME,
	A.Order_Status,
	A.Order_Status_DTime,
	A.RESULT_DTIME,
	A.RESULT,
	A.VisitEndDateTime,
	A.DischargeDisposition,
	A.Mortality_Flag,
	[RN] = ROW_NUMBER() OVER (
		PARTITION BY A.MRN,
		A.PTNO_NUM,
		A.PT_NAME,
		A.PT_AGE,
		A.pt_gender,
		A.RACE_CD_DESC,
		A.ADM_DTIME,
		A.nurse_sta,
		A.bed,
		A.IN_HOUSE,
		A.PT_Accomodation,
		A.Order_No,
		A.COVID_ORDER,
		A.ORDER_DTIME,
		A.Order_Status,
		A.Order_Status_DTime,
		A.RESULT_DTIME,
		A.RESULT,
		A.VisitEndDateTime,
		A.DischargeDisposition,
		A.Mortality_Flag ORDER BY A.MRN,
			A.PTNO_NUM,
			A.PT_NAME,
			A.PT_AGE,
			A.pt_gender,
			A.RACE_CD_DESC,
			A.ADM_DTIME,
			A.nurse_sta,
			A.bed,
			A.IN_HOUSE,
			A.PT_Accomodation,
			A.Order_No,
			A.COVID_ORDER,
			A.ORDER_DTIME,
			A.Order_Status,
			A.Order_Status_DTime,
			A.RESULT_DTIME,
			A.RESULT,
			A.VisitEndDateTime,
			A.DischargeDisposition,
			A.Mortality_Flag
		)
INTO #TEMPB
FROM #TEMPA AS A;

SELECT A.MRN,
	A.PTNO_NUM,
	A.PT_NAME,
	A.PT_AGE,
	A.pt_gender,
	A.RACE_CD_DESC,
	A.ADM_DTIME,
	A.nurse_sta,
	A.bed,
	A.IN_HOUSE,
	A.PT_Accomodation,
	A.Order_No,
	A.COVID_ORDER,
	A.ORDER_DTIME,
	A.Order_Status,
	A.Order_Status_DTime,
	A.RESULT_DTIME,
	REPLACE(REPLACE(A.RESULT, CHAR(13), ' '), CHAR(10), ' ') AS [RESULT],
	A.VisitEndDateTime,
	A.DischargeDisposition,
	A.Mortality_Flag,
	[RESULT_CLEAN] = CASE 
		WHEN RESULT LIKE 'DETECTED%'
			THEN 'DETECTED'
		WHEN RESULT LIKE 'NOT DETECTED%'
			THEN 'NOT-DETECTED'
		WHEN RESULT IS NULL
			THEN 'NO-RESULT'
		ELSE REPLACE(REPLACE(A.RESULT, CHAR(13), ' '), CHAR(10), ' ')
		END,
	[Distinct_Visit_Flag] = CASE 
		WHEN ROW_NUMBER() OVER (
				PARTITION BY A.PTNO_NUM ORDER BY A.PTNO_NUM,
					A.ORDER_DTIME DESC
				) = 1
			THEN 1
		ELSE 0
		END
INTO #TEMPC
FROM #TEMPB AS A
WHERE A.RN = 1;

SELECT A.MRN,
	A.PTNO_NUM,
	A.PT_NAME,
	A.PT_AGE,
	A.pt_gender,
	A.RACE_CD_DESC,
	A.ADM_DTIME,
	A.VisitEndDateTime AS DC_DTIME,
	isnull(A.nurse_sta, '') AS NURS_STA,
	isnull(A.bed, '') AS BED,
	A.IN_HOUSE,
	A.PT_Accomodation,
	A.Order_No,
	A.COVID_ORDER,
	A.ORDER_DTIME,
	A.Order_Status,
	A.Order_Status_DTime,
	A.RESULT_DTIME,
	A.[RESULT],
	isnull(A.DischargeDisposition, '') AS DC_DISP,
	A.Mortality_Flag,
	A.[RESULT_CLEAN],
	A.[Distinct_Visit_Flag],
	[VENTED] = CASE 
		WHEN VENTED.PatientAccountID IS NOT NULL
			THEN 'VENTED'
		ELSE ' '
		END,
	[VENT_FLAG] = CASE 
		WHEN VENTED.PatientAccountID IS NOT NULL
			THEN 1
		ELSE 0
		END,
	VENTED.CollectedDT [Last_Vent_Check]
FROM #TEMPC AS A
LEFT OUTER JOIN #VENTED AS VENTED ON A.PTNO_NUM = VENTED.PatientAccountID
ORDER BY A.PT_NAME,
	A.ORDER_DTIME DESC;

DROP TABLE #TEMPA;

DROP TABLE #TEMPB;

DROP TABLE #TEMPC;

DROP TABLE #VENTED;
