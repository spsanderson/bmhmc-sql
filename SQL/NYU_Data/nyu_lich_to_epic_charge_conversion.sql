DECLARE @START DATE;
DECLARE @END DATE;

SET @START = '2022-01-01';
SET @END = '2022-02-01';

SELECT [MRN] = pav.Med_Rec_No,
	--[ARRIVAL] = HPV.CreationTime,
	[ID_TYPE] = '',
	[Last_Name] = ISNULL(PTDEMOS.pt_last, ''),
	[First_Name] = ISNULL(PTDEMOS.pt_first, ''),
	[MIDDLE_INITIAL] = ISNULL(PTDEMOS.pt_middle, ''),
	[LEGACY_ACCOUNT_NUMBER] = PAV.PtNo_Num,
	[HL7_SET_ID] = '',
	[UNIQUE_ID] = ROW_NUMBER() OVER(ORDER BY (SELECT 1)),
	[TRANSACTION_DATE] = REPLACE(CAST(ACTV.actv_date AS DATE),'-',''),
	[TRANSACTION_TYPE] = 'CG',
	[GENERIC_EAP_CODE] = LEFT(ISNULL(NYU_CONVERT.nyu_converted_code, ''), 7),
	[TRNASACTION_DESCRIPTION] = ACTV_DIM.actv_name,
	[TRANSACTION_QUANTITY] = ACTV.actv_tot_qty,
	[TRANSACTION_AMOUNT] = ACTV.chg_tot_amt,
	[CHARGE_DEPARTMENT] = '',
	[HCPCS_CD] = ISNULL(CASE
		WHEN PAV.Plm_Pt_Acct_Type = 'I'
			THEN LEFT(IP_CPT.clasf_cd, 5)
		ELSE LEFT(COALESCE(XREFH.clasf_cd, XREFM.clasf_cd, XREFW.clasf_cd), 5)
		END, ''),
	[CHARGE_MODIFIER] = ISNULL(CASE
		WHEN PAV.Plm_Pt_Acct_Type = 'I'
			THEN SUBSTRING(IP_CPT.CLASF_CD, 6, 10)
		ELSE SUBSTRING(COALESCE(XREFH.clasf_cd, XREFM.clasf_cd, XREFW.clasf_cd), 6, 10)
		END, ''),
	[CUSTOMER_CDM_CODE] = ISNULL(ACTV.actv_cd, ''),
	--[REVENUE_CODE] = ISNULL(IP_CPT.rev_cd, ''),
	[REVENUE_CODE] = CASE
		WHEN IP_CPT.rev_cd IS NULL
			AND ACTV_DIM.actv_group = 'lab'
			THEN '300'
		WHEN IP_CPT.rev_cd IS NULL
			AND ACTV_DIM.actv_group = 'pharm'
			THEN '250'
		WHEN IP_CPT.rev_cd IS NULL
			AND ACTV_DIM.actv_group = 'RAD'
			THEN '320'
		WHEN IP_CPT.rev_cd IS NULL
			AND ACTV_DIM.actv_group IN ('STATS','ROOM AND BOARD')
			THEN '120'
		ELSE ISNULL(IP_CPT.REV_CD, '')
		END,
	[NDC_CODE] = ISNULL(NDC.NDC, ''),
	[NDC_QUANTITY] = ISNULL(NDC.VolQty, ''),
	[NDC_UNIT] = ISNULL(NDC.VolUOMCd, ''),
	--[NDC_MISC] = NDC.StrgText,
	[COST_CENTER] = ISNULL(NYU_CONVERT.NEW_NYU_COST_CENTER, '')
FROM smsdss.BMH_PLM_PtAcct_V AS PAV
INNER JOIN smsmir.actv AS ACTV ON PAV.PT_NO = ACTV.PT_ID
	AND PAV.unit_seq_no = ACTV.unit_seq_no
LEFT JOIN [SC_server].[Soarian_Clin_Prd_1].DBO.HPatientVisit AS HPV ON PAV.PtNo_Num = HPV.PatientAccountID
LEFT JOIN smsdss.c_lich_to_nyu_charge_conversion_tbl AS NYU_CONVERT ON ACTV.actv_cd = NYU_CONVERT.FULL_LICH_CODE
LEFT JOIN smsdss.c_patient_demos_v AS PTDEMOS ON PAV.PT_NO = PTDEMOS.pt_id
	AND ACTV.pt_id_start_dtime = PTDEMOS.pt_id_start_dtime
LEFT JOIN smsdss.actv_cd_dim_v AS ACTV_DIM ON ACTV.actv_cd = ACTV_DIM.actv_cd
-- IP CPT
LEFT JOIN smsmir.mir_actv_proc_seg_xref AS IP_CPT ON ACTV.actv_cd = IP_CPT.actv_cd
	AND IP_CPT.proc_pyr_ind = 'A'
-- OP CPT
LEFT JOIN SMSMIR.mir_actv_proc_seg_xref AS XREFH ON ACTV.actv_cd = XREFH.actv_cd
    	AND XREFH.proc_pyr_ind = 'H'
-- Medicare 
LEFT JOIN SMSMIR.mir_actv_proc_seg_xref AS XREFM ON ACTV.actv_cd = XREFM.actv_cd
    AND XREFM.proc_pyr_ind = 'M'
-- Medicaid 
LEFT JOIN SMSMIR.mir_actv_proc_seg_xref AS XREFW ON ACTV.actv_cd = XREFW.actv_cd
    AND XREFW.proc_pyr_ind = 'W'
-- NDC INFORMATION
LEFT JOIN smsmir.PHM_DrugMstr AS NDC ON ACTV.actv_cd = NDC.DispCDMCd
WHERE PAV.tot_chg_amt > 0
AND LEFT(PAV.PTNO_NUM, 1) != '2'
AND LEFT(PAV.PTNO_NUM, 4) != '1999'
AND PAV.PtNo_Num IN ('15060031','15062458','15062904')
AND ACTV.chg_tot_amt != 0
-- kick out 4+ day charges pre admit
AND DATEDIFF(DAY, PAV.Adm_Date, ACTV.actv_date) >= -3