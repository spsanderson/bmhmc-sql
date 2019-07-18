-- REPORT RUN FROM SCM, GETS THE NAME OF A DX THAT A PT ACQUIRED
-- AS A PATIENT
--**************************************************************

-- COLUMN SELECTION
SELECT CV.VisitIDCode AS 'ENCOUNTER', CV.ClientDisplayName AS 'PT NAME',
CV.AdmitDtm AS 'ADMIT DATE', HID.TypeCode AS 'TYPE OF DX', HID.ShortName AS 'DX'

-- DB SCM
FROM CV3ClientVisit CV
JOIN CV3HealthIssueDeclaration HID
ON CV.GUID = HID.ClientVisitGUID
JOIN CV3CodedHealthIssue HI
ON HID.CodedHealthIssueGUID = HI.GUID

-- FILITERS USED
WHERE CV.AdmitDtm BETWEEN '2/1/13' AND '3/1/13'
AND HID.TypeCode = 'FINALDSCHDXNO'

--*************************************************************
-- SANDERSON, STEVEN MEDICAL AFFAIRS ext 4901