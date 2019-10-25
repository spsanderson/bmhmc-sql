SELECT A.PtNo_Num AS [ID_Code],
	A.Plm_Pt_Acct_Type AS [IP/OP_Indicator],
	A.Pyr1_Co_Plan_Cd AS [Primary_Payer_Code],
	B.pyr_name AS [Payer_Description],
	PT_STS.PT_STS AS [Patient_Status],
	'BMHMC' AS [Campus_Code],
	CAST(A.ADM_DATE AS DATE) AS [Adm_Date],
	CAST(A.DSCH_DATE AS DATE) AS [Dsch_Date],
	CAST(A.DAYS_STAY AS INT) AS [LOS],
	A.drg_no AS [DRG #],
	A.tot_chg_amt AS [Charges],
	A.reimb_amt AS [Total_Calculated_Reimbursement],
	ISNULL(PT_Resp.Total_Patient_Responsibility, 0) AS [Total_Patient_Responsibility],
	VST_RPT.ins_pay_amt AS [Payer_Total_Payment],
	A.tot_pay_amt AS [Total_Paid],
	A.tot_adj_amt AS [Total_Adj],
	A.Pt_Name,
	COALESCE(VST_RPT.ins1_pol_no, VST_RPT.subscr_ins1_grp_id) AS [Ins1],
	CLAIM.pay_desc AS [Claim_ID]
FROM smsdss.BMH_PLM_PtAcct_V AS A
LEFT OUTER JOIN smsdss.pyr_dim_v AS B ON A.Pyr1_Co_Plan_Cd = B.pyr_cd
	AND A.Regn_Hosp = B.orgz_cd
LEFT OUTER JOIN (
	SELECT pt_id,
		from_file_ind,
		sum(tot_pay_adj_amt) AS [Total_Patient_Responsibility]
	FROM smsmir.pay
	WHERE pay_cd IN ('0030506', '00330704', '03300605')
	GROUP BY pt_id,
		from_file_ind
	) AS PT_Resp ON A.Pt_No = PT_Resp.pt_id
	AND A.from_file_ind = PT_Resp.from_file_ind
LEFT OUTER JOIN smsmir.vst_rpt AS VST_RPT ON A.Pt_No = VST_RPT.pt_id
	AND A.unit_seq_no = VST_RPT.unit_seq_no
	AND A.from_file_ind = VST_RPT.from_file_ind
	AND A.Pyr1_Co_Plan_Cd = VST_RPT.prim_pyr_cd
-- GET LAST CLAIM NUMBER
LEFT OUTER JOIN (
	SELECT PT_ID,
		unit_seq_no,
		from_file_ind,
		PAY_DESC,
		pay_entry_date,
		[RN] = ROW_NUMBER() OVER (
			PARTITION BY PT_ID ORDER BY PAY_ENTRY_DATE DESC
			)
	FROM SMSMIR.PAY
	WHERE pay_cd = '10501435'
	) AS CLAIM ON A.PT_NO = CLAIM.pt_id
	AND A.unit_seq_no = CLAIM.unit_seq_no
	AND A.from_file_ind = CLAIM.from_file_ind
	AND CLAIM.RN = 1
-- GET INS_ID
CROSS APPLY (
	SELECT CASE 
			WHEN LTRIM(RTRIM(A.DSCH_DISP)) = 'ATW'
				THEN '06'
			WHEN LTRIM(RTRIM(A.DSCH_DISP)) = 'AHI'
				THEN '51'
			WHEN LTRIM(RTRIM(A.DSCH_DISP)) = 'AHR'
				THEN '01'
			WHEN LTRIM(RTRIM(A.DSCH_DISP)) = 'ATE'
				THEN '03'
			WHEN LTRIM(RTRIM(A.DSCH_DISP)) = 'ATL'
				THEN '03'
			WHEN LTRIM(RTRIM(A.DSCH_DISP)) = 'ATH'
				THEN '02'
			WHEN LTRIM(RTRIM(A.DSCH_DISP)) = 'ATP'
				THEN '65'
			WHEN LTRIM(RTRIM(A.DSCH_DISP)) = 'AMA'
				THEN '07'
			WHEN LTRIM(RTRIM(A.DSCH_DISP)) = 'ATF'
				THEN '43'
			WHEN LTRIM(RTRIM(A.DSCH_DISP)) = 'ATN'
				THEN '43'
			WHEN LTRIM(RTRIM(A.DSCH_DISP)) = 'ATB'
				THEN '21'
			WHEN LEFT(A.DSCH_DISP, 1) IN ('C', 'D')
				THEN '20'
			WHEN LTRIM(RTRIM(A.DSCH_DISP)) = 'ATT'
				THEN '50'
			WHEN LTRIM(RTRIM(A.dsch_disp)) = 'ATX'
				THEN '62'
			WHEN LTRIM(RTRIM(A.DSCH_DISP)) = 'AHB'
				THEN '70'
			ELSE A.DSCH_DISP
			END AS PT_STS
	) PT_STS
WHERE A.tot_chg_amt >= 0
	AND A.Dsch_Date >= '2014-01-01'
	AND A.Dsch_Date < '2018-01-01'
	AND A.Plm_Pt_Acct_Type = 'I'
	AND LEFT(A.PTNO_NUM, 1) != '2'
	AND LEFT(A.PTNO_NUM, 4) != '1999'
	AND A.Pyr1_Co_Plan_Cd IN ('E18', 'E28', 'E08', 'E12', 'E27', 'E19', 'E13', 'E29')
GO

;
