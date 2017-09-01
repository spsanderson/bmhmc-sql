SELECT LTRIM(RTRIM(RIGHT(A.Pt_No, 9)))       AS Pt_No
, CONVERT(VARCHAR, A.Svc_Date, 110)          AS Svc_Date
, B.race_cd
, C.race_cd_desc

FROM smsdss.BMH_PLM_PtAcct_Svc_V_Hold        AS A
INNER MERGE JOIN SMSDSS.BMH_PLM_PTACCT_V     AS B
ON A.Pt_No = B.Pt_No
LEFT JOIN smsdss.race_cd_dim_v               AS C
ON B.race_cd = C.src_race_cd

WHERE Svc_Cd = '04601001'
AND Svc_Date >= '2014-01-01'
AND Svc_Date < '2015-01-01'
AND C.src_sys_id = '#PMSNTX0'
