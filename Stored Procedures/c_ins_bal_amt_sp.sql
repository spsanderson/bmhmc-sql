USE [SMSPHDSSS0X0]
GO
/****** Object:  StoredProcedure [smsdss].[c_ins_bal_amt_sp]    Script Date: 12/7/2017 10:49:02 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [smsdss].[c_ins_bal_amt_sp]
AS

SET NOCOUNT ON;
SET ANSI_WARNINGS OFF;

/*
Check to see if the table even exists. If not create and populate, else insert
new records only if the run date is not already in the table. This excludes accounts
in a numeric financial class

Author: Steven P Sanderson II, MPH
Department: Finance, Revenue Cycle

v2		- 2017-12-07		- comment out unit_seq_no in pyrplan and vstrpt join
*/
IF NOT EXISTS (
	SELECT TOP 1 * FROM sysobjects WHERE name='c_ins_bal_amt' AND xtype='U'
)
	
BEGIN
	CREATE TABLE smsdss.c_ins_bal_amt (
		PK INT IDENTITY(1, 1) PRIMARY KEY NOT NULL
		, pt_id char(13) NOT NULL
		, unit_seq_no int NULL
		, cr_rating VARchar(2) NULL
		, vst_end_date date NULL
		, fc VARchar(4) NULL
		, hosp_svc char(4) NULL
		, Age_In_Days Int NULL
		, pyr_cd varchar(6) NOT NULL
		, pyr_seq_no int NOT NULL
		, tot_chg_amt money NULL
		, tot_enc_bal_amt money NULL
		, ins_pay_amt money NULL
		, pt_bal_amt money NULL
		, Ins_Bal_Amt money NULL
		, tot_pay_amt money NULL
		, pt_pay_amt money NULL
		, GuarantorDOB date NULL
		, GuarantorFirst varchar(30) NULL
		, GuarantorLast varchar(60) NULL
		, ins1_pol_no varchar(20) NULL
		, ins2_pol_no varchar(20) NULL
		, ins3_pol_no varchar(20) NULL
		, ins4_pol_no varchar(20) NULL
		, RunDate date NOT NULL
		, RunDateTime datetime NOT NULL
		, RN INT
	)

	INSERT INTO smsdss.c_ins_bal_amt

	SELECT PYRPLAN.pt_id
	, VST.unit_seq_no
	, VST.cr_rating
	, CAST(VST.vst_end_date AS date)                     AS [vst_end_date]
	, VST.fc
	, VST.hosp_svc
	, CAST(DATEDIFF(DD, VST.VST_END_DATE, GETDATE()) AS int) AS [Age_In_Days]
	, PYRPLAN.pyr_cd
	, PYRPLAN.pyr_seq_no
	, CAST(VST.tot_chg_amt AS money)                     AS [tot_chg_amt]
	, CAST(VST.tot_bal_amt AS money)                     AS [tot_enc_bal_amt]
	, CAST(VST.ins_pay_amt AS money)                     AS [ins_pay_amt]
	, CAST(VST.pt_bal_amt AS money)                      AS [pt_bal_amt]
	, CASE
		WHEN PYRPLAN.PYR_CD = '*' THEN 0
		ELSE CAST(PYRPLAN.tot_amt_due AS money)
		END                                              AS [Ins_Bal_Amt]
	, CAST(VST.tot_pay_amt AS money)                     AS [tot_pay_amt]
	, CAST((VST.tot_pay_amt - VST.ins_pay_amt) AS money) AS [pt_pay_amt]
	, CAST(guar.GuarantorDOB as date)                    AS [GuarantorDOB]
	, guar.GuarantorFirst
	, guar.GuarantorLast
	, vst.ins1_pol_no
	, vst.ins2_pol_no
	, vst.ins3_pol_no
	, vst.ins4_pol_no
	, [RunDate] = CAST(GETDATE() AS date)
	, [RunDateTime] = GETDATE()
	, [RN] = ROW_NUMBER() OVER(
		PARTITION BY PYRPLAN.PT_ID
		ORDER BY PYRPLAN.PYR_SEQ_NO
	)

	FROM SMSMIR.PYR_PLAN AS PYRPLAN
	LEFT JOIN smsmir.vst_rpt VST
	ON PYRPLAN.pt_id = VST.pt_id
			--AND PYRPLAN.unit_seq_no = VST.unit_seq_no
	LEFT JOIN smsdss.c_guarantor_demos_v AS GUAR
	ON VST.pt_id = GUAR.pt_id
		AND VST.from_file_ind = GUAR.from_file_ind

	WHERE VST.tot_bal_amt > 0
	AND PYRPLAN.tot_amt_due > 0
	AND VST.vst_end_date IS NOT NULL
	AND VST.fc not in (
		'1','2','3','4','5','6','7','8','9'
	)

	ORDER BY PYRPLAN.pt_id
	, PYRPLAN.pyr_cd
