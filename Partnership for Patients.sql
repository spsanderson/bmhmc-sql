/*
=======================================================================
INR table
=======================================================================
*/
DECLARE @inr TABLE (
	PK INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
	, Encounter               INT
	, Ord_Obj_ID              CHAR(8)
	, Value                   CHAR(6)
	, Ord_Entry_DateTime      DATETIME
	, Observation_Creation_DT DATETIME
	, Observation_Name        CHAR(3)
);

WITH CTE1 AS (
	SELECT a.episode_no
	, a.ord_obj_id
	--, b.ord_obj_id
	, CASE
		WHEN a.def_type_ind = 'an'
		THEN CAST(a.dsply_val AS VARCHAR)
		WHEN a.def_type_ind = 'nm'
		THEN CAST(a.val_no AS VARCHAR)
	  END AS dsply_value
	, b.ent_dtime
	, a.obsv_cre_dtime
	--, a.ord_occr_no
	--, b.ord_no
	--, c.ord_no
	, a.obsv_cd_name

	FROM smsmir.trn_sr_obsv           AS a
	LEFT OUTER JOIN smsmir.trn_sr_ord AS b
	ON a.episode_no = b.episode_no
		AND a.ord_obj_id = b.ord_obj_id
	LEFT OUTER JOIN smsdss.ord_v      AS c
	ON b.ord_no = c.ord_no

	WHERE a.obsv_cd = '2012'
	AND a.val_no > 5
	AND c.ord_sts_desc = 'Complete'
	AND A.obsv_cre_dtime >= '2015-12-01'
	AND A.obsv_cre_dtime < '2016-01-01'
)

INSERT INTO @inr
SELECT * FROM CTE1

/*
=======================================================================
Warfarin table
=======================================================================
*/
DECLARE @Warfarin TABLE (
	PK INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
	, Encounter           INT
	, OrderNum            INT
	, Order_Desc          VARCHAR(MAX)
	, Process_DT          DATETIME
	, Order_Status        VARCHAR(25)
	, RN                  INT
);

WITH Warfarin AS (
	SELECT so.episode_no
	, so.ord_no
	, so.svc_desc
	, sos.prcs_dtime
	, osm.ord_sts

	--, osm.ord_sts_modf
	--, osm.ord_sts_cd
	--, SOS.hist_sts
	--, osm.ord_sts_modf_cd
	--, *

	, ROW_NUMBER() OVER(
		PARTITION BY so.episode_no, so.ord_no, osm.ord_sts_cd
		ORDER BY sos.prcs_dtime
	) AS rn

	FROM smsmir.sr_ord                 AS SO
	JOIN smsmir.sr_ord_sts_hist        AS SOS
	ON SO.ord_no = SOS.ord_no
	JOIN smsmir.ord_sts_modf_mstr      AS OSM
	ON SOS.hist_no = OSM.ord_sts_cd
		and sos.hist_sts = osm.ord_sts_modf_cd

	--where so.ord_no = '18627289'
	WHERE SO.svc_desc LIKE '%Warfarin%'
	AND SO.ent_dtime >= '2015-12-01'
	AND SO.ent_dtime < '2016-01-01'
)

INSERT INTO @Warfarin
SELECT * 
FROM Warfarin 
WHERE rn = 1

SELECT D.Med_Rec_No
, INR.Encounter
, INR.Observation_Name
, INR.Observation_Creation_DT
, INR.Value
, A.OrderNum
, SUBSTRING(A.Order_Desc, 1, 8)                        AS [OrderDesc]
, A.Process_DT AS [Active DT]
, -(DATEDIFF(D, INR.Ord_Entry_DateTime, A.Process_DT)) AS [Days Med Ord before INR Test]
, B.Process_DT AS [In Progress DT]
, C.Process_DT AS [Discontinue/Suspend DT]
 
FROM @inr                               AS INR
LEFT OUTER JOIN @Warfarin               AS A
ON INR.Encounter = A.Encounter
	AND INR.Ord_Entry_DateTime > A.Process_DT
LEFT OUTER JOIN @Warfarin               AS B
ON A.Encounter = B.Encounter
	AND A.OrderNum = B.OrderNum
LEFT OUTER JOIN @Warfarin               AS C
ON A.Encounter = C.Encounter
	AND A.OrderNum = C.OrderNum
LEFT OUTER JOIN SMSDSS.BMH_PLM_PTACCT_V AS D
ON INR.Encounter = D.PtNo_Num

WHERE A.Order_Status like '%active%'
AND B.Order_Status LIKE '%IN PROGRESS%'
AND C.Order_Status != 'ACTIVE'
AND C.Order_Status != 'IN PROGRESS'
AND DATEDIFF(D, INR.Ord_Entry_DateTime, A.Process_DT) > -2

