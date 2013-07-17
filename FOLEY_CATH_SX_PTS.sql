DECLARE @SD DATETIME
DECLARE @ED DATETIME
SET @SD = '2013-04-01';
SET @ED = '2013-06-10';

SELECT *

FROM smsdss.BMH_PLM_PtAcct_V PV
JOIN smsmir.sr_ord SO
ON PV.PtNo_Num = SO.episode_no
JOIN smsmir.sr_ord_sts_hist SOS
ON SO.ord_no = SOS.ord_no
JOIN smsmir.ord_sts_modf_mstr OSM
ON SOS.hist_sts = OSM.ord_sts_modf_cd
JOIN smsdss.pract_dim_v PDV
ON SO.pty_cd = PDV.src_pract_no

WHERE PV.Adm_Date BETWEEN @SD AND @ED
AND SO.svc_cd IN ('PCO_REMFOLEY'
,'PCO_INSRTFOLEY'
,'PCO_INSTFOLEY'
,'PCO_URIMETER'
)