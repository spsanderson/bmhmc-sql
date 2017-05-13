-- VARIABLE DECLARATION AND INITIALIZATION
DECLARE @SD AS DATE;
DECLARE @ED AS DATE;
SET @SD = '2013-10-01';
SET @ED = '2014-08-01';
-- END OF VARIABLES

SELECT DISTINCT SO.episode_no
, CASE
	WHEN SUBSTRING(PDV.pract_rpt_name, 1,
			CHARINDEX(' X', PDV.PRACT_RPT_NAME, 1)) = ''
	THEN UPPER(PDV.PRACT_RPT_NAME)
	ELSE SUBSTRING(PDV.PRACT_RPT_NAME, 1,
			CHARINDEX(' X', PDV.pract_rpt_name, 1))
  END								AS [Doctor Ordering Consult]
, PDV.src_spclty_cd
, SO.svc_cd
, SO.ord_no
, RTRIM(
	REPLACE(
		REPLACE(
			REPLACE(
				SUBSTRING(SO.DESC_AS_WRITTEN, 21, 40)
			, 'Today', '')
		,'Stat','')
	,'In Am','')
)									AS [CONSULTANT CONTACTED]
, PAV.drg_no
, (
   CAST(DATEPART(YEAR, PAV.Dsch_Date) 
   AS VARCHAR(5)) 
   + '-' 
   + CAST(DATEPART(QUARTER, PAV.Dsch_Date)
   AS VARCHAR(5))
   )								AS [YYYYqN]
, CASE
	WHEN PDV.src_spclty_cd = 'HOSIM' THEN 1
	ELSE 0
  END AS [HOSPITALIST FLAG]


-- WHERE IT COMES FROM
FROM smsmir.sr_ord                  SO
LEFT MERGE JOIN smsdss.BMH_PLM_PtAcct_V        PAV
ON SO.episode_no = PAV.PtNo_Num
LEFT MERGE JOIN smsdss.pract_dim_v             PDV
ON PAV.Atn_Dr_No = PDV.src_pract_no

-- FILTER(S)
WHERE PAV.Dsch_Date >= @SD
AND PAV.Dsch_Date < @ED
AND PAV.Plm_Pt_Acct_Type = 'I'
AND PAV.PtNo_Num < '20000000'
AND PDV.orgz_cd = 'S0X0'
--AND PDV.spclty_cd != 'HOSIM'
AND svc_cd = 'Consult: Doctor'
AND SO.signon_id != 'HSF_JS'								


------------------------------------------------------------------------
-- VARIABLE DECLARATION AND INITIALIZATION
DECLARE @SD AS DATE;
DECLARE @ED AS DATE;
SET @SD = '2014-04-01';
SET @ED = '2014-05-01';
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