/*
***********************************************************************
File: covid_results.sql

Input Parameters:
	None

Tables/Views:
	HPatientVisit AS A
	SMSMIR.HL7_PT AS B
	SMSDSS.c_soarian_real_time_census_CDI_v AS C
	HORDER AS D
	HOCCURRENCEORDER AS E
	HInvestigationResult AS F 
	SMSDSS.BMH_PLM_PTACCT_V

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
	--WHERE FindingAbbr = 'A_O2 Del Method'
WHERE FindingAbbr = 'A_BMH_VFSTART'
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
WHERE FindingAbbr = 'A_BMH_VFSTART'
	--(
	--		FindingAbbr = 'A_O2 Del Method'
	--		AND Value = 'Tracheostomy with Ventilator Precautions'
	--		OR FindingAbbr = 'A_O2 Del Method'
	--		AND Value = 'Endotracheal'
	--		)
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
	SUBSTRING(RACECD.RACE_CD_DESC, 1, CHARINDEX(' ', RACECD.RACE_CD_DESC, 1)) AS RACE_CD_DESC,
	A.VISITSTARTDATETIME AS [ADM_DTIME],
	CASE 
		WHEN A.VisitEndDateTime IS NULL
			THEN C.nurse_sta
			ELSE ' '
	END AS [Nurs_Sta],
	CASE
		WHEN A.VisitEndDateTime IS NULL
			THEN C.bed
			ELSE NULL
	END AS [Bed],
	[IN_HOUSE] = CASE 
		WHEN C.pt_no_num IS NOT NULL
			THEN 1
		ELSE 0
		END,
	A.ACCOMMODATIONTYPE AS [PT_Accomodation],
	A.PatientReasonforSeekingHC,
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

/*
Misc Ref Labs
*/

SELECT B.pt_med_rec_no AS [MRN],
	A.PATIENTACCOUNTID AS [PTNO_NUM],
	CAST(B.PT_LAST_NAME AS VARCHAR) + ', ' + CAST(B.PT_FIRST_NAME AS VARCHAR) AS [PT_NAME],
	ROUND((DATEDIFF(MONTH, B.pt_birth_date, A.VisitStartDateTime) / 12), 0) AS [PT_AGE],
	B.pt_gender,
	SUBSTRING(RACECD.RACE_CD_DESC, 1, CHARINDEX(' ', RACECD.RACE_CD_DESC, 1)) AS RACE_CD_DESC,
	A.VISITSTARTDATETIME AS [ADM_DTIME],
	c.nurse_sta AS [Nurs_Sta],
	c.bed AS [Bed],
	A.ACCOMMODATIONTYPE AS [PT_Accomodation],
	A.PatientReasonforSeekingHC,
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
INTO #MREF
FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit AS A
LEFT OUTER JOIN SMSMIR.HL7_PT AS B ON A.PATIENTACCOUNTID = B.pt_id
LEFT OUTER JOIN SMSDSS.c_soarian_real_time_census_CDI_v AS C ON A.PATIENTACCOUNTID = C.pt_no_num
INNER JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HORDER AS D ON A.OBJECTid = D.patientvisit_oid
INNER JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HOCCURRENCEORDER AS E ON D.OBJECTID = E.ORDER_OID
	AND D.CREATIONTIME = E.CREATIONTIME
	AND E.ORDEROCCURRENCESTATUS NOT IN ('DISCONTINUE', 'Cancel')
	AND E.StatusEnteredDatetime = (
		SELECT MAX(XXX.StatusEnteredDatetime)
		FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HOCCURRENCEORDER AS XXX
		WHERE XXX.CREATIONTIME = E.CREATIONTIME
			AND XXX.ORDER_OID = E.ORDER_OID
		)
INNER JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HInvestigationResult AS F ON E.OBJECTID = F.OCCURRENCE_OID
	AND F.RESULTDATETIME = (
		SELECT MAX(ZZZ.RESULTDATETIME)
		FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HInvestigationResult AS ZZZ
		WHERE ZZZ.OCCURRENCE_OID = E.OBJECTID
			AND ZZZ.FINDINGABBREVIATION = F.FINDINGABBREVIATION
		)
LEFT OUTER JOIN SMSDSS.BMH_PLM_PTACCT_V AS PAV ON A.PATIENTACCOUNTID = PAV.PtNo_Num
LEFT OUTER JOIN SMSDSS.RACE_CD_DIM_V AS RACECD ON B.pt_race = RACECD.src_race_cd
	AND RACECD.src_sys_id = '#PMSNTX0'
WHERE f.RESULTVALUE LIKE '%COVID%' -- COVID MISC REF VALUE
	AND d.orderabbreviation = '00410001';


-- Subsequent --
-- positive results
SELECT C.pt_med_rec_no,
	B.VisitStartDateTime AS [Adm_Date]
INTO #POSRES
FROM smsdss.c_positive_covid_visits_tbl AS A
INNER JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit AS B ON A.PatientAccountID = B.PatientAccountID
INNER JOIN SMSMIR.hl7_pt AS C ON A.PatientAccountID = C.pt_id;

