SELECT CONVERT(VARCHAR, PAV.Adm_Date, 110) AS [Adm_Date]
, [NPI_Rendered_Svc] = CASE WHEN PAV.hosp_svc = 'PSY' THEN '1528133147' ELSE '1053354100' END
, [NPI_Billed] = CASE WHEN PAV.hosp_svc = 'PSY' THEN '1528133147' ELSE '1053354100' END
, [Medicaid] = CASE
	WHEN LEFT(PAV.Pyr1_Co_Plan_Cd, 1) IN ('I','W')
	OR
	LEFT(PAV.Pyr2_Co_Plan_Cd, 1) IN ('I','W')
	OR
	LEFT(PAV.Pyr3_Co_Plan_Cd, 1) IN ('I','W')
	OR
	LEFT(PAV.Pyr4_Co_Plan_Cd, 1) IN ('I','W')
		THEN 'Medicaid'
		ELSE 'Non-Medicaid'
	END
, [Medicaid_W_Plan] = CASE
	WHEN LEFT(PAV.Pyr1_Co_Plan_Cd, 1) = 'W'
	OR
	LEFT(PAV.Pyr2_Co_Plan_Cd, 1) = 'W'
	OR
	LEFT(PAV.Pyr3_Co_Plan_Cd, 1) = 'W'
	OR
	LEFT(PAV.Pyr4_Co_Plan_Cd, 1) = 'W'
		THEN 'Has_W_Plan'
		ELSE ''
	END
, [Medicaid_I_Plan] = CASE
	WHEN LEFT(PAV.Pyr1_Co_Plan_Cd, 1) = 'i'
	OR
	LEFT(PAV.Pyr2_Co_Plan_Cd, 1) = 'i'
	OR
	LEFT(PAV.Pyr3_Co_Plan_Cd, 1) = 'i'
	OR
	LEFT(PAV.Pyr4_Co_Plan_Cd, 1) = 'i'
		THEN 'Has_I_Plan'
		ELSE ''
	END
, [Medicaid_ID_W_Plan] = CASE
	WHEN LEFT(PAV.Pyr1_Co_Plan_Cd, 1) IN ('W')
		THEN RTRIM(ISNULL(INSA.pol_no,'')) + LTRIM(RTRIM(ISNULL(INSA.grp_no,'')))
	WHEN LEFT(PAV.Pyr2_Co_Plan_Cd, 1) IN ('W')
		THEN RTRIM(ISNULL(INSB.pol_no,'')) + LTRIM(RTRIM(ISNULL(INSB.grp_no,'')))
	WHEN LEFT(PAV.Pyr3_Co_Plan_Cd, 1) IN ('W')
		THEN RTRIM(ISNULL(INSC.pol_no,'')) + LTRIM(RTRIM(ISNULL(INSC.grp_no,'')))
	WHEN LEFT(PAV.Pyr4_Co_Plan_Cd, 1) IN ('W')
		THEN RTRIM(ISNULL(INSA.pol_no,'')) + LTRIM(RTRIM(ISNULL(INSA.grp_no,'')))
		ELSE ''
	END
, [Medicaid_ID_I_Plan] = CASE
	WHEN LEFT(PAV.Pyr1_Co_Plan_Cd, 1) IN ('I')
		THEN RTRIM(ISNULL(INSA.pol_no,'')) + LTRIM(RTRIM(ISNULL(INSA.grp_no,'')))
	WHEN LEFT(PAV.Pyr2_Co_Plan_Cd, 1) IN ('I')
		THEN RTRIM(ISNULL(INSB.pol_no,'')) + LTRIM(RTRIM(ISNULL(INSB.grp_no,'')))
	WHEN LEFT(PAV.Pyr3_Co_Plan_Cd, 1) IN ('I')
		THEN RTRIM(ISNULL(INSC.pol_no,'')) + LTRIM(RTRIM(ISNULL(INSC.grp_no,'')))
	WHEN LEFT(PAV.Pyr4_Co_Plan_Cd, 1) IN ('I')
		THEN RTRIM(ISNULL(INSA.pol_no,'')) + LTRIM(RTRIM(ISNULL(INSA.grp_no,'')))
		ELSE ''
	END
, PT.pt_last
, PT.pt_first
, CONVERT(VARCHAR, PAV.Pt_Birthdate, 110) AS [PT_DOB]
, PAV.hosp_svc
, HOSPSVC.hosp_svc_name
, PAV.PtNo_Num
, PAV.pt_type
, PTTYPE.pt_type_desc
, pav.Plm_Pt_Acct_Type
, PAV.Pyr1_Co_Plan_Cd
, PAV.Pyr2_Co_Plan_Cd
, PAV.Pyr3_Co_Plan_Cd
, PAV.Pyr4_Co_Plan_Cd

FROM SMSDSS.BMH_PLM_PtAcct_V AS PAV
LEFT OUTER JOIN SMSDSS.c_patient_demos_v AS PT
ON PAV.Pt_No = PT.PT_ID
	AND PAV.from_file_ind = PT.from_file_ind
LEFT OUTER JOIN smsmir.mir_pyr_plan      AS INSA
	ON PAV.Pt_No = INSA.pt_id
		AND PAV.Pyr1_Co_Plan_Cd = INSA.pyr_cd
LEFT OUTER JOIN smsmir.mir_pyr_plan      AS INSB
	ON PAV.Pt_No = INSB.pt_id
		AND PAV.Pyr2_Co_Plan_Cd = INSB.pyr_cd
LEFT OUTER JOIN smsmir.mir_pyr_plan      AS INSC
	ON PAV.Pt_No = INSC.pt_id
		AND PAV.Pyr3_Co_Plan_Cd = INSC.pyr_cd
LEFT OUTER JOIN smsmir.mir_pyr_plan      AS INSD
	ON PAV.Pt_No = INSD.pt_id
		AND PAV.Pyr4_Co_Plan_Cd = INSD.pyr_cd
LEFT OUTER JOIN SMSDSS.pt_type_dim_v AS PTTYPE
ON PAV.pt_type = PTTYPE.src_pt_type
	AND PAV.Regn_Hosp = PTTYPE.orgz_cd
LEFT OUTER JOIN SMSDSS.hosp_svc_dim_v AS HOSPSVC
ON PAV.hosp_svc = HOSPSVC.hosp_svc
	AND PAV.Regn_Hosp = HOSPSVC.orgz_cd

WHERE PAV.Adm_Date >= '2014-10-01' 
AND PAV.Adm_Date < '2015-01-01'
AND PAV.tot_chg_amt > 0
AND LEFT(PAV.PTNO_NUM, 1) != '2'
AND LEFT(PAV.PTNO_NUM, 4) != '1999'
--AND (
--	(
--		PAV.pt_type = 'E'
--		AND PAV.Plm_Pt_Acct_Type != 'I'
--	)
--	OR
--	PAV.Plm_Pt_Acct_Type = 'I'
--)

ORDER BY PAV.Adm_Date
, PAV.pt_type
, PAV.hosp_svc