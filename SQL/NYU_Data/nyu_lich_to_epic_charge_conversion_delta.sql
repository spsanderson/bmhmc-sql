--DECLARE @START DATE;
--DECLARE @END DATE;

--SET @START = '2022-01-01';
--SET @END = '2022-02-01';

SELECT [MRN] = pav.Med_Rec_No,
	--[ARRIVAL] = HPV.CreationTime,
	[ID_TYPE] = '',
	[Last_Name] = ISNULL(PTDEMOS.pt_last, ''),
	[First_Name] = ISNULL(PTDEMOS.pt_first, ''),
	[MIDDLE_INITIAL] = ISNULL(PTDEMOS.pt_middle, ''),
	[LEGACY_ACCOUNT_NUMBER] = PAV.PtNo_Num,
	[HL7_SET_ID] = '',
	[UNIQUE_ID] = ROW_NUMBER() OVER (
		ORDER BY (
				SELECT 1
				)
		),
	[TRANSACTION_DATE] = REPLACE(CAST(ACTV.actv_date AS DATE), '-', ''),
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
			AND ACTV_DIM.actv_group IN ('STATS', 'ROOM AND BOARD')
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
--LEFT JOIN smsdss.c_patient_demos_v AS PTDEMOS ON PAV.PT_NO = PTDEMOS.pt_id
--	AND ACTV.pt_id_start_dtime = PTDEMOS.pt_id_start_dtime
LEFT JOIN (
	SELECT [pt_id] = PTDEMOS.PT_ID,
		[pt_id_start_dtime] = PTDEMOS.PT_ID_START_DTIME,
		PTDEMOS.pt_last,
		PTDEMOS.pt_first,
		PTDEMOS.pt_middle,
		[RN] = ROW_NUMBER() OVER (
			PARTITION BY PTDEMOS.PT_ID ORDER BY PTDEMOS.PT_ID
			)
	FROM SMSDSS.c_patient_demos_v AS ptdemos
	) AS PTDEMOS ON PAV.PT_NO = PTDEMOS.pt_id
	AND pav.pt_id_start_dtime = ptdemos.pt_id_start_dtime
	AND PTDEMOS.rn = 1
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
	AND NDC.ActvInd = 'YES'
WHERE PAV.tot_chg_amt > 0
	AND LEFT(PAV.PTNO_NUM, 1) != '2'
	AND LEFT(PAV.PTNO_NUM, 4) != '1999'
	AND PAV.PtNo_Num IN (
		'14999221', '15048804', '15061989', '15062029', '15063571', '15064249', '15064306', '15066772', '15067093', '15068158', '15068695', '15068729', '15068836', '15068851', '15068943', '15069057', '15069263', '15070071', '15070188', '15070337', '15070451', '15070584', '15070618', '15070675', '15070733', '15070741', '15070774', '15070782', '15070816', '15070873', '15071004', '15071038', '15071061', '15071129', '15071145', '15071178', '15071186', '15071202', '15071269', '15071285', '15071293', '15071384', '15071434', '15071459', '15071475', '15071517', '15071525', '15071541', '15071608', '15071616', '15071632', '15071665', '15071681', '15071699', '15071749', '15071756', '15071764', '15071772', '15071798', '15071830', '15071871', '15071889', '15071905', '15071913', '15071921', '15071939', '15071947', '15071954', '15071988', '15071996', '15072028', '15072036', '15072044', '15072051', '15072069', '15072085', '15072093', '15072101', '15072119', '15072127', '15072135', '15072150', '15072168', '15072176', '15072184', '15072192', '15072200', '15072226', '15072234', '15072242', 
		'15072259', '15072275', '15072283', '15072309', '15072317', '15072325', '15072333', '15072341', '15072358', '15072366', '15072374', '15072382', '15072390', '15072408', '90196742', '90197021', '90198052', '90198532', '90198581', '90199100', '90199472', '90200262', '90200338', '90200429', '90200536', '90200684', '90200122', '90200924', '90200940', '90201013', '90201047', '90201088', '90201138', '90201153', '90201179', '90201187', '90201195', '90201211', '90201252', '90201260', '90201278', '90201286', '90201310', '90201336', '90201344', '90201351', '90201369', '90201377', '90201385', '90201393', '90201401'
		)
	AND ACTV.chg_tot_amt != 0
	-- kick out 4+ day charges pre admit
	AND DATEDIFF(DAY, PAV.Adm_Date, ACTV.actv_date) >= - 3
	-- post date is through Monday 11-07-2022
	--AND ACTV.ACTV_DATE <= '2022-11-08'
	AND ACTV.actv_entry_date >= '2022-11-09'
	AND LEFT(ISNULL(NYU_CONVERT.nyu_converted_code, ''), 7) != ''
