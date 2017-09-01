-- THIS REPORT IS FOR CARE MANAGEMENT. IT PULLS IN ALL PATIENTS WHO WERE 
-- TRANSFERED FROM THE ED TO ANOTHER LOCATION
--**********************************************************************
--
-- COLUMNS SELECTED
SELECT
S_VISIT_IDENT AS 'ENCOUNTER #', S_MRN AS 'PT MRN',
s_PATIENT_FULL_NAME AS 'PT NAME', s_DIAGNOSIS_FOR_SORT AS 'PT DIAGNOSIS',
DT_ARRIVAL AS 'PT ARRIVAL',DT_DEPARTURE AS 'PT DEPARTURE', 
DATEDIFF(MI,DT_ARRIVAL,DT_DEPARTURE) AS 'PT ED LOS MINUTES',
S_OUTCOME_LOCATION AS 'PT LOC OUTCOME'

-- DATABASE USED: MEDHOST
FROM DBO.JTM_GENERIC_LIST_V

-- FILTERS
WHERE
DT_ARRIVAL BETWEEN '3/22/13' AND '3/28/13'
AND S_OUTCOME_LOCATION LIKE '%T:%'
--
--*********************************************************************
-- SANDERSON, STEVEN MEDICAL AFFAIRS