-- DAILY
SELECT CAST(Dsch_Date as date) AS [Time]
, COUNT(DISTINCT(PTNO_NUM)) AS DSCH_COUNT

FROM smsdss.BMH_PLM_PtAcct_V

WHERE Dsch_Date >= '2001-01-01'
AND Dsch_Date < DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0)
AND tot_chg_amt > 0
AND Plm_Pt_Acct_Type = 'I'
AND LEFT(PTNO_NUM, 1) != '2'
AND LEFT(PTNO_NUM, 4) != '1999'

GROUP BY Dsch_Date

ORDER BY Dsch_Date