USE [SMSPHDSSS0X0]
GO
/****** Object:  StoredProcedure [smsdss].[c_ar_runoff_on_demand_sp]    Script Date: 1/12/2018 9:41:35 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE  [smsdss].[c_ar_runoff_on_demand_sp]

AS
	
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON; 

DECLARE @curr_mo_end datetime, @curr_year int, @prior_year_end datetime, @strt_of_year datetime;

SET arithabort OFF
SET arithignore ON
SET ansi_warnings OFF
	

SET @curr_year = YEAR(DATEADD(MONTH,-MONTH(sysdatetime())+1,(DATEADD(MONTH,DATEDIFF(MONTH,0,sysdatetime()),0))));
SET @prior_year_end = DATEADD(DAY,-1,DATEADD(MONTH,-MONTH(sysdatetime())+1,(DATEADD(MONTH,DATEDIFF(MONTH,0,sysdatetime()),0))));
SET @strt_of_year = DATEADD(MONTH,-MONTH(sysdatetime())+1,(DATEADD(MONTH,DATEDIFF(MONTH,0,sysdatetime()),0)));
SET @curr_mo_end = DATEADD(DAY,-1,(DATEADD(MONTH,DATEDIFF(MONTH,0,sysdatetime()),0)));

DROP TABLE smsdss.c_ar_runout_on_Demand

/*Pull Charges Posted Subsequent to Year End for Pts In AR Aging At Year End*/

SELECT pt_id
, unit_seq_no
--, pt_id_start_dtime
, SUM(chg_tot_amt) AS 'Tot_Chgs'

INTO #c_temp_subseq_chgs

FROM smsmir.mir_actv
WHERE YEAR(actv_dtime) < @curr_year
AND(CAST(LTRIM(RTRIM(pt_id)) AS VARCHAR) + CAST(LTRIM(RTRIM(unit_seq_no)) AS VARCHAR)) IN (
	SELECT (CAST(LTRIM(RTRIM(pt_id)) AS VARCHAR)+CAST(LTRIM(RTRIM(unit_seq_no)) AS VARCHAR))
	FROM smsdss.ar_aged_v
	WHERE snapshot_full_date=@prior_year_end
)

GROUP BY pt_id
, unit_seq_no
--, pt_id_start_dtime
;

SELECT pt_id
, unit_seq_no
, CASE
	WHEN pay_cd IN ('09730235','09735234','09731241') 
		THEN 'Charity'
	WHEN pay_cd BETWEEN '00990000' AND '00999999' 
		THEN 'Payment'
	WHEN pay_cd BETWEEN '09900000' AND '09999999' 
		THEN 'Payment'
	WHEN pay_cd IN (
		'00980300','00980409','00980508','00980607','00980656',
		'00980706','00980755','00980805','00980813','00980821',
		'09800095','09800277','09800301','09800400','09800459',
		'09800509','09800558','09800608','09800707','09800715',
		'09800806','09800814','09800905','09800913','09800921',
		'09800939','09800947','09800962','09800970','09800988',
		'09800996','09801002','09801010','09801028','09801036',
		'09801044','09801051','09801069','09801077','09801085',
		'09801093','09801101','09801119','09801127'
	)
		THEN 'Payment'
	WHEN pay_cd BETWEEN '09700000' AND '09730234' 
		THEN 'Allowance'
	WHEN pay_cd BETWEEN '09730236' AND '09731240' 
		THEN 'Allowance'
	WHEN pay_cd BETWEEN '09731242' AND '09735233' 
		THEN 'Allowance'
	WHEN pay_cd BETWEEN '09735235' AND '09799999' 
		THEN 'Allowance'
	WHEN pay_cd BETWEEN '00970000' AND '00979999' 
		THEN 'Allowance'
	WHEN pay_cd BETWEEN '09600000' AND '09699999' 
		THEN 'Bad_Debt_Recovery'
	ELSE 'Undefined'
  END AS 'Pay_Type'
, SUM(tot_pay_adj_amt) AS 'Tot_pmts'

INTO #c_temp_subseq_pay_allow

