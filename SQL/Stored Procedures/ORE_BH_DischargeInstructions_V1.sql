USE [Soarian_Clin_Tst_1]
GO

/****** Object:  StoredProcedure [dbo].[ORE_BH_DischargeInstructions_V1]    Script Date: 3/2/2020 9:08:24 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*****************************************************************************
File: ORE_BH_DischargeInstructions.sql      

Input  Parameters:  
    @Patient_oid
    @Visit_oid
	@AssessmentID
Tables: 
    HAssessment
	HAssessmentCategory 
	HObservation
    HOrder
	HPatient  
	HPatientVisit
	HPatientIdentifiers

Functions: 
	fn_ORE_GetPhysicianName

Author: Steve P Sanderson II, MPH

Department: Finance, Revenue Cycle
      
Revision History: 
Date		Version		Description
----		----		----
2020-03-02	v1			Initial Creation - ADDED PCP
-------------------------------------------------------------------------------- 
*/

ALTER PROC [dbo].[ORE_BH_DischargeInstructions_V1]
	-- Input parameters
	@HSF_CONTEXT_PATIENTID VARCHAR(20),
	@VisitOID VARCHAR(20)
AS
SET NOCOUNT ON

-- Local variable declaration
DECLARE @intPatient_oid INTEGER,
	@intVisit_oid INTEGER,
	@AssessmentID INTEGER

SET @intPatient_oid = @HSF_CONTEXT_PATIENTID
SET @intVisit_oid = @VisitOID

-- Get latest DI Assessment
-- Base Patient Information ********************************************************************
-- Declare Base Patient temp table 
DECLARE @tblPatTemp TABLE (
	Patient_oid INTEGER,
	PatientVisit_oid INTEGER,
	PatientReasonforSeekingHC VARCHAR(1500),
	LastName VARCHAR(100),
	FirstName VARCHAR(100),
	PatientName VARCHAR(184),
	PatientAccountID VARCHAR(30),
	PatientLocationName VARCHAR(75),
	LatestBedName VARCHAR(75),
	VisitStartDateTime DATETIME,
	MedicalRecordNumber VARCHAR(30),
	EntityName VARCHAR(50),
	BirthDate DATETIME,
	Age VARCHAR(5),
	Sex VARCHAR(10),
	CID VARCHAR(30),
	AttendDr VARCHAR(184)
	)

INSERT INTO @tblPatTemp (
	Patient_oid,
	PatientVisit_oid,
	PatientReasonforSeekingHC,
	LastName,
	FirstName,
	PatientName,
	PatientAccountID,
	PatientLocationName,
	LatestBedName,
	VisitStartDateTime,
	MedicalRecordNumber,
	EntityName,
	BirthDate,
	Age,
	Sex,
	CID,
	--Allergies, 
	AttendDr
	)
SELECT PT.ObjectID,
	PV.ObjectID,
	PV.PatientReasonforSeekingHC,
	LastName = PT.LastName,
	FirstName = PT.FirstName,
	PatientName = CASE ISNULL(pt.GenerationQualifier, '')
		WHEN ''
			THEN PT.LastName + ', ' + PT.FirstName + ' ' + ISNULL(SUBSTRING(PT.MiddleName, 1, 1), ' ')
		ELSE PT.LastName + ' ' + PT.GenerationQualifier + ', ' + PT.FirstName + ' ' + ISNULL(SUBSTRING(PT.MiddleName, 1, 1), ' ')
		END,
	PV.PatientAccountID,
	PV.PatientLocationName,
	PV.LatestBedName,
	PV.VisitStartDateTime,
	MedicalRecordNumber = PID.Value,
	PV.EntityName,
	BirthDate = convert(VARCHAR(10), per.BirthDate, 101),
	Age = (.dbo.fn_ORE_GetPatientAge(PER.BirthDate, getdate())),
	Sex = cast(CASE per.Sex
			WHEN 0
				THEN 'Male'
			WHEN 1
				THEN 'Female'
			ELSE ' '
			END AS CHAR(6)),
	CID = PID2.Value,
	AttendDr = isnull(.dbo.fn_ORE_GetPhysicianName(pv.ObjectID, 0, 6), '')
