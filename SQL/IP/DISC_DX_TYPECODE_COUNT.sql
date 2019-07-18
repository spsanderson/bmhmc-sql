-- COUNT OF TPYES OF DISCHARGE CODES FROM THE HEALTH ISSUE DECLARATION
-- EXAMPLE, FINALDISCHDXNO
--*************************************************************************************
-- COLUMNS USED
SELECT HID.TypeCode AS 'TYPE OF DX', COUNT(HID.TypeCode) AS 'COUNT OF TYPE CODE TYPES'

-- DB SCM
FROM CV3ClientVisit CV
JOIN CV3HealthIssueDeclaration HID
ON CV.GUID = HID.ClientVisitGUID

-- FILTERS USED
WHERE CV.AdmitDtm BETWEEN '2/1/13' AND '3/1/13'
GROUP BY HID.TypeCode

--*************************************************************************************
-- SANDERSON, STEVEN MEDICAL AFFAIRS ext 4901