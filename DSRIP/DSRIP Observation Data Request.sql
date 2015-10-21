SELECT a.med_Rec_no as 'MRN #',
CASE
WHEN LEFT(pyr1_co_plan_cd,1)='W'THEN rtrim(ISNULL(c.pol_no,'')) + ltrim(rtrim(ISNULL(c.grp_no,'')) )
ELSE ''
END as 'CIN #',
a.pt_no,
CONVERT(date,a.Pt_Birthdate,101) as 'DOB',
b.postal_cd as 'Zip Code',
b.nhs_id_no,
h.vst_start_dtime as 'Arrival_Date_Time',
a.Dsch_DTime,
i.pyr_name as 'Primary_Payor',
CASE

WHEN LEFT(a.pyr1_co_plan_cd,1)='B' THEN c.subscr_ins_grp_id
WHEN a.pyr1_co_plan_Cd IN ('E18','E28') THEN c.subscr_ins_grp_id

ELSE rtrim(ISNULL(c.pol_no,'')) + ltrim(rtrim(ISNULL(c.grp_no,''))) 
END as 'Primary_Payor_ID',
j.pyr_name as 'Secondary Payor',
CASE

WHEN LEFT(a.pyr2_co_plan_cd,1)='B' THEN d.subscr_ins_grp_id
WHEN a.pyr2_co_plan_Cd IN ('E18','E28') THEN d.subscr_ins_grp_id

ELSE rtrim(ISNULL(d.pol_no,'')) + ltrim(rtrim(ISNULL(d.grp_no,''))) 
END as 'Secondary_Payor_ID',
a.pyr3_co_plan_Cd as 'Tertiary Payor',
CASE

WHEN LEFT(a.pyr3_co_plan_cd,1)='B' THEN e.subscr_ins_grp_id
WHEN a.pyr3_co_plan_Cd IN ('E18','E28') THEN e.subscr_ins_grp_id

ELSE rtrim(ISNULL(e.pol_no,'')) + ltrim(rtrim(ISNULL(e.grp_no,''))) 
END as 'Tertiary_Payor_ID',
a.Atn_Dr_No,
f.pract_rpt_name,
f.npi_no,
g.spclty_cd_Desc,
'Medical Observation'





FROM smsdss.BMH_PLM_PtAcct_V a left outer join smsmir.mir_pt b
ON a.Pt_No=b.pt_id
left outer join smsmir.mir_pyr_plan c
ON a.Pt_No=c.pt_id and a.Pyr1_Co_Plan_Cd = c.pyr_cd
left outer join smsmir.mir_pyr_plan d
ON a.Pt_No=d.pt_id and a.Pyr2_Co_Plan_Cd = d.pyr_cd
left outer join smsmir.mir_pyr_plan e
ON a.Pt_No=e.pt_id and a.Pyr3_Co_Plan_Cd = e.pyr_Cd
left outer join smsmir.mir_pract_mstr f
ON a.Atn_Dr_No=f.pract_no and f.src_sys_id='#PASS0X0'
left outer join smsdss.pract_spclty_mstr g
ON f.spclty_cd1=g.spclty_cd and g.src_sys_id = '#PASS0X0'
left outer join smsmir.mir_vst h
ON a.Pt_No=h.pt_id
left outer join smsmir.mir_pyr_mstr i
ON a.pyr1_co_plan_cd=i.pyr_cd
left outer join smsmir.mir_pyr_mstr j
ON a.Pyr2_Co_Plan_Cd=j.pyr_cd
left outer join smsmir.mir_pyr_mstr k
on a.Pyr3_Co_Plan_Cd=k.pyr_cd


WHERE a.user_pyr1_Cat IN ('WWW','III')
and a.hosp_svc='OBV'
AND a.Pt_No IN

(

select distinct(pt_id)


from smsmir.mir_actv

where actv_cd ='04700019'
and chg_tot_amt > '0'
and hosp_svc = 'OBV'
and actv_dtime BETWEEN '2015-04-01 00:00:00.000' AND '2015-09-30 23:59:59.000'

)
