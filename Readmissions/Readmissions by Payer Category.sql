DECLARE @SD1 DATETIME;
DECLARE @ED1 DATETIME;
DECLARE @SD2 DATETIME;
DECLARE @ED2 DATETIME;

SET @SD1 = '01-01-2014';
SET @ED1 = '09-01-2014';
SET @SD2 = '01-01-2015';
SET @ED2 = '09-01-2015';

-- 2014 Readmits ------------------------------------------------------
SELECT *

FROM(
	SELECT 
	  CASE
		WHEN B.User_Pyr1_Cat IN ('AAA','ZZZ') Then 'Medicare'
		WHEN B.User_Pyr1_Cat = 'WWW' Then 'Medicaid'
		ELSE 'Other'
	  END                                 AS [Payer Cat]
	, CASE
		WHEN B.User_Pyr1_Cat IN ('AAA','ZZZ') Then 'Medicare'
		WHEN B.User_Pyr1_Cat = 'WWW' Then 'Medicaid'
		ELSE 'Other'
	  END                                 AS [Payer Category]
	, CAST(MONTH(B.Adm_Date) AS INT)      AS [ADM_MO]
	
	FROM smsdss.vReadmits                         AS A
	JOIN smsdss.BMH_PLM_PtAcct_V                  AS B
	ON A.[INDEX] = B.PtNo_Num
	LEFT OUTER JOIN smsdss.c_LIHN_Svc_Lines_Rpt_v AS E
	ON A.[INDEX]=CAST(e.pt_id AS INT)

	WHERE B.Adm_Date >= @SD1 AND B.Adm_Date < @ED1
	AND A.INTERIM < 31
	AND A.[READMIT SOURCE DESC] != 'Scheduled Admission'	
	AND B.hosp_svc != 'PSY'
	AND B.tot_chg_amt > '0'
	AND B.Plm_Pt_Acct_Type='I'
	AND E.[ICD_CD_SCHM] = '9'
	AND (
		E.PROC_CD_SCHM = '9'
		OR
		E.PROC_CD_SCHM IS NULL
		)
) A

PIVOT(
	COUNT([PAYER CATEGORY])
	FOR [ADM_MO] IN ("1","2","3","4","5","6","7","8","9","10","11","12")
) AS PVT

-- 2014 Readmits Grand Total ------------------------------------------
UNION ALL

SELECT *

FROM(
	SELECT
	  CASE
	    WHEN B.User_Pyr1_Cat 
	    IN (
	    '???', 'AAA', 'BBB', 'CCC', 
	    'DDD', 'EEE', 'III', 'JJJ',
	    'KKK', 'MIS', 'NNN', 'WWW',
	    'XXX', 'ZZZ'
	    )
	    THEN 'Grand Total 2014'      
	  END                               AS [Grand Total 2014]
	  , B.User_Pyr1_Cat                 AS [Payer Category]
	  , CAST(MONTH(B.ADM_DATE) AS INT)  AS [ADM_MO]	  
	  
	FROM smsdss.vReadmits                         AS A
	JOIN smsdss.BMH_PLM_PtAcct_V                  AS B
	ON A.[INDEX] = B.PtNo_Num
	LEFT OUTER JOIN smsdss.c_LIHN_Svc_Lines_Rpt_v AS E
	ON A.[INDEX]=CAST(e.pt_id AS INT)

	WHERE B.Adm_Date >= @SD1 AND B.Adm_Date < @ED1
	AND A.INTERIM < 31
	AND A.[READMIT SOURCE DESC] != 'Scheduled Admission'	
	AND B.hosp_svc != 'PSY'
	AND B.tot_chg_amt > '0'
	AND B.Plm_Pt_Acct_Type='I'
	AND E.[ICD_CD_SCHM] = '9'
	AND (
		E.PROC_CD_SCHM = '9'
		OR
		E.PROC_CD_SCHM IS NULL
		)
) A

