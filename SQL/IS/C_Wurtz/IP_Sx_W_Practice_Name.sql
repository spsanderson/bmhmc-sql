/*
Get OR Room cases and the provider id to fill out the outpatient surgery trend
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

SET @ORSOS_START_1 = '2021-12-01 00:00:00';
SET @ORSOS_END_1   = '2022-01-01 00:00:00';
SET @BMH_START_1   = @ORSOS_START_1;
SET @BMH_END_1     = @ORSOS_END_1;
SET @ORSOS_START_2 = '2025-01-01 00:00:00';
SET @ORSOS_END_2   = '2025-08-01 00:00:00';
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
	, [DSS Src Pract No A]  VARCHAR(15)
	, [DSS Spclty Code A]   VARCHAR(15)
	, [DSS Spclty Desc A]   VARCHAR(100)
	, [ORSOS_CROSSWALK_ID]  VARCHAR(10)
	, [DSS_CROSSWALK_ID]    VARCHAR(10)
);

WITH CTE AS (
	SELECT A.CASE_NO
	, C.FACILITY_ACCOUNT_NO
	, REPLACE(E.RESOURCE_ID, '-', '')         AS [RESOURCE_ID]
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
	ON REPLACE(E.RESOURCE_ID, '-', '') = ZZZ.ORSOS_STAFF_ID COLLATE SQL_LATIN1_GENERAL_CP1_CI_AS
	
	-- TRY TO GET DSS PROVIDER ID MATCH UP
	LEFT OUTER JOIN smsdss.pract_dim_v AS G
	ON REPLACE(E.RESOURCE_ID, '-', '') = G.SRC_PRACT_NO COLLATE SQL_Latin1_General_CP1_CI_AS
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
	--AND A.ROOM_ID NOT IN (
	--	'ENDO_01', 'ENDO_02', 'ENDO_03', 'PRO RM_01', 'PRO RM_02'
	--)
	AND (
		(A.START_DATE >= @ORSOS_START_1 AND A.START_DATE < @ORSOS_END_1)
		OR
		(A.START_DATE >= @ORSOS_START_2 AND A.START_DATE < @ORSOS_END_2)
	)
	AND RIGHT(C.FACILITY_ACCOUNT_NO, 1) != 'J'
)

INSERT INTO @ORSOS_OR_RM_TBL
SELECT * FROM CTE;

---------------------------------------------------------------------------------------------------
-- C R E A T E - T E M P O R A R Y - P E R S I S T A N T - T A B L E                              |
---------------------------------------------------------------------------------------------------
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
, A.[DSS Src Pract No A]
, A.[DSS Spclty Code A]
, A.[DSS Spclty Desc A]
, A.[ORSOS_CROSSWALK_ID]
, A.[DSS_CROSSWALK_ID]

INTO #ORSOS_OR_RM_TMP_A

FROM @ORSOS_OR_RM_TBL AS A

---------------------------------------------------------------------------------------------------
-- C O A L E S C E - MD_ID - N U M B E R S                                                        |
---------------------------------------------------------------------------------------------------
SELECT A.*
, COALESCE(A.[DSS_CROSSWALK_ID], A.[DSS Src Pract No A]) AS MD_ID

INTO #ORSOS_OR_RM_TMP_B

FROM #ORSOS_OR_RM_TMP_A AS A;

---------------------------------------------------------------------------------------------------
-- Get accounts with AMB Surge Fee 01800010 Ambulatory Surgery Fee                                |
---------------------------------------------------------------------------------------------------
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
		FROM @ORSOS_OR_RM_TBL AS A
	)

	GROUP BY pt_id

	HAVING SUM(actv_tot_qty) > 0
	AND SUM(chg_tot_amt) > 0
)

INSERT INTO @DSS_AmbSurg_Activity
SELECT * FROM CTE3;

--SELECT TOP 5 * FROM @DSS_AmbSurg_Activity;

---------------------------------------------------------------------------------------------------
-- Get accounts with Operating Room Time Charges                                                  |
---------------------------------------------------------------------------------------------------
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
		FROM @ORSOS_OR_RM_TBL AS A
	)

	GROUP BY pt_id

	HAVING SUM(actv_tot_qty) > 0
	AND SUM(chg_tot_amt) > 0
)

INSERT INTO @DSS_OR_Time_Activity
SELECT * FROM CTE3;

--SELECT TOP 5 * FROM @DSS_OR_Time_Activity;

---------------------------------------------------------------------------------------------------
-- A D D - R O W N U M B E R - T O - G E T - S I N G L E - L I N E - P E R - C A S E              |
---------------------------------------------------------------------------------------------------
SELECT A.*
, B.[Total Actv Qty]    AS [Total Actv Qty AmbSurg]
, B.[Total Actv Charge] AS [Total Actv Charge AmbSurg]
, C.[Total Actv Qty]    AS [Total Actv Qty OR Time]
, C.[Total Actv Charge] AS [Total Actv Charge OR Time]
, ROW_NUMBER() OVER(
	PARTITION BY A.[ORSOS Case No]
	ORDER BY A.[ORSOS Case No]
)                       AS RN

INTO #TEMP_A

FROM #ORSOS_OR_RM_TMP_B AS A
LEFT OUTER JOIN @DSS_AmbSurg_Activity AS B
ON A.[DSS Case No] = SUBSTRING(B.Encounter, 5, 8)
LEFT OUTER JOIN @DSS_OR_Time_Activity AS C
ON A.[DSS Case No] = SUBSTRING(C.Encounter, 5, 8);

---------------------------------------------------------------------------------------------------
-- O N L Y - P U L L - I N - O N E - R E C O R D - P E R - C A S E                                |
---------------------------------------------------------------------------------------------------
SELECT A.[ORSOS Case No]
, A.[DSS CASE NO]
, A.[MD_ID]
, A.[ORSOS START DATE]
, A.[ORSOS ROOM ID]
, A.[ENT PROC RM TIME]
, A.[LEAVE PROC RM TIME]
, A.[PROCEDURE]
, A.[ANES START DATE]
, A.[ANES START TIME]
, A.[ANES END DATE]
, A.[ANES END TIME]
, A.[PATIENT TYPE]
, A.[ADM RECOVERY DATE]
, A.[ADM RECOVERY TIME]
, A.[LEAVE RECOVERY DATE]
, A.[LEAVE RECOVERY TIME]
, A.[TOTAL ACTV QTY AMBSURG]
, A.[TOTAL ACTV CHARGE AMBSURG]
, A.[TOTAL ACTV QTY OR TIME]
, A.[Total ACTV Charge OR Time]
, A.[RN]

INTO #TEMP_B

FROM #TEMP_A AS A

WHERE A.RN = 1;

---------------------------------------------------------------------------------------------------
-- G E T - P R O V I D E R - S P E C A L T Y - C O D E - A N D - D E S C R I P T I O N            |
---------------------------------------------------------------------------------------------------
SELECT A.[ORSOS CASE NO]
, A.[DSS CASE NO]
, A.[MD_ID]
, CONCAT(z.[Last Name], ' ', z.[Middle Name], ' ', z.[First Name]) AS [PROVIDER NAME]
--, B.pract_rpt_name AS [PROVIDER NAME]
, B.spclty_cd1
, C.spclty_cd_desc
, C.med_staff_dept
, A.[ORSOS START DATE]
, A.[ORSOS ROOM ID]
, A.[ENT PROC RM TIME]
, A.[LEAVE PROC RM TIME]
, A.[PROCEDURE]
, A.[ANES START DATE]
, A.[ANES START TIME]
, A.[ANES END DATE]
, A.[ANES END TIME]
, A.[PATIENT TYPE]
, A.[ADM RECOVERY DATE]
, A.[ADM RECOVERY TIME]
, A.[LEAVE RECOVERY DATE]
, A.[LEAVE RECOVERY TIME]
, A.[TOTAL ACTV QTY AMBSURG]
, A.[TOTAL ACTV CHARGE AMBSURG]
, A.[TOTAL ACTV QTY OR TIME]
, A.[TOTAL ACTV CHARGE OR TIME]

INTO #TEMP_C

FROM #TEMP_B                       AS A
LEFT JOIN smsmir.pract_mstr        AS B
ON A.[MD_ID] = B.pract_no
	AND B.iss_orgz_cd = 'S0X0'
LEFT JOIN smsdss.pract_spclty_mstr AS C
ON B.spclty_cd1 = C.spclty_cd
	AND B.iss_orgz_cd = C.orgz_cd
	AND C.orgz_cd = 'S0X0'
LEFT JOIN smsdss.BMH_PLM_PtAcct_V  AS D
ON A.[DSS CASE NO] = D.PtNo_Num
left join [SQL-WEBAPPS\WEBAPPS].[VergeExport].[dbo].[VergeRoster] as z
on a.MD_ID = z.[InstitutionId] COLLATE SQL_Latin1_General_CP1_CI_AS
	

--WHERE [DSS CASE NO] = ''
--WHERE MDID IS NULL

ORDER BY A.[ORSOS CASE NO];

---------------------------------------------------------------------------------------------------
-- S T A G E - F O R - (I N / O U T) P A T I E N T - S U R G I C A L - C O U N T S                |
---------------------------------------------------------------------------------------------------
SELECT A.*
, B.pt_type
, B.hosp_svc
, B.tot_chg_amt

INTO #TEMP_D

FROM #TEMP_C                      AS A
LEFT JOIN smsdss.BMH_PLM_PtAcct_V AS B
ON A.[DSS CASE NO] = B.PtNo_Num

WHERE (
	B.pt_type NOT IN (
		'D', 'G'
	)
	AND B.hosp_svc NOT IN (
		'INF', 'CTH'
	)
	AND B.tot_chg_amt > 0
	AND B.Plm_Pt_Acct_Type = 'I'
	AND B.PtNo_Num < '20000000'
	AND LEFT(B.PTNO_NUM, 1) = '1'
	AND (
		(B.Adm_Date >= @BMH_START_1 AND B.Adm_Date < @BMH_END_1)
		OR 
		(B.Adm_Date >= @BMH_START_2 AND B.Adm_Date < @BMH_END_2)
	)
)

---------------------------------------------------------------------------------------------------
-- G E T - R E C O R D S                                                                          |
---------------------------------------------------------------------------------------------------
SELECT *

INTO #TEMP_E

FROM #TEMP_D;

---------------------------------------------------------------------------------------------------
-- A D D - P R AC T I C E - N A M E - T O - R E C O R D                                           |
---------------------------------------------------------------------------------------------------
DECLARE @Practice_Info TABLE (
	PK INT IDENTITY(1, 1) PRIMARY KEY
	, [Practice Name]      VARCHAR(MAX)
	, [DSS Prov Num]       VARCHAR(100)
);

WITH CTE AS (
	select [PRACTICE NAME],
		INSTITUTIONID
	from [SQL-WEBAPPS\WEBAPPS].[VergeExport].[dbo].[VergeRoster] AS A
	LEFT OUTER JOIN SMSDSS.pract_dim_v AS B
		ON A.INSTITUTIONID COLLATE SQL_Latin1_General_Pref_CP1_CI_AS = B.pract_no
	WHERE INSTITUTIONID != ''
	AND B.orgz_cd = 'S0X0'
)

INSERT INTO @Practice_Info
SELECT * FROM CTE

SELECT *
, ROW_NUMBER() OVER (
	PARTITION BY A.[DSS PROV NUM]
	ORDER BY A.[DSS PROV NUM]
) AS RN

INTO #PRACT_NAME_TEMP

FROM @Practice_Info AS A
WHERE A.[DSS Prov Num] IS NOT NULL
ORDER BY A.[Practice Name];

---------------------------------------------------------------------------------------------------
-- S E L E C T - R E C O R D S - W I T H - P R A C T I C E - N A M E                              |
---------------------------------------------------------------------------------------------------
SELECT DATEPART(YEAR, A.[ORSOS START DATE]) AS SVC_YEAR
, DATEPART(MONTH, A.[ORSOS START DATE]) AS SVC_MONTH
, A.[ORSOS Case No]
, A.[DSS Case No]
, C.Pt_Name
, A.MD_ID
, A.[PROVIDER NAME]
, A.spclty_cd1
, A.spclty_cd_desc
, A.med_staff_dept
, A.[ORSOS Start Date]
, A.[ORSOS Room ID]
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
, A.[Total Actv Qty AmbSurg]
, A.[Total Actv Charge AmbSurg]
, A.[Total Actv Qty OR Time]
, A.[Total Actv Charge OR Time]
, A.pt_type
, A.hosp_svc
, A.tot_chg_amt
, B.[Practice Name]

FROM #TEMP_E AS A
LEFT JOIN #PRACT_NAME_TEMP AS B
ON A.[MD_ID] = B.[DSS PROV NUM]
	AND B.[RN] = 1
LEFT JOIN smsdss.BMH_PLM_PtAcct_V AS C
ON A.[DSS Case No] = C.PtNo_Num
	
WHERE A.MD_ID IS NOT NULL

---------------------------------------------------------------------------------------------------
-- D R O P - T A B L E - S T A T E M E N T S                                                      |
---------------------------------------------------------------------------------------------------
DROP TABLE #ORSOS_OR_RM_TMP_A;
DROP TABLE #ORSOS_OR_RM_TMP_B;
DROP TABLE #TEMP_A;
DROP TABLE #TEMP_B;
DROP TABLE #TEMP_C;
DROP TABLE #TEMP_D;
DROP TABLE #PRACT_NAME_TEMP;
DROP TABLE #TEMP_E;

---------------------------------------------------------------------------------------------------
-- T R O U B L E S H O O T                                                                        |
---------------------------------------------------------------------------------------------------
--SELECT *
--FROM #ORSOS_OR_RM_TMP_B
--WHERE [DSS CASE NO] IN ('14324123')

--SELECT *
--FROM #TEMP_A
--WHERE [DSS CASE NO] IN ('14324123')

--SELECT *
--FROM #TEMP_B
--WHERE [DSS CASE NO] IN ('14324123')

--SELECT * 
--FROM #ORSOS_OR_RM_TMP_A
--WHERE [DSS CASE NO] IN ('14324123')

--select *
--from #temp_e
--WHERE [DSS CASE NO] IN ('14324123')
