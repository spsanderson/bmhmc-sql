-- THIS REPORT GATHERS ALL THE COMORBID CONDITIONS FOR A PATIENTS SPECIFIC ENCOUNTER
-- THIS DATA IS USED FOR THE READMISSIONS TASK FORCE
--***********************************************************************************
--
-- COLUMNS USED
SELECT CV.AdmitDtm AS 'PT ADMIT DATE', CV.IDCode AS 'PT MRN', CV.VisitIDCode AS 'ENC #',
CV.DischargeDtm AS 'PT DISC DATE', DATEDIFF(DD,CV.AdmitDtm,CV.DischargeDtm) AS 'LOS',
CV.ClientDisplayName AS 'PT NAME', HID.TypeCode AS 'DX TYPE CODE', HID.ShortName AS
'DX SHORT NAME', CV.ProviderDisplayName AS 'DOC NAME'

-- DATABASE USED: SAM, ALIAS' CV, HID
FROM CV3ClientVisit CV
JOIN CV3HealthIssueDeclaration HID
ON HID.CLIENTVISITGUID = CV.GUID

-- FILTERS
WHERE CV.AdmitDtm BETWEEN '1/1/12' AND '1/1/13'
AND CV.ClientDisplayName != 'ALLSCRIPTS, CORE'
AND HID.TypeCode IN
(
'FINALDSCHDXYES',
'FINALDSCHDXNO'
)
AND CV.VisitIDCode IN
(

)
