SELECT b.Pt_No,
       a.Pt_Name,
       a.Pt_Type,
       a.User_Pyr1_Cat,
       a.Pyr1_Co_Plan_Cd,
       b.Svc_Date,
       b.PostDate,
       b.Svc_Cd,
       b.Tot_Chg_Amt,
       b.Chg_Qty,
       a.hosp_svc

FROM smsdss.BMH_PLM_PtAcct_V AS a INNER JOIN smsdss.BMH_PLM_PtAcct_Svc_V_Hold AS b  
     ON a.Pt_Key = b.Pt_Key AND a.Bl_Unit_Key = b.Bl_Unit_Key

WHERE b.Svc_Date BETWEEN '01/01/22' AND '08/31/22'

--    Renal Dialysis
AND a.Plm_Pt_Acct_Type = 'I'
--AND a.Pt_Type IN ('R')
AND b.Svc_Cd BETWEEN '05400000' AND '05499999'
and b.tot_chg_amt <>0



ORDER BY a.Pt_No ASC, b.Svc_Date ASC

