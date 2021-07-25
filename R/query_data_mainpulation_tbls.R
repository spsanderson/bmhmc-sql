#' Inpatient Coding Lag tibble
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' This function takes in the query [inpatient_coding_lag_query()] as the data
#' argument and augments the data so that it can be taken into the
#' [inpatient_coding_lag_automation()] function.
#'
#' @details
#' - Takes in [inpatient_coding_lag_query()] as the data argument.
#' - Returns a tibble that can be used in the [inpatient_coding_lag_automation()]
#' function.
#'
#' @param .data Data that you want to manipulate typically from [inpatient_coding_lag_query()]
#'
#' @examples
#' \dontrun{
#' library(tidyverse)
#'
#' inpatient_coding_lag_query() %>%
#'   inpatient_coding_lag_tbl()
#' }
#'
#' @return
#' A tibble
#'
#' @export
#'

inpatient_coding_lag_tbl <- function(.data) {

  # Check
  if(!is.data.frame(.data)) {
    stop(call. = FALSE,"(.data) is not a data.frame/tibble. Please supply.")
  }

  # * Get Data ----
  data_tbl <- tibble::as_tibble(.data)

  # * Manipulate ----
  coder_tbl <- data_tbl %>%
    dplyr::select(coder, lag) %>%
    dplyr::group_by(coder) %>%
    dplyr::summarise(
      count = dplyr::n()
      , avg_lag = base::round(base::mean(lag, na.rm = TRUE), 2)
    ) %>%
    dplyr::ungroup()

  gt_tbl <- data_tbl %>%
    dplyr::summarise(
      coder     = "Grand Totals"
      , count   = dplyr::n()
      , avg_lag = base::round(base::mean(lag, na.rm = TRUE), 2)
    )

  final_tbl <- base::rbind(coder_tbl, gt_tbl)

  # * Return ----
  return(final_tbl)

}

#' Monthly PSY Admit/Discharge tibble
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' Takes data from [monthly_psy_admits_query()] and [monthly_psy_discharges_query()]
#' and puts them inside of an excel workbook with data on different sheets.
#'
#' There are no parameters to this function, it takes in it directly the queries
#' internally.
#'
#' The [monthly_psy_admits_discharges_automation()] will internally handle this.
#'
#' @details
#' - Creates a sheet for the raw admit and discharge data
#' - Creates a sheet for distinct Admitted and Discharged MRN's
#' - Creates a sheet with pivot tables for Admited/Discharged financial grouping
#' (i.e. Medicare, Blue Cross)
#' - Creates a sheet a count of distinct Admitted and Discharged MRN's
#'
#' @examples
#' \dontrun{
#' monthly_psy_admits_discharges_tbl()
#' }
#'
#' @return
#' A java pointer to an excel workbook (or a list in the future)
#'
#' @export
#'

