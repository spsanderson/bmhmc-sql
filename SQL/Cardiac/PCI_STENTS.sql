/*
***********************************************************************
File: PCI_STENTS.sql

Input Parameters:
	NONE

Tables/Views:
	smsmir.actv
    smsdss.actv_cd_dim_v

Creates Table:
	none

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Obtain data on patients that had PCI/Stent yesterday based upon
    activity date

Revision History:
Date		Version		Description
----		----		----
2019-12-03	v1			Initial Creation
2019-12-05	v2			Add column [Thirty_Five_Days_Out]
						SELECT DISTINCT patients and 35 day out date
2019-12-27	v3			Drop 35 days out column
						Change svc_date to MMDDYYYY
***********************************************************************
*/

DECLARE @TODAY AS DATE;
DECLARE @YESTERDAY AS DATE;

SET @TODAY = CAST(GETDATE() AS DATE);
SET @YESTERDAY = DATEADD(DAY, - 1, @TODAY);

SELECT ACTV.pt_id,
	ACTV.unit_seq_no,
	ACTV.from_file_ind,
	ACTV.actv_cd,
	ACTV_DIM.actv_name,
	ACTV.actv_tot_qty,
	ACTV.chg_tot_amt,
	CAST(ACTV.actv_date AS DATE) AS [Actv_Date]
	--CAST(DATEADD(DAY, 35, ACTV.ACTV_DATE) AS DATE) AS [Thirty_Five_Days_Out]
INTO #TEMPA
FROM smsmir.actv AS ACTV
INNER JOIN SMSDSS.actv_cd_dim_v AS ACTV_DIM ON ACTV.actv_cd = ACTV_DIM.actv_cd
	AND ACTV.orgz_cd = ACTV_DIM.orgz_cd
WHERE ACTV.actv_entry_date = @YESTERDAY
	AND ACTV.ACTV_CD IN ('07090061', '07090079', '07090004');

SELECT DISTINCT A.[PT_ID]
, CONVERT(VARCHAR, a.Actv_Date, 101) AS [Actv_Date]
FROM #TEMPA AS A;

DROP TABLE #TEMPA;