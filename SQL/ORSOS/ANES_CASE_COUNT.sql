DECLARE @SD DATETIME;
DECLARE @ED DATETIME;
SET @SD = '2012-11-01';
SET @ED = '2013-10-31';

SELECT s.name AS [DOCOTR],
COUNT(DISTINCT case_no) AS [CASE COUNT]
FROM ORSPROD.POST_RESOURCE PR
JOIN orsprod.staff s
ON pr.resource_id = s.staff_id
WHERE group_id = 'ANES'
AND pr.start_date BETWEEN @SD AND @ED
GROUP BY s.name

UNION ALL

SELECT 'Total Cases'
, COUNT(case_no)
FROM ORSPROD.POST_RESOURCE pr
JOIN orsprod.staff s
ON pr.resource_id = s.staff_id
WHERE group_id = 'ANES'
AND pr.start_date BETWEEN @SD AND @ED