SELECT B.FindingAbbr
, FindingName

FROM smsmir.sc_Assessment AS A
LEFT OUTER JOIN smsmir.sc_Observation AS B
ON A.Patient_oid = B.Patient_oid
	AND A.AssessmentID = B.AssessmentID
	AND A.ObjectID = B.Assessment_oid

WHERE FormUsage = 'BMH_CMDaily Discharge Disp'
AND FindingName LIKE '%FAMILY%'

GROUP BY B.FindingAbbr
, B.FindingName

ORDER BY B.FindingAbbr