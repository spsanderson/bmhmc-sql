-- REPORT IS FOR JENINES' PICC FOCUS GROUP STUDY
-- 
--*********************************************************************************

-- Column Selection and Table Join's
-- CV3ClientVisit alias CV, CV3HealthIssueDeclaration alias HID, CV3CodedHealthIssue alias HI
-- Join HID.ClientVisitGUID onto the CV.GUID column
-- Join HI onto HID.CodedHealthIssueGUID

SELECT CV.VisitIDCode AS 'ENCOUNTER NUM', COUNT(CV.VisitIDCode) AS 'COUNT'

-- Database: SAM, Tables [CV, HI, HID]
FROM CV3ClientVisit CV
JOIN CV3HealthIssueDeclaration HID ON HID.ClientVisitGUID = CV.GUID
JOIN CV3CodedHealthIssue HI ON HID.CodedHealthIssueGUID = HI.GUID

-- TEST FILTERS
WHERE RTRIM(HID.TypeCode) not in ('Admitting Dx','Past Medical Hx')
AND HID.Status = 'ACTIVE' 
AND CV.VisitIDCode IN (

)
GROUP BY CV.VisitIDCode
