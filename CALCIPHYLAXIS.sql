SELECT *

FROM smsdss.BMH_PLM_PtAcct_Clasf_Dx_V DV
JOIN smsdss.BMH_PLM_PtAcct_V PAV
ON DV.PtNo_Num = PAV.PtNo_Num
JOIN smsmir.sr_ord so
ON DV.PtNo_Num = so.episode_no

WHERE dv.ClasfCd IN (
'275.49'
, '728.88'
)
AND dv.Clasf_Eff_Date >= '2013-01-01'
AND so.svc_desc LIKE 'sodium%'
ORDER BY DV.PtNo_Num