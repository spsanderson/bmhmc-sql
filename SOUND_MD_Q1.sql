/*
THIS REPORT IS FOR SOUND PHYSICIAN, IT WILL BE USED ON A MONTHLY
BASIS GOING FORWARD IN ORDER FOR THEIR INTERNAL BENCHMARKING
*/
SET ANSI_NULLS OFF
GO
-- VARIABLE DECLARATION AND INITIALIZATION
DECLARE @SD DATETIME;
DECLARE @ED DATETIME;
SET @SD = '2012-10-01';
SET @ED = '2013-09-30';

/*
-----------------------------------------------------------------------
THIS QUERY WILL GET ALL THE FRONT END INFORMATION REQUIRED FOR HOSIM
AND INSERT IT INTO A TABLE THAT WILL GET MATCHED UP WITH THE DISCHARGE
ORDERS TABLE
-----------------------------------------------------------------------
START OF QUERY 1
-----------------------------------------------------------------------
*/

-- TABLE DECLARATION
DECLARE @T1 TABLE (
[ENCOUNTER ID] VARCHAR(200)
, FINANCIALCLASSORIG VARCHAR(200)
, [ADMIT DATE] DATE
, [ADMIT TIME] TIME
, [ADMIT FROM] VARCHAR(200)
, [DISCHARGE DATE] DATE
, [DISCHARGE TIME] TIME
, [MS DRG] VARCHAR(200)
, LOS VARCHAR(20)
, [ADMIT PATIENT STATUS] VARCHAR (10)
, [DISCHARGE PATIENT STATUS] VARCHAR(10)
, [DISCHARGE DISPOSITION] VARCHAR (200)
, [DISCHARGE UNIT] VARCHAR (200)
)
-- WHAT GETS INSERTED INTO @T1
INSERT INTO @T1
SELECT
A.[VISIT ID]
, A.FINANCIALCLASSORIG
, A.[ADMIT DATE]
, A.[ADMIT TIME]
, A.[ADMIT FROM]
, A.[DISCHARGE DATE]
, A.[DISCHARGE TIME]
, A.[MS DRG]
, A.LOS
, A.[ADMIT PATIENT STATUS]
, A.[DISCHARGE PATIENT STATUS]
, A.[DISCHARGE DISPOSITION]
, A.[DISCHARGE UNIT]
-- END @T1 INSERT SELECTION

-- WHERE IT ALL COMES FROM
-- COLUMN SELECTION
FROM (
SELECT DISTINCT PAV.PtNo_Num AS [VISIT ID]
, PD.pyr_name AS [FinancialClassOrig]
, CAST(PAV.Adm_Date AS DATE) AS [ADMIT DATE]
, CAST(PAV.vst_start_dtime AS TIME) AS [ADMIT TIME]
, PAV.Adm_Source AS [ADMIT FROM]
, CAST(PAV.Dsch_Date AS DATE) AS [DISCHARGE DATE]
, CAST(PAV.Dsch_DTime AS TIME) AS [DISCHARGE TIME]
, PAV.drg_no AS [MS DRG]
, PAV.Days_Stay AS [LOS]
, 'I' AS [ADMIT PATIENT STATUS]
, 'I' AS [DISCHARGE PATIENT STATUS]
, DDM.dsch_disp_desc AS [DISCHARGE DISPOSITION]
, VR.ward_cd AS [DISCHARGE UNIT]

-- FROM DB(S)
FROM smsdss.BMH_PLM_PtAcct_V PAV
JOIN smsdss.pract_dim_v PDV
ON PAV.Adm_Dr_No = PDV.src_pract_no
JOIN smsdss.pyr_dim PD
ON PAV.Pyr1_Co_Plan_Cd = PD.pyr_cd
JOIN smsmir.vst_rpt VR
ON PAV.PtNo_Num = VR.acct_no
JOIN smsdss.dsch_disp_mstr DDM
ON VR.dsch_disp = DDM.dsch_disp

-- FILTER(S)
WHERE PAV.Dsch_Date BETWEEN @SD AND @ED
AND PAV.Plm_Pt_Acct_Type = 'I'
AND PAV.PtNo_Num < '20000000'
AND PDV.src_spclty_cd = 'HOSIM'
AND PD.orgz_cd = 'S0X0'
AND PD.pyr_name != '?'
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
, [ORDER NUMBER] VARCHAR(200)
, [ORDER DATE] DATE
, [ORDER TIME] TIME
)

-- WHAT GETS INSERTED INTO @T2
INSERT INTO @T2
SELECT
SRC.episode_no
, SRC.ord_no
, SRC.DATE
, SRC.TIME


-- WHERE IT ALL COMES FROM
FROM (
	SELECT EPISODE_NO
	, ORD_NO
	, CAST(ENT_DTIME AS DATE) AS [DATE]
	, CAST(ENT_DTIME AS TIME) AS [TIME]
	, ROW_NUMBER() OVER(
						PARTITION BY EPISODE_NO ORDER BY ORD_NO
						) AS ROWNUM
	FROM smsmir.sr_ord
	WHERE svc_desc = 'DISCHARGE TO'
	AND episode_no < '20000000'
) SRC

WHERE SRC.ROWNUM = 1

--SELECT * FROM @T2
/*
-----------------------------------------------------------------------
END OF QUERY TWO (2)
-----------------------------------------------------------------------
*/

/*
PUTTING IT ALL TOGETHER NOW
*/

SELECT T1.FINANCIALCLASSORIG
, T1.[ADMIT DATE]
, T1.[ADMIT TIME]
, T1.[ADMIT FROM]
, T1.[DISCHARGE DATE]
, T1.[DISCHARGE TIME]
, T1.[MS DRG]
, T1.LOS
, T1.[ADMIT PATIENT STATUS]
, T1.[DISCHARGE PATIENT STATUS]
, T1.[DISCHARGE DISPOSITION]
, T1.[DISCHARGE UNIT]
, ISNULL(T2.[ORDER DATE], '1800-01-01') AS [ORDER DATE]
, ISNULL(T2.[ORDER TIME], '00:00:00') AS [ORDER TIME]

FROM @T1 T1
LEFT JOIN @T2 T2
ON T1.[ENCOUNTER ID] = T2.[ENCOUNTER ID]