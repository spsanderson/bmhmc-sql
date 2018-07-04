USE [Soarian_Clin_Tst_1]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
*****************************************************************************  
File: ORE_BH_DischargeInstructions.sql      

Input  Parameters:
	@Patient_oid  
    @Visit_oid  
	@AssessmentID NOT USED

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
2018-07-03	v1			Initial Creation
-------------------------------------------------------------------------------- 
*/

CREATE PROCEDURE [dbo].[ORE_BH_DischargeInstructions_test_sp]  
	-- Input parameters  
	@HSF_CONTEXT_PATIENTID VARCHAR(20),  
	@VisitOID VARCHAR(20)  
AS  

SET NOCOUNT ON
-- Local variable declaration  
DECLARE @intPatient_oid INTEGER;
DECLARE @intVisit_oid  INTEGER;  
DECLARE @AssessmentID INTEGER;

SET @intPatient_oid = @HSF_CONTEXT_PATIENTID
SET @intVisit_oid = @VisitOID

-- Get Latest Discharge Instuction Assessment
-- Base Patient Information
-- Declare Base Patient Temp Table
DECLARE @tblPatTemp TABLE (
	Patient_oid INTEGER
	, PatientVisit_oid INTEGER
	, PatientReasonforSeekingHC VARCHAR(1500)
	, LastName VARCHAR(100)
	, FirstName VARCHAR(100)
	, PatientName VARCHAR(184)
	, PatientAccountID VARCHAR(30)
	, PatientLocationName VARCHAR(75)
	, LatestBedName VARCHAR(75)
	, VisitStartDateTime DATETIME
	, MedicalRecordNumber VARCHAR(30)
	, EntityName VARCHAR(50)
	, BirthDate DATETIME
	, Age VARCHAR(5)
	, Sex VARCHAR(10)
	, CID VARCHAR(30)
	, AttendDr VARCHAR(184)
)

INSERT INTO @tblPatTemp (
	Patient_oid
	, PatientVisit_oid
	, PatientReasonforSeekingHC
	, LastName
	, FirstName
	, PatientName
	, PatientAccountID
	, PatientLocationName
	, LatestBedName
	, VisitStartDateTime
	, MedicalRecordNumber
	, EntityName
	, BirthDate
	, Age
	, Sex
	, CID
	, AttendDr
)

SELECT pt.ObjectID
, PV.ObjectID
, PV.PatientReasonForSeekingHC
, LastName = PT.LastName
, FirstName = PT.FirstName
, PatientName = CASE ISNULL(PT.GENERATIONQUALIFIER, '')
	WHEN ''
		THEN PT.LastName + ', ' + PT.FirstName + ' ' + ISNULL(SUBSTRING(PT.MIDDLENAME, 1, 1), ' ')
		ELSE PT.LastName + ' ' + PT.GenerationQualifier + ', ' + PT.FirstName + ' ' + ISNULL(SUBSTRING(PT.MIDDLENAME, 1, 1), ' ')
	END
, PV.PatientAccountID
, PV.PatientLocationName
, PV.LatestBedName
, PV.VisitStartDateTime
, MedicalRecordNumber = PID.[Value]
, PV.EntityName
, BirthDate = CONVERT(VARCHAR(10), PER.BIRTHDATE, 101)
, Age = (.DBO.fn_ORE_GetPatientAge(PER.BIRTHDATE, GETDATE()))
, Sex = CAST(
	CASE PER.SEX
		WHEN 0
			THEN 'Male'
		WHEN 1
			THEN 'Female'
		ELSE ' '
	END AS CHAR(6)
	)
, CID = PID2.[Value]
, AttendDR = ISNULL(.DBO.fn_ORE_GetPhysicianName(PV.OBJECTID, 0, 6), '')

FROM HPatient AS PT WITH(NOLOCK)
INNER JOIN HPatientVisit AS PV WITH(NOLOCK)
ON PT.ObjectID = PV.Patient_oid
INNER JOIN HPerson AS PER WITH(NOLOCK)
ON PT.ObjectID = PER.ObjectID
INNER JOIN HPatientIdentifiers AS PID WITH(NOLOCK)
ON PID.EntityOID = PV.Entity_oid
	AND PID.Patient_oid = PV.Patient_oid
	AND PID.IsDeleted = 0
	AND PID.[Type] = 'MR'
LEFT OUTER JOIN HPatientIdentifiers AS PID2 WITH(NOLOCK)
ON PID2.Patient_oid = PT.ObjectID
	AND PID2.IsDeleted = 0
	AND PID2.[Type] = 'MPI'

