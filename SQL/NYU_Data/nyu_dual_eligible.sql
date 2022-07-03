SELECT PAV.PtNo_Num,
	PAV.drg_no,
	PAV.prin_dx_cd,
	PAV.Pyr1_Co_Plan_Cd,
	PDV.PYR_GROUP2,
	*
FROM smsdss.BMH_PLM_PtAcct_V AS PAV
INNER JOIN smsdss.pyr_dim_v AS PDV ON PAV.Pyr1_Co_Plan_Cd = PDV.src_pyr_cd
	AND PAV.Regn_Hosp = PDV.orgz_cd
WHERE LEFT(PAV.PTNO_NUM, 1) != '2'
AND LEFT(PAV.PTNO_NUM, 4) != '1999'
AND PAV.tot_chg_amt > 0
AND PAV.prin_dx_cd IS NOT NULL
AND PAV.Dsch_Date BETWEEN '2020-09-01' AND '2021-08-31'
AND PAV.Pt_Age < 65
AND PDV.pyr_group2 IN ('Medicaid', 'Medicaid HMO')
AND (
	-- ESRD
	(
		-- DRG
		(
			PAV.drg_no IN ('650','651','652')
		)
		-- ICD10
		OR 
		(
			PAV.prin_dx_cd IN ('N18.5','N18.6')
		)
	)
	-- ALS
	OR 
	(
		PAV.prin_dx_cd IN ('G12.21')
	)
)