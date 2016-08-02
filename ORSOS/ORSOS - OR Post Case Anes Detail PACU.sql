 /*
Get OR cases with OR room fee charges from SMS
*/

DECLARE @ORSOS_START_DT DATETIME;
DECLARE @ORSOS_END_DT   DATETIME;

SET @ORSOS_START_DT = '2016-05-01 00:00:00';
SET @ORSOS_END_DT   = '2016-06-01 00:00:00';
---------------------------------------------------------------------------------------------------
 DECLARE @ORSOS_OR_Table TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, [ORSOS Case No]        VARCHAR(12)
	, [DSS Case No]          VARCHAR(12)
	, [ORSOS Start Date]     DATE
	, [ORSOS Room ID]        VARCHAR(30)
	, [ORSOS Delete Flag]    VARCHAR(10)
	, [Enter Proc Room Time] TIME(0)
	, [Leave Proc Room Time] TIME(0)
	, [Leave Proc Room Date] DATE
	, [Enter Proc Room Date] DATE
	, [Anes Type Code]       VARCHAR(10)
	, [Anes Abbreviation]    VARCHAR(MAX)
	, [Procedure]            VARCHAR(MAX)
	, [Anes Stop Date]       DATE
	, [Anes Start Date]      DATE
	, [Anes Stop Time]       TIME(0)
	, [Anes Start Time]      TIME(0)
	, [Patient Type]         VARCHAR(10)
	, [Anes Description]     VARCHAR(20)
	, [Leave Recovery Date]  DATE
	, [Admit Recovery Date]  DATE
	, [Leave Recovery Time]  TIME(0)
	, [Admit Recovery Time]  TIME(0)
 );
 
 WITH CTE AS (
	 SELECT "POST_CASE"."CASE_NO"
	 , "CLINICAL"."FACILITY_ACCOUNT_NO"
	 , "POST_CASE"."START_DATE"
	 , "POST_CASE"."ROOM_ID"
	 , "POST_CASE"."DELETE_FLAG"
	 , "POST_CASE"."ENTER_PROC_ROOM_TIME"
	 , "POST_CASE"."LEAVE_PROC_ROOM_TIME"
	 , "POST_CASE"."LEAVE_PROC_ROOM_DATE"
	 , "POST_CASE"."ENTER_PROC_ROOM_DATE"
	 , "POST_ANES_TYPE"."ANES_TYPE_CODE"
	 , "CODES_ANES_TYPE"."ABBR"
	 , "PROCEDURES"."DESCRIPTION" AS PROC_DESC
	 , "POST_ANES_TYPE"."ANES_STOP_DATE"
	 , "POST_ANES_TYPE"."ANES_START_DATE"
	 , "POST_ANES_TYPE"."ANES_STOP_TIME"
	 , "POST_ANES_TYPE"."ANES_START_TIME"
	 , "CLINICAL"."PATIENT_TYPE"
	 , "CODES_ANES_TYPE"."DESCRIPTION"
	 , "POST_CASE"."LEAVE_RECOVERY_DATE"
	 , "POST_CASE"."ADMIT_RECOVERY_DATE"
	 , "POST_CASE"."LEAVE_RECOVERY_TIME"
	 , "POST_CASE"."ADMIT_RECOVERY_TIME"
	 
	 FROM
	 (
		(
			"BMH-ORSOS"."ORSPROD"."ORSPROD"."POST_CASE" AS "POST_CASE"
			INNER JOIN "BMH-ORSOS"."ORSPROD"."ORSPROD"."PROCEDURES" AS "PROCEDURES"
			ON "POST_CASE"."MAIN_PROCEDURE_ID" = "PROCEDURES"."PROCEDURE_ID"
		) 
		INNER JOIN "BMH-ORSOS"."ORSPROD"."ORSPROD"."CLINICAL" AS "CLINICAL" 
		ON "POST_CASE"."ACCOUNT_NO"="CLINICAL"."ACCOUNT_NO"
	) 
	LEFT OUTER JOIN (
		"BMH-ORSOS"."ORSPROD"."ORSPROD"."CODES_ANES_TYPE" AS "CODES_ANES_TYPE" 
		LEFT OUTER JOIN "BMH-ORSOS"."ORSPROD"."ORSPROD"."POST_ANES_TYPE" AS "POST_ANES_TYPE" 
		ON "CODES_ANES_TYPE"."CODE" = "POST_ANES_TYPE"."ANES_TYPE_CODE"
	) 
	ON "POST_CASE"."CASE_NO" = "POST_ANES_TYPE"."CASE_NO"

	WHERE 
	(
		"POST_CASE"."DELETE_FLAG" IS NULL  
		OR 
		(
			"POST_CASE"."DELETE_FLAG" = '' 
			OR 
			"POST_CASE"."DELETE_FLAG" = 'z'
		)
	)
	AND "POST_CASE"."ROOM_ID" NOT IN (
		'ENDO_01', 'ENDO_02', 'ENDO_03', 'PRO RM_01', 'PRO RM_02'
	) 
	AND (
		"POST_CASE"."START_DATE">= @ORSOS_START_DT 
		AND 
		"POST_CASE"."START_DATE"< @ORSOS_END_DT
	)
)

INSERT INTO @ORSOS_OR_Table
SELECT * FROM CTE;

SELECT * FROM @ORSOS_OR_Table