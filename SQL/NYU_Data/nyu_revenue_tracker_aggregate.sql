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

    DO NOT RUN FOR MORE THAN 7 CONSECUTIVE DAYS, THERE IS NO DATE COLUMN
    SO TUESDAY COULD BE A TUESDAY OF MULTIPLE WEEKS IF YOUR NOT CAREFUL.

Revision History:
Date		Version		Description
----		----		----
2022-09-07	v1			Initial Creation
2022-09-14	v2			Add hospital service name to results
***********************************************************************
*/

DECLARE @START_DATE DATE;
DECLARE @END_DATE DATE;

SET @START_DATE = '2022-01-01';
SET @END_DATE = '2022-02-01';

PRINT 'DO NOT RUN THIS FOR MORE THAN 7 CONSECUTIVE DAYS YOU WILL GET ERRONEOUS RESULTS'

SELECT DATENAME(WEEKDAY, A.ACTV_DATE) AS [weekday],
	A.actv_cd,
	B.actv_name,
	B.actv_group,
	A.hosp_svc,
	C.hosp_svc_name,
	SUM(A.actv_tot_qty) AS [actv_tot_qty],
	SUM(A.chg_tot_amt) AS [chg_tot_amt]
FROM smsmir.actv AS A
LEFT OUTER JOIN smsdss.actv_cd_dim_v AS B ON A.actv_cd = B.actv_cd
	AND A.orgz_cd = B.orgz_cd
LEFT OUTER JOIN smsdss.hosp_svc_dim_v AS C ON A.hosp_svc = C.src_hosp_svc
	AND A.orgz_cd = C.orgz_cd
WHERE CAST(actv_entry_date AS DATE) >= @START_DATE
	AND CAST(actv_entry_date AS DATE) < @END_DATE
GROUP BY DATENAME(WEEKDAY, A.ACTV_DATE),
	A.actv_cd,
	B.actv_name,
	B.actv_group,
	A.hosp_svc,
	C.hosp_svc_name