FROM HPatient PT WITH (NOLOCK)
INNER JOIN HPatientVisit PV WITH (NOLOCK) ON PT.ObjectID = PV.Patient_oid
INNER JOIN HPerson PER WITH (NOLOCK) ON PT.ObjectID = PER.ObjectID
INNER JOIN HPatientIdentifiers PID WITH (NOLOCK) ON PID.EntityOID = PV.Entity_oid
	AND PID.Patient_oid = PV.Patient_oid
	AND PID.IsDeleted = 0
	AND PID.Type = 'MR'
LEFT OUTER JOIN HPatientIdentifiers PID2 WITH (NOLOCK) ON PID2.Patient_oid = PT.ObjectID
	AND PID2.IsDeleted = 0
	AND PID2.Type = 'MPI'
WHERE PV.IsDeleted = 0
	AND PT.ObjectID = @intPatient_oid
	AND PV.ObjectID = @intVisit_oid

DECLARE @Allergies TABLE (
	Patient_oid INT,
	Allergy VARCHAR(1000)
	)

----------------------------------------------------------------
-- Get patient allergies
----------------------------------------------------------------
INSERT INTO @Allergies
SELECT pt.Patient_oid,
	Allergy = isnull(hpa.AlgName, '') + ' ' + CASE 
		WHEN hpa.AlgCategoryName IS NULL
			OR hpa.AlgCategoryName = ''
			THEN ''
		ELSE CASE 
				WHEN hpa.AlgName IN ('No Known Allergies', 'No Known Drug Allergies', 'No Known Food Allergies')
					THEN ''
				ELSE '(' + hpa.AlgCategoryName + ')'
				END
		END
FROM @tblPatTemp pt
LEFT OUTER JOIN HPtAllergy hpa WITH (NOLOCK) ON pt.Patient_oid = hpa.PatientOID
LEFT OUTER JOIN HPtAllergyReaction hpr WITH (NOLOCK) ON hpa.ObjectID = hpr.AllergyOID
	AND hpr.IsLatest = 1
	AND hpr.IsRemoved = 0
WHERE hpa.IsLatest = 1
	AND hpa.AlgStatusCode = 'C'
	AND hpa.Patientoid = @intPatient_oid
ORDER BY hpa.AlgName ASC
OPTION (FORCE ORDER)

DECLARE @AlgPivot TABLE (
	Patient_oid INT,
	Allergies VARCHAR(1000)
	)

INSERT INTO @AlgPivot
SELECT t1.Patient_oid,
	AllergyList = substring((
			SELECT (', ' + Allergy)
			FROM @Allergies t2
			WHERE t1.Patient_oid = t2.Patient_oid
			ORDER BY Patient_oid,
				Allergy
			FOR XML PATH('')
			), 3, 1000)
FROM @Allergies t1
GROUP BY Patient_oid

--********************************************************************************************
-- Get Orders for DI
--********************************************************************************************
DECLARE @tblOrders TABLE (
	Patient_oid INTEGER,
	PatientVisit_oid INTEGER,
	CreationTime DATETIME,
	StartDateTime DATETIME,
	RequestedBy VARCHAR(1500),
	OrderAbbreviation VARCHAR(20),
	OrderDescAsWritten VARCHAR(2000),
	DCOrderComment VARCHAR(1500),
	DCDiagnosis VARCHAR(max)
	)

INSERT INTO @tblOrders
SELECT ho.Patient_oid,
	ho.PatientVisit_oid,
	ho.CreationTime,
	StartDateTime,
	ho.RequestedBy,
	ho.OrderAbbreviation,
	ho.OrderDescAsWritten,
	hoe.UserDefinedString8,
	hoe.UserDefinedString16
FROM HOrder ho WITH (NOLOCK)
LEFT OUTER JOIN HExtendedOrder hoe WITH (NOLOCK) ON ho.ExtendedOrder_oid = hoe.ObjectID
WHERE Patient_oid = @intPatient_oid
	AND PatientVisit_oid = @intVisit_oid
	AND OrderAbbreviation IN ('ADTDCIf', 'ADTDCHome')

