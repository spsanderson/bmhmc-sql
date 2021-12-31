
# Lib Load ----------------------------------------------------------------

library(readxl)
library(tidyverse)
library(odbc)
library(DBI)
library(lubridate)
library(healthyR)
library(timetk)
library(sqldf)

# data --------------------------------------------------------------------

raw_bench_tbl <- readxl::read_excel(
  path = "00_Data/xsolis_ip_cls_score_detail_2021_01_through_09.xlsx"
)

base::colnames(raw_bench_tbl) <- c(
  "account","dashboard_url","entity_name","payer_description",
  "location_code","last_status","mel_last","discharge_disposition",
  "admission_dtime","attending_provider","discharge_dtime",
  "los","los_from_ip_status","avg_max_cls"
)


data_tbl <- raw_bench_tbl %>%
  dplyr::slice(2:(dplyr::n() - 1)) %>%
  dplyr::mutate(dplyr::across(contains("_dtime"), lubridate::mdy_hms)) %>%
  dplyr::mutate(dplyr::across(where(is.character), stringr::str_squish)) %>%
  dplyr::mutate(
    avg_max_cls        = as.numeric(avg_max_cls),
    los                = as.numeric(los),
    los_from_ip_status = as.numeric(los_from_ip_status)
  ) %>%
  dplyr::mutate(
    attending_provider = stringr::str_replace_all(
      attending_provider, "\\."," "
      ) %>%
      stringr::str_squish()
  ) %>%
  dplyr::mutate(
    status_time_diff = round(lubridate::dminutes(los - los_from_ip_status), 2)
  ) %>%
  dplyr::mutate(ip_status_dtime = admission_dtime + status_time_diff) %>%
  dplyr::mutate(last_status = stringr::str_replace_all(
      last_status, "-", ""
    ) %>%
      stringr::str_to_title()
  ) %>%
  dplyr::mutate(location_code = forcats::as_factor(location_code)) %>%
  dplyr::mutate(
    payer_description = stringr::str_to_upper(payer_description) %>%
      forcats::as_factor()
  )

start_date <- min(data_tbl$admission_dtime, data_tbl$discharge_dtime)
end_date   <- max(data_tbl$admission_dtime, data_tbl$discharge_dtime)

date_seq <- timetk::tk_make_timeseries(
  start_date = "2021-01-01",
  end_date   = "2021-09-30",
  by         = "day"
) %>%
  tibble::as_tibble() %>%
  purrr::set_names("date_col") %>%
  dplyr::mutate(date_col = as.Date(date_col))

ts_tbl <- data_tbl %>%
  dplyr::select(
    account, admission_dtime, discharge_dtime, avg_max_cls
  ) %>%
  dplyr::mutate(admission_dtime = as.Date(admission_dtime)) %>%
  dplyr::mutate(discharge_dtime = as.Date(discharge_dtime))

max_cls_tbl <- sqldf::sqldf(
  "
  SELECT *
  FROM date_seq AS A
  LEFT JOIN ts_tbl AS B
  ON B.admission_dtime <= A.date_col
    AND B.discharge_dtime >= A.date_col
  "
) %>%
  tibble::as_tibble() %>%
  filter(
    !if_all(.cols = account:avg_max_cls, .fns = is.na)
  )

max_cls_summary_tbl <- max_cls_tbl %>%
  timetk::summarise_by_time(
    .date_var = date_col,
    .by = "day",
    avg_max_cls = round(mean(avg_max_cls, na.rm = TRUE), 2),
    n = dplyr::n()
  ) %>%
  timetk::filter_by_time(
    .date_var = date_col,
    .end_date = "2021-09-23"
  )

# Save Data ---------------------------------------------------------------

write_rds(
  x = data_tbl,
  file = "00_Data/data_tbl.RDS"
)

write_rds(
  x = date_seq,
  file = "00_Data/date_seq.RDS"
)

write_rds(
  x = max_cls_tbl,
  file = "00_Data/max_cls_tbl.RDS"
)

write_rds(
  x = max_cls_summary_tbl,
  file = "00_Data/max_cls_summary_tbl.RDS"
)
