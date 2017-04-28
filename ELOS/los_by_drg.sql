-- VARIABLE DECLARATION
DECLARE @YEAR INT;

-- VARIABLE INITIALIZATION
SET @YEAR = DATEPART(year, getdate());

-- COLUMN SELECTION
SELECT drg_no
, ISNULL(ROUND(P.[1], 2), 0) AS 'Jan'
, ISNULL(ROUND(P.[2], 2), 0) AS 'Feb'
, ISNULL(ROUND(P.[3], 2), 0) AS 'Mar'
, ISNULL(ROUND(P.[4], 2), 0) AS 'Apr'
, ISNULL(ROUND(P.[5], 2), 0) AS 'May'
, ISNULL(ROUND(P.[6], 2), 0) AS 'Jun'
, ISNULL(ROUND(P.[7], 2), 0) AS 'Jul'
, ISNULL(ROUND(P.[8], 2), 0) AS 'Aug'
, ISNULL(ROUND(P.[9], 2), 0) AS 'Sep'
, ISNULL(ROUND(P.[10], 2), 0) AS 'Oct'
, ISNULL(ROUND(P.[11], 2), 0) AS 'Nov'
, ISNULL(ROUND(P.[12], 2), 0) AS 'Dec'

FROM (
	SELECT DRG_NO
	, DAYS_STAY
	, datepart(month, Dsch_Date) AS [Discharge Month]
	FROM smsdss.BMH_PLM_PtAcct_V
	WHERE tot_chg_amt > 0
	AND Plm_Pt_Acct_Type = 'I'
	AND PtNo_Num < '20000000'
	AND LEFT(PTNO_NUM, 4) != '1999'
	AND DATEPART(YEAR, Dsch_Date) = @YEAR
	AND drg_no IS NOT NULL
) A

PIVOT (
	AVG(DAYS_STAY)
	FOR [Discharge Month] IN (
		"1","2","3","4","5","6","7","8","9","10","11","12"
	)
)P

ORDER BY drg_no;