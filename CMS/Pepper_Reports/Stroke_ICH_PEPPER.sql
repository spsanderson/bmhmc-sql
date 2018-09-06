USE [SMSPHDSSS0X0]
GO

/*
*****************************************************************************  
File: Stroke_ICH_PEPPER.sql      

Input  Parameters:
	None

Tables/Views:   
	None
  
Creates Tables/Views:
	smsdss.c_Stroke_ICH_PEPPER_v

Functions:
	None

Author: Steve P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose:
	This query will get the underlying data for Stroke ICH discharges 
	as defined by the ST PEPPER report.

Definitions:
N*: count of discharges for DRGs 
	061 (ischemic stroke, precerebral occlusion or transient ischemia with thrombolytic agent with MCC)
	062 (ischemic stroke, precerebral occlusion or transient ischemia  with thrombolytic agent with CC)
	063 (ischemic stroke, precerebral occlusion or transient ischemia with thrombolytic agent without CC/MCC)
	064 (intracranial hemorrhage or cerebral infarction with MCC)
	065 (intracranial hemorrhage or cerebral infarction with CC or tPA in 24 hours)
	066 (intracranial hemorrhage or cerebral infarction without CC/MCC)

D*: count of discharges for DRGs 
	061 (ischemic stroke, precerebral occlusion or transient ischemia with thrombolytic agent with MCC)
	062 (ischemic stroke, precerebral occlusion or transient ischemia  with thrombolytic agent with CC)
	063 (ischemic stroke, precerebral occlusion or transient ischemia with thrombolytic agent without CC/MCC)
	064 (intracranial hemorrhage or cerebral infarction with MCC)
	065 (intracranial hemorrhage or cerebral infarction with CC or tPA in 24 hours)
	066 (intracranial hemorrhage or cerebral infarction without CC/MCC)
	067 (nonspecific CVA and precerebral occlusion without infarct with MCC)
	068 (nonspecific CVA and precerebral occlusion without infarct without MCC)
	069 (transient ischemia without thrombolytic)
	      
Revision History: 
Date		Version		Description
----		----		----
2018-08-31	v1			Initial Creation
-------------------------------------------------------------------------------- 
*/

DECLARE @TODAY DATE;
DECLARE @START DATE;
DECLARE @END   DATE;

SET @TODAY = CAST(GETDATE() AS date);
SET @START = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, @TODAY) - 12, 0);
SET @END   = DATEADD(QUARTER, DATEDIFF(QUARTER, 0, @TODAY) - 1, 0);


SELECT A.Med_Rec_No
, A.PtNo_Num
, A.Pt_No
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
		'061','062','063','064','065',
		'066','067','068','069'
	) 
		THEN 1
  END AS [Denominator]
, CASE 
	WHEN A.DRG_NO IN (
		'061','062','063','064','065','066'
	) 
	THEN 1 
	ELSE 0
  END [Numerator]

FROM smsdss.BMH_PLM_PtAcct_V AS A
LEFT OUTER JOIN smsdss.c_tot_pymts_w_pip_v AS B
ON A.Pt_No = B.pt_id
	AND A.unit_seq_no = B.unit_seq_no

WHERE A.drg_no IN (
	'061','062','063','064','065','066','067','068','069'
)
AND A.User_Pyr1_Cat IN (
	'AAA', 'ZZZ'
)
AND A.Dsch_Date >= @START
AND A.Dsch_Date < @END

ORDER BY A.Dsch_Date