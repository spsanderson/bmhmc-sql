-- Count of patients arriving to the ED by hour for a specific date range
-- 
--*********************************************************************************

-- Columns selected
SELECT DISTINCT n_ARRIVAL_HOUR AS 'ARRIVAL BY HOUR', COUNT(n_ARRIVAL_HOUR) AS 'COUNT BY HOUR'

-- Database Used: MEDHOST
FROM dbo.JTM_GENERIC_LIST_V

-- Filters
WHERE dt_ARRIVAL BETWEEN '1/1/13' AND '4/1/13'
GROUP BY n_ARRIVAL_HOUR
ORDER BY n_ARRIVAL_HOUR

--*********************************************************************************
-- End Report
-- Sanderson, Steven 1.8.12