FROM smsmir.mir_pay
WHERE pay_entry_dtime BETWEEN @strt_of_year AND getdate()--@curr_mo_end
AND(CAST(LTRIM(RTRIM(pt_id)) AS VARCHAR) + CAST(LTRIM(RTRIM(unit_seq_no)) AS VARCHAR)) IN (
	SELECT (CAST(LTRIM(RTRIM(pt_id)) AS VARCHAR)+CAST(LTRIM(RTRIM(unit_seq_no)) AS VARCHAR))
	FROM smsdss.ar_aged_v
	WHERE snapshot_full_date = @prior_year_end
)

GROUP BY pt_id
, unit_seq_no
, pay_cd
;

SELECT rr.pt_id
, rr.unit_seq_no
--, pt_id_start_dtime
, rr.Pay_Type
, SUM(rr.Tot_pmts) AS 'Tot_pmts'

INTO #c_temp_subseq_pay_allow_rollup

FROM #c_temp_subseq_pay_allow AS rr

GROUP BY rr.pt_id
, rr.unit_seq_no
, rr.pay_type
--pt_id_start_dtime, pay_type
;

SELECT (CAST(LTRIM(RTRIM(b.pt_no)) AS VARCHAR) + CAST(LTRIM(RTRIM(b.unit_seq_no)) AS VARCHAR)) AS 'pt_number'
, b.pt_no AS 'pt_id'
, b.unit_seq_no
, b.fc
--, b.acct_close_ind_cd
, ccc.fc_name
, ccc.fc_cat
, b.User_Pyr1_Cat
, b.pyr1_co_plan_cd
, LEFT(LTRIM(RTRIM(b.from_file_ind)),1)AS 'acct_sts'
, b.adm_date
, b.adm_date AS visit_date
, b.pt_type AS 'pt_type'
, b.pt_type AS 'pt_type_2'
, b.plm_pt_acct_type AS 'vst_type_cd'
, b.plm_pt_acct_type AS 'vst_type_cd_2'
, YEAR(b.adm_date) AS 'vst_year'
, b.tot_amt_due AS 'tot_bal_amt'
, b.tot_chg_amt
, '0' AS fnl_bl_cnt
, GETDATE() AS snapshot_full_date

INTO #c_temp_current_ar

FROM smsdss.bmh_plm_ptacct_v AS b--smsdss.ar_aged_v AS b 
LEFT JOIN smsmir.mir_fc_mstr AS ccc 
ON LEFT(b.user_pyr1_cat, 1) = ccc.fc 
	AND ccc.src_sys_id='#PASS0X0'

--WHERE b.snapshot_full_date=(SELECT MAX(c.snapshot_full_date) FROM smsdss.ar_aged_v AS c)
;

SELECT (CAST(LTRIM(RTRIM(a.pt_id)) AS VARCHAR) + CAST(LTRIM(RTRIM(a.unit_seq_no)) AS VARCHAR)) AS 'pt_number'
, a.pt_id
, a.unit_seq_no
, a.fc
--, a.acct_close_ind_cd
, a.fc_name
, a.fc_cat
, a.pyr_cd
, (
	SELECT w.pyr_group
	FROM smsdss.pyr_dim_v AS w
	WHERE w.pyr_cd=a.pyr_cd
	and w.orgz_cd='S0X0'
) AS 'Prim_Pyr_Cat'
, d.user_pyr1_cat
, d.pyr1_co_plan_cd
, a.acct_sts
, a.adm_full_date
, a.vst_full_date
, a.pt_type
, a.pt_type_2
, a.vst_type_cd
, a.vst_type_cd_2
, a.vst_year
, a.tot_bal_amt
, a.tot_chg_amt
, a.fnl_bl_cnt
, CASE
	WHEN d.acct_sts IN ('4','6') THEN 0
	WHEN d.tot_bal_amt IS NULL THEN 0
	WHEN d.acct_sts IN ('7','8') AND g.alt_bd_wo_amt>0 THEN d.tot_bal_Amt-g.alt_bd_wo_amt
	ELSE d.tot_bal_amt
  END AS 'AR_Balance'
