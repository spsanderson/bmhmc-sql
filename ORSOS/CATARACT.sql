SELECT DISTINCT provider_short_name
, COUNT(DISTINCT account_no) AS [pt count]

FROM orsprod.post_case

WHERE pre_diagnosis LIKE '%cataract%'
AND provider_short_name IS NOT NULL
AND enter_dept_date BETWEEN '2013-01-01' AND '2013-12-31'

GROUP BY provider_short_name
ORDER BY provider_short_name
