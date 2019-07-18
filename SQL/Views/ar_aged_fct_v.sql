USE [SMSPHDSSS0X0]
GO

/****** Object:  View [smsdss].[ar_aged_fct_v]    Script Date: 10/5/2018 3:32:21 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO

/* Fact Table View Name: smsdss.ar_aged_fct_v
   Description:          AR Aged Fact View
*/ 
ALTER view [smsdss].[ar_aged_fct_v] as select 
acct_age_day = f.acct_age_day,
acct_close_unit_ind_cd = f.acct_close_unit_ind_cd,
acct_prim_pyr_cd = f.acct_prim_pyr_cd,
acct_pyr2_cd = f.acct_pyr2_cd,
acct_pyr3_cd = f.acct_pyr3_cd,
acct_pyr4_cd = f.acct_pyr4_cd,
acct_sts = f.acct_sts,
acct_unit_key = f.acct_unit_key,
adm_date = f.adm_date,
ar_aged_ctrl_key = f.ar_aged_ctrl_key,
bl_unit_key = f.bl_unit_key,
cr_bal_ind_cd = f.cr_bal_ind_cd,
curr_pyr_cd = f.curr_pyr_cd,
drg_no = f.drg_no,
drg_vers = f.drg_vers,
dsch_disp = f.dsch_disp,
fc = f.fc,
fnl_bl_date = f.fnl_bl_date,
fnl_bl_ind_cd = f.fnl_bl_ind_cd,
hosp_svc = f.hosp_svc,
ip_fnl_bl_date = f.ip_fnl_bl_date,
iss_cd = f.iss_cd,
last_pay_acct_age_day = f.last_pay_acct_age_day,
last_pay_date = f.last_pay_date,
op_fnl_bl_date = f.op_fnl_bl_date,
orgz_cd = f.orgz_cd,
pers_addr_key = f.pers_addr_key,
prim_pract_no = f.prim_pract_no,
prin_dx_cd = f.prin_dx_cd,
prin_dx_icd10_cd = f.prin_dx_icd10_cd,
prin_dx_icd9_cd = f.prin_dx_icd9_cd,
prin_icd9_proc_cd = f.prin_icd9_proc_cd,
prin_proc_icd_cd = f.prin_proc_icd_cd,
prin_proc_icd10_cd = f.prin_proc_icd10_cd,
pt_type = f.pt_type,
pt_type_2 = f.pt_type_2,
reg_area_cd = f.reg_area_cd,
snapshot_date = f.snapshot_date,
src_sys_id = f.src_sys_id,
state_cd = f.state_cd,
std_cntry_cd = f.std_cntry_cd,
vst_date = f.vst_date,
vst_end_acct_age_day = f.vst_end_acct_age_day,
vst_end_ind_cd = f.vst_end_ind_cd,
vst_postal_cd = f.vst_postal_cd,
vst_type_cd = f.vst_type_cd,
vst_type_cd_2 = f.vst_type_cd_2,
net_rev = f.net_rev,
tot_adj_amt = f.tot_adj_amt,
tot_bal_amt = f.tot_bal_amt,
tot_chg_amt = f.tot_chg_amt,
fnl_bl_cnt = f.fnl_bl_cnt,
ended_vst_cnt = f.ended_vst_cnt,
closed_unit_cnt = f.closed_unit_cnt,
alt_net_rev = f.alt_net_rev,
pror_bd_wo_amt = f.pror_bd_wo_amt,
nrm_net_rev = f.nrm_net_rev,
plm_rev_ind = f.plm_rev_ind,
pt_id = f.pt_id,
acct_no = f.acct_no,
unit_seq_no = f.unit_seq_no,
pt_city = f.pt_city,
rpt_name = f.rpt_name,
iss_orgz_cd = f.iss_orgz_cd,
prin_dx_schm = f.prin_dx_schm,
prin_proc_schm = f.prin_proc_schm,
unit_cnt = 1,
billed_ar = f.tot_bal_amt * f.fnl_bl_cnt,
dsch_ar = f.tot_bal_amt * f.ended_vst_cnt,
closed_ar = f.tot_bal_amt * f.closed_unit_cnt,
credit_bal_ar = f.tot_bal_amt * (case when f.tot_bal_amt < 0 then 1 else 0 end),
rpt_tot_adj_amt = f.tot_adj_amt * -1,
rpt_net_rev = case when (select net_rev_schm from smsdss.rpt_schm_mstr) = 'NRM' then f.nrm_net_rev when (select net_rev_schm from smsdss.rpt_schm_mstr) = 'PLM' then (f.net_rev * f.plm_rev_ind) + (f.alt_net_rev * (1- f.plm_rev_ind)) else f.alt_net_rev end,
cr_bal_cnt = case when f.tot_bal_amt < 0 then 1 else 0 end,
pt_mne = substring(f.rpt_name,1,15),
dflt_measure = 0,
unit_no = right(f.unit_seq_no,2)
from smsdss.ar_aged_fct f
GO


