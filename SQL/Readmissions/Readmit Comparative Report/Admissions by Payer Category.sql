DECLARE @ADM_START14 DATE;
DECLARE @ADM_END14   DATE;
DECLARE @ADM_START15 DATE;
DECLARE @ADM_END15   DATE;

SET @ADM_START14 = '01-01-2014';
SET @ADM_END14   = '09-01-2014';
SET @ADM_START15 = '01-01-2015';
SET @ADM_END15   = '09-01-2015';

-- 2014 Admits --------------------------------------------------------
SELECT *

FROM(
	SELECT 
	  CASE
		WHEN User_Pyr1_Cat IN ('AAA','ZZZ') Then 'Medicare'
		WHEN User_Pyr1_Cat = 'WWW' Then 'Medicaid'
		ELSE 'Other'
	  END                               AS [Payer Cat Admits 2014]
	, CASE
		WHEN User_Pyr1_Cat IN ('AAA','ZZZ') Then 'Medicare'
		WHEN User_Pyr1_Cat = 'WWW' Then 'Medicaid'
		ELSE 'Other'
	  END                               AS [Payer Category]
	, CAST(MONTH(ADM_DATE) AS INT)      AS [ADM_MO]

	FROM smsdss.BMH_PLM_PtAcct_V

	WHERE Adm_Date >= @ADM_START14 
	AND ADM_DATE < @ADM_END14
	AND tot_chg_amt > '0'
	AND Plm_Pt_Acct_Type='I'
	AND hosp_svc <> 'PSY'
	AND PtNo_Num < '20000000'
) A

PIVOT(
	COUNT([PAYER CATEGORY])
	FOR [ADM_MO] IN ("1","2","3","4","5","6","7","8","9","10","11","12")
) AS PVT

-- 2014 Admits Grand Totals -------------------------------------------
UNION ALL

SELECT *

FROM(
	SELECT
	  CASE
	    WHEN User_Pyr1_Cat 
	    IN (
	    '???', 'AAA', 'BBB', 'CCC', 
	    'DDD', 'EEE', 'III', 'JJJ',
	    'KKK', 'MIS', 'NNN', 'WWW',
	    'XXX', 'ZZZ'
	    )
	    THEN 'Grand Total 2014'      
	  END                               AS [Grand Total 2014]
	, User_Pyr1_Cat                     AS [Payer Category]
	, CAST(MONTH(ADM_DATE) AS INT)      AS [ADM_MO]

	FROM smsdss.BMH_PLM_PtAcct_V

	WHERE Adm_Date >= @ADM_START14 
	AND ADM_DATE < @ADM_END14
	AND tot_chg_amt > '0'
	AND Plm_Pt_Acct_Type='I'
	AND hosp_svc <> 'PSY'
	AND PtNo_Num < '20000000'	
) A

PIVOT(
	COUNT([PAYER CATEGORY])
	FOR [ADM_MO] IN ("1","2","3","4","5","6","7","8","9","10","11","12")
) AS PVT

-- 2015 Admits --------------------------------------------------------
-- Inser a query break here for results readability by excluding the
-- UNION ALL statement

SELECT *

FROM(
	SELECT 
	  CASE
		WHEN User_Pyr1_Cat IN ('AAA','ZZZ') Then 'Medicare'
		WHEN User_Pyr1_Cat = 'WWW' Then 'Medicaid'
		ELSE 'Other'
	  END                               AS [Payer Cat Admits 2015]
	, CASE
		WHEN User_Pyr1_Cat IN ('AAA','ZZZ') Then 'Medicare'
		WHEN User_Pyr1_Cat = 'WWW' Then 'Medicaid'
		ELSE 'Other'
	  END                               AS [Payer Category]
	, CAST(MONTH(ADM_DATE) AS INT)      AS [ADM_MO]

	FROM smsdss.BMH_PLM_PtAcct_V

	WHERE Adm_Date >= @ADM_START15 
	AND ADM_DATE < @ADM_END15
	AND tot_chg_amt > '0'
	AND Plm_Pt_Acct_Type='I'
	AND hosp_svc <> 'PSY'
	AND PtNo_Num < '20000000'	
) A

PIVOT(
	COUNT([PAYER CATEGORY])
	FOR [ADM_MO] IN ("1","2","3","4","5","6","7","8","9","10","11","12")
) AS PVT

-- 2015 Admits Grand Totals -------------------------------------------
UNION ALL

SELECT *

FROM(
	SELECT
	  CASE
	    WHEN User_Pyr1_Cat 
	    IN (
	    '???', 'AAA', 'BBB', 'CCC', 
	    'DDD', 'EEE', 'III', 'JJJ',
	    'KKK', 'MIS', 'NNN', 'WWW',
	    'XXX', 'ZZZ'
	    )
	    THEN 'Grand Total 2015'      
	  END                               AS [Grand Total 2015]
	, User_Pyr1_Cat                     AS [Payer Category]
	, CAST(MONTH(ADM_DATE) AS INT)      AS [ADM_MO]

	FROM smsdss.BMH_PLM_PtAcct_V

	WHERE Adm_Date >= @ADM_START15 
	AND ADM_DATE < @ADM_END15
	AND tot_chg_amt > '0'
	AND Plm_Pt_Acct_Type='I'
	AND hosp_svc <> 'PSY'
	AND PtNo_Num < '20000000'	
) A

PIVOT(
	COUNT([PAYER CATEGORY])
	FOR [ADM_MO] IN ("1","2","3","4","5","6","7","8","9","10","11","12")
) AS PVT