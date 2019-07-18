-- REPORT IS FOR JENINES' PICC FOCUS GROUP STUDY
-- 
--*********************************************************************************

-- Column Selection and Table Join's
-- CV3ClientVisit alias CV, CV3HealthIssueDeclaration alias HID, CV3CodedHealthIssue alias HI
-- Join HID.ClientVisitGUID onto the CV.GUID column
-- Join HI onto HID.CodedHealthIssueGUID
SELECT CV.ClientDisplayName AS 'PT NAME', CV.IDCode AS 'PT MRN', CV.VisitIDCode AS 'ENCOUNTER NUM',
HID.Text AS 'TEXT', HID.TypeCode AS 'TYPE CODE', HID.ShortName AS 'SHORT NAME', HI.Code AS 'ICD-9'

-- Database: SAM, Tables [CV, HI, HID]
FROM CV3ClientVisit CV
JOIN CV3HealthIssueDeclaration HID ON HID.ClientVisitGUID = CV.GUID
JOIN CV3CodedHealthIssue HI ON HID.CodedHealthIssueGUID = HI.GUID

-- Filters
WHERE HID.Status = 'ACTIVE'
AND HID.TypeCode != 'Admitting Dx'
AND HID.TypeCode != 'Past Medical Hx'
AND CV.VisitIDCode IN (

)