monthly_psy_admits_discharges_tbl <- function() {

  # Queries - gets raw data ----
  admits_tbl     <- LICHospitalR::monthly_psy_admits_query()
  discharges_tbl <- LICHospitalR::monthly_psy_discharges_query()

  # Admits FC
  admits_fc_pvt_tbl <- tidyquant::pivot_table(
    .data     = admits_tbl
    , .rows   = pyr_group2
    , .values = ~ tidyquant::COUNT(pyr_group2)
  ) %>%
    tibble::as_tibble() %>%
    purrr::set_names("Payer_Group","Count") %>%
    dplyr::arrange(desc(Count)) %>%
    dplyr::mutate_all(as.character)


  discharges_fc_pvt_tbl <- tidyquant::pivot_table(
    .data     = discharges_tbl
    , .rows   = pyr_group2
    , .values = ~ tidyquant::COUNT(pyr_group2)
  ) %>%
    tibble::as_tibble() %>%
    purrr::set_names("Payer_Group","Count") %>%
    dplyr::arrange(desc(Count)) %>%
    dplyr::mutate_all(as.character)

  # Distinct MRNs
  distinct_admits_mrn_tbl     <- dplyr::distinct(
    .data = admits_tbl
    , med_rec_no
    )

  distinct_discharges_mrn_tbl <- dplyr::distinct(
    .data = discharges_tbl
    , med_rec_no
    )

  # Distinct MRN counts
  admits_distinct <- admits_tbl %>%
    dplyr::select(med_rec_no) %>%
    dplyr::n_distinct() %>%
    tibble::as_tibble()

  discharges_distinct <- discharges_tbl %>%
    dplyr::select(med_rec_no) %>%
    dplyr::n_distinct() %>%
    tibble::as_tibble()

  # Make a list of tibbles *TO BE USED IN THE FUTURE*
  l <- list(
    admits_tbl
    , discharges_tbl
    , admits_fc_pvt_tbl
    , discharges_fc_pvt_tbl
    , distinct_admits_mrn_tbl
    , distinct_discharges_mrn_tbl
    , admits_distinct
    , discharges_distinct
    )

  # Create Excel File and add sheets
  # Make Workbook
  wb <- xlsx::createWorkbook(type = "xlsx")

  # Make data sheets
  admits_data      <- xlsx::createSheet(wb = wb, sheetName = "admits")
  admits_fc        <- xlsx::createSheet(wb = wb, sheetName = "admits_fin_class")
  admits_mrns      <- xlsx::createSheet(wb = wb, sheetName = "admit_mrns")
  admits_mrn_count <- xlsx::createSheet(wb = wb, sheetName = "amdit_mrn_count")

  disch_data      <- xlsx::createSheet(wb = wb, sheetName = "dsch")
  disch_fc        <- xlsx::createSheet(wb = wb, sheetName = "dsch_fin_class")
  disch_mrns      <- xlsx::createSheet(wb = wb, sheetName = "dsch_mrns")
  disch_mrn_count <- xlsx::createSheet(wb = wb, sheetName = "dsch_mrn_count")

  # Add data.frames to sheets
  xlsx::addDataFrame(x = admits_tbl, sheet = admits_data)
  xlsx::addDataFrame(x = admits_fc_pvt_tbl, sheet = admits_fc)
  xlsx::addDataFrame(x = distinct_admits_mrn_tbl, sheet = admits_mrns)
  xlsx::addDataFrame(x = admits_distinct, sheet = admits_mrn_count)

  xlsx::addDataFrame(x = discharges_tbl, sheet = disch_data)
  xlsx::addDataFrame(x = discharges_fc_pvt_tbl, sheet = disch_fc)
  xlsx::addDataFrame(x = distinct_discharges_mrn_tbl, sheet = disch_mrns)
  xlsx::addDataFrame(x = discharges_distinct, sheet = disch_mrn_count)

  # * Return ----
  return(wb)

}

#' ORSOS to SPROC Tibble
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' This function takes the data from [orsos_to_sproc_query()] and performs
#' the necessary manipulations before using [orsos_to_sproc_automation()]
#'
#' @details
#' - Expects the data from [orsos_to_sproc_query()] exactly
#'
#' @param .data The data from [orsos_to_sproc_query()]
#'
#' @examples
#' \dontrun{
#' library(tidyverse)
#'
#' orsos_to_sproc_query() %>%
#'   orsos_to_sproc_tbl()
#'
#' orsos_to_sproc_query() %>%
#'   orsos_to_sproc_tbl() %>%
#'   save_to_excel(.file_name = "orsos_to_sproc")
#' }
#'
#' @return
#' A tibble
#'
#' @export
#'

orsos_to_sproc_tbl <- function(.data) {

  # Checks
  if(!is.data.frame(.data)) {
    base::stop(call. = FALSE,"(.data) is not a data.frame/tibble. Please provide.")
  }

  # * Get Data ----
  data_tbl <- tibble::as_tibble(.data)

  # * Get provider table ----
  # provider_tbl <- LICHospitalR::pract_dim_v_query()

  # proc_date_tbl <- data_tbl %>%
  #   dplyr::select(encounter, proc_eff_date) %>%
  #   dplyr::mutate(proc_eff_date = as.character.Date(proc_eff_date)) %>%
  #   View()

  # * Manipulate ----
  data_tbl <- data_tbl %>%
    #dplyr::select(-proc_cd_prio, -pract_rpt_name) %>%
    dplyr::select(encounter, grouping) %>%
    dplyr::distinct(.keep_all = TRUE) %>%
    tidyr::pivot_wider(
      id_cols         = encounter #:resp_pty_cd
      , names_from    = grouping
      , values_from   = grouping
      , values_fill   = "NOT FOUND"
    ) %>%
    dplyr::filter(SPROC == "NOT FOUND")
    # dplyr::left_join(provider_tbl, by = c("resp_pty_cd" = "pract_no")) %>%
    # dplyr::arrange(encounter, resp_pty_cd) %>%
    # dplyr::group_by(encounter) %>%
    # dplyr::mutate(provider_number = dplyr::row_number()) %>%
    # dplyr::ungroup()

  # * Return ----
  return(data_tbl)

}

