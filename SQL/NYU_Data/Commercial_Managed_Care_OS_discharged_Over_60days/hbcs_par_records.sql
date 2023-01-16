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
	Gather the PAR records for HCS on the self pay accounts

Revision History:
Date		Version		Description
----		----		----
2022-10-21	v1			Initial Creation
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
	--AND PAV.FC IN ('G', 'P', 'R')
	AND PAV.tot_chg_amt > 0
	AND PAV.Tot_Amt_Due > 0
	AND PAV.prin_dx_cd IS NOT NULL
	--AND PAV.unit_seq_no != '99999999'
	AND PAV.hosp_svc NOT IN ('DIA', 'DMS')
	AND NOT LEFT(PAV.PT_NAME, 1) BETWEEN 'A' AND 'L'
	AND EXISTS (
		SELECT 1
		FROM smsmir.pyr_plan AS pyr
		WHERE PYR.PT_ID = PAV.PT_NO
			AND PYR.unit_seq_no = PAV.unit_seq_no
			AND PYR.pyr_cd IN (
				'B01', 'B02', 'B03', 'B04', 'B05', 'B06', 'B07', 'B08', 'B09', 'B10', 'B11', 'B15', 'B25', 'B30', 'B31', 'B32', 'B67', 'B70', 'B71', 'B72', 'B73', 'B75', 'B76', 'B78', 'B79', 'B80', 'B87', 'B88', 'B89', 'B91', 'B92', 'B93', 'B94', 'B95', 'B96', 'B97', 'B98', 'B99', 'S20', 'M31', 'M32', 'M33', 'M34', 'M35', 'M36', 'M96', 'M97', 'M98', 'X01', 'X02', 'X03', 'X04', 'X05', 'X06', 'X07', 'X08', 'X09', 'X10', 'X11', 'X12', 'X13', 'X14', 'X15', 'X16', 'X17', 'X18', 'X19', 'X20', 'X21', 'X22', 'X23', 'X24', 'X25', 'X26', 'X27', 'X28', 'X29', 'X30', 'X31', 'X32', 'X33', 'X34', 'X35', 'X36', 'X37', 'X38', 'X39', 'X40', 'X41', 'X42', 'X43', 'X44', 'X45', 'X46', 'X47', 'X48', 'X50', 'X51', 'X52', 'X59', 'X60', 'X61', 'X62', 'X63', 'X64', 'X65', 'X66', 'X67', 'X68', 'X69', 'X70', 'X72', 'X75', 'X80', 'X81', 'X85', 'X86', 'X87', 'X91', 'X92', 'X94', 'X95', 'X96', 'X97', 'X98', 'X99', 'E01', 'E02', 'E03', 'E04', 'E05', 'E06', 'E07', 'E08', 'E09', 'E10', 'E11', 'E12', 'E13', 'E14', 'E16', 'E17', 'E18', 'E19', 'E20', 'E21', 'E22', 'E23', 'E26', 'E27', 'E28', 'E29', 'E36', 'E37', 'E38', 'E39', 'E47', 'E99', 'I01', 'I02', 'I03', 'I04', 'I05', 'I06'
				, 'I07', 'I08', 'I09', 'I10', 'I18', 'I19', 'I93', 'I94', 'I95', 'I96', 'I97', 'I98', 'I99', 'J01', 'J03', 'J04', 'J05', 'J06', 'J07', 'J08', 'J09', 'J10', 'J11', 'J12', 'J13', 'J14', 'J15', 'J16', 'J17', 'J18', 'J20', 'J21', 'J22', 'J24', 'J25', 'J29', 'J30', 'J35', 'J36', 'J44', 'J50', 'J89', 'J90', 'J91', 'J92', 'J96', 'J97', 'J98', 'J99', 'K01', 'K02', 'K03', 'K04', 'K05', 'K06', 'K07', 'K08', 'K09', 'K10', 'K11', 'K12', 'K13', 'K14', 'K15', 'K16', 'K17', 'K18', 'K19', 'K20', 'K21', 'K22', 'K30', 'K31', 'K43', 'K50', 'K51', 'K52', 'K53', 'K54', 'K55', 'K56', 'K57', 'K58', 'K59', 'K60', 'K61', 'K62', 'K64', 'K66', 'K68', 'K69', 'K70', 'K71', 'K72', 'K74', 'K75', 'K76', 'K79', 'K80', 'K81', 'K84', 'K86', 'K88', 'K89', 'K90', 'K91', 'K92', 'K93', 'K94', 'K95', 'K96', 'K98', 'K99'
				)
			AND PYR.tot_amt_due > 0
		);

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
	AND PAY.pay_entry_dtime >= DATEADD(DAY, -1, CAST(GETDATE() AS DATE));