/*
***********************************************************************
File: nyu_adt_backload.sql

Input Parameters:
	None

Tables/Views:
	[SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit

Creates Table:
	
Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get patient visit data

Revision History:
Date		Version		Description
----		----		----
2022-08-23  v1          Initial Creation
2022-9-23	v2			Add ED_ARRIVAL and PreAdmit Number
***********************************************************************
*/

SELECT [PAT_LAST_NM] = PT.LastName,
	[PAT_FIRST_NM] = PT.FirstName,
	[PAT_MDL_NM] = PT.MiddleName,
	[PREFERRED_NAME] = '',
	[LICH_MRN] = B.pt_med_rec_no,
	[DOB] = CAST(B.pt_birth_date AS DATE),
	[SEX] = B.pt_gender,
	[PAT_SSN] = b.pt_ssa_no,
	[PAT_ADDR1] = b.pt_street_addr,
	[PAT_CITY] = b.pt_city,
	[PAT_ST] = b.pt_state,
	[PAT_ZIP] = b.pt_zip_cd,
	[PAT_COUNTY] = '',
	[PAT_COUNTRY] = '',
	[PAT_PHONE] = '(' + CAST(B.pt_phone_area_city_cd AS VARCHAR) + ')' + ' ' + CAST(LEFT(B.PT_PHONE_NO, 3) AS VARCHAR) + '-' + CAST(RIGHT(B.PT_PHONE_NO, 4) AS VARCHAR),
	[PAT_WRK_PH] = '(' + CAST(B.bus_phone_area_city_cd AS VARCHAR) + ')' + ' ' + CAST(LEFT(B.bus_phone_no, 3) AS VARCHAR) + '-' + CAST(RIGHT(B.bus_phone_no, 4) AS VARCHAR),
	[PAT_MOBILE_PH] = CAST(MobilePhone.PhoneAreaCode AS VARCHAR) + '-' + CAST(MobilePhone.PhoneNo AS VARCHAR),
	[EMAIL_ADDR] = EMAIL.UserDataText,
	[MOTHER_NAME] = B.mother_maiden_name,
	[COUNTRY_OF_ORIGIN] = '',
	[BIRTHPLACE] = '',
	[PREFERRED_LANG] = PT.PrimaryLanguage,
	[MARTIAL_STAT] = Person.MaritalStatus,
	[ETHNICITY] = Person.Ethnicity,
	[RACE] = Person.Race,
	[NATIONALITY] = Person.Nationality,
	[RELIGION] = Person.Religion,
	[EMPLOYMENT_STAT] = Occupation.JobStatus,
	[PCP_NM] = PCP.[Name],
	[PCP_NPI] = PCP.npi_no,
	[PCP_ADDR] = '',
	[PAT_CONTACT_NM] = EMCON.PAT_CONTACT_NM,
	[PAT_CONTACT_PH] = EMCON.PAT_CONTACT_PH,
	[PAT_CONTACT_REL] = EMCON.PAT_CONTACT_REL,
	[PAT CONTACT ADDR] = EMCON.PAT_CONTACT_ADDR,
	[PREFERRED_PHARM] = Pharmacy.PharmacyName,
	[PREFERRED_LAB] = '',
	[HOMELESS] = CASE 
		WHEN AdmitSource.Finding = 'Homeless'
			THEN 'Y'
		ELSE 'N'
		END,
	[PRIMARY_LOCATION] = '',
	[SCHOOL_COMMUNITY_HEALTH_LOCATION] = '',
	[FPL_FAMILY_SIZE] = '',
	[FPL_ANNUAL_INCOME] = '',
	[FPL_DATE] = '',
	[FPL_STATUS_DENIAL_REASON] = '',
	[GUARANTOR] = GUAR.guar_last_name + ', ' + GUAR.guar_first_name,
	[PAT_RELATION_TO_GUARNT] = CASE 
		WHEN GUAR.guar_rel = '1'
			THEN 'SELF'
		WHEN GUAR.guar_rel = '2'
			THEN 'SPOUSE'
		WHEN GUAR.guar_rel = '3'
			THEN 'FATHER'
		WHEN GUAR.guar_rel = '4'
			THEN 'MOTHER'
		WHEN GUAR.guar_rel = '5'
			THEN 'STEP PARENT'
		WHEN GUAR.guar_rel = '6'
			THEN 'GRANDPARENT'
		WHEN GUAR.guar_rel = 'A'
			THEN 'POA'
		WHEN GUAR.guar_rel = 'B'
			THEN 'GUARDIAN'
		WHEN GUAR.guar_rel = 'C'
			THEN 'OTHER'
		END,
	[GUARANT_ADDR] = GUAR.guar_street_addr,
	[GUARANT_CITY] = GUAR.guar_city,
	[GUARANT_ZIP] = GUAR.guar_zip_cd,
	[GUARANT_PH] = '(' + CAST(GUAR.guar_phone_area_city_cd AS VARCHAR) + ')' + ' ' + CAST(LEFT(GUAR.guar_phone_no, 3) AS VARCHAR) + '-' + CAST(RIGHT(GUAR.guar_phone_no, 4) AS VARCHAR),
	[FC_PRIM_INS] = A.FinancialClass,
	[PRIM_CARRIER_NAME] = FirstIns.InsCoName,
	[PRIM_SUBSCRIBER_RELATION_TO_PAT] = CASE 
		WHEN FirstIns.SubscriberRelationToPt = '1'
			THEN 'SELF'
		WHEN FirstIns.SubscriberRelationToPt = '2'
			THEN 'SPOUSE'
		WHEN FirstIns.SubscriberRelationToPt = '3'
			THEN 'FATHER'
		WHEN FirstIns.SubscriberRelationToPt = '4'
			THEN 'MOTHER'
		WHEN FirstIns.SubscriberRelationToPt = '5'
			THEN 'STEP PARENT'
		WHEN FirstIns.SubscriberRelationToPt = '6'
			THEN 'GRANDPARENT'
		WHEN FirstIns.SubscriberRelationToPt = 'A'
			THEN 'POA'
		WHEN FirstIns.SubscriberRelationToPt = 'B'
			THEN 'GUARDIAN'
		WHEN FirstIns.SubscriberRelationToPt = 'C'
			THEN 'OTHER'
		ELSE FirstIns.SubscriberRelationToPt
		END,
	[PRIM_SUBSCRIBER_ADDR1] = FirstInsAddress.StreetAddress,
	[PRIM_SUBSCRIBER_CITY] = FirstInsAddress.City,
	[PRIM_SUBSCRIBER_ZIP] = FirstInsAddress.PostalCode,
	[PRIM_SUBSCRIBER_COUNTY] = FirstInsAddress.County,
	[PRIM_PLAN_CD] = FirstIns.InsPlan,
	[PRIM_INS_ID] = FirstIns.[Policy],
	[PRIM_INS_GROUP] = FirstIns.GroupNo,
	[FC_SECND_INS] = (
		SELECT zzz.pyr_group2
		FROM smsdss.pyr_dim_v AS ZZZ
		WHERE SecondIns.InsPlan = ZZZ.src_pyr_cd
			AND ZZZ.orgz_cd = 's0x0'
		),
	[SECND_CARRIER_NM] = SecondIns.InsCoName,
	[SECND_PLAN_NM] = '',
	[SECOND_SUBSCRIBER_RELATION_TO_PAT] = CASE 
		WHEN SecondIns.SubscriberRelationToPt = '1'
			THEN 'SELF'
		WHEN SecondIns.SubscriberRelationToPt = '2'
			THEN 'SPOUSE'
		WHEN SecondIns.SubscriberRelationToPt = '3'
			THEN 'FATHER'
		WHEN SecondIns.SubscriberRelationToPt = '4'
			THEN 'MOTHER'
		WHEN SecondIns.SubscriberRelationToPt = '5'
			THEN 'STEP PARENT'
		WHEN SecondIns.SubscriberRelationToPt = '6'
			THEN 'GRANDPARENT'
		WHEN SecondIns.SubscriberRelationToPt = 'A'
			THEN 'POA'
		WHEN SecondIns.SubscriberRelationToPt = 'B'
			THEN 'GUARDIAN'
		WHEN SecondIns.SubscriberRelationToPt = 'C'
			THEN 'OTHER'
		ELSE SecondIns.SubscriberRelationToPt
		END,
	[SECOND_SUBSCRIBER_ADDR1] = SecondInsAddress.StreetAddress,
	[SECOND_SUBSCRIBER_CITY] = SecondInsAddress.City,
	[SECOND_SUBSCRIBER_ZIP] = SecondInsAddress.PostalCode,
	[SECOND_SUBSCRIBER_COUNTY] = SecondInsAddress.County,
	[SECND_PLAN_CD] = SecondIns.InsPlan,
	[SECND_INS_ID] = SecondIns.[Policy],
	[SECND_INS_GROUP] = SecondIns.GroupNo,
	[FC_TERT_INS] = (
		SELECT ZZZ.PYR_GROUP2
		FROM smsdss.pyr_dim_v AS ZZZ
		WHERE ThirdIns.InsPlan = ZZZ.src_pyr_cd
			AND ZZZ.orgz_cd = 's0x0'
		),
	[TERT_CARRIER_NM] = ThirdIns.InsCoName,
	[TERT_PLAN_NM] = '',
	[TERT_SUBSCRIBER_RELATION_TO_PAT] = CASE 
		WHEN ThirdIns.SubscriberRelationToPt = '1'
			THEN 'SELF'
		WHEN ThirdIns.SubscriberRelationToPt = '2'
			THEN 'SPOUSE'
		WHEN ThirdIns.SubscriberRelationToPt = '3'
			THEN 'FATHER'
		WHEN ThirdIns.SubscriberRelationToPt = '4'
			THEN 'MOTHER'
		WHEN ThirdIns.SubscriberRelationToPt = '5'
			THEN 'STEP PARENT'
		WHEN ThirdIns.SubscriberRelationToPt = '6'
			THEN 'GRANDPARENT'
		WHEN ThirdIns.SubscriberRelationToPt = 'A'
			THEN 'POA'
		WHEN ThirdIns.SubscriberRelationToPt = 'B'
			THEN 'GUARDIAN'
		WHEN ThirdIns.SubscriberRelationToPt = 'C'
			THEN 'OTHER'
		ELSE ThirdIns.SubscriberRelationToPt
		END,
	[TERT_SUBSCRIBER_ADDR1] = ThirdInsAddress.StreetAddress,
	[TERT_SUBSCRIBER_CITY] = ThirdInsAddress.City,
	[TERT_SUBSCRIBER_ZIP] = ThirdInsAddress.PostalCode,
	[TERT_SUBSCRIBER_COUNTY] = ThirdInsAddress.County,
	[TERT_PLAN_CD] = ThirdIns.InsPlan,
	[TERT_INS_ID] = ThirdIns.[Policy],
	[TERT_INS_GROUP] = ThirdIns.GroupNo,
	[LICH_ACCT_NUMBER] = A.PatientAccountID,
	[EPIC_MRN] = '',
	[UPGRADED_ED_ACCT] = PreAdmit.UserDefinedNumeric1,
	[ED_ARRIVAL] = A.PreVisitDate,
	[ADM_DT] = CAST(A.VisitStartDateTime AS DATE),
	[ADM_TM] = LEFT(CAST(A.VisitStartDateTime AS TIME), 8),
	[CUR_UNIT] = A.PatientLocationName,
	[CUR_ROOM] = A.LatestBedName,
	[CUR_BED] = '',
	[CUR_ATTEND_CD] = Attending.MSINumber,
	[CUR_ATTEND_NM] = Attending.[Name],
	[ATTEND_NPI] = Attending.npi_no,
	[ADMIT_CD] = Admitting.MSINumber,
	[ADMIT_NM] = Admitting.[Name],
	[ADMIT_NPI] = Admitting.npi_no,
	[REFERRING_CD] = '',
	[REFERRING_NM] = '',
	[REFERRING_NPI] = '',
	[ADM_DIAG] = REPLACE(REPLACE(REPLACE(REPLACE(A.PatientReasonforSeekingHC, CHAR(43), ' '), CHAR(45), ' '), CHAR(13), ' '), CHAR(10), ' '),
	[SERVICE] = A.UnitContactedName,
	[ADM_SOURCE] = AdmitSource.Finding,
	[ADM_TYPE] = A.VisitTypeCode,
	[TRANSF_FROM_HOSP] = '',
	[PATIENT_TYPE] = A.AccommodationType,
	[VISIT_GUARANTOR_ACCT_TYPE] = '',
	[AUTHORIZATION_NUMBER] = FirstIns.TreatAuth,
	[AUTH_START_DT] = '',
	[AUTH_END_DT] = '',
	[ADM_UNIT] = '',
	[ADM_ROOM] = '',
	[ADM_BED] = '',
	[NO_FAULT_ITEMS] = '',
	[HIE] = PT.MedHistoryConsent,
	[HIPPA] = '',
	[ADVANCE_DIRECTIVE] = PT.AdvancedDirectiveonFile,
	[NOPP] = '',
	[PROVIDER_TEAM] = ''
FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit AS A
LEFT JOIN SMSMIR.HL7_PT AS B ON A.PATIENTACCOUNTID = B.pt_id
LEFT JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HPatient AS PT ON A.Patient_oid = PT.ObjectID
LEFT JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HPerson AS Person ON A.Patient_oid = Person.objectID
	AND Person.IsDeleted = 0
	AND Person.IsVersioned = 1
-- employment
LEFT JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HOccupation AS Occupation ON A.Patient_oid = Occupation.Person_oid
	AND Occupation.IsVersioned = 1
	AND Occupation.PresentOccupation = 1
	AND Occupation.IsPrimary = 1
---- GUARANTOR
--LEFT JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HGuarantor AS HG ON A.Patient_oid = HG.Patient_oid
--	AND HG.IsVersioned = 1
LEFT JOIN smsmir.hl7_guar AS GUAR ON GUAR.PT_ID = A.PatientAccountID
LEFT JOIN smsmir.hl7_ins AS INS ON GUAR.pt_id = INS.pt_id
	AND GUAR.last_msg_cntrl_id = INS.last_msg_cntrl_id
	AND INS.ins_plan_prio_no = 1
------ INS2
LEFT JOIN smsmir.hl7_ins AS INS2 ON GUAR.pt_id = INS2.pt_id
	AND GUAR.last_msg_cntrl_id = INS2.last_msg_cntrl_id
	AND INS2.ins_plan_prio_no = 2
