SELECT (
	CAST(DATEPART(YEAR, Dsch_Date) AS varchar)
	+
	CAST(DATEPART(MONTH, Dsch_Date) AS VARCHAR)
) AS [Time]
, COUNT(DISTINCT(PTNO_NUM)) AS DSCH_COUNT
--, SUM(TOT_CHG_AMT) AS [Tot_Chgs]
--, SUM(-tot_pay_amt) AS [Tot_Pmts]
, ROUND(SUM(-tot_pay_amt) / COUNT(DISTINCT(PTNO_NUM)), 2) AS [Avg_Pmts]
, ROUND(SUM(tot_chg_amt) / COUNT(DISTINCT(PTNO_NUM)), 2) AS [Avg_Chgs]

FROM smsdss.BMH_PLM_PtAcct_V

WHERE Dsch_Date >= '2010-01-01'
AND Dsch_Date < '2018-07-01'
AND tot_chg_amt > 0
AND Plm_Pt_Acct_Type = 'I'
AND LEFT(PTNO_NUM, 1) != '9'
AND LEFT(PTNO_NUM, 4) != '1999'

GROUP BY DATEPART(YEAR, Dsch_Date)
, DATEPART(MONTH, Dsch_Date)

ORDER BY DATEPART(YEAR, Dsch_Date)
, DATEPART(MONTH, Dsch_Date)

-- DAILY
SELECT CAST(Dsch_Date as date) AS [Time]
, COUNT(DISTINCT(PTNO_NUM)) AS DSCH_COUNT
--, SUM(TOT_CHG_AMT) AS [Tot_Chgs]
--, SUM(-tot_pay_amt) AS [Tot_Pmts]
--, ROUND(SUM(-tot_pay_amt) / COUNT(DISTINCT(PTNO_NUM)), 2) AS [Avg_Pmts]
--, ROUND(SUM(tot_chg_amt) / COUNT(DISTINCT(PTNO_NUM)), 2) AS [Avg_Chgs]

FROM smsdss.BMH_PLM_PtAcct_V

WHERE Dsch_Date >= '2001-01-01'
AND Dsch_Date < DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 1, 0)
AND tot_chg_amt > 0
AND Plm_Pt_Acct_Type = 'I'
AND LEFT(PTNO_NUM, 1) != '9'
AND LEFT(PTNO_NUM, 4) != '1999'

GROUP BY Dsch_Date

ORDER BY Dsch_Date