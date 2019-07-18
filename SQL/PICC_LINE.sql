SELECT PAV.PtNo_Num AS [VISIT ID]
, SO.ord_no AS [ORDER NUMBER]
, SO.ord_sts_prcs_dtime AS [ORD PROCESS TIME]
, SO.svc_desc AS [ORDER DESCRIPTION]
, X.[ORDER STATUS]
, PAV.prin_dx_cd AS [PRINICPAL DX]

FROM smsmir.sr_ord SO
JOIN smsdss.BMH_PLM_PtAcct_Clasf_Dx_V DV
ON SO.episode_no = DV.PtNo_Num
JOIN smsdss.BMH_PLM_PtAcct_V PAV
ON SO.episode_no = PAV.PtNo_Num
JOIN smsmir.ord_sts_hist SOS
ON SO.ord_no = SOS.ord_no
JOIN smsmir.ord_sts_modf_mstr OSM
ON SOS.hist_sts = OSM.ord_sts_modf_cd

-- CROSS APPLY FOR ORDER STATUS
CROSS APPLY (
SELECT
	CASE
		WHEN OSM.ord_sts = 'ACTIVE' THEN '1 - ACTIVE'
		WHEN OSM.ord_sts = 'IN PROGRESS' THEN '2 - IN PROGRESS'
		WHEN OSM.ord_sts = 'COMPLETE' THEN '3 - COMPLETE'
		WHEN OSM.ord_sts = 'CANCEL' THEN '4 - CANCEL'
		WHEN OSM.ord_sts = 'DISCONTINUE' THEN '5 - DISCONTINUE'
		WHEN OSM.ord_sts = 'SUSPEND' THEN '6 - SUSPEND'
	END AS [ORDER STATUS]
) X
WHERE SO.svc_desc IN (
	'Insert Peripheral Intravenous Catheter'
	, 'Insert Peripherally Inserted Central Catheter'
	, 'PICC Line Blood Culture'
	, 'Remove Peripherally Inserted Central Catheter'
)
AND PAV.Plm_Pt_Acct_Type = 'I'
AND DV.ClasfCd IN (
	'451.11'
	, '451.19'
	,' 453.40'
	, '453.41'
	, '453.42'
	, '415.1'
)
AND SO.ord_no NOT IN (
	SELECT SO.ord_no
	
	FROM smsmir.sr_ord SO
	JOIN smsdss.BMH_PLM_PtAcct_Clasf_Dx_V DV
	ON SO.episode_no = DV.PtNo_Num
	JOIN smsdss.BMH_PLM_PtAcct_V PAV
	ON SO.episode_no = PAV.PtNo_Num
	JOIN smsmir.ord_sts_hist SOS
	ON SO.ord_no = SOS.ord_no
	JOIN smsmir.ord_sts_modf_mstr OSM
	ON SOS.hist_sts = OSM.ord_sts_modf_cd
	
	WHERE OSM.ord_sts IN (
		'DISCONTINUE'
		, 'CANCEL'
	)
	AND SO.svc_desc IN (
		'Insert Peripheral Intravenous Catheter'
		, 'Insert Peripherally Inserted Central Catheter'
		, 'PICC Line Blood Culture'
		, 'Remove Peripherally Inserted Central Catheter'
	)
	AND PAV.Plm_Pt_Acct_Type = 'I'
	AND DV.ClasfCd IN (
		'451.11'
		, '451.19'
		,' 453.40'
		, '453.41'
		, '453.42'
		, '415.1'
	)
)
ORDER BY PAV.PtNo_Num, SO.ord_no, SOS.prcs_dtime