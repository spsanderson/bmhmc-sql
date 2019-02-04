USE [SMSPHDSSS0X0]
GO

/*
***********************************************************************
File: c_ORSOS_Post_Case_sp.sql

Input Parameters:
	None

Tables/Views:
	[BMH-ORSOS].[ORSPROD].[ORSPROD].[POST_CASE]
	[BMH-ORSOS].[ORSPROD].[ORSPROD].[PROCEDURES]
	[BMH-ORSOS].[ORSPROD].[ORSPROD].[CLINICAL]
	[BMH-ORSOS].[ORSPROD].[ORSPROD].[POST_ANES_TYPE]
	[BMH-ORSOS].[ORSPROD].[ORSPROD].[POST_RESOURCE]
	[BMH-ORSOS].[ORSPROD].[ORSPROD].[CODES_ROLE]
	smsdss.pract_dim_v
	smsdss.C_ORSOS_TO_DSS_MISSING_IDS

Creates Table:
	smsdss.c_ORSOS_Post_Case_Rpt_Tbl

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Entere Here

Revision History:
Date		Version		Description
----		----		----
2018-12-05	v1			Initial Creation
2018-12-18	v2			Fix table scheme from dbo to smsdss
2019-01-07	v3			Drop "J" accounts
***********************************************************************
*/

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [smsdss].[c_ORSOS_Post_Case_sp]
AS

IF NOT EXISTS (
	SELECT TOP 1 * FROM SYSOBJECTS WHERE name = 'c_ORSOS_Post_Case_Rpt_Tbl' AND xtype = 'U'
)

