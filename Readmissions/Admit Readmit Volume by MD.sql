DECLARE @SD1 DATE;
DECLARE @SD2 DATE;
DECLARE @ED1 DATE;
DECLARE @ED2 DATE;
DECLARE @SCD CHAR(5);

SET @SD1 = '2015-01-01';
SET @SD2 = '2016-01-01';
SET @ED1 = '2016-01-01';
SET @ED2 = '2016-02-01';
SET @SCD = 'HOSIM';

DECLARE @Admits1 TABLE (
	[Doctor]          VARCHAR(50)
	, [# Admits 2015] INT
);

WITH Admits1 AS (
	SELECT B.pract_rpt_name AS MD
	, COUNT(A.PtNo_Num)     AS [# Admits]

	FROM SMSDSS.BMH_PLM_PtAcct_V       AS A
	LEFT OUTER JOIN SMSDSS.pract_dim_v AS B
	ON A.Atn_Dr_No = B.src_pract_no
		AND B.orgz_cd = 'S0X0'

	WHERE A.hosp_svc != 'PSY'
	AND A.PtNo_Num < '20000000'
	AND A.Plm_Pt_Acct_Type = 'I'
	AND B.spclty_cd != @SCD
	AND A.tot_chg_amt > 0
	AND A.Adm_Date >= @SD1
	AND A.Adm_Date < @ED1

	GROUP BY B.pract_rpt_name
)

INSERT INTO @Admits1
SELECT * FROM Admits1

--SELECT * FROM @Admits1
-----------------------------------------------------------------------
DECLARE @Admits2 TABLE (
	[Doctor]          VARCHAR(50)
	, [# Admits 2016] INT
);

WITH Admits2 AS (
	SELECT B.pract_rpt_name AS MD
	, COUNT(A.PtNo_Num)     AS [# Admits]

	FROM SMSDSS.BMH_PLM_PtAcct_V       AS A
	LEFT OUTER JOIN SMSDSS.pract_dim_v AS B
	ON A.Atn_Dr_No = B.src_pract_no
		AND B.orgz_cd = 'S0X0'

	WHERE A.hosp_svc != 'PSY'
	AND A.PtNo_Num < '20000000'
	AND A.Plm_Pt_Acct_Type = 'I'
	AND B.spclty_cd != @SCD
	AND A.tot_chg_amt > 0
	AND A.Adm_Date >= @SD2
	AND A.Adm_Date < @ED2

	GROUP BY B.pract_rpt_name
)

INSERT INTO @Admits2
SELECT * FROM Admits2

--SELECT * FROM @Admits2
-----------------------------------------------------------------------
DECLARE @Readmits1 TABLE (
	Doctor              VARCHAR(50)
	, [# Readmits 2015] INT
);

WITH Readmits1 AS (
	SELECT C.pract_rpt_name AS MD
	, COUNT(A.[READMIT])    AS Readmit_Count

	FROM smsdss.vReadmits                         AS A
	LEFT OUTER MERGE JOIN smsdss.bmh_plm_ptacct_v AS B
	ON a.[INDEX] = b.PtNo_Num
		AND a.MRN = b.Med_Rec_No
	LEFT OUTER JOIN smsdss.pract_dim_v            AS C
	ON b.Atn_Dr_No = c.src_pract_no
		AND c.orgz_cd = 'S0X0'

	WHERE INTERIM < 31
	AND a.[READMIT SOURCE DESC] != 'Scheduled Admission'
	AND b.hosp_svc != 'PSY'
	AND b.Adm_Date >= @SD1
	AND b.Adm_Date < @ED1
	AND b.tot_chg_amt > 0
	AND C.spclty_cd != @SCD

	GROUP BY C.pract_rpt_name
)

INSERT INTO @Readmits1
SELECT * FROM Readmits1

--SELECT * FROM @Readmits1

-----------------------------------------------------------------------
DECLARE @Readmits2 TABLE (
	Doctor              VARCHAR(50)
	, [# Readmits 2016] INT
);

WITH Readmits2 AS (
	SELECT C.pract_rpt_name AS MD
	, COUNT(A.[READMIT])    AS Readmit_Count

	FROM smsdss.vReadmits                         AS A
	LEFT OUTER MERGE JOIN smsdss.bmh_plm_ptacct_v AS B
	ON a.[INDEX] = b.PtNo_Num
		AND a.MRN = b.Med_Rec_No
	LEFT OUTER JOIN smsdss.pract_dim_v            AS C
	ON b.Atn_Dr_No = c.src_pract_no
		AND c.orgz_cd = 'S0X0'

	WHERE INTERIM < 31
	AND a.[READMIT SOURCE DESC] != 'Scheduled Admission'
	AND b.hosp_svc != 'PSY'
	AND b.Adm_Date >= @SD2
	AND b.Adm_Date < @ED2
	AND b.tot_chg_amt > 0
	AND C.spclty_cd != @SCD

	GROUP BY C.pract_rpt_name
)

INSERT INTO @Readmits2
SELECT * FROM Readmits2

--SELECT * FROM @Readmits2
-----------------------------------------------------------------------
SELECT 
CASE
	WHEN A.Doctor IS NULL
		THEN B.Doctor
		ELSE A.Doctor
END AS Doctor
, ISNULL(A.[# Admits 2015], 0)   AS [# Admits 2015]
, ISNULL(C.[# Readmits 2015], 0) AS [# Readmits 2015]
, ''                             AS [Readmit % 2015]
, ISNULL(B.[# Admits 2016], 0)   AS [# Admits 2016]
, ISNULL(D.[# Readmits 2016], 0) AS [# Readmits 2016]
, ''                             AS [Readmit % 2016]

FROM @Admits1              AS A
FULL OUTER JOIN @Admits2   AS B
ON A.Doctor = B.Doctor
FULL OUTER JOIN @Readmits1 AS C
ON A.Doctor = C.Doctor
FULL OUTER JOIN @Readmits2 AS D
ON A.Doctor = D.Doctor

ORDER BY Doctor