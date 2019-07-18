USE [SMSPHDSSS0X0]
GO
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

/*
***********************************************************************
File: c_ip_card_cath_v.sql

Input Parameters:
	None

Tables/Views:
	Start Here

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Create IP Cardiac Cath View

Revision History:
Date		Version		Description
----		----		----
2019-01-17	v1			Initial Creation
***********************************************************************
*/

--ALTER VIEW [smsdss].[c_ip_card_cath_v] AS
SELECT a.pt_id,
a.pt_id_start_dtime,
b.vst_start_dtime as 'Admit_Dtime',
b.vst_end_dtime as 'Dsch_Dtime',
(SELECT MONTH(q.actv_dtime)
FROM smsmir.mir_actv as q
WHERE a.pt_id=q.pt_id AND a.pt_id_start_dtime=q.pt_id_start_dtime AND q.actv_cd BETWEEN '07000000' AND '07099999'
GROUP BY MONTH(q.actv_Dtime)
) as 'Proc_Month',
(SELECT YEAR(q.actv_dtime)
FROM smsmir.mir_actv as q
WHERE a.pt_id=q.pt_id AND a.pt_id_start_dtime=q.pt_id_start_dtime AND q.actv_cd BETWEEN '07000000' AND '07099999'
GROUP BY YEAR(q.actv_Dtime)
) as 'Proc_Year',
(SELECT SUM(g.actv_tot_qty)
FROM smsmir.mir_actv as g
WHERE a.pt_id=g.pt_id AND a.pt_id_start_dtime=g.pt_id_start_dtime
AND g.actv_cd='07000433'
) as 'Cath_Stat_Ind',
SUM(a.actv_tot_qty) as 'Cath_Chg_Qty',
SUM(a.chg_tot_amt) as 'Cath_Chgs'

FROM smsmir.mir_actv as a LEFT JOIN smsmir.mir_vst as b
ON a.pt_id=b.pt_id AND a.pt_id_start_dtime=b.pt_id_start_dtime

WHERE a.actv_cd BETWEEN '07000000' AND '07099999'
--AND chg_tot_amt <> 0

GROUP BY a.pt_id, a.pt_id_start_dtime, b.vst_start_dtime, b.vst_end_dtime



GO