BEGIN

	CREATE TABLE smsdss.c_ORSOS_Post_Case_Rpt_Tbl (
		PK INT IDENTITY(1, 1)   PRIMARY KEY
		, [ORSOS_Case_No]       VARCHAR(MAX)
		, [Encounter]           VARCHAR(MAX)
		, [ORSOS_MD_ID]         VARCHAR(MAX)
		, [ORSOS Description]   VARCHAR(MAX)
		, [ORSOS_Provider_Name] VARCHAR(MAX)
		, [ORSOS_Start_Date]    DATE
		, [ORSOS_Room_ID]       VARCHAR(MAX)
		, [Ent_Proc_Rm_Time]    TIME
		, [Leave_Proc_Rm_Time]  TIME
		, [Procedure]           VARCHAR(MAX)
		, [Anes_Start_Date]     DATE
		, [Anes_Start_Time]     TIME
		, [Anes_End_Date]       DATE
		, [Anes_End_Time]       TIME
		, [Patient_Type]        VARCHAR(MAX)
		, [Adm_Recovery_Date]   DATE
		, [Adm_Recovery_Time]   TIME
		, [Leave_Recovery_Date] DATE
		, [Leave_Recovery_Time] TIME
		, [DSS_Src_Pract_No]    VARCHAR(MAX)
		, [DSS_Pract_Rpt_Name]  VARCHAR(MAX)
		, [DSS_Spclty_Code]     VARCHAR(MAX)
		, [DSS_Spclty_Desc]     VARCHAR(MAX)
	)
	;
	
	INSERT INTO smsdss.c_ORSOS_Post_Case_Rpt_Tbl

	SELECT A.CASE_NO
	, C.FACILITY_ACCOUNT_NO
	, E.RESOURCE_ID
	, F.DESCRIPTION AS RESOURCE_DESCRIPTION
	, A.PROVIDER_SHORT_NAME
	, CAST(A.START_DATE AS DATE)                                  AS [START_DATE]
	, A.ROOM_ID
	, CAST(A.ENTER_PROC_ROOM_TIME AS TIME(0))                     AS [ENTER_PROC_ROOM_TIME]
	, CAST(A.LEAVE_PROC_ROOM_TIME AS TIME(0))                     AS [LEAVE_PROC_ROOM_TIME]
	, B.DESCRIPTION                                               AS [PROCEDURE_DESCRIPTION]
	, CAST(D.ANES_START_DATE AS DATE)                             AS [ANES_START_DATE]
	, CAST(D.ANES_START_TIME AS TIME(0))                          AS [ANES_START_TIME]
	, CAST(D.ANES_STOP_DATE AS DATE)                              AS [ANES_STOP_DATE]
	, CAST(D.ANES_STOP_TIME AS TIME(0))                           AS [ANES_STOP_TIME]
	, C.PATIENT_TYPE
	, CAST(A.ADMIT_RECOVERY_DATE AS DATE)                         AS [ADMIT_RECOVERY_DATE]
	, CAST(A.ADMIT_RECOVERY_TIME AS TIME(0))                      AS [ADMIT_RECOVERY_TIME]
	, CAST(A.LEAVE_RECOVERY_DATE AS DATE)                         AS [LEAVE_RECOVERY_DATE]
	, CAST(A.LEAVE_RECOVERY_TIME AS TIME(0))                      AS [LEAVE_RECOVERY_TIME]
	, COALESCE(G.SRC_PRACT_NO, H.SRC_PRACT_NO, ZZZ.DSS_STAFF_ID)  AS [SRC_PRACT_NO]
	, COALESCE(G.PRACT_RPT_NAME, H.PRACT_RPT_NAME, ZZZ.DSS_NAME)  AS [PRACT_RPT_NAME]
	, COALESCE(G.SRC_SPCLTY_CD, H.SRC_SPCLTY_CD, I.SRC_SPCLTY_CD) AS [SRC_SPCLTY_CD]
	, COALESCE(G.SPCLTY_DESC, H.SPCLTY_DESC, I.SPCLTY_DESC)       AS [SPCLTY_DESC]

	FROM [BMH-ORSOS].[ORSPROD].[ORSPROD].[POST_CASE] AS A
	INNER JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[PROCEDURES] AS B
	ON A.MAIN_PROCEDURE_ID = B.PROCEDURE_ID
	INNER JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[CLINICAL] AS C
	ON A.ACCOUNT_NO = C.ACCOUNT_NO
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
	-- use the crosswalk table to get miss matches
	LEFT OUTER JOIN smsdss.C_ORSOS_TO_DSS_MISSING_IDS                AS ZZZ
	ON E.RESOURCE_ID = ZZZ.ORSOS_STAFF_ID COLLATE SQL_LATIN1_GENERAL_CP1_CI_AS 
	LEFT OUTER JOIN smsdss.PRACT_DIM_V AS I
	ON ZZZ.DSS_STAFF_ID = I.src_pract_no
		AND I.orgz_cd = 'S0X0'

	WHERE (
		A.DELETE_FLAG IS NULL
		OR 
		(
			A.DELETE_FLAG = ''
			OR
			A.DELETE_FLAG = 'Z'
		)
	)
	AND A.[START_DATE] >= '2010-01-01'
	AND RIGHT(c.FACILITY_ACCOUNT_NO, 1) != 'J'
	;

END

