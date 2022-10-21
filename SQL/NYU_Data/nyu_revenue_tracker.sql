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
2022-07-22	v2			Add support for new ED Treat and Relase charges
2022-09-14	v3			Add hospital service at time of record
2022-09-15	v4			Add A.pt_type
2022-09-21	v5			Add LICH and NYU Cost Center Information
2022-09-22	v6			Add Revenue Code
***********************************************************************
*/

DECLARE @START_DATE DATE;
DECLARE @END_DATE DATE;

SET @START_DATE = '2022-01-01';
SET @END_DATE = '2022-02-01';

SELECT A.pt_id,
	A.unit_seq_no,
	[ip_op_ed_flag] = CASE 
		WHEN LEFT(A.pt_id, 5) IN ('00008', '00009')
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
	D.NEW_NYU_COST_CENTER,
	D.NYU_CONVERTED_CODE,
	A.gl_key,
	CC_XREF.actv_cost_ctr,
	CC_XREF.actv_cost_ctr_name,
	A.hosp_svc,
	C.hosp_svc_name,
	A.pt_type,
	CASE		
		WHEN E.rev_cd IS NULL
		AND B.actv_group = 'lab'	
			THEN '300'
		WHEN E.rev_cd IS NULL
		AND B.actv_group = 'pharm'	
			THEN '250'
		WHEN E.rev_cd IS NULL
		AND B.actv_group = 'rad'	
			THEN '320'
		WHEN E.rev_cd IS NULL
		AND B.actv_group in ('stats', 'room and board')	
			THEN '120'
		ELSE E.rev_cd
	END AS [rev_code],
	SUM(A.actv_tot_qty) AS [actv_tot_qty],
	SUM(A.chg_tot_amt) AS [chg_tot_amt]
FROM smsmir.actv AS A
LEFT OUTER JOIN smsdss.actv_cd_dim_v AS B ON A.actv_cd = B.actv_cd
	AND A.orgz_cd = B.orgz_cd
LEFT OUTER JOIN smsdss.hosp_svc_dim_v AS C ON A.hosp_svc = C.src_hosp_svc
	AND A.orgz_cd = C.orgz_cd
-- Cost Center Information
LEFT OUTER JOIN smsdss.c_lich_to_nyu_charge_conversion_tbl AS D ON A.actv_cd = D.FULL_LICH_CODE
LEFT OUTER JOIN smsmir.actv_mstr AS ACTV_MSTR ON A.actv_cd = ACTV_MSTR.actv_cd
LEFT OUTER JOIN smsdss.c_glkey_cstctr_xref AS CC_XREF ON A.gl_key = CC_XREF.gl_key
LEFT OUTER JOIN smsmir.mir_actv_proc_seg_xref AS E ON A.actv_cd = E.actv_cd
	AND E.proc_pyr_ind = 'A'
WHERE CAST(actv_entry_date AS DATE) >= @START_DATE
	AND CAST(actv_entry_date AS DATE) < @END_DATE
GROUP BY A.pt_id,
	A.unit_seq_no,
	CASE 
		WHEN LEFT(A.pt_id, 5) IN ('00008', '00009')
			THEN 'ED_Patient'
		WHEN LEFT(A.pt_id, 5) = '00001'
			THEN 'Inpatient'
		ELSE 'Outpatient'
		END,
	CAST(A.actv_entry_date AS DATE),
	CAST(A.actv_date AS DATE),
	A.actv_cd,
	B.actv_name,
	B.actv_group,
	D.NEW_NYU_COST_CENTER,
	D.NYU_CONVERTED_CODE,
	A.gl_key,
	CC_XREF.actv_cost_ctr,
	CC_XREF.actv_cost_ctr_name,
	A.hosp_svc,
	C.hosp_svc_name,
	A.pt_type,
	E.rev_cd

