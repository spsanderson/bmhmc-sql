SELECT PAV.PtNo_Num,
	CAST(PAV.Dsch_Date AS DATE) AS [Dsch_Date],
	CAST(PAV.PT_BIRTHDATE AS DATE) AS [Pt_DOB],
	pav.Pt_Zip_Cd,
	PAV.drg_no,
	PAV.prin_dx_cd,
	PAV.Pyr1_Co_Plan_Cd,
	PDV.pyr_name AS [Primary_Ins_Desc],
	INSPOL1.ins1_pol_no,
	PDV.pyr_group2 AS [Primary_Ins_Group],
	PAV.Pyr2_Co_Plan_Cd,
	PDV2.pyr_name AS [Secondary_Ins_Desc],
	INSPOL2.ins2_pol_no,
	PDV2.PYR_GROUP2 AS [Secondary_Ins_Group],
	[primary_secondary_dx_flag] = CASE
		WHEN PAV.PRIN_DX_CD IN ('N18.5','N18.6')
			THEN 'PRIMARY_DX'
		ELSE 'SECONDARY_DX'
		END,
	pav.tot_chg_amt,
	pav.tot_adj_amt,
	pav.tot_pay_amt,
	pav.Tot_Amt_Due
FROM smsdss.BMH_PLM_PtAcct_V AS PAV
INNER JOIN smsdss.pyr_dim_v AS PDV ON PAV.Pyr1_Co_Plan_Cd = PDV.src_pyr_cd
	AND PAV.Regn_Hosp = PDV.orgz_cd
INNER JOIN smsdss.pyr_dim_v AS PDV2 ON PAV.Pyr2_Co_Plan_Cd = PDV2.src_pyr_cd
	AND PAV.Regn_Hosp = PDV2.orgz_cd
-- primary ins pol no
LEFT JOIN smsmir.vst_rpt AS INSPOL1 ON PAV.PTNO_NUM = INSPOL1.EPISODE_NO
	AND INSPOL1.unit_seq_no = PAV.unit_seq_no
-- secondary ins pol no
LEFT JOIN smsmir.vst_rpt AS INSPOL2 ON PAV.PTNO_NUM = INSPOL2.EPISODE_NO
	AND INSPOL2.unit_seq_no = PAV.unit_seq_no
WHERE LEFT(PAV.PTNO_NUM, 1) != '2'
AND LEFT(PAV.PTNO_NUM, 4) != '1999'
AND PAV.tot_chg_amt > 0
AND PAV.prin_dx_cd IS NOT NULL
AND PAV.Dsch_Date BETWEEN '2020-09-01' AND '2021-08-31'
AND PAV.Pt_Age < 65
-- INSURANCE FILTERS
AND (
	(
		-- Primary Insurance Payer Group
		PDV.PYR_GROUP2 IN ('Medicaid', 'Medicaid HMO')
	)
	OR
	(
		-- Primary
		PDV.PYR_GROUP2 IN ('Medicare A','Medicare HMO')
		-- Secondary
		AND PDV2.pyr_group2 IN ('Medicaid','Medicaid HMO')
	) 
)
-- CLINICAL FITLERS
AND (
	-- ESRD
	(
		-- DRG
		(
			PAV.drg_no IN ('650','651','652')
		)
		-- ICD10
		OR PAV.Pt_No IN 
		(
			SELECT DISTINCT ZZZ.pt_id
			FROM smsmir.dx_grp AS ZZZ
			WHERE PAV.PT_NO = ZZZ.pt_id
				AND PAV.UNIT_SEQ_NO = ZZZ.unit_seq_no
				AND ZZZ.dx_cd IN ('N18.5','N18.6')
				AND LEFT(ZZZ.dx_cd_type, 2) = 'DF'
		)
	)
	-- ALS
	OR PAV.Pt_No IN
	(
			SELECT DISTINCT ZZZ.pt_id
			FROM smsmir.dx_grp AS ZZZ
			WHERE PAV.PT_NO = ZZZ.pt_id
				AND PAV.UNIT_SEQ_NO = ZZZ.unit_seq_no
				AND ZZZ.dx_cd IN ('G12.21')
				AND LEFT(ZZZ.dx_cd_type, 2) = 'DF'
	)
)