, ISNULL(d.acct_sts,'7') AS 'Current_Status'
, ISNULL(d.tot_chg_amt,g.tot_chg_amt) AS 'Current_Tot_Chgs'
, (
	SELECT j.tot_chgs
	FROM #c_temp_subseq_chgs AS j
	WHERE a.pt_id=j.pt_id AND a.unit_seq_no=j.unit_Seq_no
) AS 'Prior_Yr_Chgs'
, ISNULL(d.tot_bal_amt,0) AS 'Current_Balance'
, ISNULL(d.tot_bal_amt,0)-a.tot_bal_amt AS 'Balance_Change'
, (
	SELECT SUM(e.Tot_pmts)
	FROM #c_temp_subseq_pay_allow_rollup AS e
	WHERE a.pt_id = e.pt_id 
	AND a.unit_seq_no = e.unit_seq_no
	AND e.pay_type = 'Payment'
	GROUP BY e.pt_id
	, e.unit_seq_no
) AS 'RO_Pymts'
, (
	SELECT SUM(e.Tot_pmts)
	FROM #c_temp_subseq_pay_allow_rollup AS e
	WHERE a.pt_id = e.pt_id 
	AND a.unit_seq_no = e.unit_seq_no
	AND e.pay_type = 'Allowance'
	GROUP BY e.pt_id
	, e.unit_seq_no
) AS 'RO_Allowances'
, (
	SELECT SUM(e.Tot_pmts)
	FROM #c_temp_subseq_pay_allow_rollup AS e
	WHERE a.pt_id = e.pt_id 
	AND a.unit_seq_no = e.unit_seq_no
	AND e.pay_type = 'Bad_Debt_Recovery'
	GROUP BY e.pt_id
	, e.unit_seq_no
) AS 'RO_BD_Recovery'
, (
	SELECT SUM(e.Tot_pmts)
	FROM #c_temp_subseq_pay_allow_rollup AS e
	WHERE a.pt_id = e.pt_id 
	AND a.unit_seq_no = e.unit_seq_no
	AND e.pay_type = 'Charity'
	GROUP BY e.pt_id
	, e.unit_seq_no
) AS 'RO_Charity'
, (
	SELECT SUM(e.Tot_pmts)
	FROM #c_temp_subseq_pay_allow_rollup AS e
	WHERE a.pt_id=e.pt_id AND a.unit_seq_no=e.unit_seq_no
	AND e.pay_type='Undefined'
	GROUP BY e.pt_id, e.unit_seq_no) AS 'RO_Undefined'
, g.bd_wo_dtime
, g.bd_reactv_dtime
, g.arch_xfer_dtime
, g.arch_reactv_dtime
, CASE
	WHEN g.alt_bd_wo_amt IS NULL 
		AND d.acct_sts NOT IN ('4','6') 
			THEN 0
	WHEN g.alt_bd_wo_amt IS NULL 
		AND d.acct_sts IN ('4','6') 
		AND g.bd_reactv_dtime > @curr_mo_end 
			THEN -d.tot_bal_amt
	WHEN d.acct_sts IN ('4','6') 
		THEN ISNULL(-d.tot_bal_amt, 0)
	WHEN d.acct_sts NOT IN ('4','6') 
		AND g.alt_bd_wo_amt IS NOT NULL 
		AND g.bd_wo_dtime > @curr_mo_end 
			THEN 0
	ELSE g.alt_bd_wo_amt*-1 
END AS 'Bad_Debt'

INTO #c_temp_2009_ar_runout

FROM smsdss.ar_aged_v AS a LEFT JOIN #c_temp_current_ar AS d
ON a.pt_id = d.pt_id 
	AND a.unit_seq_no = d.unit_seq_no --AND a.adm_full_date=d.adm_full_date
LEFT JOIN smsmir.mir_acct AS g
ON a.pt_id = g.pt_id 
	AND a.unit_seq_no = g.unit_seq_no 
--AND a.acct_sts=g.acct_stsRIGHT(g.from_file_ind,1)--AND CAST(a.adm_full_date AS DATE)=CAST(g.adm_dtime AS DATE)

WHERE a.snapshot_full_date = @prior_year_end
--AND a.acct_sts IN ('I','O','A')
AND a.fc NOT IN ('0','1','2','3','4','5','6','7','8','9')
;

