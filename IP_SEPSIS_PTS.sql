-- VARIABLE DECLARATION AND INITIALIZATION
DECLARE @SD DATETIME
DECLARE @ED DATETIME
SET @SD = '2013-01-01';
SET @ED = '2013-06-30';

-- COLUMN SELECTION
SELECT 
DISTINCT PV.PtNo_Num AS 'VISIT ID'
, PV.Med_Rec_No AS 'MRN'
, PV.vst_start_dtime AS 'ADMIT'
, PV.vst_end_dtime AS 'DISC'
, PV.Days_Stay AS 'LOS'
, PV.dsch_disp AS 'DISPO'
, CASE
    WHEN PV.dsch_disp IN (
    'C1A','C1N','C1Z','C2A','C2N','C2Z','C3A','C3N',
    'C3Z','C4A','C4N','C4Z','C7A','C7N','C7Z','C8A',
    'C8N','C8Z','D1A','D1N','D1Z','D2A','D2N','D2Z',
    'D3A','D3N','D3Z','D4A','D4N','D4Z','D7A','D7N',
    'D7Z','D8A','D8N','D8Z'
    )
    THEN 1
    ELSE 0
  END AS MORTALITY
, PV.pt_type AS 'PT TYPE'
, PV.hosp_svc AS 'HOSP SVC'
, SO.ord_no AS 'ORDER NUMBER'
--, SO.ent_dtime AS 'ORDER ENTRY TIME'
--, DATEDIFF(HOUR,PV.vst_start_dtime,SO.ent_dtime) AS 'ADM TO ENTRY HOURS'
, SO.svc_cd AS 'SVC CD'
, CASE 
    WHEN SO.svc_desc LIKE 'CBC WITH WBC DIFF%'
    THEN 'WBC ORDER'
    WHEN SO.svc_desc LIKE 'LACTIC ACID'
    THEN 'LACTATE ORDER'
    WHEN SO.svc_desc LIKE '%XRAY%'
    THEN 'XRAY ORDER'
    WHEN SO.svc_desc LIKE 'SODIUM CHLORIDE%'
    OR SO.svc_desc LIKE 'SODIUM BICARB%'
    OR SO.svc_desc LIKE 'DEXTROSE%'
    OR SO.svc_desc LIKE 'D5%'
	THEN 'FLUID ORDER'
    WHEN SO.svc_desc LIKE 'CIPRO%'
	OR SO.svc_desc LIKE 'VANCO%'
	OR SO.svc_desc LIKE 'CEFEPIME%'
	OR SO.svc_desc LIKE 'LEVAQU%'
	OR SO.svc_desc LIKE 'ZITHROM%'
	OR SO.svc_desc LIKE 'CEFTRIA%'
	OR SO.svc_desc LIKE 'ZOSYN%'
	OR SO.svc_desc LIKE 'ROCEF'
	THEN 'ANTIBITOIC ORDER'
  END AS 'ORDER DESCRIPTION'
, CASE
    WHEN OSM.ord_sts = 'ACTIVE' THEN '1 - ACTIVE'
    WHEN OSM.ord_sts = 'IN PROGRESS' THEN '2 - IN PROGRESS'
    WHEN OSM.ord_sts = 'COMPLETE' THEN '3 - COMPLETE'
    WHEN OSM.ord_sts = 'CANCEL' THEN '4 - CANCEL'
    WHEN OSM.ord_sts = 'DISCONTINUE' THEN '5 - DISCONTINUE'
    WHEN OSM.ord_sts = 'SUSPEND' THEN '6 - SUSPEND'
  END AS 'ORDER STATUS'
, SOS.prcs_dtime AS 'ORD STS TIME'
-- NEGATIVE HRS INDICATES THAT TEST WAS ORDERED PRE-ADMIT SENT OVER BY
-- ED
, DATEDIFF(HOUR,PV.vst_start_dtime,SOS.prcs_dtime) AS 'ADM TO ORD STS IN HRS'