------ INS3
LEFT JOIN smsmir.hl7_ins AS INS3 ON GUAR.pt_id = INS3.pt_id
	AND GUAR.last_msg_cntrl_id = INS3.last_msg_cntrl_id
	AND INS3.ins_plan_prio_no = 3
---- first ins
LEFT JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HInsuranceDetails AS FirstIns ON FirstIns.PatientVisit_oid = A.ObjectID
	AND FirstIns.[Priority] = 1
	AND FirstIns.IsDeleted = 0
	AND FirstIns.InsPlan = INS.ins_plan_no
-- First Ins Subscriber Information
LEFT JOIN [SC_server].[Soarian_Clin_Prd_1].dbo.HAddress AS FirstInsAddress ON FirstIns.SubscriberAddress_oid = FirstInsAddress.ObjectID
---- secondary ins
LEFT JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HInsuranceDetails AS SecondIns ON SecondIns.PatientVisit_oid = A.ObjectID
	AND SecondIns.[Priority] = 2
	AND SecondIns.IsDeleted = 0
	AND SecondIns.InsPlan = INS2.ins_plan_no
-- Second Ins Subscriber Information
LEFT JOIN [SC_server].[Soarian_Clin_Prd_1].dbo.HAddress AS SecondInsAddress ON SecondIns.SubscriberAddress_oid = SecondInsAddress.ObjectID
---- third ins
LEFT JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HInsuranceDetails AS ThirdIns ON ThirdIns.PatientVisit_oid = A.ObjectID
	AND ThirdIns.[Priority] = 3
	AND ThirdIns.IsDeleted = 0
	AND ThirdIns.InsPlan = INS3.ins_plan_no
