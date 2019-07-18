/*
***********************************************************************
File: cigna_rate_sheet_transcatheter_closure_vsd_query.sql

Input Parameters:
	None

Tables/Views:
	SMSDSS.BMH_PLM_PtAcct_Clasf_Proc_V_New
	SMSDSS.BMH_PLM_PtAcct_V

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get Transcatheter Closure VSD Volume

Revision History:
Date		Version		Description
----		----		----
2019-07-01	v1			Initial Creation
***********************************************************************
*/
DECLARE @STARTDATE DATETIME;
DECLARE @ENDDATE DATETIME;

SET @STARTDATE = '2018-01-01';
SET @ENDDATE = '2019-01-01';

SELECT PAV.med_rec_no,
	PAV.PtNo_Num,
	CAST(PAV.Adm_Date AS DATE) AS [Adm_Date],
	CAST(PAV.Dsch_Date AS DATE) AS [Dsch_Date],
	YEAR(PAV.DSCH_DATE) AS [Dsch_YR],
	MONTH(PAV.DSCH_DATE) AS [Dsch_MO],
	pav.hosp_svc,
	pav.tot_chg_amt,
	pav.tot_pay_amt,
	pav.tot_amt_due
FROM smsdss.BMH_PLM_PtAcct_V AS PAV
WHERE PAV.Dsch_Date >= @STARTDATE
	AND PAV.Dsch_Date < @ENDDATE
	AND PAV.tot_chg_amt > 0
	AND PAV.Pyr1_Co_Plan_Cd IN ('K11', 'X01', 'E01', 'K55')
	AND PAV.PT_NO IN (
		SELECT DISTINCT PT_NO
		FROM SMSDSS.BMH_PLM_PtAcct_Clasf_Proc_V_New
		WHERE ClasfCd IN (
			'93581'
		)
	)