-- Get Discharge Order
DECLARE @tblDschOrder TABLE (
	Patient_oid INTEGER,
	PatientVisit_oid INTEGER,
	CreationTime DATETIME,
	RequestedBy VARCHAR(1500),
	DischargeOrder VARCHAR(2000),
	DCOrderComment VARCHAR(1500),
	DCDiagnosis VARCHAR(max)
	)

INSERT INTO @tblDschOrder
SELECT Patient_oid,
	PatientVisit_oid,
	CreationTime,
	RequestedBy,
	DischargeOrd = CASE 
		WHEN charindex('; Physician/Resident', OrderDescAsWritten, 1) > 0
			THEN Left(OrderDescAsWritten, charindex('; Physician/Resident', OrderDescAsWritten, 1))
		ELSE OrderDescAsWritten
		END,
	DCOrderComment,
	DCDiagnosis
FROM (
	SELECT Patient_oid,
		PatientVisit_oid,
		CreationTime,
		RequestedBy,
		OrderDescAsWritten,
		DCOrderComment,
		DCDiagnosis,
		row_number() OVER (
			PARTITION BY OrderAbbreviation ORDER BY CreationTime DESC
			) rn
	FROM @tblOrders
	WHERE OrderAbbreviation IN ('ADTDCIf', 'ADTDCHome')
	) AS x
WHERE x.rn = 1;

-- Get Code Status
--DECLARE @CodeStatus VARCHAR(1500)
--Set @CodeStatus	=
--(SELECT OrderDescAsWritten
--FROM (select Patient_oid, PatientVisit_oid, OrderDescAsWritten, StartDateTime, OrderAbbreviation,
--	  row_number() over(partition by OrderAbbreviation order by StartDateTime desc) rn
--	  from @tblOrders 
----WHERE OrderAbbreviation  = 'CODE0001'
--) as x
--where x.rn = 1);
--********************************************************************************************
-- DI Assessment Into
--********************************************************************************************
DECLARE @tblDCInst TABLE (
	AssessmentID INTEGER,
	Patient_oid INTEGER,
	PatientVisit_oid INTEGER,
	FormUsage VARCHAR(1000),
	UserAbbrName VARCHAR(1000),
	CollectedDT DATETIME,
	FindingAbbr VARCHAR(20),
	Value VARCHAR(1500)
	)

INSERT INTO @tblDCInst (
	AssessmentID,
	Patient_oid,
	PatientVisit_oid,
	FormUsage,
	UserAbbrName,
	CollectedDT,
	FindingAbbr,
	Value
	)
SELECT x.AssessmentID,
	x.Patient_oid,
	x.PatientVisit_oid,
	x.FormUsage,
	x.UserAbbrName,
	x.CollectedDT,
	HO.FindingAbbr,
	REPLACE(HO.Value, CHAR(30), ', ')
FROM (
	SELECT AssessmentID,
		Patient_oid,
		PatientVisit_oid,
		FormUsage,
		UserAbbrName,
		CollectedDT,
		row_number() OVER (
			PARTITION BY FormUsage ORDER BY CreationTime DESC
			) rn
	FROM HAssessment WITH (NOLOCK)
	WHERE Patient_oid = @intPatient_oid
		AND PatientVisit_oid = @intVisit_oid
		AND FormUsageDisplayName = 'Discharge Instructions'
		AND AssessmentStatusCode IN (1, 3)
		AND EndDT IS NULL
	) AS x
LEFT OUTER JOIN HObservation HO WITH (NOLOCK) ON HO.Patient_oid = @intPatient_oid
	AND x.AssessmentID = HO.AssessmentID
	AND HO.EndDT IS NULL
WHERE x.rn = 1;

