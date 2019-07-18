-- Patients that come into the ER with a specific complaint for a specific
-- date range
--*********************************************************************************

-- Columns Selected
SELECT DISTINCT s_COMPLAINT AS 'Complaint', COUNT(s_COMPLAINT) AS 'Count'

-- Database Used: MEDHOST
FROM dbo.JTM_GENERIC_LIST_V

-- Filters
WHERE dt_ARRIVAL BETWEEN '2/1/2013' AND '3/1/2013'
      AND s_COMPLAINT IN('abdominal pain', 'chest pain', 'nausea', 'dizziness',
      'vomiting')
	 
GROUP BY s_COMPLAINT

--*********************************************************************************
-- End Report
-- Sanderson, Steven 1.8.12
