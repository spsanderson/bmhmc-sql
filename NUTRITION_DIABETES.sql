-- This query is used for Nutritional Services in order to help
-- identify those with diabetes.
--###################################################################//
-- VARIABLE DECLARATION AND INITIALIZATION
DECLARE @SD DATETIME;
DECLARE @ED DATETIME;
SET @SD = '2014-03-23';
SET @ED = '2014-03-24';

--###################################################################//
-- COLUMN SELECTION
SELECT PAV.PtNo_Num AS [VISIT ID]
, PAV.Med_Rec_No AS MRN
, PAV.Pt_Name AS [PT NAME]
, PAV.Adm_Date AS [ADMIT DATE]
, PAV.Days_Stay AS [LOS]
, PAV.Pt_Age AS AGE
, SO.desc_as_written AS [ORDER]
, SO.prim_gnrc_drug_name AS [GENERIC DRUG NAME]
, SO.freq_dly AS [DRUG FREQUENCY]
, SO.ord_no AS [ORDER NUMBER]
, OSM.ord_sts AS [ORDER STATUS]
, SOS.prcs_dtime AS [ORDER STATUS TIME]
, OBS.dsply_val AS ENDOCRINE
  
-- DB(S) USED
FROM SMSDSS.BMH_PLM_PTACCT_V PAV
JOIN smsmir.sr_ord SO
ON PAV.PtNo_Num = SO.episode_no
JOIN smsmir.sr_ord_sts_hist SOS
ON SO.ord_no = SOS.ord_no
JOIN smsmir.ord_sts_modf_mstr OSM
ON SOS.hist_sts = OSM.ord_sts_modf_cd
JOIN smsmir.obsv OBS
ON SO.episode_no = OBS.episode_no

-- FILTER(S)
WHERE SOS.prcs_dtime >= @SD 
AND SOS.prcs_dtime < @ED
AND Plm_Pt_Acct_Type = 'I'
AND PAV.Dsch_Date IS NULL
AND SO.prim_gnrc_drug_name IN (
'ACARBOSE'
,' GLIPIZIDE'
, 'GLIPIXIDE XL'
, 'GLYBRURIDE'
, 'INSULIN ASPART 70/30'
, 'INSULIN DETEMIR'
, 'INSULIN GLARGINE'
, 'INSULIN ISOPHANE HUMAN'
, 'INSULIN LISPRO'
, 'INSULIN LISPRO 75/25'
, 'INSULIN REGULAR HUMAN'
, 'METFORMIN'
, 'PIOGLITAZONE'
, 'REPAGLINIDE'
)
AND SO.ord_no NOT IN (
	SELECT SO.ord_no

	FROM SMSDSS.BMH_PLM_PTACCT_V PAV
	JOIN smsmir.sr_ord SO
	ON PAV.PtNo_Num = SO.episode_no
	JOIN smsmir.sr_ord_sts_hist SOS
	ON SO.ord_no = SOS.ord_no
	JOIN smsmir.ord_sts_modf_mstr OSM
	ON SOS.hist_sts = OSM.ord_sts_modf_cd

	WHERE OSM.ord_sts IN (
	'DISCONTINUE'
	, 'CANCEL'
	) 
)
AND OBS.form_usage = 'ADMISSION'
AND OBS.obsv_cd_ext_name = 'ENDOCRINE'