SELECT *
INTO #Temp_Final
FROM (
	SELECT *
	FROM @tblDCInst
	Pivot(Max(Value) FOR FindingAbbr IN (
				--Header Info 
				-- Vaccinations
				--Diagnosis/My Medical Problem:  
				-- [UserDefinedString16],
				--Follow up Appointements				-- CHANGED
				[M_DCFUP1], [M_DCFUPDateTime1], [M_DCFUPtCall1], [M_DCFUP2], [M_DCFUPDateTime2], [M_DCFUPtCall2], [M_DCFUP3], [M_DCFUPDateTime3], [M_DCFUPtCall3], [M_DCFUP4], [M_DCFUPDateTime4], [M_DCFUPtCall4], [M_DCFUP5], [M_DCFUPDateTime5], [M_DCFUPtCall5], [M_DCFUP6], [M_DCFUPDateTime6], [M_DCFUPtCall6], [M_DCFUP7], [M_DCFUPDateTime7], [M_DCFUPtCall7], [M_DCFUP8], [M_DCFUPDateTime8], [M_DCFUPtCall8], [M_DCFUPComm],
				--Diet
				[M_DischargeDiet], [M_DCDischDietOth], -- CHANGED
				--Activity/Restrictions
				[M_Disch Activity], [M_DCDischActOth], -- CHANGED
				--Fever/chills, Vision Change, Dizziness, Confusion
				[M_CallWorse], [M_DCAddSymp],
				--Follow-up tests after discharge???
				[M_FUPDischarge], [M_DCFUPTest], [M_DCFUPAdd(Spec)],
				--Pending Test Results
				[In progress lab orders (Service Type Laboratory)],
				--Misc Wound Care/Incision Instructions
				[M_DCWoundCare], [M_WCFocusDCInst],
				--Misc Medication Instruction --Hold Warfarin for 3 days
				[M_DCMiscMed], [M_DCMiscMedSpec],
				--Misc Other Instruction Please keep all your follow-up appointments listed
				[M_DCMiscOther], [M_DCMiscOthSpec],
				--Diabetes Management Instructions
				[M_DEFocusDCInst],
				--If you smoke or Use Tobacco
				[A_Tobacco?],
				-- Care Management Discharge Instructions for Patient
				[M_CMFocusDCInst],
				--Home Health Agencies (w/phone and fax numbers)
				[M_CMFocusHHAgen], [M_CMFocusHHOth],
				--	Hospice Agencies (w/phone and fax numbers)
				[M_CMFocusHospice], [M_CMFocusHospOth],
				--Durable Medical Equipment (w/phone and fax numbers) 
				[M_DCFocusDMEAgen], [M_CMFocusDMEOth],
				--Durable Medical Equipment Type
				[M_CMFocusDMEType], [M_CMFocDMETypOth],
				--Intravenous Infusion (w/phone and fax numbers)
				[M_CMFocusHmInf], [M_CMFocusHInfOth],
				--External Facilities (w/phone and fax numbers)
				[M_CMFocusExtFac], [M_CMFocsExtFacOt],
				--** External Health Resource: 
				[M_CMFocExtHlhRes],
				--**External Resource Name: 
				[M_CMFocEHResName],
				--Personal Care Providers (w/phone and fax numbers)
				[M_CMFocusPersCar], [M_CMFocsPrsCPOth],
				--Wound Care Clinics (w/phone and fax numbers)
				[M_CMFocusWdClin], [M_CMFocusdWdCOth]
				)) AS P
	) pl

-- Retrive Immunization Status
DECLARE @tblImmun TABLE (
	FindingAbbr VARCHAR(64),
	Value VARCHAR(3000),
	patient_oid INT
	)

INSERT INTO @tblImmun
SELECT FindingAbbr,
	Value,
	patient_oid
FROM (
	SELECT FindingAbbr,
		Value,
		patient_oid,
		row_number() OVER (
			PARTITION BY FindingAbbr ORDER BY StartDT DESC
			) rn
	FROM HObservation WITH (NOLOCK)
	WHERE Patient_oid = @HSF_CONTEXT_PATIENTID
		AND FindingAbbr IN ('A_InfluenzaImmun', 'A_InfluenzaImDt', 'A_Pneumo Immun', 'A_Pneum Im Dt')
	) AS x
