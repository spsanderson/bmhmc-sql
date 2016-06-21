SELECT pt_no,
pt_type,
hosp_svc,
adm_date,
tot_chg_amt




FROM smsdss.BMH_PLM_PtAcct_V

where hosp_svc='PUL'
and Adm_Date between '05/01/2016' and '05/08/16'