SELECT [PAT_LAST_NM] = PT.LastName,
	[PAT_FIRST_NM] = PT.FirstName,
	[DOB] = CAST(B.pt_birth_date AS DATE),
	[SEX] = B.pt_gender,
	[LICH_MRN] = B.pt_med_rec_no,
	[LICH_ACCT_NUMBER] = A.PatientAccountID,
	[UPGRADED_ED_ACCT] = PreAdmit.UserDefinedNumeric1,
	[ED_ARRIVAL] = A.PreVisitDate, --A.CreationTime,
	[ADM_DT] = CAST(A.VisitStartDateTime AS DATE),
	[ADM_TM] = LEFT(CAST(A.VisitStartDateTime AS TIME), 8),
	[CUR_UNIT] = A.PatientLocationName,
	[CUR_ROOM] = A.LatestBedName,
	[CUR_ATTEND_CD] = Attending.MSINumber,
	[CUR_ATTEND_NM] = Attending.[Name],
	[ATTEND_NPI] = Attending.npi_no,
	[ADMIT_CD] = Admitting.MSINumber,
	[ADMIT_NM] = Admitting.[Name],
	[ADM_DIAG] = REPLACE(REPLACE(REPLACE(REPLACE(A.PatientReasonforSeekingHC, CHAR(43), ' '), CHAR(45), ' '), CHAR(13), ' '), CHAR(10), ' '),
	[SERVICE] = A.UnitContactedName,
	[ADM_SOURCE] = AdmitSource.Finding,
	[ADM_TYPE] = A.VisitTypeCode,
	[PATIENT_TYPE] = A.AccommodationType

	FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit AS A
LEFT JOIN SMSMIR.HL7_PT AS B ON A.PATIENTACCOUNTID = B.pt_id
LEFT JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HPatient AS PT ON A.Patient_oid = PT.ObjectID
---- Attending
LEFT JOIN (
	SELECT HS.[Name],
		hs.[MSINumber],
		pdv.npi_no,
		HSA.PatientVisit_oid,
		HSA.Patient_oid,
		HSA.RelationType
	FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HStaffAssociations AS hsa
	INNER JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HStaff AS hs ON hsa.staff_oid = hs.objectid
	LEFT JOIN smsdss.pract_dim_v AS PDV ON HS.MSINumber = pdv.src_pract_no
		AND pdv.orgz_cd = 's0x0'
	WHERE HSA.RelationType = 0
	) AS Attending ON Attending.PatientVisit_oid = A.ObjectId
---- Admitting
LEFT JOIN (
	SELECT HS.[Name],
		hs.[MSINumber],
		pdv.npi_no,
		HSA.PatientVisit_oid,
		HSA.Patient_oid,
		HSA.RelationType
	FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HStaffAssociations AS hsa
	INNER JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HStaff AS hs ON hsa.staff_oid = hs.objectid
	LEFT JOIN smsdss.pract_dim_v AS PDV ON HS.MSINumber = pdv.src_pract_no
		AND pdv.orgz_cd = 's0x0'
	WHERE HSA.RelationType = 4
	) AS Admitting ON Admitting.PatientVisit_oid = A.ObjectId
	-- Admit Source and Homeless?
LEFT JOIN (
	SELECT PatientOID = ha.Patient_OID,
		PatientVisitOID = ha.PatientVisit_OID,
		AssessmentID = ha.AssessmentID,
		CollectedDT = ha.EnteredDT,
		Finding = HO.[Value]
	FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HAssessment AS HA WITH (NOLOCK)
	INNER JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit AS HV ON HA.PatientVisit_OID = HV.ObjectID
	INNER JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HObservation AS HO WITH (NOLOCK) ON ha.assessmentid = ho.assessmentid
		AND ha.PatientVisit_OID = hv.ObjectID
		AND ha.EnteredDT = (
			SELECT TOP 1 ha.EnteredDT
			FROM [SC_server].[Soarian_Clin_Prd_1].DBO.hassessment AS HA
			INNER JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HObservation AS HO WITH (NOLOCK) ON ha.assessmentid = ho.assessmentid
			WHERE HO.FindingAbbr IN ('A_Admit From')
				AND HA.patient_oid = HV.Patient_OID
				AND HA.PatientVisit_oid = HV.ObjectID
				AND ha.assessmentstatuscode IN ('1', '3')
				AND ha.FormUsageDisplayName IN ('Admission')
				AND ha.enddt IS NULL
				AND ho.EndDt IS NULL
			ORDER BY ha.EnteredDT DESC
			)
	WHERE ha.EndDt IS NULL
		AND ho.EndDt IS NULL
		AND HO.FindingAbbr IN ('A_Admit From')
		AND ha.assessmentstatuscode IN ('1', '3')
		AND ha.FormUsageDisplayName IN ('Admission')
		AND HV.VisitEndDateTime IS NULL
		AND HV.PatientLocationName <> ''
		AND HV.IsDeleted = 0
	) AS AdmitSource ON A.ObjectID = AdmitSource.PatientVisitOID
	LEFT JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HExtendedPatientVisit AS PreAdmit ON A.PatientVisitExtension_oid = PreAdmit.ObjectID
WHERE A.VisitEndDateTime IS NULL
	AND A.PatientLocationName <> ''
	AND A.IsDeleted = 0