/*
***********************************************************************
File: myhealth_lab_use.sql

Input Parameters:
	DECLARE @START_DATE DATE
    DECLARE @END_DATE   DATE

Tables/Views:
	SMSDSS.BMH_PLM_PTACCT_V
	SMSMIR.ACTV

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	MyHealth downstream revenue report

Revision History:
Date		Version		Description
----		----		----
2019-10-23	v1			Initial Creation
***********************************************************************
*/

DECLARE @START_DATE DATE;
DECLARE @END_DATE DATE;

SET @START_DATE = '2019-09-01';
SET @END_DATE = '2019-10-01';

SELECT A.hosp_svc
, A.Med_Rec_No
, A.PtNo_Num
, A.Pt_Name
, CAST(A.Adm_Date AS DATE) AS [Svc_Date]

FROM SMSDSS.BMH_PLM_PtAcct_V AS A

WHERE A.hosp_svc IN (
	'BFM','MBV','MHO','MNV','MOA','MSR'
)
AND A.Adm_Date >= @START_DATE
AND A.Adm_Date < @END_DATE
AND A.tot_chg_amt > 0
AND LEFT(A.PTNO_NUM, 1) != '2'
AND LEFT(A.PTNO_NUM, 4) != '1999'
AND A.Pt_No NOT IN (
	SELECT DISTINCT XXX.PT_ID
	FROM SMSMIR.actv AS XXX
	WHERE LEFT(XXX.ACTV_CD, 3) != '004'
)
AND A.Pt_No IN (
	SELECT DISTINCT XXX.PT_ID
	FROM SMSMIR.ACTV AS XXX
	WHERE LEFT(XXX.ACTV_CD, 3) = '004'
	GROUP BY XXX.pt_id
	HAVING SUM(actv_tot_qty) > 0
)
ORDER BY A.hosp_svc
, A.Adm_Date