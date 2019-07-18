-- Inpatients
-- Column Selection
SELECT A.Pt_No
, CAST(A.Adm_Date AS date)  AS [Admit Date]
, CAST(A.Dsch_Date AS date) AS [Discharge Date]
, CAST(A.Days_Stay AS int)  AS [LOS]
, A.mdc                     AS [MDC No]
, G.mdc_name                AS [MDC Name]
, A.hosp_svc                AS [Hosp Svc Cd]
, B.hosp_svc_name           AS [Hosp Service]
, A.drg_no                  AS [DRG No]
, A.Adm_Dr_No               AS [Adm Provider No]
, UPPER(C.pract_rpt_name)   AS [Admitting Provider]
, A.tot_chg_amt             AS [Total Charge Amt]
, a.tot_adj_amt             AS [Total Adjustment Amt]
, h.tot_pymts_w_pip
, A.Tot_Amt_Due             AS [Total Amt Due]
, a.tot_pay_amt             AS [Total Pay Amt]
, A.fc                      AS [Financial Class Code]
, E.fc_name                 AS [Financial Class Name]
, A.Pyr1_Co_Plan_Cd         AS [Primary Insurance]
, F.pyr_group2              AS [Primary Insurance Group]

-- Tables
FROM smsdss.BMH_PLM_PtAcct_V          AS a
LEFT OUTER JOIN smsdss.hosp_svc_dim_v AS b
ON A.hosp_svc = B.hosp_svc
	AND A.Regn_Hosp = B.orgz_cd
LEFT OUTER JOIN smsdss.pract_dim_v    AS c
ON A.Adm_Dr_No = C.src_pract_no
	AND A.Regn_Hosp = C.orgz_cd
LEFT OUTER JOIN smsdss.fc_dim_v       AS e
ON A.fc = E.fc
	AND A.Regn_Hosp = E.orgz_cd
LEFT OUTER JOIN smsdss.pyr_dim_v      AS f
ON A.Pyr1_Co_Plan_Cd = F.pyr_cd
	AND A.Regn_Hosp = F.orgz_cd
LEFT OUTER JOIN smsdss.mdc_dim_v      AS g
ON A.mdc = G.mdc
LEFT OUTER JOIN smsdss.c_tot_pymts_w_pip_v AS h
ON a.Pt_No = h.pt_id
	AND a.unit_seq_no = h.unit_seq_no

-- Conditions
WHERE A.Dsch_Date >= '2016-01-01'
AND A.Dsch_Date < '2017-01-01'
AND A.Plm_Pt_Acct_Type = 'i'
AND LEFT(A.ptno_num, 1) = '1'
AND A.tot_chg_amt > 0
AND LEFT(A.ptno_num, 4) != '1999'
AND a.Pt_Name NOT LIKE '%TEST%'


-- Outpatients
-- Column Selection
SELECT A.Pt_No
, a.unit_seq_no
, A.hosp_svc                AS [Hosp Svc Cd]
, B.hosp_svc_name           AS [Hosp Service]
, a.Prin_Hcpc_Proc_Cd       AS [Principal HCPCS]
, G.proc_cd_desc            AS [HCPCS Description]
, G.hcpcs_proc_summ_cat     AS [HCPCS Summary Category]
, G.hcpcs_proc_dtl_cat      AS [HCPCS Detail Category]
, A.tot_chg_amt             AS [Total Charge Amt]
, a.tot_adj_amt             AS [Total Adjustment Amt]
, A.Tot_Amt_Due             AS [Total Amt Due] 
, a.tot_pay_amt             AS [Total Pay Amt]
, A.fc                      AS [Financial Class Code]
, E.fc_name                 AS [Financial Class Name]
, A.Pyr1_Co_Plan_Cd         AS [Primary Insurance]
, F.pyr_group2              AS [Primary Insurance Group]
, a.Atn_Dr_No               AS [Provider ID]
, CASE
	WHEN a.Atn_Dr_No = '000000'
		THEN 'Not On Staff'
		ELSE UPPER(H.PRACT_RPT_NAME)
  END                       AS [Provider Name]

-- Tables
FROM smsdss.BMH_PLM_PtAcct_V          AS a
LEFT OUTER JOIN smsdss.hosp_svc_dim_v AS b
ON A.hosp_svc = B.hosp_svc
	AND A.Regn_Hosp = B.orgz_cd
LEFT OUTER JOIN smsdss.fc_dim_v       AS e
ON A.fc = E.fc
	AND A.Regn_Hosp = E.orgz_cd
LEFT OUTER JOIN smsdss.pyr_dim_v      AS f
ON A.Pyr1_Co_Plan_Cd = F.pyr_cd
	AND A.Regn_Hosp = F.orgz_cd
LEFT OUTER JOIN smsdss.proc_dim_v     AS G
ON a.Prin_Hcpc_Proc_Cd = G.proc_cd
LEFT OUTER JOIN smsdss.pract_dim_v    AS H
ON a.Atn_Dr_No = H.src_pract_no
	AND a.Regn_Hosp = H.orgz_cd

-- Conditions
WHERE A.Dsch_Date >= '2016-01-01'
AND A.Dsch_Date < '2017-01-01'
AND A.Plm_Pt_Acct_Type = 'O'
AND LEFT(A.ptno_num, 1) != '1'
AND A.tot_chg_amt > 0

order by a.PtNo_Num
