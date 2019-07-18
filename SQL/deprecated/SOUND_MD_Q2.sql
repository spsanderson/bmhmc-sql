SET ANSI_NULLS OFF
GO
-- VARIABLE DECLARATION AND INITIALIZATION
DECLARE @SD DATETIME;
DECLARE @ED DATETIME;
SET @SD = '2014-01-01';
SET @ED = '2014-01-31';

/*
-----------------------------------------------------------------------
THIS QUERY WILL GET ALL THE DISCHARGE DIAGNOSIS INFORMATION
-----------------------------------------------------------------------
START OF QUERY 1
-----------------------------------------------------------------------
*/
-- TABLE DECLARATION
DECLARE @T1 TABLE (
	[ENCOUNTER ID] VARCHAR(200) UNIQUE CLUSTERED
)
-- WHAT GETS INSERTED INTO @T1
INSERT INTO @T1
SELECT
A.[VISIT ID]
-- END @T1 INSERT SELECTION

-- WHERE IT ALL COMES FROM
-- COLUMN SELECTION
FROM (
	SELECT DISTINCT PAV.PtNo_Num AS [VISIT ID]

	-- FROM DB(S)
	FROM smsdss.BMH_PLM_PtAcct_V PAV
	JOIN smsdss.pract_dim_v PDV
	ON PAV.Adm_Dr_No = PDV.src_pract_no

	-- FILTER(S)
	WHERE PAV.Dsch_Date BETWEEN @SD AND @ED
	AND PAV.Plm_Pt_Acct_Type = 'I'
	AND PAV.PtNo_Num < '20000000'
	AND PDV.src_spclty_cd = 'HOSIM'
	AND PDV.orgz_cd = 'S0X0'
) A
/*
-----------------------------------------------------------------------
END OF QUERY ONE (1)
-----------------------------------------------------------------------
*/
--#####################################################################
/*
-----------------------------------------------------------------------
QUERY TWO (2)
-----------------------------------------------------------------------
*/
-- TABLE @T2 DECLARATION
DECLARE @T2 TABLE (
	[ENCOUNTER ID] VARCHAR(200)
	, [DX CD] VARCHAR(200)
	, [DX PRIORITY CD] VARCHAR(200)
)

-- WHAT GETS INSERTED INTO @T2
INSERT INTO @T2 
SELECT
B.PtNo_Num AS [ENCOUNTER ID]
, B.ClasfCd AS [DX CD]
, B.ClasfPrio [DX PRIORITY CD]

-- WHERE IT COMES FROM
FROM (
	SELECT PtNo_Num
	, ClasfCd
	, ClasfPrio
	FROM smsdss.BMH_PLM_PtAcct_Clasf_Dx_V
	WHERE SortClasfType = 'DF'
	AND ClasfPrio IN (
		1,2,3
	)
	AND PtNo_Num < '20000000'
) B
/*
-----------------------------------------------------------------------
END OF QUERY TWO (2)
-----------------------------------------------------------------------
*/
/*
-----------------------------------------------------------------------
PUTTING IT ALL TOGETHER NOW
-----------------------------------------------------------------------
*/
SELECT *

FROM @T1 T1
LEFT JOIN @T2 T2
ON T1.[ENCOUNTER ID] = T2.[ENCOUNTER ID]