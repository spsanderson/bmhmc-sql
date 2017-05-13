/*
Get Endo Room Cases from ORSOS with Anestesia Type and associated
SMS charges.
*/

DECLARE @ORSOS_START_DT DATETIME;
DECLARE @ORSOS_END_DT   DATETIME;

SET @ORSOS_START_DT = '2016-05-01 00:00:00';
SET @ORSOS_END_DT   = '2016-06-01 00:00:00';
---------------------------------------------------------------------------------------------------
DECLARE @ORSOS_ENDO_ANES_TBL TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, [ORSOS Case No]      VARCHAR(10)
	, [DSS Case No]        VARCHAR(10)
	, [ORSOS Start Date]   DATE
	, [ORSOS Room ID]      VARCHAR(10)
	, [ORSOS Delete Flag]  VARCHAR(10)
	, [Ent Proc Rm Date]   DATE
	, [Ent Proc Rm Time]   TIME(0)
	, [Leave Proc Rm Date] DATE
	, [Leave Proc Rm Time] TIME(0)
	, [Anes Type Code]     VARCHAR(10)
	, [Anes Abbreviation]  VARCHAR(50)
	, [Procedure Desc]     VARCHAR(MAX)
	, [Anes Start Date]    DATE
	, [Anes Start Time]    TIME(0)
	, [Anes Stop Date]     DATE
	, [Anes Stop Time]     TIME(0)
	, [ORSOS Patient Type] VARCHAR(10)
);

WITH CTE AS (
	SELECT A.CASE_NO
	, C.FACILITY_ACCOUNT_NO
	, CAST(A.START_DATE AS DATE) AS [START_DATE]
	, A.ROOM_ID
	, A.DELETE_FLAG
	, CAST(A.ENTER_PROC_ROOM_DATE AS DATE)    AS ENTER_PROC_ROOM_DATE
	, CAST(A.ENTER_PROC_ROOM_TIME AS TIME(0)) AS ENTER_PROC_ROOM_TIME
	, CAST(A.LEAVE_PROC_ROOM_DATE AS DATE)    AS LEAVE_PROC_ROOM_DATE
	, CAST(A.LEAVE_PROC_ROOM_TIME AS TIME(0)) AS LEAVE_PROC_ROOM_TIME
	, D.ANES_TYPE_CODE
	, E.ABBR
	, B.[DESCRIPTION]
	, CAST(D.ANES_START_DATE AS DATE)         AS ANES_START_DATE
	, CAST(D.ANES_START_TIME AS TIME(0))      AS ANES_START_TIME
	, CAST(D.ANES_STOP_DATE AS DATE)          AS ANES_STOP_DATE
	, CAST(D.ANES_STOP_TIME AS TIME(0))       AS ANES_STOP_TIME
	, C.PATIENT_TYPE

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
	LEFT JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[POST_ANES_TYPE] AS D
	ON A.CASE_NO = D.CASE_NO
	LEFT OUTER JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[CODES_ANES_TYPE] AS E
	ON D.ANES_TYPE_CODE = E.CODE

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

INSERT INTO @ORSOS_ENDO_ANES_TBL
SELECT * FROM CTE

--SELECT * FROM @ORSOS_ENDO_ANES_TBL
---------------------------------------------------------------------------------------------------
DECLARE @DSS_Anesthesia_Charge TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, [Encounter]         VARCHAR(12)
	, [Total Actv Qty]    INT
	, [Total Actv Charge] MONEY
);

WITH CTE AS (
	SELECT PT_ID
	, SUM(ACTV_TOT_QTY) AS TOTAL_QUANTITY
	, SUM(CHG_TOT_AMT)  AS TOTAL_CHARGE
	
	FROM smsmir.actv
	
	WHERE SUBSTRING(pt_id, 5, 8) IN (
		SELECT A.[DSS Case No]
		FROM @ORSOS_ENDO_ANES_TBL AS A
	)
	AND actv_cd IN (
		'04800058', --ANESTH. TIME 1ST .5 HRS
		'04800074', --ANESTH. TIME 1ST 1.5 HRS
		'04800082', --ANESTH. TIME 1ST 2 HRS
		'04800066', --ANESTH. TIME 1ST HR
		'04800090', --ANESTH. TIME EA HALF HR (5+)
		'04900023', --ANESTHESIA
		'04800017', --ANESTHESIA - UP TO 1 HOUR
		'04800025', --ANESTHESIA 1 1/2 - 2 1/2 HRS
		'04800033', --ANESTHESIA 3 OR MORE HRS
		'04900015', --ANESTHESIA LOCAL
		'04800041', --ANESTHESIA PER MIN
		'02500247' 	--INJ ANESTHETIC
	)
	
	GROUP BY pt_id
	
	HAVING SUM(ACTV_TOT_QTY) > 0
	AND SUM(CHG_TOT_AMT) > 0
)

INSERT INTO @DSS_Anesthesia_Charge
SELECT * FROM CTE

--SELECT * FROM @DSS_Anesthesia_Charge
---------------------------------------------------------------------------------------------------

SELECT *
, B.[Total Actv Qty]
, B.[Total Actv Charge]

FROM @ORSOS_ENDO_ANES_TBL AS A
LEFT OUTER JOIN @DSS_Anesthesia_Charge AS B
ON A.[DSS Case No] = SUBSTRING(B.Encounter, 5, 8)
