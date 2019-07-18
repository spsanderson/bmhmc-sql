/*
*****************************************************************************  
File: E_Plan_Non-Allowanced_APCPmt_NotNull_w_writedown_code.sql      

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
	AND PYRPLAN.PYR_CD IN (
		'E01', 'E08', 'E10', 'E12', 'E13', 'E14', 'E18', 'E19', 'E26', 'E27', 'E28', 'E39', --100% OF APC
		'E09', --103.5% OF APC
		'E29', --125% OF APC
		'E47' --102% OF APC
		)
	AND VST.tot_bal_amt > 0
	AND PYRPLAN.tot_amt_due > 0
	-- Exclude all accounts that have 09701590 pay code
	AND PYRPLAN.pt_id NOT IN (
		SELECT DISTINCT (pt_id)
		FROM smsmir.pay
		WHERE pay_cd IN ('09701590', '09735036')
		)
	AND SUBSTRING(PYRPLAN.PT_ID, 5, 1) != '1'
	AND PYRPLAN.last_bl_dtime IS NOT NULL
GO

;

SELECT A.pt_id,
	A.pyr_cd,
	a.ins_bal_amt,
	a.apc_est_net_pay_amt,
	CASE 
		WHEN A.pyr_cd IN ('E09')
			THEN A.INS_BAL_AMT - (1.035 * A.APC_Est_Net_Pay_Amt)
		WHEN A.pyr_cd IN ('E29')
			THEN a.ins_bal_amt - (1.25 * A.APC_Est_Net_Pay_Amt)
		WHEN A.PYR_CD IN ('E47')
			THEN A.INS_BAL_AMT - (1.02 * A.APC_Est_Net_Pay_Amt)
		ELSE (a.INS_BAL_AMT - A.APC_Est_Net_Pay_Amt)
		END AS [Write_Down_Amt],
	[write_down_code] = '09701590'
INTO #TEMPB
FROM #TEMPA AS A
WHERE A.APC_Est_Net_Pay_Amt IS NOT NULL
	AND A.APC_EST_NET_PAY_AMT > 0
GO

;

SELECT *
FROM #TEMPB
WHERE [Write_Down_Amt] >= 0;

DROP TABLE #TEMPA

DROP TABLE #TEMPB
GO

;
