-- VARIABLE DECLARATION AND INITIALIZATION
DECLARE @SD AS DATE;
DECLARE @ED AS DATE;
SET @SD = '2013-12-01';
SET @ED = '2014-01-01';
-- END OF VARIABLES

SELECT DISTINCT SO.episode_no
, PDV.pract_rpt_name
, SO.svc_cd
, SO.ord_no
, SUBSTRING(SO.desc_as_written,21,40) AS [CONSULTANT CONTACTED]

-- WHERE IT COMES FROM
FROM smsmir.sr_ord SO
JOIN smsdss.BMH_PLM_PtAcct_V PAV
ON SO.episode_no = PAV.PtNo_Num
JOIN smsdss.pract_dim_v PDV
ON PAV.Atn_Dr_No = PDV.src_pract_no

-- FILTER(S)
WHERE PAV.Dsch_Date >= @SD
AND PAV.Dsch_Date < @ED
AND PAV.Plm_Pt_Acct_Type = 'I'
AND PAV.PtNo_Num < '20000000'
AND PDV.orgz_cd = 'S0X0'
AND PDV.spclty_cd = 'HOSIM'
AND svc_cd = 'Consult: Doctor'
AND SO.signon_id != 'HSF_JS'

------------------------------------------------------------------------
-- VARIABLE DECLARATION AND INITIALIZATION
DECLARE @SD AS DATE;
DECLARE @ED AS DATE;
SET @SD = '2013-12-01';
SET @ED = '2014-01-01';
-- END OF VARIABLES

SELECT PDV.pract_rpt_name
, COUNT(DISTINCT SO.episode_no) AS [COUNT OF PTS]
, COUNT(SO.ord_no) AS [CONSULT ORDER COUNT]
, ROUND(
		CAST(
			CAST((COUNT(SO.ORD_NO))AS DECIMAL(10,5))
			/
			CAST((COUNT(DISTINCT SO.episode_no)) AS DECIMAL(10,5))
			AS DECIMAL(10,2))
	, 2) AS [AVG CONSULTS PER PT] 
-- WHERE IT COMES FROM
FROM smsmir.sr_ord SO
JOIN smsdss.BMH_PLM_PtAcct_V PAV
ON SO.episode_no = PAV.PtNo_Num
JOIN smsdss.pract_dim_v PDV
ON PAV.Atn_Dr_No = PDV.src_pract_no

-- FILTER(S)
WHERE PAV.Dsch_Date >= @SD
AND PAV.Dsch_Date < @ED
AND PAV.Plm_Pt_Acct_Type = 'I'
AND PAV.PtNo_Num < '20000000'
AND PDV.orgz_cd = 'S0X0'
AND PDV.spclty_cd = 'HOSIM'
AND svc_cd = 'Consult: Doctor'
AND SO.signon_id != 'HSF_JS'

GROUP BY PDV.pract_rpt_name