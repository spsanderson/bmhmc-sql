# Lib Load ----
library(RDCOMClient)
library(LICHospitalR)

# Daily ----
# * Wound Care ----
source("S:/Global Finance/1 REVENUE CYCLE/Steve Sanderson II/Code/R/Automations/wound_care_daily_batch.R")

# * Respiratory Email ----
respiratory_vae_query() %>%
  respiratory_vae_tbl() %>%
  respiratory_vae_automation(
    .delete_file = TRUE
    , .email = "ELennon@licommunityhospital.org"
  )

# * Respiratory File Save ----
respiratory_vae_query() %>%
  respiratory_vae_tbl() %>%
  save_to_excel(.file_name = "VAE")

# * Geocode ----
geocode_discharges_automation()

# Weekly ----
# * Weekly PSY Discharges ----
weekly_psy_discharges_query() %>%
  weekly_psy_discharges_automation(
    .delete_file = TRUE
    , .email = "EMullally@LICommunityHospital.org"
  )

# * Code 64 ----
code64_automation(
  .delete_file = TRUE
  , .email = c("EMullally@LICommunityHospital.org;DBabich@LICommunityHospital.org")
)

# * Duplicate Cataracts ----
duplicate_coded_cataracts_automation(
  .delete_file = TRUE
  , .email = "LProsper@licommunityhospital.org"
)

# ORSOS ----
# * ORSOS to SPROC ----
orsos_to_sproc_query() %>%
  orsos_to_sproc_tbl() %>%
  orsos_to_sproc_automation(
    .delete_file = TRUE
    , .email = c("LProsper@licommunityhospital.org;MAki@LICommunityHospital.org")
  )

# * ORSOS J Accounts ----
orsos_j_accounts_query() %>%
  orsos_j_accounts_automation(
    .delete_file = TRUE
    , .email = "CAKeenan@LICommunityHospital.org"
  )

# * Experian Return to DSS ----
source("S:/Global Finance/1 REVENUE CYCLE/Steve Sanderson II/Code/R/Automations/exp_return_file_to_dss.R")

# Monthly ----
# * Congenital Malformation ----
congenital_malformation_automation(
  .delete_file = TRUE
  , .email = "LProsper@LICommunityHospital.org"
)

# * PSY Admits and Discharges ----
monthly_psy_admits_discharges_tbl() %>%
  monthly_psy_admits_discharges_automation(
    .delete_file = TRUE
    , .email = c("KShaughness@LICommunityHospital.org;ESaporito@LICommunityHospital.org")
  )

# * TRAUMA ----
monthly_trauma_tbl() %>%
  monthly_trauma_automation(
    .delete_file = TRUE
    , .email = "EHuang@LICommunityHospital.org"
  )

# * MyHealth Sx ----
myhealth_monthly_surgery_query() %>%
  myhealth_monthly_surgery_tbl() %>%
  myhealth_monthly_surgery_automation(
    .delete_file = TRUE
    , .email = c("JPiscitelli@LICommunityHospital.org;WBayer@LICommunityHospital.org")
  )

# * Discharge Order to Discharge ----
discharge_order_to_discharge_automation(
  .delete_file = TRUE
  , .email = c("JBaranowski-Guido@LICommunityHospital.org;MPontecorvo@LICommunityHospital.org")
)

# * IP Coding Lag ----
inpatient_coding_lag_query() %>%
  inpatient_coding_lag_tbl() %>%
  inpatient_coding_lag_automation(
    .delete_file = TRUE
    , .email = "LProsper@LICommunityHospital.org"
  )

# * Infection Prevention ----
infection_prevention_patient_days_query() %>%
  infection_prevention_patient_days_tbl() %>%
  infection_prevention_patient_days_automation(
    .delete_file = TRUE
      , .email = "DVirgil@LICommunityHospital.org"
  )

# * CDI QEC ----
qec_cdi_automation(
  .delete_file = TRUE
  , .email = "PMcKenna@LICommunityHospital.org"
)

# * Readmits PSY to PSY ----
readmit_psy_to_psy_query() %>%
  readmit_psy_to_psy_tbl() %>%
  readmit_psy_to_psy_automation(
    .delete_file = TRUE
    , .email = "ESaporito@LICommunityHospital.org"
  )
