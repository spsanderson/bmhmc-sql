-- REPORT TO GET THE SEPSIS FOCUS STUDY INFORMATION, THERE IS INFO
-- THAT WILL COME FROM MEDHOST AND FROM SCM
--********************************************************************

--COLUMNS SELECTED
SELECT CV.ClientDisplayName AS 'PT NAME', CV.VisitIDCode AS 'ENCOUNTER',
*

-- DB USED
FROM CV3ClientVisit	CV
JOIN CV3ClientVisitLocation CVL
ON CV.GUID = CVL.ClientVisitGUID
JOIN CV3Location L
ON CVL.LocationGUID = L.GUID

WHERE CV.AdmitDtm BETWEEN '1/1/13' AND '1/2/13'