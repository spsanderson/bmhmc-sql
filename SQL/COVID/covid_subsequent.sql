SELECT C.pt_med_rec_no,
	B.VisitStartDateTime AS [Adm_Date]
INTO #TEMPA
FROM smsdss.c_positive_covid_visits_tbl AS A
INNER JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit AS B ON A.PatientAccountID = B.PatientAccountID
INNER JOIN SMSMIR.hl7_pt AS C ON A.PatientAccountID = C.pt_id;

SELECT HL7PT.pt_med_rec_no AS [MRN]
, PV.PatientAccountID AS [Encounter]
, CAST(HL7PT.pt_last_name AS VARCHAR) + ', ' + CAST(HL7PT.pt_first_name AS VARCHAR) AS [PT_Name]
, ROUND((DATEDIFF(MONTH, HL7PT.PT_BIRTH_DATE, PV.VisitStartDateTime) / 12), 0) as [Pt_Age]
, HL7PT.pt_gender
, SUBSTRING(RACECD.RACE_CD_DESC, 1, CHARINDEX(' ', RACECD.RACE_CD_DESC, 1)) AS RACE_CD_DESC
, PV.VisitStartDatetime AS [Adm_Date]
, HL7VST.nurse_sta
, HL7VST.bed
, [In_House] = CASE
	WHEN HL7VST.pt_id IS NOT NULL
		THEN 1
		ELSE 0
	END
, PV.AccommodationType
, '' AS [Order_No]
, '' AS [Covid_Order]
, '' AS [Order_DTime]
, '' AS [Order_Status]
, '' AS [Order_Status_DTime]
, '' AS [Result_DTime]
, '' AS [Result]
, PV.VisitendDateTime
, PV.DischargeDisposition
, [Mortality_Flag] = CASE
	WHEN LEFT(PV.DischargeDisposition, 1) IN ('C','D')
		THEN 1
		ELSE 0
	END
INTO #SUBSEQUENT
FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit AS PV
INNER JOIN SMSMIR.hl7_pt AS HL7PT ON PV.PatientAccountID = HL7PT.pt_id
LEFT OUTER JOIN SMSDSS.RACE_CD_DIM_V AS RACECD ON HL7PT.pt_race = RACECD.src_race_cd
	AND RACECD.src_sys_id = '#PMSNTX0'
LEFT OUTER JOIN smsmir.hl7_vst AS HL7VST
ON HL7PT.pt_id = HL7VST.pt_id
WHERE HL7PT.pt_med_rec_no IN (
	SELECT DISTINCT ZZZ.pt_med_rec_no
	FROM #TEMPA AS ZZZ
	WHERE PV.VisitStartDatetime > ZZZ.Adm_Date
);

SELECT *
FROM #SUBSEQUENT;

DROP TABLE #TEMPA;
DROP TABLE #SUBSEQUENT