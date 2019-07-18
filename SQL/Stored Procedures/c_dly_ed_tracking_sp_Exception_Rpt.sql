select rpt_name, pt_id, episode_no, vst_id, med_rec_no, preadm_pt_id, from_file_ind, hosp_svc, 
census_svc, hosp_svc_from, pt_type, pt_type_from, reg_dtime, adm_dtime, resp_pty, cng_type, case_sts,
vst_type_cd, ca_sts_desc, no_1t_cngs, pt_sts_xfer_ind, prin_dx_cd, clin_acct_type, adm_pract_no,
dsch_disp, adm_dr_name, tot_bal_amt, tot_adj_amt, tot_chg_amt, prim_pract_no, attend_dr_name, er_level, er_vst_qty,
er_level, er_vst_qty, er_vst_chgs, sent_to_avia_date, chief_complaint, wlkout_qty, walkout_ind
from smsdss.c_er_tracking_test
--where med_rec_no = ''
--order by rpt_name, episode_no

except

select rpt_name, pt_id, episode_no, vst_id, med_rec_no, preadm_pt_id, from_file_ind, hosp_svc, 
census_svc, hosp_svc_from, pt_type, pt_type_from, reg_dtime, adm_dtime, resp_pty, cng_type, case_sts,
vst_type_cd, ca_sts_desc, no_1t_cngs, pt_sts_xfer_ind, prin_dx_cd, clin_acct_type, adm_pract_no,
dsch_disp, adm_dr_name, tot_bal_amt, tot_adj_amt, tot_chg_amt, prim_pract_no, attend_dr_name, er_level, er_vst_qty,
er_level, er_vst_qty, er_vst_chgs, sent_to_avia_date, chief_complaint, wlkout_qty, walkout_ind
from smsdss.c_er_tracking
--where med_rec_no = ''
order by rpt_name, episode_no;