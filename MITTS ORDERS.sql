-- MITTS ORDERS

-- VARIABLE DECLARATION AND INITIALIZATION
DECLARE @SD DATETIME;
DECLARE @ED DATETIME;
SET @SD = '2013-10-19'
SET @ED = '2013-10-24'

-- COLUMN SELECTION
SELECT PV.PtNo_Num AS 'VISIT ID'
, PV.Med_Rec_No AS 'MRN'
, PV.vst_start_dtime AS 'ADMIT'
, PV.vst_end_dtime AS 'DISC'
, PV.Days_Stay AS 'LOS'
, PV.pt_type AS 'PT TYPE'
, PV.hosp_svc AS 'HOSP SVC'
, SO.ord_no AS 'ORDER NUMBER'
, SO.ent_dtime AS 'ORDER ENTRY TIME'
, DATEDIFF(HOUR,PV.vst_start_dtime,SO.ent_dtime) AS 'ADM TO ENTRY HOURS'
, CASE
    WHEN OSM.ord_sts = 'ACTIVE' THEN '1 - ACTIVE'
    WHEN OSM.ord_sts = 'IN PROGRESS' THEN '2 - IN PROGRESS'
    WHEN OSM.ord_sts = 'COMPLETE' THEN '3 - COMPLETE'
    WHEN OSM.ord_sts = 'CANCEL' THEN '4 - CANCEL'
    WHEN OSM.ord_sts = 'DISCONTINUE' THEN '5 - DISCONTINUE'
    WHEN OSM.ord_sts = 'SUSPEND' THEN '6 - SUSPEND'
  END AS 'ORDER STATUS'

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
AND SO.desc_as_written LIKE '%mittens%'
AND PV.hosp_svc NOT IN (
	'DIA'
	,'DMS'
	,'EME'
	)
ORDER BY PV.PtNo_Num, SO.ord_no, SOS.prcs_dtime