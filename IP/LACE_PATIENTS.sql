SELECT CV.VisitIDCode, CV.AdmitDtm, CV.TypeCode, CV.CareLevelCode, CV.CurrentLocation

FROM CV3ClientVisit CV

WHERE CV.AdmitDtm BETWEEN '8/1/12' AND '9/1/12'
AND CV.VisitIDCode NOT IN (

)
AND CV.TypeCode = 'INPATIENT'
AND CV.CurrentLocation NOT LIKE '%INPATIENT PREADMIT%'
AND CV.CareLevelCode NOT LIKE '%PSYCH%'
AND CV.CareLevelCode NOT LIKE '%TCU%'
ORDER BY CV.CurrentLocation