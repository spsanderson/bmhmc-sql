/*
Get Endo Room Cases from ORSOS
*/

DECLARE @ORSOS_START_DT DATETIME;
DECLARE @ORSOS_END_DT   DATETIME;

SET @ORSOS_START_DT = '2016-05-01 00:00:00';
SET @ORSOS_END_DT   = '2016-06-01 00:00:00';
---------------------------------------------------------------------------------------------------
DECLARE @ORSOS_ENDO_TBL TABLE (
	PK INT IDENTITY(1, 1)   PRIMARY KEY
	, [ORSOS Case No]       VARCHAR(10)
	, [DSS Case No]         VARCHAR(10)
	, [ORSOS MD ID]         VARCHAR(10)
	, [ORSOS Description]   VARCHAR(50)
	, [ORSOS Start Date]    DATE
	, [ORSOS Room ID]       VARCHAR(10)
	, [ORSOS Delete Flag]   VARCHAR(10)
	, [Ent Proc Rm Time]    TIME(0)
	, [Leave Proc Rm Time]  TIME(0)
	, [Procedure]           VARCHAR(MAX)
	, [Anes Start Date]     DATE
	, [Anes Start Time]     TIME(0)
	, [Anes End Date]       DATE
	, [Anes End Time]       TIME(0)
	, [Patient Type]        VARCHAR(5)
	, [Adm Recovery Date]   DATE
	, [Adm Recovery Time]   TIME(0)
	, [Leave Recovery Date] DATE
	, [Leave Recovery Time] TIME(0)
	, [DSS Src Pract No A]  VARCHAR(10)
	, [DSS Spclty Code A]   VARCHAR(10)
	, [DSS Spclty Desc A]   VARCHAR(100)
	, [DSS Src Pract No B]  VARCHAR(10)
	, [DSS Spclty Code B]   VARCHAR(10)
	, [DSS Spclty Desc B]   VARCHAR(100)
);

WITH CTE AS (
	SELECT A.CASE_NO
	, C.FACILITY_ACCOUNT_NO
	, E.RESOURCE_ID
	, F.DESCRIPTION AS RESOURCE_DESCRIPTION
	, CAST(A.START_DATE AS DATE) AS START_DATE
	, A.ROOM_ID
	, A.DELETE_FLAG
	, CAST(A.ENTER_PROC_ROOM_TIME AS TIME(0)) AS ENTER_PROC_ROOM_TIME
	, CAST(A.LEAVE_PROC_ROOM_TIME AS TIME(0)) AS LEAVE_PROC_ROOM_TIME
	, B.DESCRIPTION AS PROCEDURE_DESCRIPTION
	, CAST(D.ANES_START_DATE AS DATE) AS ANES_START_DATE
	, CAST(D.ANES_START_TIME AS TIME(0)) AS ANES_START_TIME
	, CAST(D.ANES_STOP_DATE AS DATE)  AS ANES_STOP_DATE
	, CAST(D.ANES_STOP_TIME AS TIME(0)) AS ANES_STOP_TIME
	, C.PATIENT_TYPE
	, CAST(A.ADMIT_RECOVERY_DATE AS DATE) AS ADMIT_RECOVERY_DATE
	, CAST(A.ADMIT_RECOVERY_TIME AS TIME(0)) AS ADMIT_RECOVERY_TIME
	, CAST(A.LEAVE_RECOVERY_DATE AS DATE) AS LEAVE_RECOVERY_DATE
	, CAST(A.LEAVE_RECOVERY_TIME AS TIME(0)) AS LEAVE_RECOVERY_TIME
	, G.src_pract_no AS SRC_PRACT_NO_A
	, G.src_spclty_cd AS SRC_SPCLTY_CD_A
	, G.spclty_desc AS SPCLTY_DESC_A
	, H.src_pract_no AS SRC_PRACT_NO_B
	, H.src_spclty_cd AS SRC_SPCLTY_CD_B
	, H.spclty_desc AS SPCLTY_DESC_B

	FROM 
	(
		(
			[BMH-ORSOS].[ORSPROD].[ORSPROD].[POST_CASE] AS A
			INNER JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[PROCEDURES] AS B
			ON A.MAIN_PROCEDURE_ID = B.PROCEDURE_ID
		)
		INNER JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[CLINICAL] AS C
		ON A.ACCOUNT_NO = C.ACCOUNT_NO
	)
	LEFT OUTER JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[POST_ANES_TYPE] AS D
	ON A.CASE_NO = D.CASE_NO
	LEFT OUTER JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[POST_RESOURCE] AS E
	ON A.CASE_NO = E.CASE_NO
		AND E.ROLE_CODE = '1'
	LEFT OUTER JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[CODES_ROLE] AS F
	ON E.ROLE_CODE = F.CODE
	-- TRY TO GET DSS PROVIDER ID MATCH UP
	LEFT OUTER JOIN smsdss.pract_dim_v AS G
	ON E.RESOURCE_ID = SUBSTRING(G.SRC_PRACT_NO, 1, 5)COLLATE SQL_Latin1_General_CP1_CI_AS
		AND G.orgz_cd = 'S0X0'
	LEFT OUTER JOIN smsdss.pract_dim_v AS H
	ON E.RESOURCE_ID = SUBSTRING(H.SRC_PRACT_NO, 1, 6)COLLATE SQL_Latin1_General_CP1_CI_AS
		AND H.orgz_cd = 'S0X0'

	WHERE (
		A.DELETE_FLAG IS NULL
		OR 
		(
			A.DELETE_FLAG = ''
			OR
			A.DELETE_FLAG = 'Z'
		)
	)
	AND A.ROOM_ID IN (
		'ENDO_01', 'ENDO_02', 'ENDO_03'
	)
	AND (
		A.START_DATE >= @ORSOS_START_DT
		AND
		A.START_DATE <  @ORSOS_END_DT 
	)
)

