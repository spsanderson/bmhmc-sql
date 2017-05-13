DECLARE @SD1 DATETIME;
DECLARE @ED1 DATETIME;
DECLARE @SD2 DATETIME;
DECLARE @ED2 DATETIME;
DECLARE @ICD VARCHAR(2);

-- DISCHARGE DATES USED
SET @SD1 = '2014-01-01';
SET @ED1 = '2014-10-01';
SET @SD2 = '2015-01-01';
SET @ED2 = '2015-10-01';
SET @ICD = '9';

-- Getting admissions volume by service line
DECLARE @T1 TABLE (
	[Service Line]      VARCHAR(100) PRIMARY KEY
	, [Admits 2014]     VARCHAR(10)
	, [Admits 2015]     VARCHAR(10)
)

INSERT INTO @T1 
SELECT *
FROM (
	SELECT LIHN.LIHN_Svc_Line AS [LIHN Service Line]
	, LIHN.LIHN_Svc_Line      AS [# Of Admits to Service Line]
	, YEAR(PAV.DSCH_DATE)     AS [Discharge Year]

	FROM smsdss.BMH_PLM_PtAcct_V                  AS PAV
	LEFT OUTER JOIN smsdss.c_LIHN_Svc_Lines_Rpt_v AS LIHN
	ON PAV.Pt_No = LIHN.pt_id

	WHERE PAV.Plm_Pt_Acct_Type = 'I'
	AND PAV.PtNo_Num < '20000000'
	AND (
		PAV.DSCH_DATE >= @SD1 AND PAV.DSCH_DATE < @ED1
		OR
		PAV.DSCH_DATE >= @SD2 AND PAV.DSCH_DATE < @ED2
		)
	AND LIHN.LIHN_Svc_Line IS NOT NULL
	AND LIHN.[ICD_CD_SCHM] = @ICD
	AND PAV.hosp_svc != 'PSY'
) AS A

PIVOT (
	COUNT([LIHN Service Line])
	FOR [Discharge Year] IN ("2014", "2015")
) AS PVT

--SELECT * FROM @T1

-- Getting Readmits Volume by Service Line
DECLARE @T2 TABLE (
	[Readmit Service Line] VARCHAR(100) PRIMARY KEY
	, [Readmits 2014]      VARCHAR(10)
	, [Readmits 2015]      VARCHAR(10)
)

INSERT INTO @T2
SELECT *
FROM (
	SELECT E.LIHN_Svc_Line AS [Readmit LIHN Service Line]
	, e.LIHN_Svc_Line      AS [# Of Readmits to Service Line]
	, YEAR(b.dsch_date)    AS [Readmit Discharge Year]

	FROM smsdss.vReadmits                         AS R
	LEFT OUTER JOIN smsdss.bmh_plm_ptacct_v       AS b
	ON R.[INDEX] = b.ptno_num
	LEFT OUTER JOIN smsdss.c_LIHN_Svc_Lines_Rpt_v AS e
	ON R.[INDEX]=CAST(e.pt_id AS INT) 

	WHERE B.Plm_Pt_Acct_Type = 'I'
	AND B.PtNo_Num < '20000000'
	AND(
		B.Dsch_Date >= @SD1 AND B.Dsch_Date < @ED1
		OR
		B.Dsch_Date >= @SD2 AND B.Dsch_Date < @ED2
		)
	AND E.LIHN_Svc_Line IS NOT NULL
	AND E.[ICD_CD_SCHM] = @ICD
	AND R.INTERIM < 31
	AND R.[READMIT SOURCE DESC] != 'Scheduled Admission'
	AND b.hosp_svc != 'PSY'
) AS B

PIVOT (
	COUNT([Readmit LIHN Service Line])
	FOR [Readmit Discharge Year] IN ("2014","2015")
) AS PVT2

--Select * from @T2

-- join the tables together
SELECT T1.[Service Line]
, T1.[Admits 2014]               AS [Admits 2014]
, CASE
	WHEN T2.[Readmits 2014] IS NULL 
	THEN '0'
	ELSE T2.[Readmits 2014]
  END                            AS [Readmits 2014]
, CASE
	WHEN T1.[Admits 2014] = 0
	THEN 0
	WHEN T2.[Readmits 2014] IS NULL
	THEN 0
	ELSE ROUND((CAST(T2.[Readmits 2014] AS FLOAT))
	/
   (T1.[Admits 2014]),2)    
  END                            AS [Readmit % 2014]
, T1.[Admits 2015]               AS [Admits 2015]
, CASE
	WHEN T2.[Readmits 2015] IS NULL
	THEN 0
	ELSE T2.[Readmits 2015]      
  END                            AS [Readmits 2015]
, CASE
	WHEN T1.[Admits 2015] = 0
	THEN 0
	WHEN T2.[Readmits 2015] IS NULL
	THEN 0
	ELSE  ROUND((CAST(T2.[Readmits 2015] AS FLOAT))
	/
   (T1.[Admits 2015]), 2)   
  END AS [Readmit % 2015]

FROM @T1 T1
LEFT JOIN @T2 T2
ON T1.[Service Line] = T2.[Readmit Service Line]