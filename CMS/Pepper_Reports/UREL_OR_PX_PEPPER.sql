USE [SMSPHDSSS0X0]
GO

/*
*****************************************************************************  
File: UNREL_OR_PX_PEPPER.sql      

Input  Parameters:
	None

Tables/Views:   
	None
  
Creates Tables/Views:

Functions:
	None

Author: Steve P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose:
	This query will get the underlying data for Stroke ICH discharges 
	as defined by the ST PEPPER report.

Definitions:
N* count of discharges for DRGs 
	981 (extensive OR procedure unrelated to principal diagnosis with MCC)
	982 (extensive OR procedure unrelated to principal diagnosis with CC)
	983 (extensive OR procedure unrelated to principal diagnosis without CC/MCC)
	987 (non-extensive OR procedure unrelated to principal diagnosis with MCC)
	988 (non-extensive OR procedure unrelated to principal diagnosis with CC)
	989 (non-extensive OR procedure unrelated to principal diagnosis without CC/MCC)

D: count of all discharges for surgical DRGs
	SELECT drg_no
	FROM smsdss.drg_dim_v
	WHERE drg_vers = 'MS-V25'
	AND drg_med_surg_group = 'Surgical'
	      
Revision History: 
Date		Version		Description
----		----		----
2018-09-12	v1			Initial Creation
-------------------------------------------------------------------------------- 
*/

DECLARE @TODAY  DATE;
DECLARE @START  DATE;
DECLARE @END    DATE;
DECLARE @START2 DATE;
DECLARE @END2   DATE;

SET @TODAY  = CAST(GETDATE() AS date);
SET @START  = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, @TODAY) - 12, 0);
SET @END    = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, @TODAY), 0);
SET @START2 = DATEADD(MONTH, DATEDIFF(MONTH, 0, @TODAY) - 1, 0);
SET @END2   = DATEADD(MONTH, DATEDIFF(MONTH, 0, @TODAY), 0);

SELECT A.Med_Rec_No
, A.PtNo_Num
, RTRIM(LTRIM(A.Pt_No)) AS [Pt_No]
, A.drg_no
, A.drg_cost_weight
, A.Adm_Date
, A.Dsch_Date
, CAST(A.Days_Stay AS int) AS [LOS]
, CAST(A.tot_chg_amt AS money) AS [Tot_Chgs]
, CAST(B.tot_pymts_w_pip AS money) AS [Tot_PIP]
, DATEPART(YEAR, A.DSCH_DATE) AS [DSCH_YR]
, DATEPART(QUARTER, A.DSCH_DATE) AS [DSCH_QTR]
, (
	CAST(DATEPART(YEAR, A.DSCH_date) AS varchar) 
	+ '-' 
	+ CAST(DATEPART(QUARTER, A.DSCH_DATE) AS varchar)
  ) AS [Time_Period]
, CASE 
	WHEN A.DRG_NO IN(
		SELECT drg_no
		FROM smsdss.drg_dim_v
		WHERE drg_vers = 'MS-V25'
		AND drg_med_surg_group = 'Surgical'
	) 
		THEN 1
  END AS [Denominator]
, CASE 
	WHEN A.DRG_NO IN (
		'981','982','983','987','988','989'
	) 
	THEN 1 
	ELSE 0
  END [Numerator]
, 'UREL_OR_PX' AS [PEPPER_ITEM]

FROM smsdss.BMH_PLM_PtAcct_V AS A
LEFT OUTER JOIN smsdss.c_tot_pymts_w_pip_v AS B
ON A.Pt_No = B.pt_id
	AND A.unit_seq_no = B.unit_seq_no

WHERE A.drg_no IN (
	SELECT drg_no
	FROM smsdss.drg_dim_v
	WHERE drg_vers = 'MS-V25'
	AND drg_med_surg_group = 'Surgical'
)
AND A.User_Pyr1_Cat IN (
	'AAA', 'ZZZ'
)
AND A.Dsch_Date >= @START
AND A.Dsch_Date < @END
AND B.tot_pymts_w_pip < 0

ORDER BY A.Dsch_Date