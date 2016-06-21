SELECT b.User_Pyr1_Cat,
       b.plm_pt_acct_type,
       YEAR(a.Svc_Date),
     MONTH(a.Svc_Date),
       --a.pt_no,
       --COUNT(DISTINCT(a.pt_no)),
       --COUNT(a.Pt_No),
       SUM(a.Chg_Qty)



FROM smsdss.BMH_PLM_PtAcct_Svc_V_Hold as a INNER JOIN smsdss.BMH_PLM_PtAcct_V as b
ON a.Pt_Key=b.Pt_Key AND a.Bl_Unit_Key=b.Bl_Unit_Key

WHERE a.Svc_Date BETWEEN '1/01/2015' AND '9/30/2015'  --RUN MTD 
AND a.Svc_Cd = '04601001' --ED Visit Charge 


GROUP BY b.User_Pyr1_Cat,
       b.plm_pt_acct_type,
       YEAR(a.Svc_Date),
     MONTH(a.Svc_Date)


ORDER BY b.User_Pyr1_Cat, b.plm_pt_acct_type
