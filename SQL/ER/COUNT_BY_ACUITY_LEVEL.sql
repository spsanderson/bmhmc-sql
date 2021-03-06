--Columns selected
SELECT DISTINCT s_FIRST_ACUITY, COUNT(s_FIRST_ACUITY) AS 'Acuity Level'

-- Database Used: MEDHOST
FROM dbo.JTM_GENERIC_LIST_V

-- Filters
WHERE dt_ARRIVAL BETWEEN '3/1/13' AND '4/1/13'
AND S_FIRST_ACUITY IS NOT NULL
GROUP BY s_FIRST_ACUITY
ORDER BY COUNT(s_FIRST_ACUITY) DESC