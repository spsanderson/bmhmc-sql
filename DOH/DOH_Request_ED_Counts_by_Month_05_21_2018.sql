SELECT DATEPART(MONTH, Arrival) AS [Arrival_Month]
, COUNT(Account) AS [Pt_Count]

FROM smsdss.c_Wellsoft_Rpt_tbl

WHERE Arrival >= '2017-12-01'
AND Arrival < '2018-05-01'

GROUP BY DATEPART(MONTH, ARRIVAL)

ORDER BY DATEPART(MONTH, ARRIVAL)

GO
;