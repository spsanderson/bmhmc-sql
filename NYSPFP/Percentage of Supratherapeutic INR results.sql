/*=================================================================================================
NYSPFP HANYS Percentage of Supratherapeutic INR results
Numerator: Number of INR results with values ≥ 5
Denominator: Number of all INR tests resulted

Notes:
Inclusion Criteria:
 - Samples drawn and resulted from the following units:
	- Inpatient
	- Intensive Care Unit (ICU)
	- Medical/Surgical
	- Step-Down/Intermediate
	- Critical Care Unit (CCU)
Exclusion Criteria:
  - Samples drawn and resulted from the following units:
	- Outpatient
	- Emergency Department
	- PPS-exempt units (Psych, Rehab)
	- All procedural and perioperative areas (i.e. - OR, PACU, Radiology, Cath Lab, Endoscopy, etc.)
  - Samples not resulted
=================================================================================================*/

-- variable declaration and initialization
DECLARE @START DATE;
DECLARE @END DATE;

SET @START = '2016-01-01';
SET @END = '2016-02-01';
-----
DECLARE @inr TABLE (
	PK INT IDENTITY(1, 1) NOT NULL PRIMARY KEY
	, Encounter               INT
	, Order_Number            VARCHAR(12)
	, Order_Occr_Number       VARCHAR(12)
	, Ord_Obj_ID              CHAR(80)
	, Value                   CHAR(60)
	, Ord_Entry_DateTime      DATETIME
	, Collection_DT           DATETIME
	, Vst_Start_DT            DATETIME
	, Observation_Name        CHAR(30)
	, Hospital_Svc            VARCHAR(40)
	, Ord_Spclty_Cd           VARCHAR(70)
	, Nurs_Sta                VARCHAR(50)
);

WITH CTE1 AS (
	SELECT a.episode_no
	, b.ord_no
	, a.ord_occr_no
	, a.ord_obj_id as obj
	, CASE
		WHEN a.def_type_ind = 'an'
			THEN CAST(a.dsply_val AS VARCHAR)
		WHEN a.def_type_ind = 'nm'
			THEN CAST(a.val_no AS VARCHAR)
	  END AS dsply_value
	, b.ent_dtime
	, a.coll_dtime
	, d.vst_start_dtime
	, a.obsv_cd_name
	, c.src_hosp_svc
	, c.ord_pty_spclty
	, c.nurs_sta

	FROM smsmir.trn_sr_obsv           AS a
	LEFT OUTER JOIN smsmir.trn_sr_ord AS b
	ON a.episode_no = b.episode_no
		AND a.ord_obj_id = b.ord_obj_id
	LEFT OUTER JOIN smsdss.ord_v      AS c
	ON b.ord_no = c.ord_no
	LEFT OUTER MERGE JOIN smsdss.BMH_PLM_PtAcct_V AS d
	on a.episode_no = d.ptno_num

	WHERE a.obsv_cd = '2012'
	--and a.ord_obj_id = ''
	--and a.episode_no = ''
	AND a.coll_dtime >= @START
	AND A.coll_dtime < @END
	AND LEFT(A.episode_no, 1) = '1'
	AND c.ord_pty_spclty != 'EMRED'
	AND c.loc_cd != 'EDICMS'
	AND c.src_nurs_sta != 'EMER'
	AND c.nurs_sta NOT IN (
		'EMER', 'PACU', 'SICU', 'CATH', 'PSY'
	)
	AND c.preadm_ord_ind_cd != '1'
	AND a.coll_dtime >= d.vst_start_dtime
)

INSERT INTO @inr
SELECT * FROM CTE1;

-----

SELECT *
, CAST(Value AS FLOAT) AS NEW_VAL 
INTO #TEMP_A
FROM @INR
WHERE Value IS NOT NULL
ORDER BY Encounter;

-----

SELECT COUNT(*) AS [Total_INR_Readings]
--SELECT *
FROM #TEMP_A AS A;

-----

SELECT COUNT(*) AS [Total_INR_GT_5.0]
--SELECT *
FROM #TEMP_A AS A
WHERE A.new_val >=5.0;

-----

DROP TABLE #TEMP_A;