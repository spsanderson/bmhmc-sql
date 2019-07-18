select a.pt_no,
a.Med_Rec_No,
a.Adm_Date,
a.User_Pyr1_Cat,
a.Pyr1_Co_Plan_Cd,
a.tot_chg_amt as 'Tot_Chgs',
c.nurs_sta,
c.nurs_Sta_from


from smsdss.bmh_plm_ptacct_v as a LEFT OUTER JOIN smsmir.mir_actv as b
ON a.Pt_No=b.pt_id AND A.unit_seq_no=b.unit_seq_no
LEFT OUTER JOIN smsmir.mir_cen_hist as c
ON CAST(a.pt_no as int)=CAST(c.episode_no as int) AND c.cng_type='R'

where b.actv_cd = '04700035'
AND b.actv_dtime BETWEEN '01/01/2015' AND '09/30/2015'
and a.Plm_Pt_Acct_Type <> 'I'
