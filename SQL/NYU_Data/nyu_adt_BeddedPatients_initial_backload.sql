/*
***********************************************************************

INITIAL BACKLOAD ONLY


File: nyu_adt_BeddedPatients_initial_backload.sql

Input Parameters:
	None

Tables/Views:
	[SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit
	[SC_server].[Soarian_Clin_Prd_1].DBO.HPatient
	[SC_server].[Soarian_Clin_Prd_1].DBO.HPerson
	[SC_server].[Soarian_Clin_Prd_1].DBO.HOccupation
	[SC_server].[Soarian_Clin_Prd_1].DBO.HInsuranceDetails
	[SC_server].[Soarian_Clin_Prd_1].dbo.HAddress
	[SC_server].[Soarian_Clin_Prd_1].DBO.HStaffAssociations
	[SC_server].[Soarian_Clin_Prd_1].DBO.HNextofKinDetails
	[SC_server].[Soarian_Clin_Prd_1].DBO.HAssessment
	[SC_server].[Soarian_Clin_Prd_1].DBO.HObservation
	smsmir.hl7_guar
	smsmir.hl7_msg_hdr
	smsmir.hl7_ins
	smsdss.BMH_UserTwoFact_V
	smsdss.pract_dim_v

Creates Table:
	smsdss.c_adt_bedded_tbl
	
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
2022-10-28	v3			Fix duplicate record error from invision updates
						to guar record.
2022-10-31	v4			Rearrange Columns
						Populates smsdss.c_adt_bedded_tbl
2022-11-02	v5			Complete Re-write for speed
***********************************************************************
*/

-- Patient Population
DROP TABLE IF EXISTS #bedded_pts;
	CREATE TABLE #bedded_pts (
		patient_visit_oid INT,
		patient_oid INT,
		patientaccountid INT,
		ed_arrival SMALLDATETIME,
		adm_dt DATE,
		adm_tm TIME,
		cur_unit VARCHAR(255),
		cur_room VARCHAR(255),
		adm_diag VARCHAR(max),
		[service] VARCHAR(max),
		adm_type VARCHAR(max),
		patient_type VARCHAR(255),
		fc_prim_ins VARCHAR(255),
		patientvisitextension_oid INT,
		visitenddatetime DATETIME,
		isdeleted CHAR(1),
		visittypecode VARCHAR(255),
		accommodation_type VARCHAR(255)
		);

INSERT INTO #bedded_pts (
	patient_visit_oid,
	patient_oid,
	patientaccountid,
	ed_arrival,
	adm_dt,
	adm_tm,
	cur_unit,
	cur_room,
	adm_diag,
	[service],
	adm_type,
	patient_type,
	fc_prim_ins,
	patientvisitextension_oid,
	visitenddatetime,
	isdeleted,
	visittypecode,
	accommodation_type
	)
SELECT objectID,
	patient_oid,
	patientaccountid,
	PREVISITDATE,
	CAST(VisitStartDateTime AS DATE) AS [ADM_DT],
	LEFT(CAST(VisitStartDateTime AS TIME), 8) AS [ADM_TM],
	PATIENTLOCATIONNAME,
	LATESTBEDNAME,
	[ADM_DIAG] = REPLACE(REPLACE(REPLACE(REPLACE(PatientReasonforSeekingHC, CHAR(43), ' '), CHAR(45), ' '), CHAR(13), ' '), CHAR(10), ' '),
	[SERVICE] = UnitContactedName,
	[ADM_TYPE] = VisitTypeCode,
	[PATIENT_TYPE] = AccommodationType,
	[FC_PRIM_INS] = FINANCIALCLASS,
	patientvisitextension_oid,
	visitenddatetime,
	isdeleted,
	VisitTypeCode,
	AccommodationType
FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit
WHERE VisitEndDateTime IS NULL
	AND PatientLocationName <> ''
	AND IsDeleted = 0;

-- SC Patient Data
DROP TABLE IF EXISTS #patient;
	CREATE TABLE #patient (
		patient_oid INT, -- joins to bedded_pts.patient_oid
		last_name VARCHAR(255),
		first_name VARCHAR(255),
		middle_name VARCHAR(255),
		primary_language VARCHAR(255),
		hie VARCHAR(255), -- medhistoryconsent
		advance_directive VARCHAR(255) -- advanceddirectiveonfile
		);

