/*
***********************************************************************
File: bad_debt.sql

Input Parameters:
	None

Tables/Views:
	smsdss.bmh_plm_ptacct_v
    smsdss.pyr_dim_v

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get accounts in bad debt

Revision History:
Date		Version		Description
----		----		----
20121-12-02	v1			Initial Creation
***********************************************************************
*/

DECLARE @START DATE;
DECLARE @END DATE;

SET @START = '2021-01-01';
SET @END = GETDATE();

SELECT *
FROM SMSDSS.BMH_PLM_PtAcct_V AS PAV
LEFT JOIN SMSDSS.PYR_DIM_V AS PDV ON PAV.Pyr1_Co_Plan_Cd = PDV.src_pyr_cd
	AND PAV.Regn_Hosp = PDV.orgz_cd
WHERE PAV.pt_type NOT IN ('C', 'K', 'R', 'V')
	AND PAV.bd_wo_date >= @START
	AND PAV.bd_wo_date < @END
	AND PAV.fc IN ('1', '2', '3', '4', '5', '6', '7', '8', '9', '10')
