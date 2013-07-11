-- THIS QUERY WILL GET DATE ON WEATHER OR NOT TESTING FOR TIA PTS
-- IS BEING DONE IN A TIMELY FASHION OR NOT
--#####################################################################
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
, OSM.ord_sts AS 'ORDER STATUS'
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
	
	WHERE OSM.ord_sts = 'DISCONTINUE'
	AND pv.drg_no IN (067,068,069)
	AND SO.svc_cd IN (
	'00424283'
	,'00700104'
	,'00720045'
	,'00720060'
	,'00720011'
	,'00720052'
	,'00700096'
	,'00720037'
	,'00714006'
	,'00700500'
	,'01710078'
	,'01710094'
	,'01710110'
	,'01404201'
	,'01404151'
	,'01330935'
	,'01330968'
	,'CAT9999GDT'
	,'0109994R'
	,'01330000'
	,'01330208'
	,'01330927'
	,'01301654'
	,'01307008'
	,'01330109'
	,'01330919'
	,'01320001'
	,'01330257'
	,'01330307'
	,'01330943'
	,'01330950'
	)
)
AND pv.drg_no IN (067,068,069)
AND SO.svc_cd IN (
'00424283'
,'00700104'
,'00720045'
,'00720060'
,'00720011'
,'00720052'
,'00700096'
,'00720037'
,'00714006'
,'00700500'
,'01710078'
,'01710094'
,'01710110'
,'01404201'
,'01404151'
,'01330935'
,'01330968'
,'CAT9999GDT'
,'0109994R'
,'01330000'
,'01330208'
,'01330927'
,'01301654'
,'01307008'
,'01330109'
,'01330919'
,'01320001'
,'01330257'
,'01330307'
,'01330943'
,'01330950'
)
ORDER BY PV.PtNo_Num, SO.ord_no, SOS.prcs_dtime
--#####################################################################
-- END REPORT...[]...[]...[]
