/*=================================================================================================
NYSPFP HANYS Percentage of hyperglycemic POCT blood glucose results >= 200 mg/dL
Numerator: Number of POCT blood glucose results with values >= 200 mg/dL
Denominator: Number of all POCT blood glucose tests resulted.

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

-- Variable Declaration and initialization
DECLARE @START DATE;
DECLARE @END DATE;

SET @START = '2016-01-01';
SET @END = '2016-02-01';

-- Get initial results, they will need to be cleaned up as we want values as integers
SELECT a.episode_no
, b.ord_no
, a.ord_occr_no
, a.ord_obj_id
, CASE
	WHEN a.def_type_ind = 'an'
		THEN CAST(RTRIM(LTRIM(A.DSPLY_VAL)) AS varchar)
	WHEN a.def_type_ind = 'nm'
		THEN CAST(RTRIM(LTRIM(A.val_no)) AS varchar)
  END AS dsply_value
, a.def_type_ind
, b.ent_dtime
, a.coll_dtime
, D.vst_start_dtime
, a.obsv_cd_name
, c.src_hosp_svc
, c.ord_pty_spclty
, c.nurs_sta
, c.ord_sts_no_desc

INTO #TEMP_A

FROM smsmir.trn_sr_obsv           AS a
LEFT OUTER JOIN smsmir.trn_sr_ord AS b
ON a.episode_no = b.episode_no
	AND a.ord_obj_id = b.ord_obj_id
LEFT OUTER JOIN smsdss.ord_v      AS c
ON b.ord_no = c.ord_no
LEFT OUTER MERGE JOIN smsdss.BMH_PLM_PtAcct_V AS D
ON a.episode_no = D.PtNo_Num

WHERE A.obsv_cd_name LIKE '%GLUCOSE%' -- Get any glucose test
-- get rid of erroneous result values
AND A.dsply_val NOT LIKE 'yes%'
AND A.dsply_val NOT LIKE 'out%'
AND A.dsply_val NOT LIKE 'name%'
AND A.DSPLY_VAL NOT LIKE 'no%'
AND A.dsply_val NOT LIKE 'test%'
AND A.dsply_val NOT LIKE 'call%'
AND A.dsply_val NOT LIKE 'fing%'
AND A.dsply_val NOT LIKE 'qns%'
AND A.dsply_val NOT LIKE 'see%'
AND B.ent_dtime >= @START
AND B.ent_dtime < @END
AND LEFT(A.episode_no, 1) = '1'
AND c.ord_pty_spclty != 'EMRED'
AND c.loc_cd != 'EDICMS'
AND c.src_nurs_sta != 'EMER'
AND c.nurs_sta NOT IN (
	'EMER', 'PACU', 'SICU', 'CATH', 'PSY'
)
AND c.preadm_ord_ind_cd != '1'
AND a.coll_dtime >= d.vst_start_dtime
-- special note: we do not need to specify a complete order as we are
-- only bringing in orders that have a valid result which be default means
-- they were complete even if the status is discontinue or cancel
;

-----

SELECT A.episode_no
, A.ord_no
, A.ord_occr_no
, A.ord_obj_id
, A.dsply_value
-- Substring the floats by getting digits up to the decimal point, all test values are integers
, CASE
	WHEN UNICODE(SUBSTRING(a.dsply_value, 1, 1)) = 46 THEN '0'
	WHEN UNICODE(SUBSTRING(a.dsply_value, 2, 1)) = 46 THEN RTRIM(LTRIM(SUBSTRING(a.dsply_value, 1, 1)))
	WHEN UNICODE(SUBSTRING(a.dsply_value, 3, 1)) = 46 THEN RTRIM(LTRIM(SUBSTRING(a.dsply_value, 1, 2)))
	WHEN UNICODE(SUBSTRING(a.dsply_value, 4, 1)) = 46 THEN RTRIM(LTRIM(SUBSTRING(a.dsply_value, 1, 3)))
	WHEN UNICODE(SUBSTRING(a.dsply_value, 5, 1)) = 46 THEN RTRIM(LTRIM(SUBSTRING(a.dsply_value, 1, 4)))
	ELSE a.dsply_value
  END AS clean_value
, A.ent_dtime
, A.coll_dtime
, A.vst_start_dtime
, A.obsv_cd_name
, A.src_hosp_svc
, A.ord_pty_spclty
, A.nurs_sta
, A.ord_sts_no_desc

INTO #TEMP_B

FROM #TEMP_A AS A
;

-----

SELECT A.episode_no
, A.ord_no
, A.ord_occr_no
, A.ord_obj_id
-- we need to clean out the new values and cast them as integer data types in order to filter
, CAST(dbo.c_udf_NumericChars(CLEAN_VALUE) AS int) AS Glucose_Val
, A.ent_dtime
, A.coll_dtime
, A.vst_start_dtime
, A.obsv_cd_name
, A.src_hosp_svc
, A.ord_pty_spclty
, A.nurs_sta
, A.ord_sts_no_desc

INTO #TEMP_C 

FROM #TEMP_B AS A

WHERE clean_value IS NOT NULL
;

-----

SELECT COUNT(*)
FROM #TEMP_C;

-----

SELECT COUNT(*)
--SELECT *
FROM #TEMP_C
WHERE Glucose_Val >= 200
ORDER BY Glucose_Val;

-----

DROP TABLE #TEMP_A, #TEMP_B, #TEMP_C;