-- Count of registrations per registrar in MedHost.
-- 
--*********************************************************************************

-- Columns Selected
SELECT DISTINCT FIN_REG, COUNT(FIN_REG) as 'Count'

-- Database Used: MEDHOST
FROM dbo.JTM_GENERIC_LIST_V

-- Filters
WHERE dt_ARRIVAL BETWEEN '3/1/2013' AND '4/1/2013'
AND FIN_REG != ' '
GROUP BY FIN_REG
ORDER BY COUNT(FIN_REG) DESC

--*********************************************************************************
-- End Report
-- Sanderson, Steven 1.8.12