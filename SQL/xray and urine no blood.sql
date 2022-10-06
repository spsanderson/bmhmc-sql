-- COLUMN SELECTION
SELECT svc.Pt_No
, Svc_Date
, CASE
    WHEN DV.svc_cd_desc LIKE '%XRAY%' THEN 'XRAY'
    WHEN DV.svc_cd_desc LIKE '%URIN%' THEN 'URINE'
    ELSE DV.svc_cd_desc
  END AS [XRAY / URINE / OTHER]

  -- DB(S) USED
FROM smsdss.BMH_PLM_PtAcct_Svc_V_Hold SVC
JOIN smsdss.svc_cd_dim_v DV
ON SVC.Svc_Cd = DV.svc_cd

-- FILTERS
WHERE SVC.Svc_Date >= '2014-01-01'
AND SVC.Pt_Type = 'E'

-- WE DO NOT WANT PATIENTS WHO HAVE RECIEVED SOME SORT OF BLOOD WORK
AND SVC.Pt_No NOT IN (
	SELECT SVC.Pt_No
	FROM smsdss.BMH_PLM_PtAcct_Svc_V_Hold SVC
	WHERE SVC.Svc_Cd IN (
		'0041285',   -- BLOOD PREGNANCY TEST
		'00419994',  -- VEIN PUNCTURE
		'00400143',
		'00400218',
		'00400572',
		'00400671',
		'00400705',
		'00400788',
		'00400838',
		'00400929',
		'00400945',
		'00401034',
		'00401042',
		'00401620',
		'00401760',
		'00402347',
		'00402370',
		'00402453',
		'00402776',
		'00402925',
		'00403147',
		'00403154',
		'00403170',
		'00403501',
		'00403642',
		'00403741',
		'00404079',
		'00407304',
		'00407627',
		'00408492',
		'00408500',
		'00409656',
		'00412205',
		'00422550',
		'00424762'
		)
	)

-- WE WANT ONLY THOSE PATIETNS WHO HAVE HAD BOTH A URINE PREGNANCY TEST
-- AND HAVE HAD AN XRAY
AND SVC.Pt_No IN (
    SELECT DISTINCT SVC.Pt_No
    FROM smsdss.BMH_PLM_PtAcct_Svc_V_Hold SVC
    JOIN smsdss.svc_cd_dim_v DV
    ON SVC.Svc_Cd = DV.svc_cd
    WHERE SVC.Svc_Cd = '00455550' -- URINE PREGNANCY TEST
    )
AND SVC.Pt_No IN(
    SELECT DISTINCT SVC.Pt_No
    FROM smsdss.BMH_PLM_PtAcct_Svc_V_Hold SVC
    JOIN smsdss.svc_cd_dim_v DV
    ON SVC.Svc_Cd = DV.svc_cd
    WHERE DV.svc_cd_desc LIKE '%XRAY%'
    )
ORDER BY SVC.Pt_No