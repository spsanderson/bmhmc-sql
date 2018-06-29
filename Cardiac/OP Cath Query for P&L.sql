SELECT user_pyr1_cat,
Pt_No,
Pt_Name,
Pt_Age,
Pt_Sex,
Pt_Zip_Cd,
Med_Rec_No,
fc, 
pt_type,
hosp_svc,
Adm_Date,
Adm_Dr_No,
--b.pract_rpt_name,
e.UserDataText as 'Adm_Dr_Name',
--Atn_Dr_No,
--c.pract_rpt_name,
f.UserDataText AS 'Referring_Dr_Name',
prin_dx_cd,
d.clasf_desc,
Pyr1_Co_Plan_Cd,
Pyr2_Co_Plan_Cd,
Pyr3_Co_Plan_Cd,
tot_chg_amt,
g.tot_pymts_w_pip,
tot_adj_amt,
Tot_Amt_Due,
bd_wo_date,
Alt_Bd_WO_Amt


FROM smsdss.BMH_PLM_PtAcct_V as a LEFT OUTER JOIN smsmir.mir_pract_mstr as b
ON a.Adm_Dr_No=b.pract_no AND b.src_sys_id = '#PASS0X0'
LEFT OUTER JOIN smsmir.mir_pract_mstr as c
ON a.Atn_Dr_No=c.pract_no AND c.src_sys_id = '#PASS0X0'
LEFT OUTER JOIN smsmir.mir_clasf_mstr as d
ON a.prin_dx_cd=d.clasf_cd
LEFT OUTER JOIN smsdss.BMH_UserTwoFact_V as e
ON a.PtNo_Num=e.PtNo_Num AND e.UserDataKey='18'--Adm Dr Non-Staff
LEFT OUTER JOIN smsdss.BMH_UserTwoFact_V as f
ON a.PtNo_Num=f.PtNo_Num AND f.UserDataKey='455' --Ref Dr Non-Staff
LEFT OUTER JOIN smsdss.c_tot_pymts_w_pip_v as g
ON a.Pt_No=g.pt_id AND a.pt_id_start_dtime=g.pt_id_start_dtime AND a.unit_seq_no=g.unit_Seq_no


WHERE a.tot_chg_amt > '0'
AND dsch_Date BETWEEN '01/01/2018' AND '04/30/2018'--GETDATE()
AND Plm_Pt_Acct_Type='O'
AND a.Pt_No IN 

(SELECT DISTINCT(Pt_id)
fROM smsmir.mir_actv
WHERE LEFT(actv_cd,3)='070'
AND actv_dtime BETWEEN '01/01/2018' AND '04/30/2018'
)

ORDER BY adm_date
