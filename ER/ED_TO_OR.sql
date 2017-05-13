-- Patients that come into the ER and go to the Operating Room for a specified
-- date range
--*********************************************************************************

-- Columns Selection
SELECT 
s_MRN AS 'MRN', s_VISIT_IDENT AS 'Encounter Number', s_PATIENT_FULL_NAME AS 'PT Name',
dt_ARRIVAL AS 'Arrival', s_OUTCOME_LOCATION AS 'Outcome Location',
s_COMPLAINT AS 'Complaint'

-- Database Used: Medhost
FROM 
dbo.JTM_GENERIC_LIST_V

-- Filters
WHERE
dt_ARRIVAL BETWEEN '3/1/13' AND '4/1/13'
AND s_OUTCOME_LOCATION LIKE '%Operating Room%'
ORDER BY dt_ARRIVAL ASC

--*********************************************************************************
-- End Report
-- Sanderson, Steven 4.1.13