PIVOT(
	COUNT([PAYER CATEGORY])
	FOR [ADM_MO] IN ("1","2","3","4","5","6","7","8","9","10","11","12")
) AS PVT

-- 2015 Readmits ------------------------------------------------------
SELECT *

FROM(
	SELECT 
	  CASE
		WHEN B.User_Pyr1_Cat IN ('AAA','ZZZ') Then 'Medicare'
		WHEN B.User_Pyr1_Cat = 'WWW' Then 'Medicaid'
		ELSE 'Other'
	  END                                 AS [Payer Cat]
	, CASE
		WHEN B.User_Pyr1_Cat IN ('AAA','ZZZ') Then 'Medicare'
		WHEN B.User_Pyr1_Cat = 'WWW' Then 'Medicaid'
		ELSE 'Other'
	  END                                 AS [Payer Category]
	, CAST(MONTH(B.Adm_Date) AS INT)      AS [ADM_MO]
	
	FROM smsdss.vReadmits                         AS A
	JOIN smsdss.BMH_PLM_PtAcct_V                  AS B
	ON A.[INDEX] = B.PtNo_Num
	LEFT OUTER JOIN smsdss.c_LIHN_Svc_Lines_Rpt_v AS E
	ON A.[INDEX]=CAST(e.pt_id AS INT)

	WHERE B.Adm_Date >= @SD2 AND B.Adm_Date < @ED2
	AND A.INTERIM < 31
	AND A.[READMIT SOURCE DESC] != 'Scheduled Admission'	
	AND B.hosp_svc != 'PSY'
	AND B.tot_chg_amt > '0'
	AND B.Plm_Pt_Acct_Type='I'
	AND E.[ICD_CD_SCHM] = '9'
	AND (
		E.PROC_CD_SCHM = '9'
		OR
		E.PROC_CD_SCHM IS NULL
		)
) A

PIVOT(
	COUNT([PAYER CATEGORY])
	FOR [ADM_MO] IN ("1","2","3","4","5","6","7","8","9","10","11","12")
) AS PVT

-- 2015 Readmits Grand Total ------------------------------------------
UNION ALL

SELECT *

FROM(
	SELECT
	  CASE
	    WHEN B.User_Pyr1_Cat 
	    IN (
	    '???', 'AAA', 'BBB', 'CCC', 
	    'DDD', 'EEE', 'III', 'JJJ',
	    'KKK', 'MIS', 'NNN', 'WWW',
	    'XXX', 'ZZZ'
	    )
	    THEN 'Grand Total 2015'      
	  END                               AS [Grand Total 2015]
	  , B.User_Pyr1_Cat                 AS [Payer Category]
	  , CAST(MONTH(B.ADM_DATE) AS INT)  AS [ADM_MO]	  
	  
	FROM smsdss.vReadmits                         AS A
	JOIN smsdss.BMH_PLM_PtAcct_V                  AS B
	ON A.[INDEX] = B.PtNo_Num
	LEFT OUTER JOIN smsdss.c_LIHN_Svc_Lines_Rpt_v AS E
	ON A.[INDEX]=CAST(e.pt_id AS INT)

	WHERE B.Adm_Date >= @SD2 AND B.Adm_Date < @ED2
	AND A.INTERIM < 31
	AND A.[READMIT SOURCE DESC] != 'Scheduled Admission'	
	AND B.hosp_svc != 'PSY'
	AND B.tot_chg_amt > '0'
	AND B.Plm_Pt_Acct_Type='I'
	AND E.[ICD_CD_SCHM] = '9'
	AND (
		E.PROC_CD_SCHM = '9'
		OR
		E.PROC_CD_SCHM IS NULL
		)
) A

PIVOT(
	COUNT([PAYER CATEGORY])
	FOR [ADM_MO] IN ("1","2","3","4","5","6","7","8","9","10","11","12")
) AS PVT