ORDER BY A.Encounter, A.Process_DT

/*
=======================================================================
ANTI-COAGULANT END
=======================================================================
*/

/*
=======================================================================
BLOOD GLUCOSE START
=======================================================================
*/
/*
=======================================================================
Glucose table
=======================================================================
*/
-- Get initial results
DECLARE @GlucoseTmp TABLE (
	PK INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
	, Encounter               INT
	, Ord_Obj_ID              VARCHAR(MAX)
	, Value                   VARCHAR(MAX)
	, Ord_Entry_DateTime      DATETIME
	, Observation_Creation_DT DATETIME
	, Observation_Name        varCHAR(MAX)
);

WITH GlucoseTmp AS (
	SELECT a.episode_no
	, a.ord_obj_id
	--, b.ord_obj_id
	, RTRIM(LTRIM(SUBSTRING(a.dsply_val, 1, 4))) AS Dsply_Val
	, b.ent_dtime
	, a.obsv_cre_dtime
	--, a.ord_occr_no
	--, b.ord_no
	--, c.ord_no
	, a.obsv_cd_name

	FROM smsmir.trn_sr_obsv           AS a
	LEFT OUTER JOIN smsmir.trn_sr_ord AS b
	ON a.episode_no = b.episode_no
		AND a.ord_obj_id = b.ord_obj_id
	LEFT OUTER JOIN smsdss.ord_v      AS c
	ON b.ord_no = c.ord_no

	WHERE A.obsv_cd_name LIKE '%GLUCOSE%'
	AND A.dsply_val NOT LIKE 'yes%'
	AND A.dsply_val NOT LIKE 'out%'
	AND A.dsply_val NOT LIKE 'name%'
	AND A.DSPLY_VAL NOT LIKE 'no%'
	AND A.dsply_val NOT LIKE 'test%'
	AND A.dsply_val NOT LIKE 'call%'
	AND A.dsply_val NOT LIKE 'fing%'
	AND A.dsply_val NOT LIKE 'qns%'
	AND A.dsply_val NOT LIKE 'see%'
	AND c.ord_sts_desc = 'Complete'
	AND B.ent_dtime >= '2015-12-01'
	AND B.ent_dtime < '2016-01-01'
	
)

INSERT INTO @GlucoseTmp
SELECT * FROM GlucoseTmp

-- Strip un-wanted unicode characters from observation values
DECLARE @GlucoseTmp2 TABLE (
	PK INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
	, Encounter                    INT
	, Ord_Obj_ID                   INT
	, Value                        VARCHAR(10)
	, Ord_Entry_DateTime           DATETIME
	, Observation_Creation_DT      DATETIME
	, Observation_Name             VARCHAR(50)
	, test_val                     VARCHAR(10)
);

WITH GlucoseTmp2 AS (
	SELECT Encounter
	, Ord_Obj_ID
	, Value
	, Ord_Entry_DateTime
	, Observation_Creation_DT
	, Observation_Name
	, CASE
		WHEN UNICODE(SUBSTRING(a.Value, 1, 1)) = 164 THEN '0'
		WHEN UNICODE(SUBSTRING(a.Value, 2, 1)) = 164 THEN '0'
		WHEN UNICODE(SUBSTRING(a.Value, 3, 1)) = 164 THEN RTRIM(LTRIM(SUBSTRING(a.Value, 1, 2)))
		WHEN UNICODE(SUBSTRING(a.Value, 4, 1)) = 164 THEN RTRIM(LTRIM(SUBSTRING(a.Value, 1, 3)))
		WHEN UNICODE(SUBSTRING(a.Value, 5, 1)) = 164 THEN RTRIM(LTRIM(SUBSTRING(a.Value, 1, 4)))
		ELSE a.Value
	  END AS test_val

	FROM @GlucoseTmp AS A
	WHERE UNICODE(SUBSTRING(A.VALUE, 1, 1)) != 164
	AND UNICODE(SUBSTRING(A.VALUE, 2, 1)) != 164
)

INSERT INTO @GlucoseTmp2
SELECT * FROM GlucoseTmp2

-- cast clean values as integers
DECLARE @GlucoseClean TABLE (
	PK INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
	, Encounter                    INT
	, Ord_Obj_ID                   INT
	, Obs_Value                    INT
	, Ord_Entry_Datetime           DATETIME
	, Observation_Creation_DT      DATETIME
	, Observation_Name             VARCHAR(50)
);

WITH GlucoseClean AS (
	SELECT Encounter
	, Ord_Obj_ID
	, CAST(dbo.c_udf_NumericChars(test_val) AS INT) AS Obs_Value
	, Ord_Entry_DateTime
	, Observation_Creation_DT
	, Observation_Name

	FROM @GlucoseTmp2

)

