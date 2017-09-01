DECLARE @SD1 DATETIME;
DECLARE @ED1 DATETIME;
DECLARE @SD2 DATETIME;
DECLARE @ED2 DATETIME;

-- DISCHARGE DATES USED
SET @SD1 = '2014-01-01';
SET @ED1 = '2014-09-01';
SET @SD2 = '2015-01-01';
SET @ED2 = '2015-09-01';

-- Get admissions by attnding md
DECLARE @T1 TABLE (
	[Attending MD]      VARCHAR(100) 
	, [Discharges 2014] VARCHAR(10)
	, [Discharges 2015] VARCHAR(10)
)

INSERT INTO @T1
SELECT *
FROM (
	SELECT PDV.pract_rpt_name                     AS [Attending MD]
	, PDV.pract_rpt_name                          AS [# Of Admits]
	, YEAR(PAV.DSCH_DATE)                         AS [Discharge Year]
	
	FROM smsdss.BMH_PLM_PtAcct_V                  AS PAV
	LEFT JOIN smsdss.pract_dim_v                  AS PDV
	ON PAV.Atn_Dr_No = PDV.src_pract_no
	
	WHERE PAV.Plm_Pt_Acct_Type = 'I'
	AND PAV.PtNo_Num < '20000000'
	AND (
		PAV.Dsch_Date >= @SD1 AND PAV.Dsch_Date < @ED1
		OR
		PAV.Dsch_Date >= @SD2 AND PAV.Dsch_Date < @ED2
		)
	AND PDV.orgz_cd = 'S0X0'
	AND PAV.tot_chg_amt > '0'
	AND PAV.hosp_svc != 'PSY'
	-- Filter out OR for hospitailists
	AND PDV.spclty_cd != 'HOSIM'
) AS A

PIVOT (
	COUNT([Attending MD])
	FOR [Discharge Year] IN ("2014", "2015")
) AS PVT

--SELECT * FROM @T1 

-- Getting Readmits Volume by Attending
DECLARE @T2 TABLE (
	[Readmit Attending] VARCHAR(100)
	, [Readmits 2014] VARCHAR(10)
	, [Readmits 2015] VARCHAR(10)
)

INSERT INTO @T2
SELECT *
FROM (
	SELECT C.pract_rpt_name                 AS [Readmit Attn]
	, C.pract_rpt_name                      AS [# of Readmits]
	, YEAR(B.Dsch_Date)                     AS [Readmit Year]
	
	FROM smsdss.vReadmits                   AS R
	LEFT OUTER JOIN smsdss.BMH_PLM_PtAcct_V AS B
	ON R.[INDEX]  = B.Pt_No
	LEFT OUTER JOIN smsdss.pract_dim_v      AS C
	ON B.Atn_Dr_No = C.pract_no
	
	WHERE B.Plm_Pt_Acct_Type = 'I'
	AND B.PtNo_Num < '20000000'
	AND (
		B.DSCH_DATE >= @SD1 AND B.DSCH_DATE < @ED1
		OR
		B.DSCH_DATE >= @SD2 AND B.DSCH_DATE < @ED2
		)
	AND C.orgz_cd = 'S0X0'
	AND B.tot_chg_amt > '0'
	AND B.hosp_svc != 'PSY'
	-- Filter out OR for hospitailists
	AND C.spclty_cd != 'HOSIM'
	AND R.INTERIM < 31
	AND R.[READMIT SOURCE DESC] != 'Scheduled Admission'
) AS B

PIVOT (
	COUNT([Readmit Attn])
	FOR [Readmit Year] IN ("2014", "2015")
) AS PVT2

--SELECT * FROM @T2

-- Bring it all together
SELECT UPPER(T1.[Attending MD])    AS [Attending MD]
, T1.[Discharges 2014]             AS [Discharges 2014]
, CASE 
	WHEN T2.[Readmits 2014] IS NULL 
	THEN '0' 
	ELSE T2.[READMITS 2014] 
  END                              AS [Readmits 2014]
, CASE
	WHEN T1.[Discharges 2014] = 0
	THEN 0
	WHEN T2.[Readmits 2014] IS NULL
	THEN 0
	ELSE ROUND((CAST(T2.[Readmits 2014] AS FLOAT))
		/
		(T1.[DISCHARGES 2014]), 2)
  END                              AS [Readmit % 2014]
, T1.[Discharges 2015]             AS [Discharges 2015]
, CASE
	WHEN T2.[Readmits 2015] IS NULL THEN '0'
	ELSE T2.[Readmits 2015]
  END                              AS [Readmits 2015]
, CASE
	WHEN T1.[Discharges 2015] = 0
	THEN 0
	WHEN T2.[Readmits 2015] IS NULL
	THEN 0
	ELSE ROUND((CAST(T2.[Readmits 2015] AS FLOAT))
		/
		(T1.[Discharges 2015]), 2) 
  END                              AS [Readmit % 2015]

FROM @T1 T1
LEFT JOIN @T2 T2
ON T1.[Attending MD] = T2.[Readmit Attending]