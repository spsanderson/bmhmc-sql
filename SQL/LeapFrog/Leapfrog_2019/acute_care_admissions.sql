/*
***********************************************************************
File: acute_care_admissions.sql

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
	Get total Actue Care Adult and Pediatric Admissions for 2018 LF survey

Revision History:
Date		Version		Description
----		----		----
2019-06-07	v1			Initial Creation
***********************************************************************
*/

SELECT COUNT(*) AS [Admits_Adult]

FROM SMSDSS.BMH_PLM_PtAcct_V

WHERE tot_chg_amt > 0
AND LEFT(PTNO_NUM, 1) != '2'
AND LEFT(PTNO_NUM, 4) != '1999'
AND Plm_Pt_Acct_Type = 'I'
AND hosp_svc != 'PSY'
AND Pt_Age >= 18
AND Adm_Date >= '2018-01-01'
AND Adm_Date < '2019-01-01'

UNION

SELECT COUNT(*) AS [Admits_Peds]

FROM SMSDSS.BMH_PLM_PtAcct_V

WHERE tot_chg_amt > 0
AND LEFT(PTNO_NUM, 1) != '2'
AND LEFT(PTNO_NUM, 4) != '1999'
AND Plm_Pt_Acct_Type = 'I'
AND hosp_svc != 'PSY'
AND Pt_Age < 18
AND Adm_Date >= '2018-01-01'
AND Adm_Date < '2019-01-01'