-- positive results with extra data
SELECT HL7PT.pt_med_rec_no AS [MRN],
	PV.PatientAccountID AS [Encounter],
	CAST(HL7PT.pt_last_name AS VARCHAR) + ', ' + CAST(HL7PT.pt_first_name AS VARCHAR) AS [PT_Name],
	ROUND((DATEDIFF(MONTH, HL7PT.PT_BIRTH_DATE, PV.VisitStartDateTime) / 12), 0) AS [Pt_Age],
	HL7PT.pt_gender,
	SUBSTRING(RACECD.RACE_CD_DESC, 1, CHARINDEX(' ', RACECD.RACE_CD_DESC, 1)) AS RACE_CD_DESC,
	PV.VisitStartDatetime AS [Adm_Date],
	HL7VST.nurse_sta,
	HL7VST.bed,
	PV.AccommodationType,
	PV.PatientReasonforSeekingHC,
	'' AS [Order_No],
	'' AS [Covid_Order],
	'' AS [Order_DTime],
	'' AS [Order_Status],
	'' AS [Order_Status_DTime],
	'' AS [Result_DTime],
	'' AS [Result],
	PV.VisitendDateTime,
	PV.DischargeDisposition,
	[Mortality_Flag] = CASE 
		WHEN LEFT(PV.DischargeDisposition, 1) IN ('C', 'D')
			THEN 1
		ELSE 0
		END
INTO #SUBSEQUENT
FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit AS PV
INNER JOIN SMSMIR.hl7_pt AS HL7PT ON PV.PatientAccountID = HL7PT.pt_id
LEFT OUTER JOIN SMSDSS.RACE_CD_DIM_V AS RACECD ON HL7PT.pt_race = RACECD.src_race_cd
	AND RACECD.src_sys_id = '#PMSNTX0'
LEFT OUTER JOIN smsmir.hl7_vst AS HL7VST ON HL7PT.pt_id = HL7VST.pt_id
WHERE HL7PT.pt_med_rec_no IN (
		SELECT DISTINCT ZZZ.pt_med_rec_no
		FROM #POSRES AS ZZZ
		WHERE PV.VisitStartDatetime > ZZZ.Adm_Date
		AND LEFT(PV.PatientAccountID, 1) IN ('1','8')
		);

SELECT A.*
INTO #UNIONED
FROM (
	SELECT A.MRN,
		A.PTNO_NUM,
		A.PT_NAME,
		A.PT_AGE,
		A.pt_gender,
		A.RACE_CD_DESC,
		A.ADM_DTIME,
		A.nurs_sta,
		A.bed,
		A.PT_Accomodation,
		A.PatientReasonforSeekingHC,
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
	FROM #TEMPA AS A
	
	UNION
	
	SELECT *
	FROM #SUBSEQUENT
	WHERE Encounter NOT IN (
		SELECT DISTINCT ZZZ.PTNO_NUM
		FROM #TEMPA AS ZZZ
		)
	
	UNION

	SELECT *
	FROM #MREF
) AS A;

-- 
SELECT A.MRN,
	A.PTNO_NUM,
	A.PT_NAME,
	A.PT_AGE,
	A.pt_gender,
	A.RACE_CD_DESC,
	A.ADM_DTIME,
	A.nurs_sta,
	A.bed,
	A.PT_Accomodation,
	A.PatientReasonforSeekingHC,
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
		A.nurs_sta,
		A.bed,
		A.PT_Accomodation,
		A.PatientReasonforSeekingHC,
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
			A.nurs_sta,
			A.bed,
			A.PT_Accomodation,
			A.PatientReasonforSeekingHC,
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
FROM #UNIONED AS A;

SELECT A.MRN,
	A.PTNO_NUM,
	A.PT_NAME,
	A.PT_AGE,
	A.pt_gender,
	A.RACE_CD_DESC,
	A.ADM_DTIME,
	A.nurs_sta,
	A.bed,
	A.PT_Accomodation,
	A.PatientReasonforSeekingHC,
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
		WHEN RESULT LIKE 'DETECE%'
			THEN 'DETECTED'
		WHEN RESULT LIKE 'POSITIV%'
			THEN 'DETECTED'
		WHEN RESULT LIKE 'PRESUMP% POSITIVE%'
			THEN 'DETECTED'
		WHEN RESULT LIKE 'NOT DETECTED%'
			THEN 'NOT-DETECTED'
		WHEN RESULT IS NULL
			THEN 'NO-RESULT'
		ELSE REPLACE(REPLACE(A.RESULT, CHAR(13), ' '), CHAR(10), ' ')
		END,
	[Distinct_Visit_Flag] = CASE 
		WHEN ROW_NUMBER() OVER (
				PARTITION BY A.PTNO_NUM ORDER BY A.RESULT_DTIME DESC,
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
	CASE
		WHEN A.VisitEndDateTime IS NOT NULL
			THEN ''
			ELSE ISNULL(A.Nurs_Sta, '')
	END AS NURS_STA,
	--isnull(A.nurs_sta, '') AS NURS_STA,
	CASE
		WHEN A.VisitEndDateTime IS NOT NULL
			THEN ''
			ELSE ISNULL(A.Bed, '')
	END AS [BED],
	--isnull(A.bed, '') AS BED,
	CASE WHEN A.VisitEndDatetime IS NOT NULL
		THEN 0
		ELSE 1
	END AS [IN_HOUSE],-- A.IN_HOUSE,
	A.PT_Accomodation,
	A.PatientReasonforSeekingHC,
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
	A.RESULT_DTIME DESC,
	A.ORDER_DTIME DESC;

DROP TABLE #TEMPA;

DROP TABLE #TEMPB;

DROP TABLE #TEMPC;

DROP TABLE #VENTED;

DROP TABLE #UNIONED;

DROP TABLE #POSRES;

DROP TABLE #SUBSEQUENT;

DROP TABLE #MREF;