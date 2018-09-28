USE [SMSPHDSSS0X0];
GO

--SET THE OPTIONS TO SUPPORT INDEXED VIEWS.
SET NUMERIC_ROUNDABORT OFF;
SET ANSI_PADDING, ANSI_WARNINGS, CONCAT_NULL_YIELDS_NULL, ARITHABORT,
	QUOTED_IDENTIFIER, ANSI_NULLS ON;
GO

ALTER VIEW [smsdss].[c_charity_care_v]
AS

/*
*****************************************************************************  
File: c_charity_care_v.sql      

Input  Parameters:
	None

Tables:   
	smsmir.vst
	smsmir.pay
	smsdss.pay_cd_dim_v
	smsmir.pt
	smsmir.acct
	smsdss.pyr_dim_v
  
Functions:   
	None

Author: Steve P Sanderson II, MPH

Department: Finance, Revenue Cycle

Description: Create a charity care view that is in account and pay_entry_date
order
      
Revision History: 
Date		Version		Description
----		----		----
2018-09-27	v1			Initial Creation
-------------------------------------------------------------------------------- 
*/

SELECT LTRIM(RTRIM(VST.vst_med_rec_no)) AS [MRN]
, CAST(VST.pt_id AS bigint) AS [PtNo_Num]
, CAST(VST.vst_start_date AS date) AS [Adm_Date]
, CAST(VST.vst_end_date AS DATE) AS [Dsch_Date]
, YEAR(VST.vst_end_date) AS [Dsch_Yr]
, A.pt_id
, A.hosp_svc
, A.fc
, A.pay_cd AS [Pay_Cd]
, B.pay_cd_name AS [Pay_Cd_Name]
, CASE
	WHEN A.pay_cd = '09730235' THEN 'Adjustment'
	WHEN A.pay_cd = '09731241' THEN 'Adjustment'
	WHEN A.pay_cd = '09735234' THEN 'Adjustment'
	WHEN A.pay_cd = '09700097' THEN 'NLIU'
	WHEN A.pay_cd = '09700287' THEN 'NLIU'
	WHEN A.pay_cd = '09735267' THEN 'Adjustment'
	WHEN A.pay_cd = '09735291' THEN 'AR Adjustment'
	WHEN A.pay_cd = '09735283' THEN 'AR Adjustment'
	WHEN A.pay_cd = '09735341' THEN 'Writedown'
	WHEN A.pay_cd = '09735317' THEN 'Writedown'
	WHEN A.pay_cd = '09735325' THEN 'Writedown'
	WHEN A.pay_cd = '09735333' THEN 'Writedown'
	WHEN A.pay_cd = '09735309' THEN 'Allowance'
	WHEN A.pay_cd = '09730243' THEN 'Allowance'
	WHEN A.pay_cd = '09735242' THEN 'Allowance'
	WHEN A.pay_cd = '09731258' THEN 'Allowance'
  END AS [Category]
, CASE
	WHEN A.pay_cd = '09730235 ' THEN '1'
	WHEN A.pay_cd = '09731241 ' THEN '1'
	WHEN A.pay_cd = '09735234 ' THEN '1'
	WHEN A.pay_cd = '09700097 ' THEN '2'
	WHEN A.pay_cd = '09700287 ' THEN '2'
	WHEN A.pay_cd = '09735267 ' THEN '1'
	WHEN A.pay_cd = '09735291 ' THEN '3'
	WHEN A.pay_cd = '09735283 ' THEN '3'
	WHEN A.pay_cd = '09735341 ' THEN '4'
	WHEN A.pay_cd = '09735317 ' THEN '4'
	WHEN A.pay_cd = '09735325 ' THEN '4'
	WHEN A.pay_cd = '09735333 ' THEN '4'
	WHEN A.pay_cd = '09735309 ' THEN '5'
	WHEN A.pay_cd = '09730243 ' THEN '5'
	WHEN A.pay_cd = '09735242 ' THEN '5'
	WHEN A.pay_cd = '09731258 ' THEN '5'
  END AS [Category_Cd]
