/*
***********************************************************************
File: hbcs_par_records.sql

Input Parameters:
	None

Tables/Views:
	smsdss.bmh_plm_ptacct_v
	smsmir.pay
	smsdss.pay_cd_dim_v

Creates Table:
	None

Functions:
	None

Author: Steven P Sanderson II, MPH

Department: Finance, Revenue Cycle

Purpose/Description
	Gather the PAR records for HBCS on the self pay accounts

Revision History:
Date		Version		Description
----		----		----
2022-06-14	v1			Initial Creation
2022-06-29	v2			Add payment_code_type and drop $0.00 transactions
***********************************************************************
*/

DROP TABLE IF EXISTS #visits_tbl
CREATE TABLE #visits_tbl (
	med_rec_no VARCHAR(12),
	pt_id VARCHAR(12),
	unit_seq_no VARCHAR(12),
	pt_id_start_dtime DATE
)

INSERT INTO #visits_tbl
SELECT DISTINCT PAV.Med_Rec_No,
	PAV.Pt_No,
	PAV.unit_seq_no,
	PAV.pt_id_start_dtime
FROM SMSDSS.BMH_PLM_PtAcct_V AS PAV
WHERE PAV.Tot_Amt_Due > 0
AND PAV.FC IN ('G','P','R')
AND PAV.tot_chg_amt > 0
AND PAV.Tot_Amt_Due > 0
AND PAV.prin_dx_cd IS NOT NULL
AND PAV.unit_seq_no != '99999999';

SELECT [RECORD_IDENTIFIER] = 'PAR',
	[MEDICAL_RECORD_NUMBER] = UV.med_rec_no,
	[PATIENT_ACCOUNT_NUMBER] = UV.pt_id,
	[PATIENT_ACCOUNT_UNIT_NO] = UV.unit_seq_no,
	[PATIENT_ID_START_DTIME] = UV.pt_id_start_dtime,
	[TRANSACTION_CATEGORY] = PAYDIM.pay_cd_name,
	[TRANSACTION_CODE] = PAY.pay_cd,
	[TRANSACTION_CODE_TYPE] = CASE
		WHEN PAY.pay_cd IN ('09760109','09760117','09760125')
			THEN '9'
		WHEN LEFT(PAY.PAY_CD, 3) = '097'
			THEN '3'
		WHEN LEFT(PAY.PAY_CD, 4) = '0097'
			THEN '3'
		WHEN LEFT(PAY.PAY_CD, 3) = '099'
			THEN '6'
		ELSE '999'
		END,
	[TRANSACTION_RECEIVED_DATE] = CAST(PAY.pay_dtime AS DATE),
	[TRANSACTION_POSTING_DATE] = CAST(PAY.pay_entry_date AS DATE),
	[TRANSACTION_AMOUNT] = PAY.tot_pay_adj_amt
FROM #visits_tbl AS UV
INNER JOIN smsdss.BMH_PLM_PTACCT_V AS PAV ON UV.med_rec_no = PAV.Med_Rec_No
	AND UV.pt_id = PAV.Pt_No
	AND UV.unit_seq_no = PAV.unit_seq_no
INNER JOIN smsmir.pay AS PAY ON UV.pt_id = PAY.pt_id
	AND UV.unit_seq_no = PAY.unit_seq_no
INNER JOIN smsdss.pay_cd_dim_v AS PAYDIM ON PAY.pay_cd = PAYDIM.pay_cd
	AND PAY.orgz_cd = PAYDIM.orgz_cd
WHERE PAY.tot_pay_adj_amt != 0