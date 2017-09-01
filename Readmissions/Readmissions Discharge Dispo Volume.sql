DECLARE @SD1 DATETIME;
DECLARE @ED1 DATETIME;
DECLARE @SD2 DATETIME;
DECLARE @ED2 DATETIME;

SET @SD1 = '01-01-2014';
SET @ED1 = '09-01-2014';
SET @SD2 = '01-01-2015';
SET @ED2 = '09-01-2015';

-- 2014 Admits --------------------------------------------------------
SELECT *

FROM(
	SELECT dsch_disp                              AS [Discharge Dispo 2014]
	, dsch_disp                                   AS [Dispo Cat]
	, CAST(MONTH(B.Adm_Date) AS INT)              AS [ADM_MO]
	
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
		
	--ORDER BY [Discharge Dispo 2014]
) A

PIVOT(
	COUNT([Dispo Cat])
	FOR [ADM_MO] IN ("1","2","3","4","5","6","7","8","9","10","11","12")
) AS PVT

-- 2014 Grand Totals --------------------------------------------------
UNION ALL

SELECT *

FROM(
	SELECT 
	  CASE 
	    WHEN dsch_disp = dsch_disp
	    THEN 'Grand Total 2014'
	END                                           AS [Discharge Dispo 2014]
	, dsch_disp                                   AS [Dispo Cat]
	, CAST(MONTH(B.Adm_Date) AS INT)              AS [ADM_MO]
	
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
	COUNT([Dispo Cat])
	FOR [ADM_MO] IN ("1","2","3","4","5","6","7","8","9","10","11","12")
) AS PVT

ORDER BY [Discharge Dispo 2014]