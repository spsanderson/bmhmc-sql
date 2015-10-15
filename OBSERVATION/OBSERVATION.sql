SELECT *
, DATEDIFF(HH,adm_strt_dtime,dsch_strt_dtime) AS [OBS_HRS]
, ROUND(
 CONVERT(
  FLOAT
  , DATEDIFF(HH, ADM_STRT_DTIME,DSCH_STRT_DTIME)
  ,NULL)/24
,2)                                           AS [DAYS_OBS]

FROM smsdss.c_obv_Comb_1

ORDER BY pt_id