INSERT INTO @ORSOS_ENDO_TBL
SELECT * FROM CTE;

SELECT A.[ORSOS Case No]
, A.[DSS Case No]
, A.[ORSOS Description]
, A.[ORSOS Start Date]
, A.[ORSOS Room ID]
, A.[ORSOS Delete Flag]
, A.[Ent Proc Rm Time]
, A.[Leave Proc Rm Time]
, A.[Procedure]
, A.[Anes Start Date]
, A.[Anes Start Time]
, A.[Anes End Date]
, A.[Anes End Time]
, A.[Patient Type]
, A.[Adm Recovery Date]
, A.[Adm Recovery Time]
, A.[Leave Recovery Date]
, A.[Leave Recovery Time]
, A.[ORSOS MD ID]
, CASE
	WHEN A.[DSS Src Pract No A] IS NULL
		THEN A.[DSS Src Pract No B]
		ELSE A.[DSS Src Pract No A]
  END AS [DSS Src Pract No]
, CASE
	WHEN A.[DSS Spclty Code A] IS NULL
		THEN A.[DSS Spclty Code B]
		ELSE A.[DSS Spclty Code A]
  END AS [DSS Spclty Code]
, CASE
	WHEN A.[DSS Spclty Desc A] IS NULL
		THEN A.[DSS Spclty Desc B]
		ELSE A.[DSS Spclty Desc A]
  END AS [DSS Spclty Desc]

INTO #ORSOS_ENDO_TMP

FROM @ORSOS_ENDO_TBL AS A;

---------------------------------------------------------------------------------------------------
-- Get accounts with AMB Surge Fee 01800010 Ambulatory Surgery Fee
DECLARE @DSS_AmbSurg_Activity TABLE(
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, [Encounter]         VARCHAR(12)
	, [Total Actv Qty]    INT
	, [Total Actv Charge] MONEY
);

WITH CTE3 AS (
	SELECT pt_id
	, SUM(actv_tot_qty) AS total_quantity
	, SUM(chg_tot_amt)  AS total_charge

	FROM smsmir.actv

	WHERE actv_cd = '01800010'
	AND SUBSTRING(pt_id, 5, 8) IN (
		SELECT A.[DSS Case No]
		FROM @ORSOS_ENDO_TBL AS A
	)

	GROUP BY pt_id

	HAVING SUM(actv_tot_qty) > 0
	AND SUM(chg_tot_amt) > 0
)

INSERT INTO @DSS_AmbSurg_Activity
SELECT * FROM CTE3;

--SELECT TOP 5 * FROM @DSS_AmbSurg_Activity;
---------------------------------------------------------------------------------------------------
-- Get accounts with Operating Room Time Charges
DECLARE @DSS_OR_Time_Activity TABLE(
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, [Encounter]         VARCHAR(12)
	, [Total Actv Qty]    INT
	, [Total Actv Charge] MONEY
);

WITH CTE3 AS (
	SELECT pt_id
	, SUM(actv_tot_qty) AS total_quantity
	, SUM(chg_tot_amt)  AS total_charge

	FROM smsmir.actv

	WHERE actv_cd IN (
		'01800010', '00800011', '00800029', '00800037', '00800045', 
		'00800052', '00800060', '00800078', '00800086', '00800094', 
		'00800102', '00800110', '00800128', '00800136', '00800144', 
		'00800151', '00800169', '00800177', '00800185', '00800193', 
		'00800201', '00800219', '00800227', '00800235', '00800243', 
		'00800250', '00800268', '00800276', '00800284', '00800292', 
		'00800300', '00800318', '00800326'
	)
	AND SUBSTRING(pt_id, 5, 8) IN (
		SELECT A.[DSS Case No]
		FROM @ORSOS_ENDO_TBL AS A
	)

	GROUP BY pt_id

	HAVING SUM(actv_tot_qty) > 0
	AND SUM(chg_tot_amt) > 0
)

INSERT INTO @DSS_OR_Time_Activity
SELECT * FROM CTE3;

--SELECT TOP 5 * FROM @DSS_OR_Time_Activity;
---------------------------------------------------------------------------------------------------

SELECT A.*
, B.[Total Actv Qty]
, B.[Total Actv Charge]
, C.[Total Actv Qty]
, C.[Total Actv Charge]

FROM #ORSOS_ENDO_TMP AS A
LEFT OUTER JOIN @DSS_AmbSurg_Activity AS B
ON A.[DSS Case No] = SUBSTRING(B.Encounter, 5, 8)
LEFT OUTER JOIN @DSS_OR_Time_Activity AS C
ON A.[DSS Case No] = SUBSTRING(C.Encounter, 5, 8)
---------------------------------------------------------------------------------------------------
DROP TABLE #ORSOS_ENDO_TMP