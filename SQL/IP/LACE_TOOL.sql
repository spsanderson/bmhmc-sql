-- Report for getting a population of patients on which a LACE score will be 
-- calculated.
--*********************************************************************************
-- ALIAS = CV3ClientVisit == CV; CV3HealthIssueDeclaration == HID;
--         CV3CodedHealthIssue == CHI

-- Column Selction
SELECT CV.IDCODE AS 'MRN', CV.VisitIDCode AS 'PT ENCOUNTER #',CV.ClientDisplayName AS
'PT NAME', CV.AdmitDtm AS 'ADMIT DATE', CV.DischargeDtm AS 'DISCHARGE DATE',
DATEDIFF(HOUR,CV.AdmitDtm,CV.DischargeDtm)/24 AS 'LOS',CHI.Code AS 'ICD CODE'

-- Database used: SCM, CV3ClientVisit Table,
FROM dbo.CV3ClientVisit CV LEFT JOIN dbo.CV3HealthIssueDeclaration HID
	ON CV.GUID = HID.ClientVisitGUID
	LEFT JOIN dbo.CV3CodedHealthIssue CHI
	ON CHI.GUID = HID.CodedHealthIssueGUID

-- Filters
WHERE CV.AdmitDtm BETWEEN '7/1/12' AND '10/1/2012'
AND CV.TypeCode = 'Inpatient'
AND CV.CurrentLocation != 'Inpatient Preadmit'
AND HID.TypeCode != 'Admitting Dx'
AND HID.TypeCode != 'PrimFinalDschDx' -- <--ADDED 1/23/12
--AND CHI.Code IN (
ORDER BY CV.VisitStatus

--*********************************************************************************
-- End Report
-- Sanderson, Steven 12.13.12