#' Monthly Trauma Tibble
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' Takes data from the queries
#' 1. [monthly_admit_trauma_query()], and
#' 2. [monthly_discharge_trauma_query()]
#' And then performs the necessary transformations on them to get them into one
#' excel file with two sheets. One for Admits and one for Discharges.
#'
#' @details
#' 1. Internally gets data from [monthly_admit_trauma_query()]
#' 2. Internally gets data from [monthly_discharge_trauma_query()]
#' 3. Transforms them into one excel file with two sheets that can be
#' written out to disk
#'
#' @examples
#' \dontrun{
#' monthly_trauma_tbl()
#' }
#'
#' @return
#' A java pointer to an excel workbook (or a list in the future)
#'
#' @export
#'

monthly_trauma_tbl <- function() {

  # * Queries ----
  admits_tbl     <- LICHospitalR::monthly_admit_trauma_query()
  discharges_tbl <- LICHospitalR::monthly_discharge_trauma_query()

  # Make a list of tibbles *TO BE USED IN THE FUTURE*
  l <- list(
    admits_tbl
    , discharges_tbl
  )

  # Create Excel File and add sheets
  # Make Workbook
  wb <- xlsx::createWorkbook(type = "xlsx")

  # Make data sheets
  admits_data <- xlsx::createSheet(wb = wb, sheetName = "admits")

  disch_data  <- xlsx::createSheet(wb = wb, sheetName = "dsch")

  # Add data.frames to sheets
  xlsx::addDataFrame(x = admits_tbl, sheet = admits_data)

  xlsx::addDataFrame(x = discharges_tbl, sheet = disch_data)

  # * Return
  return(wb)

}

#' MyHealth Monthly Surgery Tibble
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' This takes data in from the [myhealth_monthly_surgery_query()] and performs the
#' necessary manipulation/cleanup to get it ready to email out or use in conjuntion
#' with [save_to_excel()]
#'
#' @details
#' - Returns a tibble
#' - Expects data from the [myhealth_monthly_surgery_query()]
#'
#' @param .data The result of the [myhealth_monthly_surgery_query()]
#'
#' @examples
#' \dontrun{
#' library(tidyverse)
#'
#' myhealth_monthly_surgery_query() %>%
#'   myhealth_monthly_surgery_tbl()
#' }
#'
#' @return
#' A tibble
#'
#' @export
#'

myhealth_monthly_surgery_tbl <- function(.data) {

  # Checks
  if(!is.data.frame(.data)){
    stop(call. = FALSE, "(.data) is missing. Please supply.")
  }

  # * Get Data ----
  data_tbl <- tibble::as_tibble(.data)

  # * Manipulate ----
  data_tbl <- data_tbl %>%
    purrr::set_names(
      'ORSOS Case No',
      'DSS Case No',
      'ORSOS MD ID',
      'Provider Name',
      'ORSOS Room ID',
      'ORSOS Start Date',
      'Ent Proc Rm Time',
      'Leave Proc Rm Time',
      'Procedure',
      'Anes Start Date',
      'Anes Start Time',
      'Anes End Date',
      'Anes End Time',
      'Patient Type',
      'Adm Recovery Date',
      'Adm Recovery Time',
      'Leave Recovery Date',
      'Leave Recovery Time'
    ) %>%
    janitor::clean_names() %>%
    dplyr::mutate(
      orsos_start_date      = orsos_start_date %>% lubridate::ymd()
      , anes_start_date     = anes_start_date %>% lubridate::ymd()
      , anes_end_date       = anes_end_date %>% lubridate::ymd()
      , adm_recovery_date   = adm_recovery_date %>% lubridate::ymd()
      , leave_recovery_date = leave_recovery_date %>% lubridate::ymd()
    )

  # * Return ----
  base::return(data_tbl)

}