-- Third Ins Subscriber Information
LEFT JOIN [SC_server].[Soarian_Clin_Prd_1].dbo.HAddress AS ThirdInsAddress ON ThirdIns.SubscriberAddress_oid = ThirdInsAddress.ObjectID
-- Get Mobile Phone
LEFT JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HAddress AS MobilePhone ON A.Patient_oid = MobilePHone.person_oid
	AND MobilePhone.IsVersioned = 1
	AND MobilePhone.AddressType = 2
-- Get Email
LEFT JOIN smsdss.BMH_UserTwoFact_V AS EMAIL ON EMAIL.PtNo_Num = A.PatientAccountID
	AND EMAIL.UserDataKey = '631'
-- Primary Care Provider
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
	WHERE HSA.RelationType = 1
	) AS PCP ON PCP.Patient_oid = A.Patient_oid
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
-- EMERGENCY CONTACT
LEFT JOIN (
	SELECT [HKD_OBJECTID] = HKD.ObjectID,
		[Patient_oid] = HKD.Patient_oid,
		[PAT_CONTACT_NM] = CASE 
			WHEN HKD.ContactPerson IS NULL
				THEN HKD.[Description]
			ELSE HKD.ContactPerson
			END,
		[PAT_CONTACT_PH] = CAST(HA.PhoneAreaCode AS VARCHAR) + '-' + CAST(HA.PhoneNo AS VARCHAR),
		[PAT_CONTACT_REL] = HKD.Relationship,
		[PAT_CONTACT_ADDR] = ISNULL(HA.StreetAddress, '') + ', ' +
		--ISNULL(HA.CityDistrict,'') + ', ' +
		ISNULL(HA.City, '') + ',' + ISNULL(HA.AreaofCountry, '') + ' ' + ISNULL(HA.PostalCode, '')
	FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HNextofKinDetails AS HKD
	INNER JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HPerson AS HP ON HKD.ObjectID = HP.ObjectID
		AND HP.IsVersioned = 1
		AND HP.IsDeleted = 0
	INNER JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HAddress AS HA ON HP.ObjectID = HA.Person_oid
		AND HA.AddressType = 0
		AND HA.IsVersioned = 1
	WHERE HKD.IsVersioned = 1
		AND HKD.PrimaryContact = 1
	) AS EMCON ON A.Patient_oid = EMCON.Patient_oid
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
-- pharmacy
LEFT JOIN (
	SELECT PP.PatientOID,
		P.PharmacyName
	FROM [SC_server].[Soarian_Clin_Prd_1].DBO.PatientPharmacy AS PP
	INNER JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.Pharmacy AS P ON PP.PharmacyOID = P.PharmacyOID
	INNER JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HPatient AS HP ON PP.PatientOID = HP.ObjectID
	) AS Pharmacy ON Pharmacy.PatientOID = A.patient_oid
-- Preadmit ID
LEFT JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HExtendedPatientVisit AS PreAdmit ON A.PatientVisitExtension_oid = PreAdmit.ObjectID
WHERE A.VisitEndDateTime IS NULL
	AND A.PatientLocationName <> ''
	AND A.IsDeleted = 0
-- testing
--AND A.ObjectID = 2685763;
ORDER BY A.PatientAccountID;
