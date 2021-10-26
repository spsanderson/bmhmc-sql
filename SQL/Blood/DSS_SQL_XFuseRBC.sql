DECLARE @TODAY DATE;
DECLARE @START DATETIME;
DECLARE @END DATETIME;

SET @TODAY = GETDATE();
SET @START = DATEADD(MONTH, DATEDIFF(MONTH, 0, @TODAY) - 1, 0);
SET @END = DATEADD(MONTH, DATEDIFF(MONTH, 0, @TODAY), 0);

/* 
======================================================================
G E T - T H E - P A T I E N T S
=======================================================================
*/
DECLARE @Patients TABLE (
	PK INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
	, Vst_Start_Dtime     DATETIME
	, Vst_End_Dtime       DATETIME
	, Pt_Name             VARCHAR(50)
	, Age                 VARCHAR(4)
	, MRN                 INT
	, Encounter           INT
	, Ordering_Party      VARCHAR(50)
	, Ord_No              VARCHAR(15)
	, Svc_Desc            VARCHAR(MAX)
	, [x]                 CHAR(1)
	, [xx]                CHAR(1)
	, Order_Ent_DTime     DATETIME
	, Order_Str_DTime     DATETIME
	, Order_Stp_DTime     DATETIME
	, Vst_No              INT
);

WITH Patients AS (
	SELECT A.vst_start_dtime
	, A.vst_end_dtime
	, B.rpt_name
	, ISNULL(CAST(FLOOR(DATEDIFF(DAY, B.BIRTH_DTIME, GETDATE()) / 365.25) AS VARCHAR), '') AS [AGE]
	, A.med_rec_no
	, A.episode_no
	, C.pty_name
	, C.ord_no
	, C.svc_desc
	, '' AS X
	, '' AS XX
	, C.ent_dtime
	, C.str_dtime
	, C.stp_dtime
	, C.vst_no

	FROM SMSMIR.trn_sr_vst_pms   AS A
	INNER JOIN SMSMIR.trn_sr_pt  AS B
	ON A.pt_id = B.pt_id
	INNER JOIN SMSMIR.trn_sr_ord AS C
	ON A.vst_no = C.vst_no
		AND C.svc_cd = 'XFuseRBC'
		AND C.ord_sts = 27

	WHERE A.vst_end_dtime IS NOT NULL
	AND A.vst_end_dtime >= @START
	AND A.vst_end_dtime < @END
)
INSERT INTO @Patients
SELECT * FROM Patients

--SELECT * FROM @Patients

/* 
======================================================================
G E T - T H E - B E F O R E - R E S U L T
=======================================================================
*/
DECLARE @Before TABLE (
	PK INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
	, Before_Results      VARCHAR(MAX)
	, Result_Before_Date  DATETIME
	, Vst_No              VARCHAR(MAX)
	, Coll_DTime          DATETIME
	, Rslt_Obj_ID         VARCHAR(MAX)
	, Obsv_CD             VARCHAR(15)
	, Unit                VARCHAR(10)
);

WITH Before AS (
	SELECT 
	CASE
		WHEN UNICODE(SUBSTRING(OBS.dsply_val, 1, 1)) = 164 THEN '0'
		WHEN UNICODE(SUBSTRING(OBS.dsply_val, 2, 1)) = 164 THEN '0'
		WHEN UNICODE(SUBSTRING(OBS.dsply_val, 3, 1)) = 164 THEN RTRIM(LTRIM(SUBSTRING(OBS.dsply_val, 1, 2)))
		WHEN UNICODE(SUBSTRING(OBS.dsply_val, 4, 1)) = 164 THEN RTRIM(LTRIM(SUBSTRING(OBS.dsply_val, 1, 3)))
		WHEN UNICODE(SUBSTRING(OBS.dsply_val, 5, 1)) = 164 THEN RTRIM(LTRIM(SUBSTRING(OBS.dsply_val, 1, 4)))
		ELSE OBS.dsply_val
	  END              AS Result_Value_Before
		--case
		--	when val_no is null
		--	then CAST(dsply_val AS VARCHAR)
		--	else CAST(val_no AS VARCHAR)
		--end as result_value_before
	 -- CASE
		--	WHEN def_type_ind = 'AN' THEN dsply_val
		--	WHEN def_type_ind != 'AN' THEN CAST(val_no AS VARCHAR)
		--END            AS Result_Value_Before
	  , obs.coll_dtime AS Result_Before_Date
	  , obs.vst_no
	  , obs.coll_dtime
	  , obs.rslt_obj_id
	  , obs.obsv_cd
	  , obs.obsv_std_unit
	
	FROM SMSMIR.trn_sr_obsv AS OBS

	WHERE OBS.obsv_cd = '1010'
	AND OBS.obsv_std_unit = 'g/dl'
	AND OBS.coll_dtime >= DATEADD(DAY,-60, @START)
	AND OBS.coll_dtime < @END 
)

INSERT INTO @BEFORE 
SELECT * FROM Before

--SELECT * FROM @Before

