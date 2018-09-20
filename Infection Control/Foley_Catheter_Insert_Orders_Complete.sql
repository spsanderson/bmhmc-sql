/*
--------------------------------------------------------------------------------

File : Foley_Catheter_Insert_Orders_Complete.sql

Parameters : 
	None 
--------------------------------------------------------------------------------
Purpose: Get completed Foley Catheter Insert Orders

Tables: 

Views:
	smsdss.BMH_PLM_PtAcct_V  AS PV
    smsmir.sr_ord            AS SO
    smsmir.sr_ord_sts_hist   AS SOS
    smsmir.ord_sts_modf_mstr AS OSM

Functions:
	
Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle
	
Revision History: 
Date		Version		Description
----		----		----
2018-09-18	v1			Initial Creation

--------------------------------------------------------------------------------
*/
-- VARIABLE DECLARATION AND INITIALIZATION
DECLARE @SD DATETIME
DECLARE @ED DATETIME
SET @SD = '2018-08-01';
SET @ED = '2018-09-01';

-- COLUMN SELECTION
SELECT PV.PtNo_Num    AS [VISIT ID]
, PV.Med_Rec_No       AS [MRN]
, PV.vst_start_dtime  AS [Admit_Date]
, PV.vst_end_dtime    AS [Dishcarge_Date]
, PV.Days_Stay        AS [LOS]
, PV.pt_type          AS [PT TYPE]
, PTTYPE.pt_type_desc AS [Pt_Type_Desc]
, PV.hosp_svc         AS [HOSP SVC]
, SO.pty_cd           AS [Provider_ID]
, SO.pty_name         AS [Proivder_Name]
, SO.ord_no           AS [ORDER NUMBER]
, SO.ent_dtime        AS [ORDER ENTRY TIME]
--, DATEDIFF(HOUR,PV.vst_start_dtime,SO.ent_dtime) AS [ADM TO ENTRY HOURS]
, CASE
	WHEN SO.svc_cd IN (
		'PCO_InstFoley','PCO_InstFoley','PCO_InsrtFoley','PCO_LIPFoley','PCO_FoleyPlcdOR'
	)
		THEN 'INSERT'
  END AS [ORD DESC]
, SO.svc_desc        AS [Order_Desc]
, CASE
    WHEN OSM.ord_sts = 'ACTIVE' 
		THEN '1 - ACTIVE'
    WHEN OSM.ord_sts = 'IN PROGRESS' 
		THEN '2 - IN PROGRESS'
    WHEN OSM.ord_sts = 'COMPLETE' 
		THEN '3 - COMPLETE'
    WHEN OSM.ord_sts = 'CANCEL' 
		THEN '4 - CANCEL'
    WHEN OSM.ord_sts = 'DISCONTINUE' 
		THEN '5 - DISCONTINUE'
    WHEN OSM.ord_sts = 'SUSPEND' 
		THEN '6 - SUSPEND'
  END AS [ORDER STATUS]
, SOS.prcs_dtime     AS [ORDER STATUS TIME]

-- TABLE(S) USED
FROM smsdss.BMH_PLM_PtAcct_V PV
LEFT OUTER JOIN smsmir.sr_ord SO
ON PV.PtNo_Num = SO.episode_no
LEFT OUTER JOIN smsmir.sr_ord_sts_hist SOS
ON SO.ord_no = SOS.ord_no
LEFT OUTER JOIN smsmir.ord_sts_modf_mstr OSM
ON SOS.hist_sts = OSM.ord_sts_modf_cd
LEFT OUTER JOIN smsdss.pt_type_dim_v AS PTTYPE
ON PV.pt_type = PTTYPE.src_pt_type
	AND PV.Regn_Hosp = PTTYPE.orgz_cd

-- FILTER(S)
WHERE PV.Dsch_Date >= @SD 
AND PV.Dsch_Date < @ED
AND SO.svc_cd IN (
	'PCO_InstFoley'
	,'PCO_InstFoley'
	,'PCO_InsrtFoley'
	,'PCO_FoleyPlcdOR'
	,'PCO_LIPFoley'
)
-- We do not want orders for those patients on dialysis
AND PV.hosp_svc NOT IN (
	'DIA'
	,'DMS'
	,'EME'
)
-- We only want orders that have a status of complete
AND OSM.ord_sts = 'COMPLETE'

ORDER BY PV.PtNo_Num
, SO.ord_no
, SOS.prcs_dtime