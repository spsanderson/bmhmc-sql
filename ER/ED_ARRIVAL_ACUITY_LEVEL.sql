-- ED VISITS BY ACUITY LEVEL FOR A SPECIFIED DATE RANGE
-- 
--*********************************************************************************

-- Column Selection
SELECT DT_ARRIVAL AS 'ARRIVAL TO ED', n_ARRIVAL_YEAR AS 'YEAR', n_ARRIVAL_MONTH AS 'MONTH',
n_ARRIVAL_WEEK AS 'WEEK', n_ARRIVAL_HOUR AS 'HOUR', s_FIRST_ACUITY AS 'ACUITY LEVEL AT ARRIVAL'

-- Database Used: Medhost
FROM dbo.JTM_GENERIC_LIST_V
	 
-- Filters
WHERE DT_ARRIVAL BETWEEN '1/1/2009' AND '1/1/2013'
AND S_FIRST_ACUITY IS NOT NULL
ORDER BY DT_ARRIVAL ASC

--*********************************************************************************
-- End Report
-- Sanderson, Steven 1.28.12