#' Patient Days for Infection Prevention Tibble
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' This takes data in from the [infection_prevention_patient_days_query()] and performs the
#' necessary manipulation/cleanup to get it ready to email out or use in conjunction
#' with [save_to_excel()]
#'
#' @details
#' - Returns a tibble
#' - Expects data from the [infection_prevention_patient_days_query()]
#'
#' @param .data The data that results from [infection_prevention_patient_days_query()]
#'
#' @examples
#' \dontrun{
#' library(tidyverse)
#'
#' infection_prevention_patient_days_query() %>%
#'   infection_prevention_patient_days_tbl()
#' }
#'
#' @return
#' An excel workbook object pointer
#'
#' @export
#'

infection_prevention_patient_days_tbl <- function(.data){
  # Checks
  if(!is.data.frame(.data)){
    stop(call. = FALSE, "(.data) is missing. Please supply.")
  }

  # * Get Data ----
  data_tbl <- tibble::as_tibble(.data)

  # * Manipulate ----
  data_tbl <- data_tbl %>%
    dplyr::select(
      pt_id
      , hosp_svc
      , nurs_sta
      , cen_date
      , cen_yr
      , cen_mo
      , tot_cen
      , attending_id
      , attending_name
      , hospitalist_private
      , hospitalist_atn_flag
      , private_atn_flag
      , adm_date
      , dsch_date
      , kick_out_flag
    ) %>%
    dplyr::group_by(pt_id, cen_date) %>%
    dplyr::mutate(
      rn = dplyr::with_order(
        order_by = cen_date
        , fun = dplyr::row_number
        , x = cen_date
      )
    ) %>%
    dplyr::ungroup() %>%
    dplyr::filter(kick_out_flag == 0) %>%
    dplyr::filter(rn == 1)

  summary_tbl <- data_tbl %>%
    dplyr::group_by(attending_id, attending_name) %>%
    dplyr::summarise(tot_cen = base::sum(tot_cen, na.rm = TRUE)) %>%
    dplyr::ungroup() %>%
    dplyr::arrange(attending_name) %>%
    dplyr::mutate(attending_name = stringr::str_to_title(attending_name))

  # Create Excel File and add sheets
  # Make Workbook
  wb <- xlsx::createWorkbook(type = "xlsx")

  # Make data sheets
  data_sheet    <- xlsx::createSheet(wb = wb, sheetName = "data")
  summary_sheet <- xlsx::createSheet(wb = wb, sheetName = "summary_data")

  # Add data.frames to sheets
  xlsx::addDataFrame(x = data_tbl, sheet = data_sheet)
  xlsx::addDataFrame(x = summary_tbl, sheet = summary_sheet)

  # * Return ----
  return(wb)

}

#' Respiratory VAE Tibble
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' This takes data from the [respiratory_vae_query()] and performs the necessary
#' calculations to see if a possible VAE has occurred.
#'
#' @details
#' - Returns a tibble
#' - Expects [respiratory_vae_query()] as the data argument
#' - Makes the calculations according to the CDC NHSN VAE Calculator
#' \url{https://nhsn.cdc.gov/VAECalculator/vaecalc_v7.html}
#'
#' @seealso
#'
#' This one works better, more concise and works in 3.6.x and 4.0.x
#' \url{https://stackoverflow.com/questions/26553638/calculate-elapsed-time-since-last-event}
#'
#' VAE Calculator (requires javascript)
#' \url{https://nhsn.cdc.gov/VAECalculator/vaecalc_v7.html}
#'
#' Adding data.table to Depends: issue
#' \url{https://stackoverflow.com/questions/27980835/r-data-table-works-in-direct-call-but-same-function-in-a-package-fails}
#'
#' @param .data The data passed in from [respiratory_vae_query()]
#'
#' @examples
#' \dontrun{
#' respiratory_vae_query() %>%
#'   respiratory_vae_tbl()
#'
#' respiratory_vae_query() %>%
#'   respiratory_vae_tbl() %>%
#'   save_to_excel(.file_name = "respiratory_vae")
#' }
#'
#' @return
#' A tibble
#'
#' @export
#'