WHERE PV.IsDeleted = 0
AND PT.ObjectID = @intPatient_oid
AND PV.ObjectID = @intVisit_oid

-- GET PATIENT ALLERGIES ----------------------------------------------
DECLARE @Allergies TABLE (
	Patient_oid INT
	, Allergy VARCHAR(1000)
)

INSERT INTO @Allergies

SELECT PT.Patient_oid
, Allergy = ISNULL(HPA.ALGNAME, '') + ' ' +
	CASE
		WHEN HPA.AlgCategoryName IS NULL
		OR
		HPA.AlgCategoryName = ''
			THEN ''
		ELSE CASE
			WHEN HPA.AlgName IN ('No Known Allergies','No Known Drug Allergies','No Known Food Allergies') THEN ''
			ELSE '(' + HPA.AlgCategoryName + ')'
		END
	END

FROM @tblPatTemp AS PT
LEFT OUTER JOIN HPtAllergy AS HPA WITH(NOLOCK)
ON PT.Patient_oid = HPA.PatientOID
LEFT OUTER JOIN HPtAllergyReaction AS HPR WITH(NOLOCK)
ON HPA.ObjectID = HPR.AllergyOID
	AND HPR.IsLatest = 1
	AND HPR.IsRemoved = 0

WHERE HPA.IsLatest = 1
AND HPA.AlgStatusCode = 'C'
AND HPA.PatientOID = @intPatient_oid

ORDER BY HPA.AlgName ASC

OPTION(FORCE ORDER)

DECLARE @AlgPivot TABLE (
	Patient_oid INT
	, Allergies VARCHAR(1000)
)

INSERT INTO @AlgPivot

SELECT T1.Patient_oid
, AllergyList = SUBSTRING(
	(
		SELECT ( ', ' + Allergy )
		FROM @Allergies T2
		WHERE T1.Patient_oid = T2.Patient_oid
		ORDER BY Patient_oid
		, Allergy
		FOR XML PATH( '' )
	)
	, 3, 1000 )
	FROM @Allergies AS T1

GROUP BY Patient_oid

-- GET ORDERS FOR DISCHARGE INSTRUCTIONS ------------------------------
DECLARE @tblOrders TABLE (
	Patient_oid INTEGER
	, PatientVisit_oid INTEGER
	, CreationTime DATETIME
	, StartDateTime DATETIME
	, RequestedBy VARCHAR(1500)
	, OrderAbbreviation VARCHAR(20)
	, OrderDescAsWritten VARCHAR(2000)
	, DCOrderComment VARCHAR(1500)
	, DCDiagnosis VARCHAR(MAX)
)

INSERT INTO @tblOrders

SELECT HO.Patient_oid
, HO.PatientVisit_oid
, HO.CreationTime
, StartDateTime
, HO.RequestedBy
, HO.OrderAbbreviation
, HO.OrderDescAsWritten
, HOE.UserDefinedString8
, HOE.UserDefinedString16

FROM HOrder AS HO WITH(NOLOCK)
LEFT OUTER JOIN HExtendedOrder AS HOE WITH(NOLOCK)
ON HO.ExtendedOrder_oid = HOE.ObjectID

WHERE Patient_oid = @intPatient_oid
AND PatientVisit_oid = @intVisit_oid
AND OrderAbbreviation IN ('ADTDCIf', 'ADTDCHome')

-- GET DISCHARGE ORDER
DECLARE @tblDschOrder TABLE (
	Patient_oid INTEGER
	, PatientVisit_oid INTEGER
	, CreationTime DATETIME
	, RequestedBy VARCHAR(1500)
	, DischargeOrder VARCHAR(2000)
	, DCOrderComment VARCHAR(1500)
	, DCDiagnosis VARCHAR(MAX)
)

INSERT INTO @tblDschOrder

SELECT PATIENT_OID
, PatientVisit_oid
, CreationTime
, RequestedBy
, DischargeOrd = Case
	WHEN CHARINDEX('; Physician/Resident',OrderDescAsWritten,1) > 0
		THEN LEFT(OrderDescAsWritten ,charindex('; Physician/Resident',OrderDescAsWritten,1))
		ELSE OrderDescAsWritten
	END
, DCOrderComment
, DCDiagnosis  

