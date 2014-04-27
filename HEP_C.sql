SET ANSI_NULLS OFF
GO

-- VARIABLE DECLARATION AND INITIALIZATION
DECLARE @SD DATETIME;
DECLARE @ED DATETIME;
DECLARE @BD1 DATETIME;
DECLARE @BD2 DATETIME;
SET @SD = '2014-01-01';
SET @ED = '2014-01-31';
SET @BD1 = '1945-01-01';
SET @BD2 = '1965-12-31';

/*
THIS QUERY WILL CREATE A TABLE THAT ALL OF THE PEOPLE WHO ARE BORN
BETWEEN THE YEARS SPECIFIED WILL POPULATE
*/
-- TABLE DECLARATION
DECLARE @T1 TABLE (
[ENCOUNTER ID] VARCHAR(200)
, [ATTENDING] VARCHAR(200)
)
-- WHAT GETS INSERTED INTO @T1
INSERT INTO @T1
SELECT
A.[VISIT ID]
, A.ATTENDING

-- FROM
FROM (
	SELECT DISTINCT PTNO_NUM AS [VISIT ID]
	, pract_rpt_name AS [ATTENDING]
	FROM smsdss.BMH_PLM_PtAcct_V
	JOIN smsdss.pract_dim_v
	ON Atn_Dr_No = src_pract_no
	WHERE Pt_Birthdate BETWEEN @BD1 AND @BD2
	AND Dsch_Date BETWEEN @SD AND @ED
	AND Plm_Pt_Acct_Type = 'I'
	AND PtNo_Num < '20000000'
	AND orgz_cd = 'S0X0'
) A
--SELECT * FROM @T1
/*
-----------------------------------------------------------------------
END OF QUERY ONE (1)
-----------------------------------------------------------------------
*/
--#####################################################################
/*
-----------------------------------------------------------------------
START OF QUERY TWO (2)
-----------------------------------------------------------------------
*/
-- @T2 DECLARATION
DECLARE @T2 TABLE (
[ENCOUNTER ID] VARCHAR(200)
, [ORDERING PARTY] VARCHAR(200)
, [ORDER NUMBER] VARCHAR(200)
, [ORDER DESC] VARCHAR(500)
, [GOT HEP C ORDER] VARCHAR(200)
)

-- WHAT GETS INSERTED INTO @T2
INSERT INTO @T2
SELECT
B.[ENCOUNTER ID]
, B.[ORDERING PARTY]
, B.[ORD NO]
, B.[ORDER DESC]
, B.ROWNUM

-- WHERE IT ALL COMES FROM
FROM (
	SELECT EPISODE_NO AS [ENCOUNTER ID]
	, pty_name AS [ORDERING PARTY]
	, ord_no AS [ORD NO]
	, svc_desc AS [ORDER DESC]
	, ROW_NUMBER() OVER(
					PARTITION BY EPISODE_NO ORDER BY ORD_NO
					) AS ROWNUM
					
	FROM smsmir.sr_ord
	WHERE svc_desc IN (
		'HEPATITIS C GENOTYPE'
		, 'HEPATITIS C'
		, 'HEPATITIS PANEL ( B AND C)'
		)
	AND episode_no < '20000000'
) B

WHERE B.ROWNUM = 1

--SELECT * FROM @T2
/*
-----------------------------------------------------------------------
END OF QUERY TWO (2)
-----------------------------------------------------------------------
*/
--#####################################################################
/*
-----------------------------------------------------------------------
PUTTING IT ALL TOGETHER NOW
-----------------------------------------------------------------------
*/
SELECT DISTINCT T1.[ENCOUNTER ID]
, T1.ATTENDING
, ISNULL(T2.[ORDERING PARTY], 'NO ORDER') AS [ORDERING PARTY]
, ISNULL(T2.[ORDER DESC], 'NO ORDER') AS [ORDER DESC]
, ISNULL(T2.[ORDER NUMBER], 'NO ORDER') AS [ORDER NUMBER]

FROM @T1 T1
LEFT JOIN @T2 T2
ON T1.[ENCOUNTER ID] = T2.[ENCOUNTER ID]