WHERE x.rn = 1;

--Diagnosis
--Declare @diagnosis varchar(max)
--Select @diagnosis =  HExtendedOrder.UserDefinedString22 
--From HOrder HOrder with(nolock)       
-- Inner JOIN HExtendedOrder HExtendedOrder WITH ( NOLOCK )
-- ON HExtendedOrder.ObjectID = HOrder.ExtendedOrder_OID
-- Where HOrder.Patient_oid = @HSF_CONTEXT_PATIENTID
CREATE TABLE #Imm_Final (
	InfluenzaImmun VARCHAR(100),
	InfluenzaImmunDt VARCHAR(100),
	PneumoImmun VARCHAR(100),
	PneumoImmunDt VARCHAR(100),
	patient_oid VARCHAR(100)
	)

INSERT INTO #Imm_Final
SELECT DISTINCT InfluenzaImmun = t1.Value,
	InfluenzaImmunDt = t2.Value,
	PneumoImmun = t3.Value,
	PneumoImmunDt = t4.Value,
	t.patient_oid
FROM @tblImmun t
LEFT OUTER JOIN @tblImmun t1 ON t.patient_oid = t1.patient_oid
	AND t1.FindingAbbr = 'A_InfluenzaImmun'
LEFT OUTER JOIN @tblImmun t2 ON t.patient_oid = t2.patient_oid
	AND t2.FindingAbbr = 'A_InfluenzaImDt'
LEFT OUTER JOIN @tblImmun t3 ON t.patient_oid = t3.patient_oid
	AND t3.FindingAbbr = 'A_Pneumo Immun'
LEFT OUTER JOIN @tblImmun t4 ON t.patient_oid = t4.patient_oid
	AND t4.FindingAbbr = 'A_Pneum Im Dt'

SELECT TOP 1 UserDefinedString22,
	HO.Patient_oid,
	UserDefinedString23,
	HO.CreationTime
INTO #DCDiagnosis
FROM HOrder HO WITH (NOLOCK)
INNER JOIN HExtendedOrder HEO WITH (NOLOCK) ON HO.ExtendedOrder_oid = HEO.ObjectID
WHERE HO.Patient_oid = @intPatient_oid
ORDER BY HO.CreationTime DESC

DECLARE @Nurseprovider VARCHAR(100),
	@OrderDescAsWritten VARCHAR(max)

SELECT TOP 1 @Nurseprovider = UserAbbrName
FROM HAssessment WITH (NOLOCK)
WHERE Patient_oid = @intPatient_oid
	AND PatientVisit_oid = @intVisit_oid
ORDER BY CreationTime DESC

SELECT TOP 1 @OrderDescAsWritten = OrderDescAsWritten
FROM Horder
WHERE Patient_oid = @intPatient_oid
	AND PatientVisit_oid = @intVisit_oid
	AND ordertypeabbr = 'Laboratory'
	AND OrderStatusModifier = 'In progress'
ORDER BY EnteredDateTime DESC

---------------------------
--INSERT INTO @tblFormUsageNames 
--	 (FormUsageNames)
--	 SELECT DISTINCT * FROM fn_GetStrParmTable('Physician Discharge Instructions')
--Declare @AssessmentID   int	 	 
--Set @AssessmentID = 
--(select top 1 a.AssessmentID  
--	 from HAssessment a 
--	 where a.Patient_oid = @HSF_CONTEXT_PATIENTID 
--and a.PatientVisit_oid = @VisitOID  
--AND A.FormUsageDisplayName ='Physician Discharge Instructions' ) 	  	 
DECLARE @UserAbbrName VARCHAR(100),
	@collectedDt DATETIME

SELECT TOP 1 @UserAbbrName = ha.UserAbbrName,
	@collectedDt = ha.CollectedDT
FROM HAssessment ha
INNER JOIN HAssessmentCategory hac ON ha.AssessmentID = hac.AssessmentID
	AND ha.Patient_oid = @HSF_CONTEXT_PATIENTID
	AND ha.PatientVisit_oid = @VisitOID