FROM (
	SELECT Patient_oid
	, PatientVisit_oid
	, CreationTime
	, RequestedBy
	, OrderDescAsWritten
	, DCOrderComment
	, DCDiagnosis
	, ROW_NUMBER() OVER(PARTITION BY OrderAbbreviation ORDER BY CreationTime DESC) AS [RN]
	
	FROM @tblOrders

	WHERE OrderAbbreviation IN ('ADTDCIf', 'ADTDCHome')
) AS X

WHERE X.RN = 1
;

-- DISCHARGE ASSESSMENT INTO
DECLARE @tblDCInst TABLE (
	AssessmentID INTEGER
	, Patient_oid INTEGER
	, PatientVisit_oid INTEGER
	, FormUsage VARCHAR(1000)
	, UserAbbrName VARCHAR(1000)
	, CollectedDT DATETIME
	, FindingAbbr VARCHAR(20)
	, [Value] VARCHAR(1500)
)

INSERT INTO @tblDCInst (
	AssessmentID
	, Patient_oid
	, PatientVisit_oid
	, FormUsage
	, UserAbbrName
	, CollectedDT
	, FindingAbbr
	, [Value]
)

SELECT X.AssessmentID
, X.Patient_oid
, X.PatientVisit_oid
, X.FormUsage
, X.CollectedDT
, HO.FindingAbbr
, REPLACE(HO.Value, CHAR(30), ', ')

FROM (
	SELECT AssessmentID
	, Patient_oid
	, PatientVisit_oid
	, FormUsage
	, UserAbbrName
	, CollectedDT
	, ROW_NUMBER() OVER(PARTITION BY FORMUSAGE ORDER BY CREATIONTIME DESC) AS [RN]

	FROM HAssessment WITH(NOLOCK)
	WHERE Patient_oid = @intPatient_oid
	AND PatientVisit_oid = @intVisit_oid
	AND FormUsageDisplayName = 'Discharge Instructions'
	AND AssessmentStatusCode IN (1, 3)
	AND ENDDT IS NULL
) AS X
LEFT OUTER JOIN HObservation AS HO WITH(NOLOCK)
ON HO.Patient_oid = @intPatient_oid
AND X.AssessmentID = HO.Assessment_oid
AND HO.EndDT IS NULL

WHERE X.RN = 1
;

SELECT *

INTO #Temp_Final

FROM (
	SELECT *
	FROM @tblDCInst
	PIVOT (
		MAX([Value])
		FOR FindingAbbr IN (
			-- Header Info   
			-- Vaccinations  
			-- Diagnosis/My Medical Problem:    
			-- [UserDefinedString16],  
			-- Follow up Appointements    -- CHANGED  
			 [M_DCFUP1],  [M_DCFUPDateTime1],  [M_DCFUPtCall1],  
			 [M_DCFUP2],  [M_DCFUPDateTime2],  [M_DCFUPtCall2],  
			 [M_DCFUP3],  [M_DCFUPDateTime3],  [M_DCFUPtCall3],  
			 [M_DCFUP4],  [M_DCFUPDateTime4],  [M_DCFUPtCall4],  
			 [M_DCFUP5],  [M_DCFUPDateTime5],  [M_DCFUPtCall5],  
			 [M_DCFUP6],  [M_DCFUPDateTime6],  [M_DCFUPtCall6],  
			 [M_DCFUP7],  [M_DCFUPDateTime7],  [M_DCFUPtCall7],  
			 [M_DCFUP8],  [M_DCFUPDateTime8],  [M_DCFUPtCall8],  
			 [M_DCFUPComm],  
			-- Diet  
			[M_DischargeDiet] ,[M_DCDischDietOth],  -- CHANGED  
			--Activity/Restrictions  
			[M_Disch Activity],[M_DCDischActOth], -- CHANGED  
			--Fever/chills, Vision Change, Dizziness, Confusion  
			[M_CallWorse], [M_DCAddSymp],  
			--Follow-up tests after discharge???  
			[M_FUPDischarge],[M_DCFUPTest],[M_DCFUPAdd(Spec)],  
			--Pending Test Results  
			[In progress lab orders (Service Type Laboratory)],  
			--Misc Wound Care/Incision Instructions  
			[M_DCWoundCare],[M_WCFocusDCInst],  
			--Misc Medication Instruction --Hold Warfarin for 3 days  
			[M_DCMiscMed],[M_DCMiscMedSpec],  
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
			-- Hospice Agencies (w/phone and fax numbers)  
			[M_CMFocusHospice], [M_CMFocusHospOth],  
			--Durable Medical Equipment (w/phone and fax numbers)   
			[M_DCFocusDMEAgen], [M_CMFocusDMEOth],  
			--Durable Medical Equipment Type  
			[M_CMFocusDMEType],[M_CMFocDMETypOth],  
			--Intravenous Infusion (w/phone and fax numbers)  
			[M_CMFocusHmInf],[M_CMFocusHInfOth],  
			--External Facilities (w/phone and fax numbers)  
			[M_CMFocusExtFac],[M_CMFocsExtFacOt],  
			--** External Health Resource:   
			[M_CMFocExtHlhRes],  
			--**External Resource Name:   
			[M_CMFocEHResName],  
			--Personal Care Providers (w/phone and fax numbers)  
			[M_CMFocusPersCar],[M_CMFocsPrsCPOth],  
			--Wound Care Clinics (w/phone and fax numbers)  
			[M_CMFocusWdClin],[M_CMFocusdWdCOth]
		)
	) as P
) pl

