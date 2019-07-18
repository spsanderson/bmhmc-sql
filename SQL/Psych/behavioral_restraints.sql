/*
***********************************************************************
File: behavioral_restraints.sql

Input Parameters:
	None

Tables/Views:
	smsmir.sr_ord AS A
    SMSDSS.BMH_PLM_PTACCT_V AS PAV
    SMSDSS.dly_cen_beds_occ_fct_v AS C
    SMSDSS.rm_bed_mstr_v AS D

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get Behavioral Restraints data for LM

Revision History:
Date		Version		Description
----		----		----
2019-06-11	v1			Initial Creation
***********************************************************************
*/

DECLARE @S DATE;
DECLARE @E DATE;

SET @S = '2019-01-01';
SET @E = GETDATE();

SELECT pav.Med_Rec_No
, A.episode_no
, A.ord_no          AS [ORDER_NO]
, A.svc_desc        AS [ORDER_DESC]
, a.desc_as_written AS [Order_As_Writen]
, A.pty_name        AS [ORDERING_PARTY]
, A.ent_dtime       AS [ENTRY_DTIME]
, A.str_dtime       AS [START_DTIME]
, A.freq_dly        AS FREQUENCY
, A.stp_dtime       AS [STOP_DTIME]
, A.freq_wk         AS [REPEAT]
, C.day_of_stay
--, C.cen_date
, D.RM_NO           AS [CENSUS_ROOM_NO]
, D.NURS_STA        AS [CENSUS_NURS_STA]
, ROW_NUMBER() OVER (
				PARTITION BY A.EPISODE_NO
				ORDER BY A.ORD_NO ASC
				) AS [ORDER COUNT]

FROM smsmir.sr_ord AS A
LEFT OUTER JOIN SMSDSS.BMH_PLM_PTACCT_V AS PAV
ON A.EPISODE_NO = PAV.PTNO_NUM
LEFT OUTER JOIN SMSDSS.dly_cen_beds_occ_fct_v AS C
ON PAV.PT_NO = C.PT_ID
	AND A.ent_date = C.cen_date
LEFT OUTER JOIN SMSDSS.rm_bed_mstr_v AS D
ON C.RM_BED_KEY = D.ID_COL

WHERE A.svc_cd = 'PCO_RstBehav'
AND LEFT(PAV.PTNO_NUM, 1) != '2'
AND LEFT(PAV.PTNO_NUM, 4) != '1999'
--AND PAV.PLM_PT_ACCT_TYPE = 'I'
AND PAV.TOT_CHG_AMT > 0
AND A.ent_date >= @S
AND A.ent_date < @E
AND D.NURS_STA = 'PSY'

ORDER BY episode_no DESC, [ORDER_NO] ASC