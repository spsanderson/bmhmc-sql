SELECT a.user_pyr1_Cat,
SUM(b.tot_chg_amt),
SUM(b.chg_qty)


FROM smsdss.BMH_PLM_PtAcct_V as a inner join smsdss.BMH_PLM_PtAcct_Svc_V_Hold as b
On a.Pt_Key = b.Pt_Key and a.Bl_Unit_Key=b.Bl_Unit_key

WHERE b.Svc_Date BETWEEN '1/1/17' and '12/31/17'
AND a.Plm_Pt_Acct_Type = 'o'
--AND a.pt_type IN ('R')
AND b.Svc_Cd BETWEEN '05400000' AND '05499999'


GROUP BY a.User_Pyr1_Cat

ORDER BY a.User_Pyr1_Cat asc