INSERT INTO @GlucoseClean
SELECT * FROM GlucoseClean

--SELECT * FROM @GlucoseClean

/*
=======================================================================
MEDICATIONS
=======================================================================
*/
DECLARE @Insulin TABLE (
	PK INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
	, Encounter           INT
	, OrderNum            INT
	, Order_Desc          VARCHAR(MAX)
	, Process_DT          DATETIME
	, Order_Status        VARCHAR(25)
	, RN                  INT
);

WITH Insulin AS (
	SELECT so.episode_no
	, so.ord_no
	, so.svc_desc
	, sos.prcs_dtime
	, osm.ord_sts

	--, osm.ord_sts_modf
	--, osm.ord_sts_cd
	--, SOS.hist_sts
	--, osm.ord_sts_modf_cd
	--, *

	, ROW_NUMBER() OVER(
		PARTITION BY so.episode_no, so.ord_no, osm.ord_sts_cd
		ORDER BY sos.prcs_dtime
	) AS rn

	FROM smsmir.sr_ord                 AS SO
	JOIN smsmir.sr_ord_sts_hist        AS SOS
	ON SO.ord_no = SOS.ord_no
	JOIN smsmir.ord_sts_modf_mstr      AS OSM
	ON SOS.hist_no = OSM.ord_sts_cd
		and sos.hist_sts = osm.ord_sts_modf_cd

	--where so.ord_no = '18627289'
	WHERE SO.prim_gnrc_drug_name IN (
		'ACARBOSE'
		, 'GLIPIZIDE'
		, 'GLIPIXIDE XL'
		, 'GLYBRURIDE'
		, 'INSULIN ASPART 70/30'
		, 'INSULIN DETEMIR'
		, 'INSULIN GLARGINE'
		, 'INSULIN ISOPHANE HUMAN'
		, 'INSULIN LISPRO'
		, 'INSULIN LISPRO 75/25'
		, 'INSULIN REGULAR HUMAN'
		, 'METFORMIN'
		, 'PIOGLITAZONE'
		, 'REPAGLINIDE'
	)
	AND SO.ent_dtime >= '2015-12-01'
	AND SO.ent_dtime < '2016-01-01'
)

INSERT INTO @Insulin
SELECT * 
FROM Insulin
WHERE rn = 1

/*
=======================================================================
PULL TOGETHER
=======================================================================
*/
DECLARE @Interim TABLE (
	PK INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
	, Encounter                    INT
	, Ord_Obj_ID                   INT
	, Observation_Name             VARCHAR(50)
	, Obs_Value                    INT
	, Ord_Entry_Datetime           DATETIME
	, Observation_Creation_DT      DATETIME
	, [Med_Order]                  VARCHAR(MAX)
	, [Med_Active_DT]              DATETIME
	, [Med_IP_DT]                  DATETIME
	, [Med_Dis_DT]                 DATETIME
);

WITH Interim AS (
	SELECT g.Encounter
	, g.Ord_Obj_ID
	, g.Observation_Name
	, g.Obs_Value
	, g.Ord_Entry_Datetime
	, g.Observation_Creation_DT
	, a.Order_Desc AS [Med_Order]
	, a.Process_DT AS [Med_Active_DT]
	, b.Process_DT AS [Med_IP_DT]
	, c.Process_DT AS [Med_Dis_DT]

	FROM @GlucoseClean       AS G
	LEFT OUTER JOIN @Insulin AS A
	ON G.Encounter = A.Encounter
	LEFT OUTER JOIN @Insulin AS B
	ON A.Encounter = B.Encounter
		AND A.OrderNum = B.OrderNum
	LEFT OUTER JOIN @Insulin AS C
	ON A.Encounter = C.Encounter
		AND A.OrderNum = C.OrderNum

	WHERE A.Order_Status LIKE '%ACTIVE%'
	AND B.Order_Status LIKE '%IN PROGRESS%'
	AND C.Order_Status != 'ACTIVE'
	AND C.Order_Status != 'IN PROGRESS'
	AND C.Order_Status != 'SUSPEND'
	AND G.Obs_Value > 200
)

INSERT INTO @Interim
SELECT * FROM Interim

DECLARE @Final TABLE (
	PK INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
	, Encounter                     INT
	, Ord_Obj_ID                   INT
	, Observation_Name             VARCHAR(50)
	, Obs_Value                    INT
	, Ord_Entry_Datetime           DATETIME
	, Observation_Creation_DT      DATETIME
	, [Med_Order]                  VARCHAR(MAX)
	, [Med_Active_DT]              DATETIME
	, [Med_IP_DT]                  DATETIME
	, [Med_Dis_DT]                 DATETIME
	, RN                           INT
);