/* 
======================================================================
G E T - T H E - A F T E R - R E S U L T
=======================================================================
*/
DECLARE @After TABLE (
	PK INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
	, After_Results       VARCHAR(MAX)
	, Result_After_Date   DATETIME
	, Vst_No              VARCHAR(MAX)
	, Coll_DTime          DATETIME
	, Rslt_Obj_ID         VARCHAR(MAX)
	, Obsv_CD             VARCHAR(15)
	, Unit                VARCHAR(10)
);

WITH After AS (
	SELECT 
	CASE
		WHEN UNICODE(SUBSTRING(OBS.dsply_val, 1, 1)) = 164 THEN '0'
		WHEN UNICODE(SUBSTRING(OBS.dsply_val, 2, 1)) = 164 THEN '0'
		WHEN UNICODE(SUBSTRING(OBS.dsply_val, 3, 1)) = 164 THEN RTRIM(LTRIM(SUBSTRING(OBS.dsply_val, 1, 2)))
		WHEN UNICODE(SUBSTRING(OBS.dsply_val, 4, 1)) = 164 THEN RTRIM(LTRIM(SUBSTRING(OBS.dsply_val, 1, 3)))
		WHEN UNICODE(SUBSTRING(OBS.dsply_val, 5, 1)) = 164 THEN RTRIM(LTRIM(SUBSTRING(OBS.dsply_val, 1, 4)))
		ELSE OBS.dsply_val
	  END              AS Result_Value_After
		--case
		--	when val_no is null
		--	then CAST(dsply_val AS VARCHAR)
		--	else CAST(val_no AS VARCHAR)
		--end as result_value_after
	 -- CASE
		--	WHEN def_type_ind = 'AN' THEN dsply_val
		--	WHEN def_type_ind != 'AN' THEN CAST(val_no AS VARCHAR)
		--END            AS Result_Value_After
	  , obs.coll_dtime AS Result_After_Date
	  , obs.vst_no
	  , obs.coll_dtime
	  , obs.rslt_obj_id
	  , obs.obsv_cd
	  , obs.obsv_std_unit
	
	FROM SMSMIR.trn_sr_obsv AS OBS

	WHERE OBS.obsv_cd = '1010'
	AND OBS.obsv_std_unit = 'g/dl'
	AND OBS.coll_dtime >= DATEADD(DAY,-60, @START)
	AND OBS.coll_dtime < @END 
)

INSERT INTO @After
SELECT * FROM After

SELECT A.Vst_Start_Dtime
, A.Vst_End_Dtime
, A.Pt_Name
, A.Age
, A.MRN
, A.Encounter
, A.Ordering_Party
, A.Ord_No
, A.Svc_Desc
, '' AS [Admitting_Diag]
, '' AS [Admitting_Diag_Code]
, A.Order_Ent_DTime
, A.Order_Str_DTime
, A.Order_Stp_DTime
--, CAST(dbo.c_udf_NumericChars(B.Before_Results) AS float) AS Before_Result
, CASE
	WHEN UNICODE(SUBSTRING(B.Before_Results, 4, 1)) = 13
		THEN SUBSTRING(B.Before_Results, 1, 3)
	WHEN UNICODE(SUBSTRING(B.Before_Results, 5, 1)) = 13
		THEN SUBSTRING(B.Before_Results, 1, 4)
	ELSE B.Before_Results
  END AS Before_Results
--, B.Before_Results
, B.Result_Before_Date
--, CAST(dbo.c_udf_NumericChars(C.After_Results) AS float)  AS After_Result
, CASE
	WHEN UNICODE(SUBSTRING(C.After_Results, 4, 1)) = 13
		THEN SUBSTRING(C.After_Results, 1, 3)
	WHEN UNICODE(SUBSTRING(C.After_Results, 5, 1)) = 13
		THEN SUBSTRING(C.After_Results, 1, 4)
	ELSE C.After_Results
  END AS After_Results
--, C.After_Results
, C.Result_After_Date

FROM @Patients         AS A
JOIN @Before           AS B
ON A.vst_no = B.vst_no
	AND A.Order_Ent_DTime > B.coll_dtime
	AND B.Before_Results > '7'
	AND B.rslt_obj_id = (
		SELECT TOP 1 AA.rslt_obj_id
		FROM @Before AS AA
		WHERE B.vst_no = AA.vst_no
		AND A.Order_Ent_DTime > AA.coll_dtime
		--AND AA.obsv_cd = '1010'
		--AND AA.Unit = 'g/dl'
		ORDER BY AA.coll_dtime DESC
	)
LEFT OUTER JOIN @After AS C
ON B.Vst_No = C.Vst_No
	AND B.Rslt_Obj_ID <> C.Rslt_Obj_ID
	AND B.Coll_DTime < C.Coll_DTime
	AND C.Rslt_Obj_ID = (
		SELECT TOP 1 BB.Rslt_Obj_ID
		FROM @After BB
		WHERE B.Vst_No = BB.Vst_No
		AND B.Rslt_Obj_ID <> BB.Rslt_Obj_ID
		AND B.Coll_DTime < BB.Coll_DTime
		--AND BB.Obsv_CD = '1010'
		--AND BB.Unit = 'g/dl'
		ORDER BY BB.Coll_DTime ASC
	)