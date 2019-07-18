/*
***********************************************************************
File: lf_icu_visits_2018.sql

Input Parameters:
	None

Tables/Views:
	smsdss.bmh_plm_ptacct_v

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get visits to an ICU unit for peds and adults

Revision History:
Date		Version		Description
----		----		----
2019-06-07	v1			Initial Creation
***********************************************************************
*/

SELECT COUNT(DISTINCT(a.pt_id)) AS pt_count

FROM smsdss.dly_cen_occ_fct_v AS A

WHERE A.nurs_sta IN (
	'MICU','SICU','CCU'
)
AND A.pt_id IN (
	SELECT XXX.PT_NO
	FROM smsdss.BMH_PLM_PtAcct_V AS XXX
	WHERE XXX.Adm_Date >= '2018-01-01'
	AND XXX.Adm_Date < '2019-01-01'
	AND XXX.tot_chg_amt > 0
	AND LEFT(XXX.PtNo_Num, 1) != '2'
	AND LEFT(XXX.PTNO_NUM, 4) != '1999'
	AND XXX.Pt_Age >= 18
)

GO
;

SELECT COUNT(DISTINCT(a.pt_id)) AS pt_count

FROM smsdss.dly_cen_occ_fct_v AS A

WHERE A.nurs_sta IN (
	'MICU','SICU','CCU'
)
AND A.pt_id IN (
	SELECT XXX.PT_NO
	FROM smsdss.BMH_PLM_PtAcct_V AS XXX
	WHERE XXX.Adm_Date >= '2018-01-01'
	AND XXX.Adm_Date < '2019-01-01'
	AND XXX.tot_chg_amt > 0
	AND LEFT(XXX.PtNo_Num, 1) != '2'
	AND LEFT(XXX.PTNO_NUM, 4) != '1999'
	AND XXX.Pt_Age < 18
)

GO
;