-- RETRIEVE IMMUNIZATION STATUS
DECLARE @tblImmun TABLE (
	FindingAbbr VARCHAR(64)
	, [Value] VARCHAR(3000)
	, Patient_oid INT
)

INSERT INTO @tblImmun

SELECT FindingAbbr
, [Value]
, Patient_oid

FROM (
	SELECT FindingAbbr
	, [Value]
	, Patient_oid
	, ROW_NUMBER() OVER(PARTITION BY FindingAbbr ORDER BY StartDT DESC) AS [RN]
	
	FROM HObservation WITH(NOLOCK)

	WHERE Patient_oid = @HSF_CONTEXT_PATIENTID
	AND FindingAbbr IN ('A_InfluenzaImmun', 'A_InfluenzaImDt', 'A_Pneumo Immun', 'A_Pneum Im Dt')
) AS X

WHERE X.RN = 1
;

CREATE TABLE #Imm_Final (
	InfluenzaImmun VARCHAR(100)
	, InfluenzaImmunDt VARCHAR(100)
	, PneumoIMmun VARCHAR(100)
	, PneumoImmunDt VARCHAr(100)
	, Patient_oid VARCHAR(100)
)

INSERT INTO #Imm_Final

SELECT DISTINCT InfluenzaImmun = T1.[Value]
, InfluenzaImmunDt = T2.[Value]
, PneumoImmun = T3.[Value]
, PneumoImmunDt = T4.[Value]
, T.Patient_oid

FROM @tblImmun AS T
LEFT OUTER JOIN @tblImmun AS T1
ON T.Patient_oid = T1.Patient_oid
	AND T1.FindingAbbr = 'A_InfluenzaImmun'
LEFT OUTER JOIN @tblImmun AS T2
ON T.Patient_oid = T2.Patient_oid
	AND T2.FindingAbbr = 'A_InfluenzaImDt'
LEFT OUTER JOIN @tblImmun AS T3
ON T.Patient_oid = T3.Patient_oid
	AND T3.FindingAbbr = 'A_Pneumo Immun'
LEFT OUTER JOIN @tblImmun AS T4
ON T.Patient_oid = T4.Patient_oid
	AND T4.FindingAbbr = 'A_PneumO Im Dt'
;

SELECT TOP 1 HEO.UserDefinedString22
, HO.Patient_oid
, HEO.UserDefinedString23
, HO.CreationTime

INTO #DCDiagnosis

FROM HOrder AS HO WITH(NOLOCK)
INNER JOIN HExtendedOrder AS HEO WITH(NOLOCK)
ON HO.ExtendedOrder_oid = HEO.ObjectID

WHERE HO.Patient_oid = @intPatient_oid

ORDER BY HO.CreationTime DESC
;

DECLARE @Nurseprovider VARCHAR(100);
DECLARE @OrderDescAsWritten VARCHAR(MAX);

SELECT TOP 1 @Nurseprovider = UserAbbrName

FROM HAssessment WITH(NOLOCK)

WHERE Patient_oid = @intPatient_oid
AND PatientVisit_oid = @intVisit_oid
ORDER BY CreationTime DESC

SELECT TOP 1 @OrderDescAsWritten = OrderDescAsWritten

FROM HOrder

WHERE Patient_oid = @intPatient_oid
AND PatientVisit_oid = @intVisit_oid
AND OrderTypeAbbr = 'Laboratory'
AND OrderStatusModifier = 'In Progress'

ORDER BY EnteredDateTime DESC
;