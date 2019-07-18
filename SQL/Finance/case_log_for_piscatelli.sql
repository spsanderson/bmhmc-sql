/*
Get OR Room cases and the provider id to fill out the inpatient and out patient surgery trend
report
*/
---------------------------------------------------------------------------------------------------
-- V A R I A B L E - D E C L A R A T I O N                                                        |
---------------------------------------------------------------------------------------------------
DECLARE @BMH_START_1    DATETIME;
DECLARE @BMH_END_1      DATETIME;
DECLARE @BMH_START_2    DATETIME;
DECLARE @BMH_END_2      DATETIME;
DECLARE @ORSOS_START_1  DATETIME;
DECLARE @ORSOS_END_1    DATETIME;
DECLARE @ORSOS_START_2  DATETIME;
DECLARE @ORSOS_END_2    DATETIME;

SET @ORSOS_START_1 = '2017-01-01 00:00:00';
SET @ORSOS_END_1   = '2018-03-01 00:00:00';
SET @BMH_START_1   = @ORSOS_START_1;
SET @BMH_END_1     = @ORSOS_END_1;
SET @ORSOS_START_2 = '2019-01-01 00:00:00';
SET @ORSOS_END_2   = '2019-08-01 00:00:00';
SET @BMH_START_2   = @ORSOS_START_2;
SET @BMH_END_2     = @ORSOS_END_2;

---------------------------------------------------------------------------------------------------
-- G E T - O R - R O O M - C A S E S - F R O M - O R S O S                                        |
---------------------------------------------------------------------------------------------------
DECLARE @ORSOS_OR_RM_TBL TABLE (
	PK INT IDENTITY(1, 1)   PRIMARY KEY
	, [ORSOS Case No]       VARCHAR(10)
	, [DSS Case No]         VARCHAR(15)
	, [ORSOS MD ID]         VARCHAR(15)
	, [ORSOS Description]   VARCHAR(MAX)
	, [ORSOS Start Date]    DATE
	, [ORSOS Room ID]       VARCHAR(50)
	, [ORSOS Delete Flag]   VARCHAR(25)
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
	, [Incision_Start_Date] DATE
	, [Incision_Start_Time] TIME(0)
	, [Incision_End_Date]   DATE
	, [Incision_End_Time]   TIME(0)
	, [DSS Src Pract No A]  VARCHAR(15)
	, [DSS Spclty Code A]   VARCHAR(15)
	, [DSS Spclty Desc A]   VARCHAR(100)
	, [ORSOS_CROSSWALK_ID]  VARCHAR(10)
	, [DSS_CROSSWALK_ID]    VARCHAR(10)
);

WITH CTE AS (
	SELECT A.CASE_NO
	, C.FACILITY_ACCOUNT_NO
	, E.RESOURCE_ID
	, F.DESCRIPTION AS RESOURCE_DESCRIPTION
	, CAST(A.START_DATE AS DATE)              AS [START_DATE]
	, A.ROOM_ID
	, A.DELETE_FLAG
	, CAST(A.ENTER_PROC_ROOM_TIME AS TIME(0)) AS [ENTER_PROC_ROOM_TIME]
	, CAST(A.LEAVE_PROC_ROOM_TIME AS TIME(0)) AS [LEAVE_PROC_ROOM_TIME]
	, B.DESCRIPTION AS PROCEDURE_DESCRIPTION
	, CAST(D.ANES_START_DATE AS DATE)         AS [ANES_START_DATE]
	, CAST(D.ANES_START_TIME AS TIME(0))      AS [ANES_START_TIME]
	, CAST(D.ANES_STOP_DATE AS DATE)          AS [ANES_STOP_DATE]
	, CAST(D.ANES_STOP_TIME AS TIME(0))       AS [ANES_STOP_TIME]
	, C.PATIENT_TYPE
	, CAST(A.ADMIT_RECOVERY_DATE AS DATE)     AS [ADMIT_RECOVERY_DATE]
	, CAST(A.ADMIT_RECOVERY_TIME AS TIME(0))  AS [ADMIT_RECOVERY_TIME]
	, CAST(A.LEAVE_RECOVERY_DATE AS DATE)     AS [LEAVE_RECOVERY_DATE]
	, CAST(A.LEAVE_RECOVERY_TIME AS TIME(0))  AS [LEAVE_RECOVERY_TIME]
	, CAST(A.[START_DATE] AS date)            AS [Incision_Start_Date]
	, CAST(A.[START_TIME] AS time)            AS [Incision_Start_Time]
	, CAST(A.[STOP_DATE] AS date)             AS [Incision_End_Date]
	, CAST(A.[STOP_TIME] AS time)             AS [Incision_End_Time]
	, G.src_pract_no                          AS [SRC_PRACT_NO_A]
	, G.src_spclty_cd                         AS [SRC_SPCLTY_CD_A]
	, G.spclty_desc                           AS [SPCLTY_DESC_A]
	, ZZZ.ORSOS_STAFF_ID                      AS [ORSOS_CROSSWALK_ID]
	, ZZZ.DSS_STAFF_ID                        AS [DSS_CROSSWALK_ID]

	FROM 
	(
		(
			[BMH-ORSOS].[ORSPROD].[ORSPROD].[POST_CASE]              AS A
			INNER JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[PROCEDURES]  AS B
			ON A.MAIN_PROCEDURE_ID = B.PROCEDURE_ID
		)
		INNER JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[CLINICAL]        AS C
		ON A.ACCOUNT_NO = C.ACCOUNT_NO
	)
	LEFT OUTER JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[POST_ANES_TYPE] AS D
	ON A.CASE_NO = D.CASE_NO
	LEFT OUTER JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[POST_RESOURCE]  AS E
	ON A.CASE_NO = E.CASE_NO
		AND E.ROLE_CODE = '1'
	LEFT OUTER JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[CODES_ROLE]     AS F
	ON E.ROLE_CODE = F.CODE
	
	-- use the crosswalk table to get miss matches
	LEFT OUTER JOIN smsdss.C_ORSOS_TO_DSS_MISSING_IDS                AS ZZZ
	ON E.RESOURCE_ID = ZZZ.ORSOS_STAFF_ID COLLATE SQL_LATIN1_GENERAL_CP1_CI_AS
	
	-- TRY TO GET DSS PROVIDER ID MATCH UP
	LEFT OUTER JOIN smsdss.pract_dim_v AS G
	ON E.RESOURCE_ID = G.SRC_PRACT_NO COLLATE SQL_Latin1_General_CP1_CI_AS
		AND G.orgz_cd = 'S0X0'

	WHERE (
		A.DELETE_FLAG IS NULL
		OR 
		(
			A.DELETE_FLAG = ''
			OR
			A.DELETE_FLAG = 'Z'
		)
	)
	AND (
		(A.START_DATE >= @ORSOS_START_1 AND A.START_DATE < @ORSOS_END_1)
		OR
		(A.START_DATE >= @ORSOS_START_2 AND A.START_DATE < @ORSOS_END_2)
	)
	AND RIGHT(C.FACILITY_ACCOUNT_NO, 1) != 'J'
)

INSERT INTO @ORSOS_OR_RM_TBL
SELECT * FROM CTE;
SELECT A.* 
FROM @ORSOS_OR_RM_TBL AS A
WHERE A.[ORSOS MD ID] = '014241'
GO
;