FROM smsdss.BMH_PLM_PtAcct_Clasf_Dx_V PDV
JOIN smsdss.BMH_PLM_PtAcct_V PV
ON PDV.PtNo_Num = PV.PtNo_Num
--JOIN smsdss.dx_cd_dim_v DX
--ON PV.prin_dx_cd = DX.dx_cd
JOIN smsmir.sr_ord SO
ON PV.PtNo_Num = SO.episode_no
JOIN smsmir.sr_ord_sts_hist SOS
ON SO.ord_no = SOS.ord_no
JOIN smsmir.ord_sts_modf_mstr OSM
ON SOS.hist_sts = OSM.ord_sts_modf_cd

WHERE PDV.ClasfCd IN (
	'785.52', '995.91', '995.92', '995.93', '995.94', '999.39', '999.89'
	)
AND PV.hosp_svc NOT IN (
	'DIA'
	,'DMS'
	,'EME'
	)
AND PV.Adm_Date BETWEEN @SD AND @ED
AND (SO.svc_desc LIKE 'CBC WITH WBC DIFF%'     -- LAB
	OR SO.svc_desc LIKE 'LACTIC ACID'          -- LAB
	OR SO.svc_desc LIKE '%XRAY%'               -- XRAY
	OR SO.svc_desc LIKE 'D5%'                  -- FLUID
	OR SO.svc_desc LIKE 'SODIUM CHLORIDE%'     -- FLUID
	OR SO.svc_desc LIKE 'SODIUM BICARB%'       -- FLUID
	OR SO.svc_desc LIKE 'DEXTROSE%'            -- FLUID
	OR SO.svc_desc LIKE 'CIPRO%'               -- AB
	OR SO.svc_desc LIKE 'VANCO%'               -- AB
	OR SO.svc_desc LIKE 'CEFEPIME%'            -- AB
	OR SO.svc_desc LIKE 'LEVAQU%'              -- AB
	OR SO.svc_desc LIKE 'ZITHROM%'             -- AB
	OR SO.svc_desc LIKE 'CEFTRIA%'             -- AB
	OR SO.svc_desc LIKE 'ZOSYN%'               -- AB
	OR SO.svc_desc LIKE 'ROCEF%'               -- AB
	)


-- THE FOLLOWING GETS RID OF ORDERS THAT WERE DISCONTINUED
-- ONLY FOR EKG, CHEST XRAY PORTABLE, LACTIC ACID, CBC W/DIFF
AND SO.ord_no NOT IN (
	SELECT SO.ord_no
	
	FROM smsdss.BMH_PLM_PtAcct_Clasf_Dx_V PDV
	JOIN smsdss.BMH_PLM_PtAcct_V PV
	ON PDV.PtNo_Num = PV.PtNo_Num
	--JOIN smsdss.dx_cd_dim_v DX
	--ON PV.prin_dx_cd = DX.dx_cd
	JOIN smsmir.sr_ord SO
	ON PV.PtNo_Num = SO.episode_no
	JOIN smsmir.sr_ord_sts_hist SOS
	ON SO.ord_no = SOS.ord_no
	JOIN smsmir.ord_sts_modf_mstr OSM
	ON SOS.hist_sts = OSM.ord_sts_modf_cd
	
	WHERE OSM.ord_sts IN (
		'DISCONTINUE'
		,'CANCEL'
		)
	AND PDV.ClasfCd IN (
		'785.52', '995.91', '995.92', '995.93', '995.94', '999.39', '999.89'
		)
	AND PV.hosp_svc NOT IN (
		'DIA'
		,'DMS'
		,'EME'
		)
	AND (
		SO.svc_desc LIKE 'CBC WITH WBC DIFF%'    -- LAB
		OR SO.svc_desc LIKE 'LACTIC ACID'        -- LAB
		OR SO.svc_desc LIKE '%XRAY%'             -- XRAY
		)
)
ORDER BY PV.PtNo_Num, SO.ord_no, SOS.prcs_dtime