INSERT INTO #patient (
	patient_oid,
	last_name,
	first_name,
	middle_name,
	primary_language,
	hie,
	advance_directive
	)
SELECT pt.objectid,
	pt.LastName,
	pt.FirstName,
	pt.MiddleName,
	pt.PrimaryLanguage,
	pt.MedHistoryConsent,
	pt.AdvancedDirectiveonFile
FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HPatient AS PT
INNER JOIN #bedded_pts AS a ON pt.objectid = a.patient_oid

-- SC Person Data
DROP TABLE IF EXISTS #person;
	CREATE TABLE #person (
		patient_oid INT, -- HPerson.objectID Joins on #patient.patient_oid
		marital_stats VARCHAR(255),
		ethnicity VARCHAR(255),
		race VARCHAR(255),
		nationality VARCHAR(255),
		religion VARCHAR(255)
		);

INSERT INTO #person (
	patient_oid,
	marital_stats,
	ethnicity,
	race,
	nationality,
	religion
	)
SELECT Person.objectID,
	person.MaritalStatus,
	person.Ethnicity,
	person.Race,
	person.Nationality,
	person.Religion
FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HPerson AS Person
INNER JOIN #bedded_pts AS a ON person.objectid = a.patient_oid
WHERE person.isdeleted = 0
	AND person.isversioned = 1;

-- employment
DROP TABLE IF EXISTS #occupation;
	CREATE TABLE #occupation (
		person_oid INT, -- join to bedded_pts.patient_oid
		employment_stat VARCHAR(255)
		);

INSERT INTO #occupation (
	person_oid,
	employment_stat
	)
SELECT Occupation.Person_oid,
	Occupation.Jobstatus
FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HOccupation AS Occupation
INNER JOIN #bedded_pts AS a ON a.patient_oid = occupation.person_oid
WHERE Occupation.IsVersioned = 1
	AND Occupation.PresentOccupation = 1
	AND Occupation.IsPrimary = 1;

-- Guarantor
DROP TABLE IF EXISTS #guar;
	CREATE TABLE #guar (
		pt_id INT,
		last_msg_cntrl_id VARCHAR(255),
		guar_street_addr VARCHAR(255),
		guar_city VARCHAR(255),
		guar_zip_cd VARCHAR(255),
		guar_rel VARCHAR(255),
		guar_last_name VARCHAR(255),
		guar_first_name VARCHAR(255),
		guar_phone_area_city_cd VARCHAR(255),
		guar_phone_no VARCHAR(255),
		rn INT
		);

INSERT INTO #guar (
	pt_id,
	last_msg_cntrl_id,
	guar_street_addr,
	guar_city,
	guar_zip_cd,
	guar_rel,
	guar_last_name,
	guar_first_name,
	guar_phone_area_city_cd,
	guar_phone_no,
	rn
	)
SELECT guar.pt_id,
	guar.last_msg_cntrl_id,
	GUAR.guar_street_addr,
	GUAR.guar_city,
	GUAR.guar_zip_cd,
	guar.guar_rel,
	guar.guar_last_name,
	guar.guar_first_name,
	GUAR.guar_phone_area_city_cd,
	GUAR.guar_phone_no,
	[rn] = ROW_NUMBER() OVER (
		PARTITION BY GUAR.PT_ID ORDER BY ZZZ.EVNT_DTIME DESC
		)
FROM smsmir.hl7_guar AS guar
LEFT JOIN smsmir.hl7_msg_hdr AS zzz ON guar.last_msg_cntrl_id = zzz.msg_cntrl_id
INNER JOIN #bedded_pts AS b ON guar.pt_id = b.patientaccountid;

DELETE
FROM #guar
WHERE rn != 1;

-- Ins Info
DROP TABLE IF EXISTS #ins;
	CREATE TABLE #ins (
		pt_id VARCHAR(12),
		last_msg_cntrl_id VARCHAR(255),
		ins_plan_prio_no VARCHAR(5),
		ins_plan_no VARCHAR(255)
		);

INSERT INTO #ins (
	pt_id,
	last_msg_cntrl_id,
	ins_plan_prio_no,
	ins_plan_no
	)
SELECT INS.pt_id,
	ins.last_msg_cntrl_id,
	ins.ins_plan_prio_no,
	ins.ins_plan_no