ELSE BEGIN

	INSERT INTO smsdss.c_ORSOS_Post_Case_Rpt_Tbl

	SELECT A.CASE_NO
	, C.FACILITY_ACCOUNT_NO
	, E.RESOURCE_ID
	, F.DESCRIPTION AS RESOURCE_DESCRIPTION
	, A.PROVIDER_SHORT_NAME
	, CAST(A.START_DATE AS DATE)                                  AS [START_DATE]
	, A.ROOM_ID
	, CAST(A.ENTER_PROC_ROOM_TIME AS TIME(0))                     AS [ENTER_PROC_ROOM_TIME]
	, CAST(A.LEAVE_PROC_ROOM_TIME AS TIME(0))                     AS [LEAVE_PROC_ROOM_TIME]
	, B.DESCRIPTION                                               AS [PROCEDURE_DESCRIPTION]
	, CAST(D.ANES_START_DATE AS DATE)                             AS [ANES_START_DATE]
	, CAST(D.ANES_START_TIME AS TIME(0))                          AS [ANES_START_TIME]
	, CAST(D.ANES_STOP_DATE AS DATE)                              AS [ANES_STOP_DATE]
	, CAST(D.ANES_STOP_TIME AS TIME(0))                           AS [ANES_STOP_TIME]
	, C.PATIENT_TYPE
	, CAST(A.ADMIT_RECOVERY_DATE AS DATE)                         AS [ADMIT_RECOVERY_DATE]
	, CAST(A.ADMIT_RECOVERY_TIME AS TIME(0))                      AS [ADMIT_RECOVERY_TIME]
	, CAST(A.LEAVE_RECOVERY_DATE AS DATE)                         AS [LEAVE_RECOVERY_DATE]
	, CAST(A.LEAVE_RECOVERY_TIME AS TIME(0))                      AS [LEAVE_RECOVERY_TIME]
	, COALESCE(G.SRC_PRACT_NO, H.SRC_PRACT_NO, ZZZ.DSS_STAFF_ID)  AS [SRC_PRACT_NO]
	, COALESCE(G.PRACT_RPT_NAME, H.PRACT_RPT_NAME, ZZZ.DSS_NAME)  AS [PRACT_RPT_NAME]
	, COALESCE(G.SRC_SPCLTY_CD, H.SRC_SPCLTY_CD, I.SRC_SPCLTY_CD) AS [SRC_SPCLTY_CD]
	, COALESCE(G.SPCLTY_DESC, H.SPCLTY_DESC, I.SPCLTY_DESC)       AS [SPCLTY_DESC]

	FROM [BMH-ORSOS].[ORSPROD].[ORSPROD].[POST_CASE]                 AS A
	INNER JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[PROCEDURES]          AS B
	ON A.MAIN_PROCEDURE_ID = B.PROCEDURE_ID
	INNER JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[CLINICAL]            AS C
	ON A.ACCOUNT_NO = C.ACCOUNT_NO
	LEFT OUTER JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[POST_ANES_TYPE] AS D
	ON A.CASE_NO = D.CASE_NO
	LEFT OUTER JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[POST_RESOURCE]  AS E
	ON A.CASE_NO = E.CASE_NO
		AND E.ROLE_CODE = '1'
	LEFT OUTER JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[CODES_ROLE]     AS F
	ON E.ROLE_CODE = F.CODE
	-- TRY TO GET DSS PROVIDER ID MATCH UP
	LEFT OUTER JOIN smsdss.pract_dim_v                               AS G
	ON E.RESOURCE_ID = SUBSTRING(G.SRC_PRACT_NO, 1, 5)COLLATE SQL_Latin1_General_CP1_CI_AS
		AND G.orgz_cd = 'S0X0'
	LEFT OUTER JOIN smsdss.pract_dim_v                               AS H
	ON E.RESOURCE_ID = SUBSTRING(H.SRC_PRACT_NO, 1, 6)COLLATE SQL_Latin1_General_CP1_CI_AS
		AND H.orgz_cd = 'S0X0'
	-- use the crosswalk table to get miss matches
	LEFT OUTER JOIN smsdss.C_ORSOS_TO_DSS_MISSING_IDS                AS ZZZ
	ON E.RESOURCE_ID = ZZZ.ORSOS_STAFF_ID COLLATE SQL_LATIN1_GENERAL_CP1_CI_AS 
	LEFT OUTER JOIN smsdss.PRACT_DIM_V                               AS I
	ON ZZZ.DSS_STAFF_ID = I.src_pract_no
		AND I.orgz_cd = 'S0X0'

	WHERE (
		A.DELETE_FLAG IS NULL
		OR 
		(
			A.DELETE_FLAG = ''
			OR
			A.DELETE_FLAG = 'Z'
		)
	)
	AND A.[START_DATE] >= '2010-01-01'
	AND A.CASE_NO COLLATE SQL_LATIN1_GENERAL_CP1_CI_AS NOT IN (
		SELECT XXX.ORSOS_Case_No
		FROM smsdss.c_ORSOS_Post_Case_Rpt_Tbl AS XXX
	)
	AND RIGHT(c.FACILITY_ACCOUNT_NO, 1) != 'J'
	;

END