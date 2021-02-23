library(RDCOMClient)
library(LICHospitalR)

respiratory_vae_query() %>%
  respiratory_vae_tbl() %>%
  respiratory_vae_automation(
    .delete_file = TRUE
    , .email = ""
  )

respiratory_vae_query() %>%
  respiratory_vae_tbl() %>%
  save_to_excel(.file_name = "VAE")

geocode_discharges_automation()

weekly_psy_discharges_query() %>%
  weekly_psy_discharges_automation(
    .delete_file = TRUE
    , .email = ""
  )

code64_automation(
  .delete_file = TRUE
  , .email = c("")
)

duplicate_coded_cataracts_automation(
  .delete_file = TRUE
  , .email = ""
)

orsos_to_sproc_query() %>%
  orsos_to_sproc_tbl() %>%
  orsos_to_sproc_automation(
    .delete_file = TRUE
    , .email = c("")
  )

orsos_j_accounts_query() %>%
  orsos_j_accounts_automation(
    .delete_file = TRUE
    , .email = ""
  )

congenital_malformation_automation(
  .delete_file = TRUE
  , .email = ""
)

monthly_psy_admits_discharges_tbl() %>%
  monthly_psy_admits_discharges_automation(
    .delete_file = TRUE
    , .email = c("")
  )

monthly_trauma_tbl() %>%
  monthly_trauma_automation(
    .delete_file = TRUE
    , .email = ""
  )

myhealth_monthly_surgery_query() %>%
  myhealth_monthly_surgery_tbl() %>%
  myhealth_monthly_surgery_automation(
    .delete_file = TRUE
    , .email = c("")
  )

discharge_order_to_discharge_automation(
  .delete_file = TRUE
  , .email = c("")
)

inpatient_coding_lag_query() %>%
  inpatient_coding_lag_tbl() %>%
  inpatient_coding_lag_automation(
    .delete_file = TRUE
    , .email = ""
  )

infection_prevention_patient_days_query() %>%
  infection_prevention_patient_days_tbl() %>%
  infection_prevention_patient_days_automation(
    .delete_file = TRUE
      , .email = ""
  )

qec_cdi_automation(
  .delete_file = TRUE
  , .email = ""
)
