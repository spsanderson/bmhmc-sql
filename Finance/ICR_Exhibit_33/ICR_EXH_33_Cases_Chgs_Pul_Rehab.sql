SELECT a.user_pyr1_cat
, SUM(b.chg_qty) AS [Cases]
, SUM(b.tot_chg_amt) AS [Tot_Chgs]

FROM smsdss.bmh_plm_ptacct_v AS A
INNER JOIN smsdss.BMH_PLM_PtAcct_Svc_V_Hold AS B
ON a.Pt_Key = b.Pt_Key
	and a.Bl_Unit_Key = b.bl_unit_key

WHERE b.svc_date BETWEEN '01/01/17' and '12/31/17'
AND a.pt_type IN ('n')
AND b.svc_cd BETWEEN '04200000' and '04299999'
AND a.Plm_Pt_Acct_Type = 'O'

GROUP BY a.user_pyr1_Cat

ORDER BY a.user_pyr1_Cat ASC
