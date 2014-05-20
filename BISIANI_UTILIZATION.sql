-- VARIABLE DECLARATION AND INTIALIZATION
DECLARE @START DATE;
DECLARE @END   DATE;

SET @START = '2014-04-01'
SET @END   = '2014-05-01'

/*
#######################################################################

NOW CREATE A TABLE TO GET THE PATIENTS OF INTEREST ONLY, WE WILL THEN
CREATE ANOTHER TABLE TO GET THE ORDERS AND TIMES THAT WE ARE INTERESTED
IN

#######################################################################
*/

DECLARE @T1 TABLE(
	VISIT        VARCHAR(20)
	, MRN        VARCHAR(20)
	, NAME       VARCHAR(50)
	, ADMIT      DATE
	, DRG        VARCHAR(10)
	, [DRG DESC] VARCHAR(100)
)

INSERT INTO @T1
SELECT
A.PtNo_Num
, A.Med_Rec_No
, A.Pt_Name
, A.Adm_Date
, A.drg_no
, A.drg_no_cd_desc

FROM (
	SELECT PAV.PtNo_Num
	, PAV.Med_Rec_No
	, PAV.Pt_Name
	, PAV.Adm_Date
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

--SELECT * FROM @T1

/*
#######################################################################

GET ORDERS FOR CT W/O CONTRAST HEAD AREA

#######################################################################
*/

DECLARE @T2 TABLE(
	VISIT                    VARCHAR(20)
	, ORDER#                 VARCHAR(20)
	, [DESCRIPTION]          VARCHAR(150)
	, [ORDERING PARTY]       VARCHAR(50)
	, [ORDER ENTRY DTIME]    DATETIME
	, [ORDER COMPLETE DTIME] DATETIME
)

INSERT INTO @T2
SELECT
B.episode_no
, B.ord_no
, B.svc_desc
, B.pty_name
, B.ent_dtime
, B.ord_sts_prcs_dtime

FROM(
	SELECT SO.episode_no
	, SO.ord_no
	, SO.svc_desc
	, SO.pty_name
	, SO.ent_dtime
	, SO.ord_sts_prcs_dtime

	FROM smsmir.sr_ord  SO

	WHERE SO.svc_cd IN ('01304104', '01331453', '01331479'
						, '01304658', '01304468' , '01304765')
		AND SO.episode_no < '20000000'
		AND SO.ent_dtime >= DATEADD(D, -180, @START)
)B

--SELECT * FROM @T2

/*
#######################################################################

GET THE STATUS AND STATUS TIME FOR RAD ORDERS

#######################################################################
*/
DECLARE @T3 TABLE (
	VISIT             VARCHAR(20)
	, [ORDER #]       VARCHAR(20)
	, [STATUS TIME]   DATETIME 
	, [DEPT ID]       VARCHAR(20)
	, [PRIM STATUS]   VARCHAR(20)
	, [ORDER STATUS]  VARCHAR(40)
	, [STATUS ROWNUM] VARCHAR(3)
)

INSERT INTO @T3
SELECT
C.episode_no
, C.ord_no
, C.prcs_dtime
, C.signon_id
, C.ord_sts
, C.ord_sts_modf
, C.RN

FROM(
	SELECT SO.episode_no
	, SO.ord_no
	, SOS.prcs_dtime
	, SOS.signon_id
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

	FROM smsmir.sr_ord                     AS SO
		JOIN smsmir.sr_ord_sts_hist        AS SOS
		ON SO.ord_no = SOS.ord_no
		JOIN smsmir.ord_sts_modf_mstr      AS OSM
		ON SOS.hist_no = OSM.ord_sts_cd

	--WHERE SO.EPISODE_NO IN ('14120141', '14120448')
	WHERE SOS.signon_id = 'RAD'
		AND SO.svc_cd IN ('01304104', '01331453', '01331479'
						, '01304658', '01304468' , '01304765')
		AND SO.episode_no < '20000000'
		AND SO.ent_dtime >= DATEADD(D, -180, @START)
)C


/*
#######################################################################

BRING IT ALL TOGETHER AND GET THE TIME FROM ARRIVAL TO ORDER ENTRY
AND TIME FROM ORDER ENTRY TO ORDER COMPLETION TIME.

THE ORDER COMPLETION TIME IS WHEN THE ORDER WAS ACKNOWLEDGED BY SOMEONE
IN THE SOARIAN SYSTEM

#######################################################################
*/

SELECT T1.VISIT
, T1.NAME
, T1.ADMIT
, T1.[DRG DESC]
, T2.ORDER#
, T2.DESCRIPTION
, T2.[ORDER ENTRY DTIME]
--, T3.[DEPT ID]
--, T3B.[PRIM STATUS]
, T3B.[STATUS TIME]         AS [IN-PROG BY RAD]
--, T3.[PRIM STATUS]
, T3.[STATUS TIME]          AS [COMPLETE BY RAD]
, T2.[ORDER COMPLETE DTIME] AS [ACKNOWLEDGED AT]

FROM @T1                    AS T1
	LEFT JOIN @T2           AS T2
	ON T1.VISIT = T2.VISIT
	LEFT JOIN @T3           AS T3
	ON T2.ORDER# = T3.[ORDER #]
	LEFT JOIN @T3           AS T3B
	ON T3.[ORDER #] = T3B.[ORDER #]

WHERE T3.[STATUS ROWNUM]    = 1
	AND T3B.[STATUS ROWNUM] = 1
	AND T3.[PRIM STATUS]    = 'COMPLETE'
	AND T3B.[PRIM STATUS]   = 'IN PROGRESS'