FROM #guar AS GUAR
LEFT JOIN smsmir.hl7_ins AS INS ON GUAR.pt_id = INS.pt_id
	AND GUAR.last_msg_cntrl_id = INS.last_msg_cntrl_id
	AND INS.ins_plan_prio_no = 1;

DROP TABLE IF EXISTS #ins2;
	CREATE TABLE #ins2 (
		pt_id VARCHAR(12),
		last_msg_cntrl_id VARCHAR(255),
		ins_plan_prio_no VARCHAR(5),
		ins_plan_no VARCHAR(255)
		);

INSERT INTO #ins2 (
	pt_id,
	last_msg_cntrl_id,
	ins_plan_prio_no,
	ins_plan_no
	)
SELECT INS2.pt_id,
	ins2.last_msg_cntrl_id,
	ins2.ins_plan_prio_no,
	ins2.ins_plan_no
FROM #guar AS GUAR
LEFT JOIN smsmir.hl7_ins AS INS2 ON GUAR.pt_id = INS2.pt_id
	AND GUAR.last_msg_cntrl_id = INS2.last_msg_cntrl_id
	AND INS2.ins_plan_prio_no = 2;

DROP TABLE IF EXISTS #ins3;
	CREATE TABLE #ins3 (
		pt_id VARCHAR(12),
		last_msg_cntrl_id VARCHAR(255),
		ins_plan_prio_no VARCHAR(5),
		ins_plan_no VARCHAR(255)
		);

INSERT INTO #ins3 (
	pt_id,
	last_msg_cntrl_id,
	ins_plan_prio_no,
	ins_plan_no
	)
SELECT INS3.pt_id,
	ins3.last_msg_cntrl_id,
	ins3.ins_plan_prio_no,
	ins3.ins_plan_no
FROM #guar AS GUAR
LEFT JOIN smsmir.hl7_ins AS INS3 ON GUAR.pt_id = INS3.pt_id
	AND GUAR.last_msg_cntrl_id = INS3.last_msg_cntrl_id
	AND INS3.ins_plan_prio_no = 3;

-- First Ins
DROP TABLE IF EXISTS #first_ins;
	CREATE TABLE #first_ins (
		patient_visit_oid INT,
		ins_co_name VARCHAR(255),
		prim_subscriber_relation_to_pat VARCHAR(50),
		ins_plan VARCHAR(255),
		ins_policy VARCHAR(255),
		group_no VARCHAR(255),
		treatauth VARCHAR(255),
		streetaddress VARCHAR(255),
		city VARCHAR(255),
		postalcode VARCHAR(255),
		county VARCHAR(255)
		);

INSERT INTO #first_ins (
	patient_visit_oid,
	ins_co_name,
	prim_subscriber_relation_to_pat,
	ins_plan,
	ins_policy,
	group_no,
	treatauth,
	streetaddress,
	city,
	postalcode,
	county
	)
SELECT A.patient_visit_oid,
	FirstIns.InsCoName,
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
	FirstIns.InsPlan,
	FirstIns.[Policy],
	FirstIns.GroupNo,
	FirstIns.TreatAuth,
	FirstInsAddress.StreetAddress,
	FirstInsAddress.City,
	FirstInsAddress.PostalCode,
	FirstInsAddress.County
FROM #bedded_pts AS a
LEFT JOIN #ins AS ins ON a.patientaccountid = ins.pt_id
LEFT JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HInsuranceDetails AS FirstIns ON FirstIns.PatientVisit_oid = A.patient_visit_oid
	AND FirstIns.[Priority] = 1
	AND FirstIns.IsDeleted = 0
	AND FirstIns.InsPlan = INS.ins_plan_no
-- First Ins Subscriber Information
LEFT JOIN [SC_server].[Soarian_Clin_Prd_1].dbo.HAddress AS FirstInsAddress ON FirstIns.SubscriberAddress_oid = FirstInsAddress.ObjectID

-- Second Ins
DROP TABLE IF EXISTS #second_ins;
	CREATE TABLE #second_ins (
		patient_visit_oid INT,
		ins_co_name VARCHAR(255),
		second_subscriber_relation_to_pat VARCHAR(50),
		ins_plan VARCHAR(255),
		ins_policy VARCHAR(255),
		group_no VARCHAR(255),
		treatauth VARCHAR(255),
		streetaddress VARCHAR(255),
		city VARCHAR(255),
		postalcode VARCHAR(255),
		county VARCHAR(255)
		);

