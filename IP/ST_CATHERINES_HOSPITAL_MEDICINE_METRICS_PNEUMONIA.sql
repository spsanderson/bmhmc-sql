SELECT CV.AdmitDtm AS 'PATIENT ADMIT DATE', CV.DischargeDtm AS 'PATIENT DISCHARGE DATE',
DATEDIFF(D,CV.AdmitDtm,CV.DischargeDtm) AS 'LOS', CV.DischargeDisposition AS 'PATIENT DISPOSITION'

FROM CV3ClientVisit CV
JOIN CV3HealthIssueDeclaration HID
ON CV.GUID = HID.ClientVisitGUID

WHERE HID.TypeCode = 'PrimFinalDschDx'
AND HID.ShortName LIKE '%PNEUmonia%'
AND CV.AdmitDtm BETWEEN '1/1/12' AND '1/1/13'
ORDER BY CV.AdmitDtm
