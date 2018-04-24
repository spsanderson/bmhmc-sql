SELECT a.user_pyr1_cat,
SUM(b.chg_qty) as 'Cases',
SUM(b.tot_chg_amt) as 'Tot_Chgs'


FROm smsdss.bmh_plm_ptacct_v as a inner join smsdss.BMH_PLM_PtAcct_Svc_V_Hold as b
ON a.Pt_Key=b.Pt_Key and a.Bl_Unit_Key=b.bl_unit_key

WHERE b.svc_date BETWEEN '01/01/17' and '12/31/17'
AND a.pt_type IN ('C')
AND b.svc_cd BETWEEN '05200001' and '05300025'


GROUP BY a.user_pyr1_Cat

ORDER BY a.user_pyr1_Cat ASC