INSERT INTO #second_ins (
	patient_visit_oid,
	ins_co_name,
	second_subscriber_relation_to_pat,
	ins_plan,
	ins_policy,
	group_no,
	treatauth,
	streetaddress,
	city,
	postalcode,
	county
	)
SELECT A.patient_visit_oid,
	SecondIns.InsCoName,
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
	SecondIns.InsPlan,
	SecondIns.[Policy],
	SecondIns.GroupNo,
	SecondIns.TreatAuth,
	SecondInsAddress.StreetAddress,
	SecondInsAddress.City,
	SecondInsAddress.PostalCode,
	SecondInsAddress.County
FROM #bedded_pts AS a
LEFT JOIN #ins2 AS ins2 ON a.patientaccountid = ins2.pt_id
LEFT JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HInsuranceDetails AS SecondIns ON SecondIns.PatientVisit_oid = A.patient_visit_oid
	AND SecondIns.[Priority] = 2
	AND SecondIns.IsDeleted = 0
	AND SecondIns.InsPlan = INS2.ins_plan_no
-- First Ins Subscriber Information
LEFT JOIN [SC_server].[Soarian_Clin_Prd_1].dbo.HAddress AS SecondInsAddress ON SecondIns.SubscriberAddress_oid = SecondInsAddress.ObjectID;

-- Third Ins
DROP TABLE IF EXISTS #third_ins;
	CREATE TABLE #third_ins (
		patient_visit_oid INT,
		ins_co_name VARCHAR(255),
		tert_subscriber_relation_to_pat VARCHAR(50),
		ins_plan VARCHAR(255),
		ins_policy VARCHAR(255),
		group_no VARCHAR(255),
		treatauth VARCHAR(255),
		streetaddress VARCHAR(255),
		city VARCHAR(255),
		postalcode VARCHAR(255),
		county VARCHAR(255)
		);

INSERT INTO #third_ins (
	patient_visit_oid,
	ins_co_name,
	tert_subscriber_relation_to_pat,
	ins_plan,
	ins_policy,
	group_no,
	treatauth,
	streetaddress,
	city,
	postalcode,
	county
	)
SELECT A.patient_visit_oid,
	ThirdIns.InsCoName,
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
	ThirdIns.InsPlan,
	ThirdIns.[Policy],
	ThirdIns.GroupNo,
	ThirdIns.TreatAuth,
	ThirdInsAddress.StreetAddress,
	ThirdInsAddress.City,
	ThirdInsAddress.PostalCode,
	ThirdInsAddress.County
FROM #bedded_pts AS a
LEFT JOIN #ins3 AS ins3 ON a.patientaccountid = ins3.pt_id
LEFT JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HInsuranceDetails AS ThirdIns ON ThirdIns.PatientVisit_oid = A.patient_visit_oid
	AND ThirdIns.[Priority] = 3
	AND ThirdIns.IsDeleted = 0
	AND ThirdIns.InsPlan = INS3.ins_plan_no
-- First Ins Subscriber Information
LEFT JOIN [SC_server].[Soarian_Clin_Prd_1].dbo.HAddress AS ThirdInsAddress ON ThirdIns.SubscriberAddress_oid = ThirdInsAddress.ObjectID;

-- Mobile Phone
DROP TABLE IF EXISTS #mobile_phone;
	CREATE TABLE #mobile_phone (
		patient_visit_oid INT,
		person_oid INT,
		pat_mobile_ph VARCHAR(255)
		);

INSERT INTO #mobile_phone (
	patient_visit_oid,
	person_oid,
	pat_mobile_ph
	)
SELECT a.patient_visit_oid,
	MobilePhone.person_oid,
	[PAT_MOBILE_PH] = CAST(MobilePhone.PhoneAreaCode AS VARCHAR) + '-' + CAST(MobilePhone.PhoneNo AS VARCHAR)
FROM #bedded_pts AS a
INNER JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HAddress AS MobilePhone ON A.Patient_oid = MobilePHone.person_oid
	AND MobilePhone.IsVersioned = 1
	AND MobilePhone.AddressType = 2;

-- Email
DROP TABLE IF EXISTS #email;
	CREATE TABLE #email (
		patientaccountid INT,
		email VARCHAR(255)
		);

INSERT INTO #email (
	patientaccountid,
	email
	)
SELECT a.patientaccountid,
	email.UserDataText