SELECT i.pt_number
, i.pt_id
, i.unit_seq_no
, i.fc AS 'Yr_End_fc'
, i.fc_name
, i.pyr_cd
, i.prim_pyr_cat
, i.user_pyr1_Cat
, i.pyr1_co_plan_cd
, i.acct_sts
, i.adm_full_date
, i.vst_full_date
, i.pt_type
, i.pt_type_2
, i.vst_type_cd
, i.vst_type_cd_2
, i.vst_year
, i.tot_bal_amt
, i.tot_chg_amt
, i.fnl_bl_cnt
, i.AR_Balance
, i.Current_Balance-i.AR_Balance AS 'BD_Balance'
, i.Current_Status
, i.Current_tot_Chgs
, i.Current_Balance
, ISNULL((i.Current_tot_chgs-i.tot_chg_amt),0) AS 'Subsequent_Chgs'
, ISNULL(i.Prior_yr_chgs,0) AS 'Prior_Yr_Chgs'
, i.AR_Balance-i.tot_bal_amt AS 'AR_Balance_Change'
, i.Current_Balance-i.tot_bal_amt AS 'Balance_Change'
, ISNULL(i.RO_Pymts,0) AS 'RO_Paymts'
, ISNULL(i.RO_Allowances,0) AS 'RO_Allow'
, ISNULL(i.RO_Charity,0) AS'RO_Charity_Care'
, ISNULL(i.RO_BD_Recovery,0) AS 'RO_BD_Recover'
, ISNULL(i.RO_Undefined,0) AS 'RO_Undefined'
, i.bd_wo_dtime
, ISNULL(i.Bad_Debt,0) AS 'RO_Bad_Dbt_Xfr'
, (
	IsNull(i.AR_Balance,0) - 
	i.tot_bal_amt - 
	IsNull(i.current_tot_chgs, 0) +
	i.tot_chg_amt - 
	ISNULL(i.ro_pymts, 0) - 
	ISNULL(i.ro_Allowances, 0) - 
	ISNULL(i.ro_charity,0) - 
	ISNULL(i.ro_bd_recovery,0) - 
	ISNULL(i.ro_undefined,0) - 
	ISNULL(i.bad_debt,0)
) AS 'Chk_Var'

INTO #c_temp2_2009_ar_runout 

FROM #c_temp_2009_ar_runout AS i
;

SELECT j.pt_number
, j.pt_id
, j.unit_seq_no
, j.Yr_End_fc
, j.fc_name
, j.pyr_cd
, j.prim_pyr_cat
, j.user_pyr1_Cat
, j.pyr1_co_plan_cd
, j.acct_sts
, j.adm_full_date
, j.vst_full_date
, j.pt_type
, j.pt_type_2
, j.vst_type_cd
, j.vst_type_cd_2
, j.vst_year
, j.tot_bal_amt
, j.tot_chg_amt
, j.fnl_bl_cnt
, j.AR_Balance
, j.BD_Balance
, j.Current_Status
, j.Current_tot_Chgs
, j.Current_Balance
, j.Prior_Yr_Chgs
, j.Subsequent_Chgs
, j.AR_Balance_Change
, j.Balance_Change
, j.RO_Paymts
, j.RO_Allow
, j.RO_Charity_Care
, j.RO_BD_Recover
, j.RO_Undefined
, j.bd_wo_dtime
, j.RO_Bad_Dbt_Xfr
, j.Chk_Var

INTO smsdss.c_ar_runout_on_Demand

FROM #c_temp2_2009_ar_runout AS j

GROUP BY j.pt_number
, j.pt_id
, j.unit_seq_no
, j.Yr_End_fc
, j.fc_name
, j.pyr_cd
, j.prim_pyr_cat
, j.user_pyr1_Cat
, j.pyr1_co_plan_cd
, j.acct_sts
, j.adm_full_date
, j.vst_full_date
, j.pt_type
, j.pt_type_2
, j.vst_type_cd
, j.vst_type_cd_2
, j.vst_year
, j.tot_bal_amt
, j.tot_chg_amt
, j.fnl_bl_cnt
, j.AR_Balance
, j.BD_Balance
, j.Current_Status
, j.Current_tot_Chgs
, j.Prior_Yr_Chgs
, j.Current_Balance
, j.Subsequent_Chgs
, j.AR_Balance_Change
, j.Balance_Change
, j.RO_Paymts
, j.RO_Allow
, j.RO_Charity_Care
, j.RO_BD_Recover
, j.RO_Undefined
, j.bd_wo_dtime
, j.RO_Bad_Dbt_Xfr
, j.Chk_Var

END