WHERE ha.FormUsageDisplayName = 'Physician Discharge Instructions'
	AND hac.FormUsageDisplayName IN ('Physician Discharge Instructions')
	AND hac.CategoryStatus NOT IN (0, 3)
	AND hac.IsLatest = 1
	AND hac.FormVersion IS NOT NULL
	AND ha.AssessmentStatus = 'Complete'
ORDER BY ha.CollectedDT DESC

---------------------------
-- added ssanderson 2018-07-06
DECLARE @UDS15_16 TABLE (
	Patient_OID INTEGER,
	PatientExtension_OID INTEGER,
	PatientVisit_OID INTEGER,
	PatientVisitExtension_OID INTEGER,
	UDS15 VARCHAR(3000),
	UDS16 VARCHAR(3000)
	)

INSERT INTO @UDS15_16
SELECT TOP 1 Patient_oid = HP.ObjectID,
	PatientExtension_oid = HP.PatientExtension_oid,
	PatientVisit_oid = HPV.ObjectID,
	PatientVisitExtension_oid = HPV.PatientVisitExtension_oid,
	HEP.UserDefinedString15
	--, HEP.UserDefinedString16
	,
	CAST(SUBSTRING(HEP.UserDefinedString16, 1, 2) + '-' + SUBSTRING(hep.userdefinedstring16, 3, 2) + '-' + substring(hep.userdefinedstring16, 5, 4) AS DATE) AS [UDS_Date]
FROM HPatient AS HP
INNER JOIN HPatientVisit AS HPV ON HP.ObjectID = HPV.Patient_oid
	AND HP.RecordId = HPV.RecordId
INNER JOIN HExtendedPatient AS HEP ON HP.PatientExtension_oid = HEP.ObjectID
	AND HP.RecordId = HEP.RecordId
WHERE HP.ObjectID = @intPatient_oid
	AND HPV.ObjectID = @intVisit_oid;

-- Get PCP
DECLARE @PCP_TBL TABLE (
	Patient_OID INTEGER,
	PCP_First VARCHAR(100),
	PCP_Middle VARCHAR(100),
	PCP_Last VARCHAR(100),
	PCP_Title VARCHAR(100)
	)

INSERT INTO @PCP_TBL
SELECT T1.Patient_oid,
	--t1.ObjectID ,
	--t1.InstanceHFCID,
	--t1.RecordID,
	--t1.RelationType,
	t2.FirstName,
	t2.MiddleName,
	t2.LastName,
	t2.Title
FROM HStaffAssociations t1 -- this table holds the current active associations a staff has with a patient. The Relationtype for the PCP = 1. 
INNER JOIN HStaff t3 ON t3.ObjectID = t1.Staff_oid -- HStaffAssociations holds the Staff_oid and needs to be join with the HStaff table. 
INNER JOIN HName t2 ON t3.ObjectID = t2.Person_oid -- The Staff_oid actually equals the Person_oid and is joined with the HName table to get the PCP's current name.
	AND (
		EndDateOfValidity IS NULL
		OR EndDateOfValidity = '1899-12-30 00:00:00'
		) -- If the Staff's name has changed, then they may have multiple entries in this table so we are looking for the 
	-- current name
	AND t1.EndDate IS NULL
WHERE (
		t1.Patient_oid = @HSF_CONTEXT_PATIENTID
		AND t1.RelationType = '1'
		)

