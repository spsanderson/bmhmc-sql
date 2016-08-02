/*
Get pain management cases with associated pain management charges
*/

DECLARE @ORSOS_START_DT DATETIME;
DECLARE @ORSOS_END_DT   DATETIME;

SET @ORSOS_START_DT = '2016-05-01 00:00:00';
SET @ORSOS_END_DT   = '2016-06-01 00:00:00';
---------------------------------------------------------------------------------------------------
DECLARE @ORSOS_Pain_Tbl TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, [ORSOS Case No]         VARCHAR(12)
	, [DSS Case No]           VARCHAR(12)
	, [ORSOS Start Date]      DATE	
	, [ORSOSO Room ID]        VARCHAR(10)
	, [ORSOS Delete Flag]     VARCHAR(10)
	, [Enter Proc Room Date]  DATE
	, [Enter Proc Room Time]  TIME(0)
	, [Leave Proc Room Date]  DATE
	, [Leave Proc Room Time]  TIME(0)
	, [ORSOS Primary Group]   VARCHAR(20)
	, [Anes Code]             VARCHAR(3)
	, [Patient Case Abbr]     VARCHAR(10)
	, [Patient Case Descrip]  VARCHAR(20)
	, [Procedure Description] VARCHAR(MAX)
	, [Anesthesia Start Date] DATE
	, [Anesthesia Start Time] TIME(0)
	, [Anesthesia Stop Date]  DATE
	, [Anesthesia Stop Time]  TIME(0)
	, [Recovery Start Date]   DATE
	, [Recovery Start Time]   TIME(0)
	, [Recovery End Date]     DATE
	, [Recovery End Time]     TIME(0)
);

WITH CTE AS (
	SELECT B.CASE_NO
	, F.FACILITY_ACCOUNT_NO
	, CAST(B.START_DATE AS DATE) AS [START_DATE]
	, B.ROOM_ID
	, B.DELETE_FLAG
	, CAST(B.ENTER_PROC_ROOM_DATE AS DATE)    AS ENTER_PROC_ROOM_DATE
	, CAST(B.ENTER_PROC_ROOM_TIME AS TIME(0)) AS ENTER_PROC_ROOM_TIME
	, CAST(B.LEAVE_PROC_ROOM_DATE AS DATE)    AS LEAVE_PROC_ROOM_DATE
	, CAST(B.LEAVE_PROC_ROOM_TIME AS TIME(0)) AS LEAVE_PROC_ROOM_TIME
	, C.PRIMARY_GROUP
	, D.ANES_TYPE_CODE
	, E.ABBR
	, E.DESCRIPTION PT_TYPE_DESC
	, C.DESCRIPTION
	, CAST(D.ANES_START_DATE AS DATE)         AS ANES_START_DATE
	, CAST(D.ANES_START_TIME AS TIME(0))      AS ANES_START_TIME
	, CAST(D.ANES_STOP_DATE AS DATE)          AS ANES_STOP_DATE
	, CAST(D.ANES_STOP_TIME AS TIME(0))       AS ANES_STOP_TIME
	, CAST(B.ADMIT_RECOVERY_DATE AS DATE)     AS ADMIT_RECOVERY_DATE
	, CAST(B.ADMIT_RECOVERY_TIME AS TIME(0))  AS ADMIT_RECOVERY_TIME
	, CAST(B.LEAVE_RECOVERY_DATE AS DATE)     AS LEAVE_RECOVERY_DATE
	, CAST(B.LEAVE_RECOVERY_TIME AS TIME(0))  AS LEAVE_RECOVERY_TIME

	FROM [BMH-ORSOS].[ORSPROD].[ORSPROD].[CODES_ANES_TYPE] AS A
	LEFT OUTER JOIN
	(
		(
			(
				[BMH-ORSOS].[ORSPROD].[ORSPROD].[POST_CASE] AS B
				LEFT OUTER JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[PROCEDURES] AS C
				ON B.MAIN_PROCEDURE_ID = C.PROCEDURE_ID
				LEFT OUTER JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[CLINICAL] AS F
				ON B.ACCOUNT_NO = F.ACCOUNT_NO
			)
			LEFT OUTER JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[POST_ANES_TYPE] AS D
			ON B.CASE_NO = D.CASE_NO
		)
		LEFT OUTER JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[CODES_PATIENT_TYPE] AS E
		ON B.PATIENT_TYPE_CODE = E.CODE
	)
	ON A.CODE = D.ANES_TYPE_CODE

	WHERE (
		B.DELETE_FLAG IS NULL
		OR
			(
				B.DELETE_FLAG = ''
				OR
				B.DELETE_FLAG = 'Z'
			)
	)
	AND B.ROOM_ID IN (
		'PRO RM_01', 'PRO RM_02'
	)
	AND (
		B.START_DATE >= @ORSOS_START_DT
		AND
		B.START_DATE < @ORSOS_END_DT
	)
)

INSERT INTO @ORSOS_Pain_Tbl
SELECT * FROM CTE;

--SELECT * FROM @ORSOS_Pain_Tbl AS A
--ORDER BY A.[Patient Case Descrip]

---------------------------------------------------------------------------------------------------
DECLARE @DSS_Pain_Mgmt_Charges TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, [Encounter]         VARCHAR(12)
	, [Total Actv Qty]    INT
	, [Total Actv Charge] MONEY
);

WITH CTE AS (
	SELECT pt_id
	, SUM(actv_tot_qty) AS TOTAL_QUANTITY
	, SUM(chg_tot_amt)  AS TOTAL_CHARGE
	
	FROM smsmir.actv
	
	WHERE SUBSTRING(pt_id, 5, 8) IN (
		SELECT A.[DSS Case No]
		FROM @ORSOS_Pain_Tbl AS A
	)
	AND actv_cd IN (
		'00508358', '00866202', '00900068', '00900076',
		'01520006', '01520014', '01700301', '01700319',
		'01700327', '01700335', '01800101'
	)
	
	GROUP BY pt_id
	
	HAVING SUM(ACTV_TOT_QTY) > 0
	AND SUM(chg_tot_amt) > 0
)

INSERT INTO @DSS_Pain_Mgmt_Charges
SELECT * FROM CTE;

--SELECT * FROM @DSS_Pain_Mgmt_Charges

---------------------------------------------------------------------------------------------------

SELECT A.*
, B.[Total Actv Qty]
, B.[Total Actv Charge]

FROM @ORSOS_Pain_Tbl AS A
LEFT OUTER JOIN @DSS_Pain_Mgmt_Charges AS B
ON A.[DSS Case No] = SUBSTRING(B.Encounter, 5, 8)

ORDER BY A.[Patient Case Descrip]