END

ELSE BEGIN
	INSERT INTO smsdss.c_ins_bal_amt
	SELECT PYRPLAN.pt_id
	, VST.unit_seq_no
	, VST.cr_rating
	, CAST(VST.vst_end_date AS date)                     AS [vst_end_date]
	, VST.fc
	, VST.hosp_svc
	, CAST(DATEDIFF(DD, VST.VST_END_DATE, GETDATE()) AS int) AS [Age_In_Days]
	, PYRPLAN.pyr_cd
	, PYRPLAN.pyr_seq_no
	, CAST(VST.tot_chg_amt AS money)                     AS [tot_chg_amt]
	, CAST(VST.tot_bal_amt AS money)                     AS [tot_enc_bal_amt]
	, CAST(VST.ins_pay_amt AS money)                     AS [ins_pay_amt]
	, CAST(VST.pt_bal_amt AS money)                      AS [pt_bal_amt]
	, CASE
		WHEN PYRPLAN.PYR_CD = '*' THEN 0
		ELSE CAST(PYRPLAN.tot_amt_due AS money)
		END                                              AS [Ins_Bal_Amt]
	, CAST(VST.tot_pay_amt AS money)                     AS [tot_pay_amt]
	, CAST((VST.tot_pay_amt - VST.ins_pay_amt) AS money) AS [pt_pay_amt]
	, CAST(guar.GuarantorDOB as date)                    AS [GuarantorDOB]
	, guar.GuarantorFirst
	, guar.GuarantorLast
	, vst.ins1_pol_no
	, vst.ins2_pol_no
	, vst.ins3_pol_no
	, vst.ins4_pol_no
	, [RunDate] = CAST(GETDATE() AS date)
	, [RunDateTime] = GETDATE()
	, [RN] = ROW_NUMBER() OVER(
		PARTITION BY PYRPLAN.PT_ID
		ORDER BY PYRPLAN.PYR_SEQ_NO
	)

	FROM SMSMIR.PYR_PLAN AS PYRPLAN
	LEFT JOIN smsmir.vst_rpt VST
	ON PYRPLAN.pt_id = VST.pt_id
			--AND PYRPLAN.unit_seq_no = VST.unit_seq_no
	LEFT JOIN smsdss.c_guarantor_demos_v AS GUAR
	ON VST.pt_id = GUAR.pt_id
		AND VST.from_file_ind = GUAR.from_file_ind

	WHERE VST.tot_bal_amt > 0
	AND PYRPLAN.tot_amt_due > 0
	AND VST.vst_end_date IS NOT NULL
	AND VST.fc not in (
		'1','2','3','4','5','6','7','8','9'
	)
	-- MAKE SURE IT WAS NOT RUN FOR THE DAY ALREADY
	AND CAST(GETDATE() AS date) <> isnull((SELECT MAX(RUNDATE) FROM smsdss.c_ins_bal_amt), getdate() - 1)

	ORDER BY PYRPLAN.pt_id
	, PYRPLAN.pyr_cd
END
;