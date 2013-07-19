DECLARE @SD DATETIME
DECLARE @ED DATETIME
SET @SD = '2013-06-01';
SET @ED = '2013-06-30';

-- COLUMN SELECTION
SELECT PV.PtNo_Num AS 'VISIT ID'
, PV.Med_Rec_No AS 'MRN'
, PV.vst_start_dtime AS 'ADMIT'
, PV.vst_end_dtime AS 'DISC'
, PV.Days_Stay AS 'LOS'
, PV.pt_type AS 'PT TYPE'
, PV.hosp_svc AS 'HOSP SVC'
, SO.ord_no AS 'ORDER NUMBER'
--, SO.ent_dtime AS 'ORDER ENTRY TIME'
--, DATEDIFF(HOUR,PV.vst_start_dtime,SO.ent_dtime) AS 'ADM TO ENTRY HOURS'
, SO.svc_desc AS 'ORDER DESCRIPTION'
, CASE
    WHEN OSM.ord_sts = 'ACTIVE' THEN '1 - ACTIVE'
    WHEN OSM.ord_sts = 'IN PROGRESS' THEN '2 - IN PROGRESS'
    WHEN OSM.ord_sts = 'COMPLETE' THEN '3 - COMPLETE'
    WHEN OSM.ord_sts = 'CANCEL' THEN '4 - CANCEL'
    WHEN OSM.ord_sts = 'DISCONTINUE' THEN '5 - DISCONTINUE'
    WHEN OSM.ord_sts = 'SUSPEND' THEN '6 - SUSPEND'
  END AS 'ORDER STATUS'
, SOS.prcs_dtime AS 'ORDER STATUS TIME'
, DATEDIFF(DAY,PV.vst_start_dtime,SOS.prcs_dtime) AS 'ADM TO ORD STS IN DAYS'

-- DB(S) USED
FROM smsdss.BMH_PLM_PtAcct_V PV
JOIN smsmir.sr_ord SO
ON PV.PtNo_Num = SO.episode_no
JOIN smsmir.sr_ord_sts_hist SOS
ON SO.ord_no = SOS.ord_no
JOIN smsmir.ord_sts_modf_mstr OSM
ON SOS.hist_sts = OSM.ord_sts_modf_cd

-- FILTER(S)
WHERE PV.Adm_Date BETWEEN @SD AND @ED
-- THE FOLLOWING GETS RID OF ORDERS THAT WERE DISCONTINUED
AND SO.ord_no NOT IN (
	SELECT SO.ord_no
	
	FROM smsdss.BMH_PLM_PtAcct_V PV
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
	AND pv.drg_no IN (067,068,069)
	AND (SO.svc_desc LIKE 'CAROTID%'
	    OR SO.svc_desc LIKE 'ECHO%'
	    OR SO.svc_desc LIKE '%WITHOUT CONTRAST'
	    )
)
AND pv.drg_no IN (067,068,069)
AND (SO.svc_desc LIKE 'CAROTID%'
    OR SO.svc_desc LIKE 'ECHO%'
    OR SO.svc_desc LIKE '%WITHOUT CONTRAST'
    )
ORDER BY PV.PtNo_Num, SO.ord_no, SOS.prcs_dtime