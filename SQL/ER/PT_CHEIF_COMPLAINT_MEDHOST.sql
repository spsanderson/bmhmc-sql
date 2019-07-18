-- Patients that come into the ER with a specific complaint for a specific
-- date range
--*********************************************************************************

-- Columns Used
SELECT s_PATIENT_FULL_NAME AS 'Name', s_VISIT_IDENT AS 'Acct Num', 
s_OUTCOME_LOCATION AS 'Outcome Loc', s_DIAGNOSIS, s_COMPLAINT AS 'Complaint', 
dt_ARRIVAL AS 'Arrival'

-- Database Used: MEDHOST
FROM dbo.JTM_GENERIC_LIST_V

-- Filters
WHERE (dt_ARRIVAL BETWEEN '2/1/2013' AND '3/1/2013'
	  AND s_COMPLAINT IN ('abdominal pain', 'chest pain', 'coughing', 'fever', 
	  'dizzines')
	   )

--*********************************************************************************
-- End Report
-- Sanderson, Steven 1.8.12