/*
***********************************************************************
File: nyu_revenue_tracker.sql

Input Parameters:
	None

Tables/Views:
	smsmir.actv

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Get basic information associated with charges for the LICommunity Hospital
    revenue tracker for NYULMC.

Revision History:
Date		Version		Description
----		----		----
2022-03-18	v1			Initial Creation
***********************************************************************
*/

DECLARE @START_DATE DATE;
DECLARE @END_DATE DATE;

SET @START_DATE = '2022-01-01';
SET @END_DATE = '2022-02-01';

SELECT A.pt_id,
	A.unit_seq_no,
	[ip_op_ed_flag] = CASE
		WHEN LEFT(A.pt_id, 5) = '00008'
			THEN 'ED_Patient'
		WHEN LEFT(A.pt_id, 5) = '00001'
			THEN 'Inpatient'
		ELSE 'Outpatient'
		END,
	CAST(A.actv_entry_date AS DATE) AS [posting_date],
	CAST(A.actv_date AS DATE) AS [service_date],
	A.actv_cd,
	B.actv_name,
	B.actv_group,
	SUM(A.actv_tot_qty) AS [actv_tot_qty],
	SUM(A.chg_tot_amt) AS [chg_tot_amt]
FROM smsmir.actv AS A
LEFT OUTER JOIN smsdss.actv_cd_dim_v AS B ON A.actv_cd = B.actv_cd
	AND A.orgz_cd = B.orgz_cd
WHERE CAST(actv_entry_date AS DATE) >= @START_DATE
	AND CAST(actv_entry_date AS DATE) < @END_DATE
GROUP BY A.pt_id,
	A.unit_seq_no,
	CASE
		WHEN LEFT(A.pt_id, 5) = '00008'
			THEN 'ED_Patient'
		WHEN LEFT(A.pt_id, 5) = '00001'
			THEN 'Inpatient'
		ELSE 'Outpatient'
		END,
	CAST(A.actv_entry_date AS DATE),
	CAST(A.actv_date AS DATE),
	A.actv_cd,
	B.actv_name,
	B.actv_group;