, CASE
	WHEN A.pay_cd = '09730235 ' THEN 'Adjustment'
	WHEN A.pay_cd = '09731241 ' THEN 'Adjustment'
	WHEN A.pay_cd = '09735234 ' THEN 'Adjustment'
	WHEN A.pay_cd = '09700097 ' THEN 'No Longer In Use'
	WHEN A.pay_cd = '09700287 ' THEN 'No Longer In Use'
	WHEN A.pay_cd = '09735267 ' THEN 'Adjustment'
	WHEN A.pay_cd = '09735291 ' THEN 'AR Adjustment - Nursing Home'
	WHEN A.pay_cd = '09735283 ' THEN 'AR Adjustment - CSP'
	WHEN A.pay_cd = '09735341 ' THEN 'Charges to APC or APG'
	WHEN A.pay_cd = '09735317 ' THEN 'Charges to APC or APG'
	WHEN A.pay_cd = '09735325 ' THEN 'Charges to APC or APG'
	WHEN A.pay_cd = '09735333 ' THEN 'Charges to APC or APG'
	WHEN A.pay_cd = '09735309 ' THEN 'APC or APG to ability to Pay'
	WHEN A.pay_cd = '09730243 ' THEN 'APC or APG to ability to Pay'
	WHEN A.pay_cd = '09735242 ' THEN 'APC or APG to ability to Pay'
	WHEN A.pay_cd = '09731258 ' THEN 'APC or APG to ability to Pay'
  END AS [Category_Desc]
, A.tot_pay_adj_amt
, A.pay_entry_date
, A.pay_dtime
, PT.rpt_name
, PT.nhs_id_no
, PT.birth_date
, PT.race_cd
, PT.gender_cd
, VST.vst_postal_cd
, ISNULL(VST.PRIM_PYR_CD, '*') AS PYR1_CD
, PDV.pyr_group2
, ACCT.pyr2_cd
, ACCT.pyr3_cd
, ACCT.pyr4_cd
, ACCT.tot_chg_amt
, ACCT.tot_pay_amt
, ACCT.tot_bal_amt

FROM smsmir.vst AS VST
INNER JOIN smsmir.pay AS A
ON VST.pt_id = A.pt_id
	AND VST.unit_seq_no = A.unit_seq_no
	AND VST.from_file_ind = A.from_file_ind
	AND VST.src_sys_id = A.src_sys_id
	AND VST.orgz_cd = A.orgz_cd
	AND VST.acct_no = A.acct_no
LEFT OUTER JOIN smsdss.pay_cd_dim_v AS B
ON A.pay_cd = B.pay_cd
LEFT OUTER JOIN smsmir.pt AS PT
ON VST.PT_ID = PT.pt_id
	AND VST.src_sys_id = PT.src_sys_id
	AND VST.from_file_ind = PT.from_file_ind
	AND VST.pt_id_start_dtime = PT.pt_id_start_dtime
INNER JOIN SMSMIR.acct AS ACCT
ON VST.pt_id = ACCT.pt_id
	AND VST.pt_id_start_dtime = ACCT.pt_id_start_dtime
	AND VST.src_sys_id = ACCT.src_sys_id
	AND VST.from_file_ind = ACCT.from_file_ind
	AND VST.orgz_cd = ACCT.orgz_cd
	AND VST.unit_seq_no = ACCT.unit_seq_no
LEFT OUTER JOIN SMSDSS.pyr_dim_v AS PDV
ON ISNULL(VST.prim_pyr_cd, '*') = PDV.src_pyr_cd
	AND VST.orgz_cd = PDV.orgz_cd

WHERE A.pay_cd IN (
	select ZZZ.pay_cd
	from smsdss.pay_cd_dim_v AS ZZZ
	where (
		ZZZ.pay_cd_name like '%charity%'
		OR
		ZZZ.pay_cd IN (
		'09722240','09722257'
		)
	)
)
