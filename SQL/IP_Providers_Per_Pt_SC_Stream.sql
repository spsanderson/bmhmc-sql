/*
***********************************************************************
File: IP_Providers_Per_Pt_SC_Stream.sql

Input Parameters:
	None

Tables/Views:
	smsmir.mir_sc_Patient AS PT
	smsmir.mir_sc_PatientVisit AS PV
	smsmir.mir_sc_Person AS PER 
	smsmir.mir_sc_PatientIdentifiers AS PID
	smsmir.mir_sc_PatientIdentifiers AS PID2
	smsmir.mir_sc_StaffAssociations AS SCSA
	smsmir.mir_staff_mstr AS STAFFMSTR
	smsdss.c_patient_demos_v AS PTDEMOS

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get a list of all providers on a case that are not the attending or admitting.
	This will bring back patients that are potentially and most likely uncoded.
	This does restarain the information coming back if there is no associated provider
	on a procedure, the structure will be slightly different.

Revision History:
Date		Version		Description
----		----		----
2018-11-28	v1			Initial Creation
***********************************************************************
*/

--SELECT PT.ObjectID AS [PATIENT_OID]
--, PV.ObjectID AS [VISIT_OID]
SELECT MedicalRecordNumber = PID.[Value]
, PV.PatientAccountID
, PV.PatientReasonForSeekingHC
, CAST(PV.VisitStartDateTime AS date) AS [ADM_DATE]
, CAST(PV.VisitEndDateTime AS date) AS [DSCH_DATE]
, PatientName = CASE ISNULL(PT.GENERATIONQUALIFIER, '')
	WHEN ''
		THEN PT.LastName + ', ' + PT.FirstName + ' ' + ISNULL(SUBSTRING(PT.MIDDLENAME, 1, 1), ' ')
		ELSE PT.LastName + ' ' + PT.GenerationQualifier + ', ' + PT.FirstName + ' ' + ISNULL(SUBSTRING(PT.MIDDLENAME, 1, 1), ' ')
	END
, BirthDate = CONVERT(VARCHAR(10), PER.BIRTHDATE, 101)
, Age = DATEDIFF(YEAR, PER.BIRTHDATE, PV.VisitStartDateTime)
, Sex = CAST(
	CASE PER.SEX
		WHEN 0
			THEN 'Male'
		WHEN 1
			THEN 'Female'
			ELSE ''
	END AS CHAR(6)
	)
, PER.MaritalStatus
, PTDEMOS.addr_line1
, PTDEMOS.Pt_Addr_Line2
, PTDEMOS.Pt_Addr_City
, PTDEMOS.Pt_Addr_State
, PTDEMOS.Pt_Addr_Zip
, PTDEMOS.Pt_Phone_No
, PV.Financialclass
, SCSA.Staff_oid
, STAFFMSTR.staff_signat
, [RN] = ROW_NUMBER() OVER(PARTITION BY PV.PatientAccountID, SCSA.STAFF_OID ORDER BY SCSA.STAFF_OID)

INTO #TEMPA

FROM smsmir.mir_sc_Patient AS PT
INNER JOIN smsmir.mir_sc_PatientVisit AS PV
ON PT.ObjectID = PV.Patient_oid
INNER JOIN smsmir.mir_sc_Person AS PER 
ON PT.ObjectID = PER.ObjectID
INNER JOIN smsmir.mir_sc_PatientIdentifiers AS PID
ON PID.EntityOID = PV.Entity_oid
	AND PID.Patient_oid = PV.Patient_oid
	AND PID.IsDeleted = 0
	AND PID.[Type] = 'MR'
LEFT OUTER JOIN smsmir.mir_sc_PatientIdentifiers AS PID2
ON PID.EntityOID = PV.Entity_oid
	AND PID2.Patient_oid = PV.Patient_oid
	AND PID2.IsDeleted = 0
	AND PID2.[Type] = 'MPI'
INNER JOIN smsmir.mir_sc_StaffAssociations AS SCSA
ON PV.ObjectID = SCSA.PatientVisit_oid
INNER JOIN smsmir.mir_staff_mstr AS STAFFMSTR
ON SCSA.Staff_oid = STAFFMSTR.staff_id
LEFT OUTER JOIN smsdss.c_patient_demos_v AS PTDEMOS
ON PV.PatientAccountID = SUBSTRING(PTDEMOS.pt_id, 5, 8)

--WHERE PV.PatientAccountID = ''
WHERE STAFFMSTR.staff_id != '1127' -- TEST DOCTOR which is useless
AND STAFFMSTR.spclty_cd1 IS NOT NULL
AND CAST(PV.VisitEndDateTime AS date) >= CAST(GETDATE() - 1 AS date)
AND PV.VisitTypeCode = 'IP'
;

SELECT A.MedicalRecordNumber
, A.PatientAccountID
, A.PatientReasonForSeekingHC
, A.ADM_DATE
, A.DSCH_DATE
, A.PatientName
, A.BirthDate
, A.Age
, A.Sex
, A.MaritalStatus
, A.addr_line1
, A.Pt_Addr_Line2
, A.Pt_Addr_City
, A.Pt_Addr_State
, A.Pt_Addr_Zip
, A.Pt_Phone_No
, A.Financialclass
, A.Staff_oid
, A.staff_signat

FROM #TEMPA AS A

WHERE RN = 1
;

DROP TABLE #TEMPA
;