FROM #bedded_pts AS a
INNER JOIN smsdss.BMH_UserTwoFact_V AS EMAIL ON EMAIL.PtNo_Num = A.PatientAccountID
	AND EMAIL.UserDataKey = '631';

-- Primary Care Provider
DROP TABLE IF EXISTS #pcp;
	CREATE TABLE #pcp (
		patient_visit_oid INT,
		patient_oid INT,
		[name] VARCHAR(255),
		msinumber INT,
		npi_no VARCHAR(255),
		relationtype VARCHAR(255)
		);

INSERT INTO #pcp (
	patient_visit_oid,
	patient_oid,
	[name],
	msinumber,
	npi_no,
	relationtype
	)
SELECT PCP.patientvisit_oid,
	PCP.Patient_oid,
	PCP.[name],
	PCP.msinumber,
	PCP.npi_no,
	PCP.relationtype
FROM #bedded_pts AS a
INNER JOIN (
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
	) AS PCP ON PCP.Patient_oid = A.patient_oid

DROP TABLE IF EXISTS #attending;
	CREATE TABLE #attending (
		patient_visit_oid INT,
		patient_oid INT,
		[name] VARCHAR(255),
		msinumber INT,
		npi_no VARCHAR(255),
		relationtype VARCHAR(255)
		);

INSERT INTO #attending (
	patient_visit_oid,
	patient_oid,
	[name],
	msinumber,
	npi_no,
	relationtype
	)
SELECT Attending.patientvisit_oid,
	Attending.Patient_oid,
	Attending.[name],
	Attending.msinumber,
	Attending.npi_no,
	Attending.relationtype
FROM #bedded_pts AS a
INNER JOIN (
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
	) AS Attending ON Attending.PatientVisit_oid = A.patient_visit_oid;

-- Admitting
DROP TABLE IF EXISTS #admitting;
	CREATE TABLE #admitting (
		patient_visit_oid INT,
		patient_oid INT,
		[name] VARCHAR(255),
		msinumber INT,
		npi_no VARCHAR(255),
		relationtype VARCHAR(255)
		);

INSERT INTO #admitting (
	patient_visit_oid,
	patient_oid,
	[name],
	msinumber,
	npi_no,
	relationtype
	)
SELECT Admitting.patientvisit_oid,
	Admitting.Patient_oid,
	Admitting.[name],
	Admitting.msinumber,
	Admitting.npi_no,
	Admitting.relationtype
FROM #bedded_pts AS a
INNER JOIN (
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
	) AS Admitting ON Admitting.PatientVisit_oid = A.patient_visit_oid;

-- Emergency Contact
DROP TABLE IF EXISTS #emcon;
	CREATE TABLE #emcon (
		patient_visit_oid INT,
		patient_oid INT,
		pat_contact_nm VARCHAR(255),
		pat_contact_ph VARCHAR(255),
		pat_contact_rel VARCHAR(255),
		pat_contact_addr VARCHAR(255)
		);

INSERT INTO #emcon (
	patient_visit_oid,
	patient_oid,
	pat_contact_nm,
	pat_contact_ph,
	pat_contact_rel,
	pat_contact_addr
	)
SELECT a.patient_visit_oid,
	EMCON.Patient_oid,
	EMCON.PAT_CONTACT_NM,
	emcon.PAT_CONTACT_PH,
	emcon.PAT_CONTACT_REL,
	emcon.PAT_CONTACT_ADDR
FROM #bedded_pts AS a
INNER JOIN (
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
	) AS EMCON ON A.Patient_oid = EMCON.Patient_oid;

-- Admit Source and Homeless?
DROP TABLE IF EXISTS #admit_src;
	CREATE TABLE #admit_src (
		patient_oid INT,
		patient_visit_oid INT,
		patientaccountid INT,
		adm_source VARCHAR(255),
		homeless VARCHAR(25)
		);

INSERT INTO #admit_src (
	patient_oid,
	patient_visit_oid,
	patientaccountid,
	adm_source,
	homeless
	)
SELECT A.patient_oid,
	A.patient_visit_oid,
	A.patientaccountid,
	AdmitSource.Finding,
	[HOMELESS] = CASE 
		WHEN AdmitSource.Finding = 'Homeless'
			THEN 'Y'
		ELSE 'N'
		END
FROM #bedded_pts AS a
INNER JOIN (
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
	) AS AdmitSource ON A.patient_visit_oid = AdmitSource.PatientVisitOID;

