/*
*****************************************************************************  
File: I_Plan_Non-Allowanced_APCPmt_NotNull_w_writedown_code.sql      

Input  Parameters:
	None

Tables:   
	smsmir.pyr_plan
	smsmir.vst_rpt
	smsmir.mir_vst_apc
  
Functions:   
	None

Author: Steve P Sanderson II, MPH

Department: Finance, Revenue Cycle
      
Revision History: 
Date		Version		Description
----		----		----
2018-09-24	v1			Initial Creation
2019-06-21	v2			Minimize code
2022-06-03	v3			Add K80
-------------------------------------------------------------------------------- 
*/

SELECT PYRPLAN.pt_id,
	VST.vst_start_date AS [Admit_Date],
	VST.vst_end_date AS [Discharge_Date],
	VST.fc,
	VST.hosp_svc,
	DATEDIFF(DD, VST.VST_END_DATE, GETDATE()) AS 'AGE IN DAYS',
	PYRPLAN.pyr_cd,
	VST.tot_chg_amt,
	VST.tot_bal_amt,
	VST.ins_pay_amt,
	VST.pt_bal_amt,
	PYRPLAN.tot_amt_due AS INS_BAL_AMT,
	VST.tot_pay_amt,
	(VST.tot_pay_amt - VST.ins_pay_amt) AS PT_PAY_AMT,
	guar.GuarantorDOB,
	guar.GuarantorFirst,
	guar.GuarantorLast,
	vst.pt_first_name,
	VST.pt_last_name,
	COALESCE(vst.ins1_pol_no, INS1.user_text, VST.subscr_ins1_grp_id) AS [Ins1],
	INS_NAME.user_text AS [Ins1_Name],
	COALESCE(vst.ins2_pol_no, INS2.USER_TEXT, VST.SUBSCR_INS2_GRP_ID) AS [Ins2],
	COALESCE(vst.ins3_pol_no, INS3.USER_TEXT, VST.SUBSCR_INS3_GRP_ID) AS [Ins3],
	COALESCE(vst.ins4_pol_no, INS4.USER_TEXT, VST.SUBSCR_INS4_GRP_ID) AS [Ins4],
	vst.drg_no,
	PYR_USER.user_text AS [Auth],
	(
		SELECT SUM(net_pay_amt)
		FROM smsmir.mir_vst_apc AS apc
		WHERE PYRPLAN.pt_id = apc.pt_id
			AND PYRPLAN.unit_seq_no = apc.unit_seq_no
		) AS [APC_Est_Net_Pay_Amt]
INTO #TEMPA
FROM SMSMIR.PYR_PLAN AS PYRPLAN
LEFT JOIN smsmir.vst_rpt VST ON PYRPLAN.pt_id = VST.pt_id
--AND PYRPLAN.unit_seq_no = VST.unit_seq_no
LEFT JOIN smsdss.c_guarantor_demos_v AS GUAR ON VST.pt_id = GUAR.pt_id
-- ADD AUTHORIZATION NUMBER '5C49AUTH'
LEFT JOIN SMSMIR.MIR_PYR_PLAN_USER AS PYR_USER ON PYRPLAN.PT_ID = PYR_USER.PT_ID
	AND PYRPLAN.pyr_cd = PYR_USER.pyr_cd
	AND PYRPLAN.from_file_ind = PYR_USER.from_file_ind
	AND PYR_USER.user_comp_id = '5C49AUTH'
-- ADD INS1 FROM MIR_PYR_PLAN_USER '5C49IDNO'
LEFT JOIN smsmir.mir_pyr_plan_user AS INS1 ON PYRPLAN.pt_id = INS1.pt_id
	AND PYRPLAN.pyr_cd = INS1.pyr_cd
	AND PYRPLAN.from_file_ind = INS1.from_file_ind
	AND INS1.user_comp_id = '5C49IDNO'
	AND PYRPLAN.pyr_seq_no = '1'
-- ADD INS2 FROM MIR_PYR_PLAN_USER '5C49IDNO'
LEFT JOIN smsmir.mir_pyr_plan_user AS INS2 ON PYRPLAN.pt_id = INS2.pt_id
	AND PYRPLAN.pyr_cd = INS2.pyr_cd
	AND PYRPLAN.from_file_ind = INS2.from_file_ind
	AND INS2.user_comp_id = '5C49IDNO'
	AND PYRPLAN.pyr_seq_no = '2'
