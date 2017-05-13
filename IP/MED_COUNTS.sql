-- THIS REPORT GETS A COUNT OF HOW MANY MEDICATIONS READMISSION PATIENTS ARE ON
-- THIS IS FOR THE READMISSIONS TASK FORCE, DATA FOR 2012
--*********************************************************************************
SELECT cv.visitIDCode, COUNT(d.ReconcileComment) AS "# Meds per DC Rec."

FROM CV3clientvisit cv

LEFT JOIN CV3OrderReconcile r
ON r.clientvisitGUID= cv.guid
LEFT JOIN CV3OrderReconcileDtl d
ON r.GUID=d.ReconcileGUID

WHERE cv.TypeCode = 'inpatient'

AND CV.VisitIDCode IN
(

)
and r.ReconcileTypeCode = 'Discharge Reconciliation'
and d.ReconcileActionType = 11

group by cv.VisitIDCode 


--***************************************************************************
