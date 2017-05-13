-- ED THROUGHPUT REPORT FOR JANUARY AND FEBRUARY FOR ALL PATIENTS
-- THIS IS FOR TREAT AND RELASE PATIENTS ONLY!!!!!
-- DATE RANGE JAN.1.13 TO FEB.28.13
--***************************************************************
--
-- COLUMNS SELECTED
SELECT
dt_ARRIVAL AS 'PT ARRIVAL TIME', dt_DEPARTURE AS 'PT DEPART TIME',
DATEDIFF(MI,DT_ARRIVAL,DT_DEPARTURE) AS 'PT ED LOS IN MINUTES',
s_VISIT_IDENT AS 'ENCOUNTER #', S_MRN AS 'PT MRN',
S_FIRST_ACUITY AS 'ACUITY AT ARRIVAL', s_OUTCOME_LOCATION AS
'PT OUTCOME LOC', S_DIAGNOSIS_FOR_SORT AS 'PT DX'

-- DATABASE USED: MEDHOST
FROM DBO.JTM_GENERIC_LIST_V

-- FILTERS
WHERE DT_ARRIVAL BETWEEN '1/1/13' AND '3/1/13'
AND S_OUTCOME_LOCATION LIKE '%D:%'
AND S_DIAGNOSIS_FOR_SORT NOT LIKE '%ALCOHOL%'
AND (
S_DIAGNOSIS_FOR_SORT LIKE '%DEPRESSION%'
OR S_DIAGNOSIS_FOR_SORT LIKE '%PSYCHOSIS%'
OR S_DIAGNOSIS_FOR_SORT LIKE '%SUICIDAL%'
OR S_DIAGNOSIS_FOR_SORT LIKE '%BIPOLAR%'
)
--**************************************************************
-- SANDERSON, STEVEN MEDICAL AFFAIRS
-- REPORT RUN 3.5.13
