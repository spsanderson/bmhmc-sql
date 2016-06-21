-- VARIABLE DECLARATION AND INTIALIZATION
DECLARE @START DATE;
DECLARE @END   DATE;

SET @START = '2014-08-01'
SET @END   = '2014-09-01'
-----------------------------------------
/*
#######################################################################

GET THOSE OF INTEREST

#######################################################################
*/
DECLARE @T1 TABLE(
	VISIT        VARCHAR(20)
	, MRN        VARCHAR(20)
	, NAME       VARCHAR(50)
	, StartDtime datetime
	, DRG        VARCHAR(10)
	, [DRG DESC] VARCHAR(100)
)

INSERT INTO @T1
SELECT
A.PtNo_Num
, A.Med_Rec_No
, A.Pt_Name
, A.vst_start_dtime
, A.drg_no
, A.drg_no_cd_desc

FROM (
	SELECT PAV.PtNo_Num
	, PAV.Med_Rec_No
	, PAV.Pt_Name
	, PAV.vst_start_dtime
	, PAV.drg_no
	, DDV.drg_no_cd_desc

	FROM smsdss.BMH_PLM_PtAcct_V     AS PAV
		JOIN smsdss.drg_dim_v        AS DDV
		ON PAV.drg_no = DDV.drg_no

	WHERE PAV.drg_no IN (67, 68,69)
		AND PAV.Dsch_Date >= @START
		AND PAV.Dsch_Date < @END
		AND DDV.drg_vers = 'MS-V25'
)A

/*
#######################################################################

END OF QUERY 1, NOW GET THE ORDERS OF INTEREST

#######################################################################
*/

DECLARE @ORDENT TABLE (
	VISIT             VARCHAR(20)
	, [ORDER #]       VARCHAR(20)
	, SVC_DESC        VARCHAR(100)
	, ORD_PTY         VARCHAR(50)
	, ENT_DTIME       DATETIME
	, SIGN_ON         VARCHAR(25)
	, [STATUS TIME]   DATETIME 
	, [PRIM STATUS]   VARCHAR(20)
	, [ORDER STATUS]  VARCHAR(40)
	, [STATUS ROWNUM] VARCHAR(3)
	, ACKNOWLEDGED    DATETIME
)

INSERT INTO @ORDENT
SELECT *

FROM (
	SELECT SO.episode_no
	, SO.ord_no
	, SO.svc_desc
	, SO.pty_name
	, SO.ent_dtime
	, SOS.signon_id
	, SOS.prcs_dtime
	, OSM.ord_sts
	, OSM.ord_sts_modf
	, ROW_NUMBER() OVER (
						PARTITION BY SO.EPISODE_NO
						, SO.ORD_NO
						, osm.ord_sts
						
						ORDER BY SO.ORD_NO ASC
						, SOS.DEPT_OBJ_ID  DESC
						,OSM.ID_COL        DESC
						) RN
	, SO.ord_sts_prcs_dtime

	FROM smsmir.sr_ord                     AS SO
		JOIN smsmir.sr_ord_sts_hist        AS SOS
		ON SO.ord_no = SOS.ord_no
		JOIN smsmir.ord_sts_modf_mstr      AS OSM
		ON SOS.hist_no = OSM.ord_sts_cd

	WHERE SO.svc_cd IN (
		'00600015', '00700096', '00700104', '00700500', '00714006',
		'00720011', '00720037', '00720045', '00720052', '00720060', 
		'01404151', '01404201', '01710078', '01710094', '01710110', 
		'02300804', '02300820', '02300846', '02300861', '02350809',
		'02350825', '02350841', '01304104', '01331453', '01331479', 
		'01304658', '01304468' , '01304765'
		)
		AND SO.episode_no < '20000000'
		AND SO.ent_dtime >= DATEADD(D, -180, @START)
)AA

SELECT	A.VISIT
, A.StartDtime
, B.[ORDER #]
, B.SVC_DESC
, B.ORD_PTY
--, B.SIGN_ON
, B.ENT_DTIME                       AS [ORDER ENTRY]
--, B.[STATUS TIME]                   AS [ACTIVE]
, C.SIGN_ON                         AS [DEPT/NAME]
, C.[STATUS TIME]                   AS [IN PROGRESS]
, D.SIGN_ON                         AS [DEPT/NAME]
, D.[STATUS TIME]                   AS COMPLETE
, D.ACKNOWLEDGED
, DATEDIFF(HOUR
			, A.StartDtime
			, B.ENT_DTIME)          AS [ORD HRS AFTER ADMIT]

FROM @T1                         A
	LEFT JOIN @ORDENT            B
	ON A.VISIT = B.VISIT
	LEFT JOIN @ORDENT            C
	ON B.[ORDER #] = C.[ORDER #]
	LEFT JOIN @ORDENT            D
	ON B.[ORDER #] = D.[ORDER #]

WHERE B.[STATUS ROWNUM] = 1
	AND C.[STATUS ROWNUM] = 1
	AND D.[STATUS ROWNUM] = 1
	AND B.[PRIM STATUS] = 'Active'
	AND C.[PRIM STATUS] = 'In Progress'
	AND D.[PRIM STATUS] = 'Complete'

ORDER BY A.VISIT  ASC
, B.[ORDER #]     ASC
, B.[STATUS TIME] ASC