-- PHARMACY
DROP TABLE IF EXISTS #pharmacy;
	CREATE TABLE #pharmacy (
		patient_oid INT,
		patient_visit_oid INT,
		patientaccountid INT,
		pharmacy_name VARCHAR(255)
		);

INSERT INTO #pharmacy (
	patient_oid,
	patient_visit_oid,
	patientaccountid,
	pharmacy_name
	)
SELECT a.patient_oid,
	a.patient_visit_oid,
	a.patientaccountid,
	Pharmacy.PharmacyName
FROM #bedded_pts AS a
INNER JOIN (
	SELECT PP.PatientOID,
		P.PharmacyName
	FROM [SC_server].[Soarian_Clin_Prd_1].DBO.PatientPharmacy AS PP
	INNER JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.Pharmacy AS P ON PP.PharmacyOID = P.PharmacyOID
	INNER JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HPatient AS HP ON PP.PatientOID = HP.ObjectID
	WHERE P.PharmacyType = 0
	) AS Pharmacy ON Pharmacy.PatientOID = A.patient_oid;

-- pull together
SELECT [PAT_LAST_NM] = PT.last_name,
	[PAT_FIRST_NM] = PT.first_name,
	[DOB] = CAST(B.pt_birth_date AS DATE),
	[SEX] = B.pt_gender,
	[LICH_MRN] = B.pt_med_rec_no,
	[LICH_ACCT_NUMBER] = A.patientaccountid,
	[UPGRADED_ED_ACCT] = PreAdmit.UserDefinedNumeric1,
	[ED_ARRIVAL] = A.ed_arrival,
	[ADM_DT] = A.adm_dt,
	[ADM_TM] = A.adm_tm,
	[CUR_UNIT] = A.cur_unit,
	[CUR_ROOM] = A.cur_room,
	[CUR_ATTEND_CD] = Attending.msinumber,
	[CUR_ATTEND_NM] = Attending.[name],
	[ATTEND_NPI] = Attending.npi_no,
	[ADMIT_CD] = Admitting.msinumber,
	[ADMIT_NM] = Admitting.[name],
	[ADM_DIAG] = A.adm_diag,
	[SERVICE] = A.[service],
	[ADM_SOURCE] = AdmitSource.adm_source,
	[ADM_TYPE] = A.visittypecode,
	[PATIENT_TYPE] = A.accommodation_type,
	[PAT_MDL_NM] = PT.middle_name,
	[PREFERRED_NAME] = '',
	[EPIC_MRN] = '',
	[CUR_BED] = '',
	[ADMIT_NPI] = Admitting.npi_no,
	[REFERRING_CD] = '',
	[REFERRING_NM] = '',
	[REFERRING_NPI] = '',
	[TRANSF_FROM_HOSP] = '',
	[PAT_SSN] = b.pt_ssa_no,
	[PAT_ADDR1] = b.pt_street_addr,
	[PAT_CITY] = b.pt_city,
	[PAT_ST] = b.pt_state,
	[PAT_ZIP] = b.pt_zip_cd,
	[PAT_COUNTY] = '',
	[PAT_COUNTRY] = '',
	[PAT_PHONE] = '(' + CAST(B.pt_phone_area_city_cd AS VARCHAR) + ')' + ' ' + CAST(LEFT(B.PT_PHONE_NO, 3) AS VARCHAR) + '-' + CAST(RIGHT(B.PT_PHONE_NO, 4) AS VARCHAR),
	[PAT_WRK_PH] = '(' + CAST(B.bus_phone_area_city_cd AS VARCHAR) + ')' + ' ' + CAST(LEFT(B.bus_phone_no, 3) AS VARCHAR) + '-' + CAST(RIGHT(B.bus_phone_no, 4) AS VARCHAR),
	[PAT_MOBILE_PH] = MobilePhone.pat_mobile_ph,
	[EMAIL_ADDR] = EMAIL.email,
	[MOTHER_NAME] = B.mother_maiden_name,
	[COUNTRY_OF_ORIGIN] = '',
	[BIRTHPLACE] = '',
	[PREFERRED_LANG] = PT.primary_language,
	[MARTIAL_STAT] = Person.marital_stats,
	[ETHNICITY] = Person.Ethnicity,
	[RACE] = Person.Race,
	[NATIONALITY] = Person.Nationality,
	[RELIGION] = Person.Religion,
	[EMPLOYMENT_STAT] = Occupation.employment_stat,
	[PCP_NM] = PCP.[Name],
	[PCP_NPI] = PCP.npi_no,
	[PCP_ADDR] = '',
	[PAT_CONTACT_NM] = EMCON.PAT_CONTACT_NM,
	[PAT_CONTACT_PH] = EMCON.PAT_CONTACT_PH,
	[PAT_CONTACT_REL] = EMCON.PAT_CONTACT_REL,
	[PAT CONTACT ADDR] = EMCON.PAT_CONTACT_ADDR,
	[PREFERRED_PHARM] = Pharmacy.pharmacy_name,
	[PREFERRED_LAB] = '',
	[HOMELSS] = AdmitSource.homeless,
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
	[FC_PRIM_INS] = A.fc_prim_ins,
	[PRIM_CARRIER_NAME] = FirstIns.ins_co_name,
	[PRIM_SUBSCRIBER_RELATION_TO_PAT] = FirstIns.prim_subscriber_relation_to_pat,
	[PRIM_SUBSCRIBER_ADDR1] = FirstIns.streetaddress,
	[PRIM_SUBSCRIBER_CITY] = FirstIns.city,
	[PRIM_SUBSCRIBER_ZIP] = FirstIns.postalcode,
	[PRIM_SUBSCRIBER_COUNTY] = FirstIns.county,
	[PRIM_PLAN_CD] = FirstIns.ins_plan,
	[PRIM_INS_ID] = FirstIns.ins_policy,
	[PRIM_INS_GROUP] = FirstIns.group_no,
	[FC_SECND_INS] = (
		SELECT zzz.pyr_group2
		FROM smsdss.pyr_dim_v AS ZZZ
		WHERE SecondIns.ins_plan = ZZZ.src_pyr_cd
			AND ZZZ.orgz_cd = 's0x0'
		),
	[SECND_CARRIER_NM] = SecondIns.ins_co_name,
	[SECND_PLAN_NM] = '',
	[SECOND_SUBSCRIBER_RELATION_TO_PAT] = CASE 
		WHEN SecondIns.second_subscriber_relation_to_pat = '1'
			THEN 'SELF'
		WHEN SecondIns.second_subscriber_relation_to_pat = '2'
			THEN 'SPOUSE'
		WHEN SecondIns.second_subscriber_relation_to_pat = '3'
			THEN 'FATHER'
		WHEN SecondIns.second_subscriber_relation_to_pat = '4'
			THEN 'MOTHER'
		WHEN SecondIns.second_subscriber_relation_to_pat = '5'
			THEN 'STEP PARENT'
		WHEN SecondIns.second_subscriber_relation_to_pat = '6'
			THEN 'GRANDPARENT'
		WHEN SecondIns.second_subscriber_relation_to_pat = 'A'
			THEN 'POA'
		WHEN SecondIns.second_subscriber_relation_to_pat = 'B'
			THEN 'GUARDIAN'
		WHEN SecondIns.second_subscriber_relation_to_pat = 'C'
			THEN 'OTHER'
		ELSE SecondIns.second_subscriber_relation_to_pat
		END,
	[SECOND_SUBSCRIBER_ADDR1] = SecondIns.streetaddress,
	[SECOND_SUBSCRIBER_CITY] = SecondIns.City,
	[SECOND_SUBSCRIBER_ZIP] = SecondIns.postalcode,
	[SECOND_SUBSCRIBER_COUNTY] = SecondIns.County,
	[SECND_PLAN_CD] = SecondIns.ins_plan,
	[SECND_INS_ID] = SecondIns.ins_policy,
	[SECND_INS_GROUP] = SecondIns.group_no,
	[FC_TERT_INS] = (
		SELECT ZZZ.PYR_GROUP2
		FROM smsdss.pyr_dim_v AS ZZZ
		WHERE ThirdIns.ins_plan = ZZZ.src_pyr_cd
			AND ZZZ.orgz_cd = 's0x0'
		),
	[TERT_CARRIER_NM] = ThirdIns.ins_co_name,
	[TERT_PLAN_NM] = '',
	[TERT_SUBSCRIBER_RELATION_TO_PAT] = CASE 
		WHEN ThirdIns.tert_subscriber_relation_to_pat = '1'
			THEN 'SELF'
		WHEN ThirdIns.tert_subscriber_relation_to_pat = '2'
			THEN 'SPOUSE'
		WHEN ThirdIns.tert_subscriber_relation_to_pat = '3'
			THEN 'FATHER'
		WHEN ThirdIns.tert_subscriber_relation_to_pat = '4'
			THEN 'MOTHER'
		WHEN ThirdIns.tert_subscriber_relation_to_pat = '5'
			THEN 'STEP PARENT'
		WHEN ThirdIns.tert_subscriber_relation_to_pat = '6'
			THEN 'GRANDPARENT'
		WHEN ThirdIns.tert_subscriber_relation_to_pat = 'A'
			THEN 'POA'
		WHEN ThirdIns.tert_subscriber_relation_to_pat = 'B'
			THEN 'GUARDIAN'
		WHEN ThirdIns.tert_subscriber_relation_to_pat = 'C'
			THEN 'OTHER'
		ELSE ThirdIns.tert_subscriber_relation_to_pat
		END,
	[TERT_SUBSCRIBER_ADDR1] = ThirdIns.streetaddress,
	[TERT_SUBSCRIBER_CITY] = ThirdIns.City,
	[TERT_SUBSCRIBER_ZIP] = ThirdIns.postalcode,
	[TERT_SUBSCRIBER_COUNTY] = ThirdIns.County,
	[TERT_PLAN_CD] = ThirdIns.ins_plan,
	[TERT_INS_ID] = ThirdIns.[ins_policy],
	[TERT_INS_GROUP] = ThirdIns.group_no,
	[VISIT_GUARANTOR_ACCT_TYPE] = '',
	[AUTHORIZATION_NUMBER] = FirstIns.TreatAuth,
	[AUTH_START_DT] = '',
	[AUTH_END_DT] = '',
	[ADM_UNIT] = '',
	[ADM_ROOM] = '',
	[ADM_BED] = '',
	[NO_FAULT_ITEMS] = '',
	[HIE] = PT.hie,
	[HIPPA] = '',
	[ADVANCE_DIRECTIVE] = PT.advance_directive,
	[NOPP] = '',
	[PROVIDER_TEAM] = '',
	[query_rundtime] = GETDATE()
