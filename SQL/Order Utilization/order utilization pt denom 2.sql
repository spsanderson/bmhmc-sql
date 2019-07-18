DROP TABLE smsdss.c_IP_Count_for_Order_Utilization_Project

DECLARE @START DATE;
DECLARE @END   DATE;

SET @START = '2013-01-01';
SET @END   = '2016-04-01';
-----------------------------------------------------------------------

SELECT A.PtNo_Num
, A.Atn_Dr_No
, B.pract_rpt_name
, YEAR(A.Adm_Date) AS [Svc_Yr]
, A.vst_start_dtime
, A.vst_end_dtime

INTO #ip_tbl_plm

FROM SMSDSS.BMH_PLM_PtAcct_V AS A
LEFT JOIN smsdss.pract_dim_v AS B
ON A.Atn_Dr_No = B.src_pract_no
	AND B.orgz_cd = 'S0X0'

WHERE A.Adm_Date >= @START
AND A.Adm_Date < @END
AND A.tot_chg_amt > 0
AND A.Plm_Pt_Acct_Type = 'I'
AND PtNo_Num < '20000000'
AND LEFT(PTNO_NUM, 1) != '1999'

--SELECT * FROM #ip_tbl_plm

-----------------------------------------------------------------------
-- G E T - E D - W A L K O U T - F R O M - M I R - T A B L E
-----------------------------------------------------------------------
SELECT DISTINCT(CAST(PT_ID AS int)) AS PT_ID

INTO #mir_tbl_ed_walkout

FROM smsmir.mir_actv AS A

WHERE actv_cd IN ('04600052','04600573','04600565')
AND LEFT(pt_id, 5) = '00001'

--SELECT * FROM #mir_tbl_ed_walkout

-----------------------------------------------------------------------
-- G E T - E D - W A L K O U T - F R O M - W E L L S O F T - T A B L E
-----------------------------------------------------------------------
SELECT Account

INTO #wellsoft_tbl_ed_walkout

FROM smsdss.c_Wellsoft_Rpt_tbl

WHERE Disposition IN ('AMA', 'LWBS', 'LABS')
AND Arrival >= DATEADD(DAY, -10, @START)
AND Arrival < @END
AND LEFT(Account, 1) = '1'

--SELECT * FROM #wellsoft_tbl_ed_walkout

-----------------------------------------------------------------------
-- G E T - O B S E R V A T I O N - X F R - M I R - T A B L E
-----------------------------------------------------------------------
SELECT DISTINCT(CAST(PT_ID AS INT)) AS PT_ID

INTO #mir_tbl_obsxfer_activity

FROM smsmir.mir_actv

WHERE actv_cd = '04700035'
AND LEFT(pt_id, 5) = '00001'

--SELECT * FROM #mir_tbl_obsxfer_activity

-----------------------------------------------------------------------
-- G E T - O B S E R V A T I O N - X F R - W E L L S O F T - T A B L E
-----------------------------------------------------------------------
SELECT Account

INTO #wellsoft_tbl_obsxfer_activity

FROM smsdss.c_Wellsoft_Rpt_tbl

WHERE Arrival >= DATEADD(DAY, -10, @START)
AND Arrival < @END
AND LEFT(Account, 1) = '1'
AND Disposition = 'Observation'

--SELECT * FROM #wellsoft_tbl_obsxfer_activity

-----------------------------------------------------------------------
-- G E T - R O O M - C H A R G E - A C T I V I T Y
-----------------------------------------------------------------------
SELECT DISTINCT(CAST(A.pt_id AS INT)) AS PT_ID

INTO #mir_room_chg_activity

FROM smsmir.mir_actv            AS A
INNER JOIN smsmir.mir_actv_mstr AS B
ON A.ACTV_CD = B.ACTV_CD

WHERE B.dept_cd = '081'
--AND B.actv_name NOT LIKE 'EMER%'
--AND B.actv_name NOT LIKE 'DEL%'

-----------------------------------------------------------------------
-- F I N A L - J O I N S
-----------------------------------------------------------------------
SELECT AA.PtNo_Num
, AA.Atn_Dr_No
, AA.pract_rpt_name
, CASE
	WHEN BB.PT_ID IS NOT NULL
		THEN 1
		ELSE 0
  END AS [ED Walkout MIR]
, CASE
	WHEN CC.Account IS NOT NULL
		THEN 1
		ELSE 0
  END AS [ED Walkout WellSoft]
, CASE
	WHEN DD.PT_ID IS NOT NULL
		THEN 1
		ELSE 0
  END AS [Obs Xfer MIR]
, CASE
	WHEN EE.Account IS NOT NULL
		THEN 1
		ELSE 0
  END AS [Obs Xfer WellSoft]
, CASE
	WHEN FF.PT_ID IS NOT NULL
		THEN 1
		ELSE 0
  END AS [IP Rm Chg Actv MIR]
, AA.Svc_Yr
, CASE
	WHEN GG.Account IS NULL
		THEN DATEDIFF(HOUR, AA.vst_start_dtime, AA.vst_end_dtime)
		ELSE DATEDIFF(HOUR, GG.Arrival, AA.vst_end_dtime)
  END AS [Hours At Hosp]

INTO smsdss.c_IP_Count_for_Order_Utilization_Project
  
FROM #ip_tbl_plm                    AS AA
LEFT JOIN #mir_tbl_ed_walkout       AS BB
ON AA.PtNo_Num = pt_id
LEFT JOIN #wellsoft_tbl_ed_walkout  AS CC
ON AA.PtNo_Num = CC.Account
LEFT JOIN #mir_tbl_obsxfer_activity AS DD
ON AA.PtNo_Num = DD.PT_ID
LEFT JOIN #wellsoft_tbl_obsxfer_activity AS EE
ON AA.PtNo_Num = EE.Account
LEFT JOIN #mir_room_chg_activity   AS FF
ON AA.PtNo_Num = FF.PT_ID
LEFT JOIN smsdss.c_Wellsoft_Rpt_tbl AS GG
ON AA.PtNo_Num = GG.Account

-----------------------------------------------------------------------
-- E N D - O F - R E P O R T
-----------------------------------------------------------------------

-----------------------------------------------------------------------
-- T A B L E - D R O P S / M A I N T E N A N C E
-----------------------------------------------------------------------
DROP TABLE #ip_tbl_plm
DROP TABLE #mir_tbl_ed_walkout
DROP TABLE #wellsoft_tbl_ed_walkout
DROP TABLE #mir_tbl_obsxfer_activity
DROP TABLE #wellsoft_tbl_obsxfer_activity
DROP TABLE #mir_room_chg_activity