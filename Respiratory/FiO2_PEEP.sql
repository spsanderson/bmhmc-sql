SELECT TOP 10 episode_no
, pt_id
, vst_id
, vst_no
, obsv_cd
, obsv_cd_name
, obsv_user_id
, dsply_val
, val_sts_cd
, coll_dtime
, rslt_obj_id
, perf_dtime
FROM SMSMIR.obsv
WHERE obsv_cd IN (
	'A_BMH_VFFiO2'
	, 'A_BMH_VFPEEP'
)
AND episode_no = '14450357'
order by obsv_cd
, perf_dtime