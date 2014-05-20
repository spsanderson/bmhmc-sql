DECLARE @S DATE;
DECLARE @E DATE;

SET @S = '2014-05-01';
SET @E = '2014-05-10';

DECLARE @T1 TABLE (
VISIT             VARCHAR(20)
, ORDER#          VARCHAR(20)
, [STATUS TIME]   DATETIME
, [PRIM STATUS]   VARCHAR(20)
, [ORDER STATUS]  VARCHAR(40)
, [SVC DESC]      VARCHAR(150)
, [STATUS ROWNUM] VARCHAR(3)
)

INSERT INTO @T1
SELECT
A.episode_no
, A.ord_no
, A.prcs_dtime
, A.ord_sts
, A.ord_sts_modf
, A.svc_desc
, A.RN

FROM(
	SELECT SO.episode_no
	, SO.ord_no
	, SOS.prcs_dtime
	, OSM.ord_sts
	, OSM.ord_sts_modf
	, SO.svc_desc
	, ROW_NUMBER() OVER (
						PARTITION BY SO.EPISODE_NO
						, SO.ORD_NO
						, osm.ord_sts
						
						ORDER BY SO.ORD_NO ASC
						, SOS.DEPT_OBJ_ID  DESC
						,OSM.ID_COL        DESC
						) RN
	
	FROM smsmir.sr_ord                 AS SO
	JOIN smsmir.sr_ord_sts_hist        AS SOS
	ON SO.ord_no = SOS.ord_no
	JOIN smsmir.ord_sts_modf_mstr      AS OSM
	ON SOS.hist_no = OSM.ord_sts_cd
	/*ON ADMIT DATE*/
	JOIN smsdss.BMH_PLM_PtAcct_V       AS PAV
	ON SO.episode_no = PAV.PtNo_Num

	WHERE svc_cd IN (
		'PRE_P2337Q4PD',
		'PCO_RemONGT',
		'PCO_InstNGT'
	)
	AND PAV.Adm_Date >= @S
	AND PAV.Adm_Date < @E
)A

SELECT *
, ROW_NUMBER() OVER (
					PARTITION BY T1.VISIT ORDER BY T1.ORDER# ASC
					) AS RN

FROM @T1 T1

WHERE T1.[STATUS ROWNUM] = 1