-- ADD INS3 FROM MIR_PYR_PLAN_USER '5C49IDNO'
LEFT JOIN smsmir.mir_pyr_plan_user AS INS3 ON PYRPLAN.pt_id = INS3.pt_id
	AND PYRPLAN.pyr_cd = INS3.pyr_cd
	AND PYRPLAN.from_file_ind = INS3.from_file_ind
	AND INS3.user_comp_id = '5C49IDNO'
	AND PYRPLAN.pyr_seq_no = '3'
-- ADD INS4 FROM MIR_PYR_PLAN_USER '5C49IDNO'
LEFT JOIN smsmir.mir_pyr_plan_user AS INS4 ON PYRPLAN.pt_id = INS4.pt_id
	AND PYRPLAN.pyr_cd = INS4.pyr_cd
	AND PYRPLAN.from_file_ind = INS4.from_file_ind
	AND INS4.user_comp_id = '5C49IDNO'
	AND PYRPLAN.pyr_seq_no = '4'
-- Add INS1 Name
LEFT JOIN SMSMIR.mir_pyr_plan_user AS INS_NAME ON PYRPLAN.PT_ID = INS_NAME.PT_ID
	AND PYRPLAN.pyr_cd = INS_NAME.pyr_cd
	AND PYRPLAN.from_file_ind = INS_NAME.from_file_ind
	AND INS_NAME.user_comp_id = '5C49NAME'
	AND PYRPLAN.pyr_seq_no = '1'
	AND INS_NAME.pyr_seq_no = '1'
WHERE VST.vst_end_date IS NOT NULL
	AND PYRPLAN.PYR_CD IN ('I01', 'I04', 'I06', 'I07', 'I10',
		'K80'
	)
	AND VST.tot_bal_amt > 0
	AND PYRPLAN.tot_amt_due > 0
	-- Exclude all accounts that have 09701590 pay code
	AND PYRPLAN.pt_id NOT IN (
		SELECT DISTINCT (pt_id)
		FROM smsmir.pay
		WHERE pay_cd IN ('09701509', '09701558', '09701608', '09730078', '09735077', '09731084')
		)
	AND SUBSTRING(PYRPLAN.PT_ID, 5, 1) != '1'
	AND PYRPLAN.last_bl_dtime IS NOT NULL
GO

;

SELECT A.*
INTO #TEMPB
FROM #TEMPA AS A
WHERE A.APC_Est_Net_Pay_Amt IS NOT NULL
GO

;

SELECT A.*
INTO #TEMPC
FROM #TEMPB AS A
WHERE A.APC_Est_Net_Pay_Amt > 0;

SELECT A.pt_id,
	A.pyr_cd,
	A.INS_BAL_AMT,
	A.APC_Est_Net_Pay_Amt,
	CASE 
		WHEN A.pyr_cd = 'I01'
			THEN A.INS_BAL_AMT - A.APC_Est_Net_Pay_Amt
		WHEN A.pyr_cd = 'I04'
			THEN A.INS_BAL_AMT - A.APC_Est_Net_Pay_Amt
		WHEN A.pyr_cd = 'I06'
			AND LEFT(A.hosp_svc, 1) = 'E'
			THEN A.INS_BAL_AMT - (0.92 * A.APC_Est_Net_Pay_Amt)
		WHEN A.pyr_cd = 'I06'
			AND LEFT(A.hosp_svc, 1) != 'E'
			THEN A.INS_BAL_AMT - A.APC_Est_Net_Pay_Amt
		WHEN A.pyr_cd = 'I07'
			THEN A.INS_BAL_AMT - A.APC_Est_Net_Pay_Amt
		WHEN A.pyr_cd = 'I10'
			THEN A.INS_BAL_AMT - A.APC_Est_Net_Pay_Amt
		WHEN A.pyr_cd = 'K80'
			THEN A.INS_BAL_AMT - (2.25 * A.APC_Est_Net_Pay_Amt)
		END AS [Write_Down_Amt],
	[Write_Down_Code] = CASE
		WHEN A.pyr_cd = 'K80'
			THEN '09735135'
		ELSE '09735077'
		END
FROM #TEMPC AS A;

DROP TABLE #TEMPA

DROP TABLE #TEMPB

DROP TABLE #TEMPC
GO

;