SELECT DISTINCT PatientReasonforSeekingHC,
	LastName,
	FirstName,
	PatientName,
	PatientAccountID,
	PatientLocationName,
	LatestBedName,
	VisitStartDateTime,
	MedicalRecordNumber,
	EntityName,
	BirthDate,
	Age,
	Sex,
	CID,
	AttendDr,
	--Allergies, 
	A.Allergies,
	Imm.InfluenzaImmun,
	Imm.InfluenzaImmunDt,
	Imm.PneumoImmun,
	Imm.PneumoImmunDt,
	t2.*,
	Appt1 = ISNULL(t2.M_DCFUP1, '') + '   ' + ISNULL(CAST(Convert(DATETIME, t2.M_DCFUPDateTime1, 109) AS VARCHAR(100)), '') + '   ' + ISNULL(t2.M_DCFUPtCall1, ''),
	Appt2 = ISNULL(t2.M_DCFUP2, '') + '   ' + ISNULL(CAST(Convert(DATETIME, t2.M_DCFUPDateTime2, 109) AS VARCHAR(100)), '') + '   ' + ISNULL(t2.M_DCFUPtCall2, ''),
	Appt3 = ISNULL(t2.M_DCFUP3, '') + '   ' + ISNULL(CAST(Convert(DATETIME, t2.M_DCFUPDateTime3, 109) AS VARCHAR(100)), '') + '   ' + ISNULL(t2.M_DCFUPtCall3, ''),
	Appt4 = ISNULL(t2.M_DCFUP4, '') + '   ' + ISNULL(CAST(Convert(DATETIME, t2.M_DCFUPDateTime4, 109) AS VARCHAR(100)), '') + '   ' + ISNULL(t2.M_DCFUPtCall4, ''),
	Appt5 = ISNULL(t2.M_DCFUP5, '') + '   ' + ISNULL(CAST(Convert(DATETIME, t2.M_DCFUPDateTime5, 109) AS VARCHAR(100)), '') + '   ' + ISNULL(t2.M_DCFUPtCall5, ''),
	Appt6 = ISNULL(t2.M_DCFUP6, '') + '   ' + ISNULL(CAST(Convert(DATETIME, t2.M_DCFUPDateTime6, 109) AS VARCHAR(100)), '') + '   ' + ISNULL(t2.M_DCFUPtCall6, ''),
	Appt7 = ISNULL(t2.M_DCFUP7, '') + '   ' + ISNULL(CAST(Convert(DATETIME, t2.M_DCFUPDateTime7, 109) AS VARCHAR(100)), '') + '   ' + ISNULL(t2.M_DCFUPtCall7, ''),
	Appt8 = ISNULL(t2.M_DCFUP8, '') + '   ' + ISNULL(CAST(Convert(DATETIME, t2.M_DCFUPDateTime8, 109) AS VARCHAR(100)), '') + '   ' + ISNULL(t2.M_DCFUPtCall8, ''),
	diagnosis = ISNULL(DCD.UserDefinedString22, ''),
	Provider = @UserAbbrName, --(Select top 1 Staffsignature from HStaff where objectid  = DCD.UserDefinedString23),
	CollectedDt_Phy = @collectedDt,
	NurseProvider = @Nurseprovider,
	PendingOrdersAtDischarge = @OrderDescAsWritten
	-- added ssanderson 2018-07-06
	,
	uds.UDS15,
	uds.UDS16,
	PCP.PCP_First,
	PCP.PCP_Middle,
	PCP.PCP_Last,
	PCP.PCP_Title
FROM @tblPatTemp t1
LEFT OUTER JOIN #Temp_Final t2 ON t1.Patient_oid = t2.Patient_oid
	AND t1.PatientVisit_oid = t2.PatientVisit_oid
LEFT OUTER JOIN @AlgPivot A ON A.Patient_oid = t1.Patient_oid
LEFT OUTER JOIN #Imm_Final Imm ON Imm.patient_oid = t1.Patient_oid
LEFT OUTER JOIN #DCDiagnosis DCD ON DCD.Patient_oid = t2.Patient_oid
--Left outer join #Tmp_Order tord
--on tord.patient_oid = t1.Patient_oid
--and tord.PatientVisit_oid = t1.PatientVisit_oid
-- added ssanderson 2018-07-06
LEFT OUTER JOIN @UDS15_16 AS uds ON t1.Patient_oid = uds.Patient_OID
	AND t1.PatientVisit_oid = uds.PatientVisit_OID
LEFT OUTER JOIN @PCP_TBL AS PCP ON T1.Patient_oid = PCP.Patient_OID