respiratory_vae_tbl <- function(.data) {

  # Checks
  if(!is.data.frame(.data)){
    stop(call. = FALSE, "(.data) is missing. Please supply.")
  }

  # * Get Data ----
  data_tbl <- tibble::as_tibble(.data)

  # * Manipulate ----
  data_tbl <- data_tbl %>%
    janitor::clean_names() %>%
    dplyr::mutate(perf_date = lubridate::as_date(perf_date)) %>%
    dplyr::mutate(val_clean = dplyr::case_when(
      !is.na(dsply_val) ~ as.numeric(dsply_val)
      , TRUE ~ NA_real_
    ))

  data_long_tbl <- data_tbl %>%
    dplyr::select(
      episode_no
      , obsv_cd
      , obsv_cd_name
      , obsv_user_id
      , perf_date
      , val_clean
    )

  # * Split Tables ----
  fi02_tbl <- data_long_tbl %>%
    dplyr::filter(obsv_cd == "A_BMH_VFFiO2") %>%
    dplyr::filter(!is.na(val_clean)) %>%
    dplyr::filter(val_clean >= 10)

  peep_tbl <- data_long_tbl %>%
    dplyr::filter(obsv_cd != "A_BMH_VFFiO2") %>%
    dplyr::filter(!is.na(val_clean))

  # * Peep Stability ----
  peep_tbl_a <- peep_tbl %>%
    dplyr::group_by(
      episode_no
      , obsv_cd
      , obsv_cd_name
      , perf_date
    ) %>%
    dplyr::summarise(min_val = base::min(val_clean)) %>%
    dplyr::mutate(peep_equivalent = dplyr::case_when(
      min_val <= 5 ~ 5,
      TRUE ~ min_val
    )) %>%
    dplyr::ungroup() %>%
    dplyr::select(-obsv_cd, -min_val)

  peep_final_tbl <- peep_tbl_a %>%
    dplyr::mutate(
      stable_flag =  dplyr::case_when(
        (peep_equivalent > 5) &
          (dplyr::lag(peep_equivalent, n = 1) <= 5) &
          (dplyr::lag(peep_equivalent, n = 2) <= 5) ~ 0,
        TRUE ~ 1
      )
    ) %>%
    dplyr::select(
      episode_no
      , obsv_cd_name
      , perf_date
      , peep_equivalent
      , stable_flag
    )

  # * Fi02 Stability ----
  fi02_tbl_a <- fi02_tbl %>%
    dplyr::group_by(
      episode_no
      , obsv_cd
      , obsv_cd_name
      , perf_date
    ) %>%
    dplyr::summarise(min_val = base::min(val_clean)) %>%
    dplyr::ungroup() %>%
    dplyr::select(-obsv_cd)

  fi02_final_tbl <- fi02_tbl_a %>%
    dplyr::group_by(episode_no) %>%
    dplyr::mutate(row_id = dplyr::row_number()) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(
      exclude_row = dplyr::case_when(
        row_id <= 2 ~ 1,
        TRUE ~ 0
      )
    ) %>%
    dplyr::mutate(
      l_1 = dplyr::lag(min_val, n = 1, default = NA_real_)
      , l_2 = dplyr::lag(min_val, n = 2, default = NA_real_)
    ) %>%
    dplyr::mutate(
      delta_a = min_val - l_1
      , delta_b = min_val - l_2
    ) %>%
    dplyr::mutate(
      stable_flag = dplyr::case_when(
        (
          (delta_a >= 20) &
            (delta_b >= 20) &
            row_id >= 3
        )~ 0
        , TRUE ~ 1
      )
    ) %>%
    dplyr::select(
      episode_no
      , obsv_cd_name
      , perf_date
      , min_val
      , stable_flag
    )

  # * Join Tbls ----
  joined_tbl <- fi02_final_tbl %>%
    dplyr::left_join(
      y = peep_final_tbl
      , by = c(
        "episode_no" = "episode_no"
        , "perf_date" = "perf_date"
      )
    ) %>%
    dplyr::select(
      episode_no
      , perf_date
      , min_val
      , stable_flag.x
      , peep_equivalent
      , stable_flag.y
    ) %>%
    purrr::set_names(
      "Episode_No"
      , "Perf_Date"
      , "Fi02_Min_Val"
      , "Fi02_Stability"
      , "Peep_Min_Val"
      , "Peep_Stability"
    )

  pre_vae_tbl <- joined_tbl %>%
    dplyr::select(
      Episode_No
      , Perf_Date
      , Fi02_Min_Val
      , Fi02_Stability
      , Peep_Min_Val
      , Peep_Stability
    ) %>%
    dplyr::mutate(
      fl1   =  dplyr::lag(Fi02_Stability, n = 1, default = NA_real_)
      , fl2 =  dplyr::lag(Fi02_Stability, n = 2, default = NA_real_)
    ) %>%
    dplyr:: mutate(
      fl_sum = fl1 + fl2
    ) %>%
    dplyr:: mutate(
      pl1   =  dplyr::lag(Peep_Stability, n = 1, default = NA_real_)
      , pl2 =  dplyr::lag(Peep_Stability, n = 2, default = NA_real_)
    ) %>%
    dplyr::mutate(
      pl_sum = pl1 + pl2
    ) %>%
    dplyr::select(-fl1,-fl2,-pl1,-pl2) %>%
    dplyr::mutate(
      sum = fl_sum + pl_sum
    ) %>%
    tibble::rowid_to_column(var = "row_id") %>%
    dplyr::mutate(
      VAE_Flag =  dplyr::case_when(
        dplyr::lead(sum, n = 2) %in% c(2,3) &
          dplyr::lead(sum, n = 1) == 3 &
          sum == 4 ~ 'VAE'
        , TRUE ~ 'No-VAE'
      )
    ) %>%
    dplyr::select(-fl_sum, -pl_sum, -sum)

  tst <- pre_vae_tbl %>%
    dplyr::group_by(Episode_No) %>%
    dplyr::mutate(last_event_flag = dplyr::case_when(
      VAE_Flag == "VAE" ~ 1,
      TRUE ~ 0
    ))

  dt <- tst %>%
    dplyr::mutate(tmpG = cumsum(c(FALSE, as.logical(diff(last_event_flag))))) %>%
    dplyr::group_by(Episode_No) %>%
    dplyr::mutate(tmp_a = c(0, diff(Perf_Date)) * !last_event_flag,
                  tmp_b = c(diff(Perf_Date), 0) * !last_event_flag) %>%
    dplyr::group_by(tmpG) %>%
    dplyr::mutate(tmp_a = as.integer(tmp_a)
                  , tmp_b = as.integer(tmp_b)) %>%
    dplyr::mutate(tae = cumsum(tmp_a),
                  tbe = rev(cumsum(rev(tmp_b)))) %>%
    dplyr::ungroup() %>%
    dplyr::select(-c(tmp_a, tmp_b, tmpG, tbe))


  final_tbl <- dt %>%
    dplyr::mutate(VAE_Flag_Final = dplyr::case_when(
      ((VAE_Flag == "VAE") & (tae > 13)) ~ "VAE-Positive",
      ((VAE_Flag == "VAE") & (is.na(tae))) ~ "VAE-Positive",
      TRUE ~ "VAE-Negative"
    )) %>%
    dplyr::select(
      Episode_No,
      Perf_Date,
      Fi02_Min_Val,
      Peep_Min_Val,
      VAE_Flag_Final
    )

  # * Return ----
  return(final_tbl)

}

#' Readmit Psych To Psych Tibble
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' This function will take the results of the [readmit_psy_to_psy_query()] and
#' ensure that the results are in a `tibble`
#'
#' @details
#' - Takes in the data from [readmit_psy_to_psy_query()]
#'
#' @param .data The data you want to pass, namely [readmit_psy_to_psy_query()]
#'
#' @examples
#' \dontrun{
#' readmit_psy_to_psy_query() %>%
#'   readmit_psy_to_psy_tbl()
#' }
#'
#' @return
#' A tibble
#'
#' @export
#'

readmit_psy_to_psy_tbl <- function(.data){

  # Checks
  if(!is.data.frame(.data)){
    stop(call. = FALSE, "(.data) is missing. Please supply.")
  }

  # * Get Data ----
  data_tbl <- tibble::as_tibble(.data)

  # * Manipulate ----
  data_tbl <- data_tbl %>%
    janitor::clean_names()

  # * Return ----
  return(data_tbl)

}