WITH Final AS (
	SELECT II.Encounter
	, II.Ord_Obj_ID
	, II.Observation_Name
	, II.Obs_Value
	, II.Ord_Entry_Datetime
	, II.Observation_Creation_DT
	, II.Med_Order
	, II.Med_Active_DT
	, II.Med_IP_DT
	, II.Med_Dis_DT
	, ROW_NUMBER() OVER(
		PARTITION BY II.Encounter
		ORDER BY II.Encounter
	) AS RN

	FROM @Interim II
)

INSERT INTO @Final
SELECT * FROM Final

SELECT F.Encounter
, plm.Med_Rec_No
, F.Ord_Obj_ID
, F.Observation_Name
, F.Obs_Value
, F.Ord_Entry_Datetime
, F.Observation_Creation_DT
, F.Med_Order
, F.Med_Active_DT
, F.Med_IP_DT
, F.Med_Dis_DT

FROM @Final F
INNER JOIN SMSDSS.BMH_PLM_PtAcct_V AS PLM
ON F.Encounter = PLM.PtNo_Num

WHERE F.RN = 1
ORDER BY F.Encounter, F.RN

/*
=======================================================================
OPIATES START
=======================================================================
*/
SELECT episode_no
, Med_Rec_No
, Days_Stay
, ord_no
, svc_desc
, pty_name
, ent_dtime

FROM smsmir.sr_ord
LEFT OUTER JOIN smsdss.bmh_plm_ptacct_v
ON smsmir.sr_ord.episode_no = smsdss.BMH_PLM_PtAcct_V.PtNo_Num

WHERE svc_desc LIKE '%narcan%'
AND ent_dtime >= '2015-12-01'
AND ent_dtime < '2016-01-01'
AND episode_no IN (
	SELECT episode_no
	FROM smsmir.sr_ord
	WHERE (
		svc_desc LIKE '%morphine%'
		OR
		svc_desc LIKE '%vicodin%'
		OR
		svc_desc LIKE '%percocet%'
		OR
		svc_desc LIKE '%oxyco%'
	)
	AND ent_dtime >= '2015-12-01'
	AND ent_dtime < '2016-01-01'
)

-- GET FROM ED
SELECT Account
, MR#
, Days_Stay
, Placer#
, OrderName
, 'ED'
, SchedDT

FROM smsdss.c_Wellsoft_Ord_Rpt_Tbl
LEFT OUTER JOIN smsdss.bmh_plm_ptacct_v
ON smsdss.c_wellsoft_ord_rpt_tbl.account = smsdss.bmh_plm_ptacct_v.PtNo_Num

WHERE OrderName LIKE '%narcan%'
AND OrderName NOT LIKE 'canceled%'
AND SchedDT >= '2015-12-01'
AND SchedDT <  '2016-01-01'
AND Account IN (
	SELECT account
	FROM smsdss.c_Wellsoft_Ord_Rpt_Tbl
	WHERE (
		OrderName LIKE '%morph%'
		OR
		OrderName LIKE '%vicod%'
		OR
		OrderName LIKE '%perco%'
		OR
		OrderName LIKE '%oxycod%'
	)
	AND SchedDT >= '2015-12-01'
	AND SchedDT < '2016-01-01'
)

-- GET FROM CHARGES
SELECT c.PtNo_Num
, c.Med_Rec_No
, c.Days_Stay
, '' AS order#
, b.actv_name
, '' AS ordering_party
, a.actv_dtime

FROM smsmir.mir_actv                    AS a
LEFT OUTER JOIN smsmir.mir_actv_mstr    AS b
ON a.actv_cd = b.actv_cd
LEFT OUTER JOIN smsdss.bmh_plm_ptacct_v AS c
ON a.pt_id = c.pt_no

WHERE b.actv_name LIKE 'naloxone%'
AND a.actv_dtime >= '2015-12-01'
AND a.actv_dtime < '2016-01-01'
AND a.pt_id IN (
	SELECT pt_id

	FROM smsmir.mir_actv                 AS a
	LEFT OUTER JOIN smsmir.mir_actv_mstr AS b
	ON a.actv_cd = b.actv_cd

	WHERE (
		b.actv_name LIKE '%morphine%'
		OR
		b.actv_name LIKE '%oxycodone%'
		OR
		b.actv_name LIKE '%percocet%'
		OR
		b.actv_name LIKE '%vicodin%'
	)
	AND a.actv_dtime >= '2015-12-01'
	AND a.actv_dtime < '2016-01-01'	
)
ORDER BY a.pt_id