INTO smsdss.c_adt_bedded_tbl
FROM #bedded_pts AS a
LEFT JOIN #patient AS pt ON a.patient_oid = pt.patient_oid
LEFT JOIN SMSMIR.HL7_PT AS B ON A.PATIENTACCOUNTID = B.pt_id
LEFT JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HExtendedPatientVisit AS PreAdmit ON A.PatientVisitExtension_oid = PreAdmit.ObjectID
	AND A.VisitEndDateTime IS NULL
	AND A.cur_unit <> ''
	AND A.IsDeleted = 0
LEFT JOIN #attending AS Attending ON A.patient_visit_oid = Attending.patient_visit_oid
LEFT JOIN #admitting AS Admitting ON A.patient_visit_oid = Admitting.patient_visit_oid
LEFT JOIN #admit_src AS AdmitSource ON A.patient_visit_oid = AdmitSource.patient_visit_oid
LEFT JOIN #mobile_phone AS MobilePhone ON A.patient_visit_oid = MobilePhone.patient_visit_oid
LEFT JOIN #email AS EMAIL ON A.patientaccountid = EMAIL.patientaccountid
LEFT JOIN #person AS Person ON A.patient_oid = Person.patient_oid
LEFT JOIN #occupation AS Occupation ON A.patient_oid = Occupation.person_oid
LEFT JOIN #pcp AS PCP ON A.patient_oid = PCP.patient_oid
LEFT JOIN #emcon AS EMCON ON A.patient_visit_oid = EMCON.patient_visit_oid
LEFT JOIN #pharmacy AS Pharmacy ON A.patient_visit_oid = Pharmacy.patient_visit_oid
LEFT JOIN #guar AS GUAR ON A.patientaccountid = GUAR.pt_id
LEFT JOIN #first_ins AS FirstIns ON A.patient_visit_oid = FirstIns.patient_visit_oid
LEFT JOIN #second_ins AS SecondIns ON A.patient_visit_oid = SecondIns.patient_visit_oid
LEFT JOIN #third_ins AS ThirdIns ON A.patient_visit_oid = ThirdIns.patient_visit_oid;

SELECT *
FROM smsdss.c_adt_bedded_tbl;