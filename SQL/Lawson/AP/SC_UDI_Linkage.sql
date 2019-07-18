DECLARE @PT_OID VARCHAR(20);
DECLARE @VISIT_OID VARCHAR(20);

SET @PT_OID = '17165138';
SET @VISIT_OID = '2026862';

SELECT A.patientoid AS [PatientOID]
, A.patientvisit_oid AS [PatientVisitOID]
, D.[Value] AS [Med_Rec_No]
, C.PATIENTACCOUNTID AS [Encounter]
, A.PerformedByStaffName
, A.PerformedByStaffOID
, A.StartDate
, A.EndDate
, A.ProcedureTime
, B.UDI
, B.UDIIssuer
, B.DeviceIdentifier
, B.ExpirationDate
, B.BatchLotNumber
, B.SerialNumber
, B.DonationIdentificationCode
, B.DeviceDescription
, B.BrandName
, B.CompanyName
, B.Model
, B.MRISafetyStatus
, B.ImplantExplantIndicator
, B.IsProtectedInfo
, B.IsDeleted
, B.GMDNPTName
, B.ProductClassCodeSet
, B.ProductClassCode
, B.ProductClassCodeName
, C.[Description]
, C.[VisitTypeCode]
, C.[PatientReasonForSeekingHC]
, C.Financialclass
, C.UnitContactedName
, C.DischargeDisposition
, C.AccommodationType

FROM [sc_server].[soarian_clin_prd_1].[dbo].[HProcedure] AS A
INNER JOIN [sc_server].[soarian_clin_prd_1].[dbo].[HProcedureDevice] AS B
ON A.Patientoid = B.patientoid
	AND a.patientvisit_oid = B.patientvisitoid
	AND A.objectid = b.procedureoid
INNER JOIN [sc_server].[soarian_clin_prd_1].[dbo].[HPatientVisit] AS C
ON A.PATIENTOID = C.PATIENT_OID
	AND A.PATIENTVISIT_OID = C.STARTINGVISITOID
INNER JOIN [sc_server].[soarian_clin_prd_1].[dbo].[HPatientIdentifiers] AS D
ON A.PATIENTOID = D.PATIENT_OID
	AND D.[TYPE] = 'MR'

WHERE A.patientoid = @PT_OID
AND A.patientvisit_oid = @VISIT_OID

ORDER BY A.creationTime
;
