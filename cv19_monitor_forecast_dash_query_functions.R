# Queries ----
# Total Daily ED Visits
tot_ed_visits_daily_query <- function() {
  
  # * Connect to DSS ----
  db_conn <- db_connect()
  
  # * Query ----
  query <- DBI::dbGetQuery(
    conn = db_conn
    , statement = base::paste0(
      "
      SELECT Arrival AS [Arrival_Date]
      , COUNT(ACCOUNT) AS [visit_Count]
      
      FROM [SQL-WS\\REPORTING].[WellSoft_Reporting].[dbo].[c_Wellsoft_Rpt_tbl]
      
      WHERE ARRIVAL >= '2010-01-01'
      AND ARRIVAL < DATEADD(DAY, DATEDIFF(DAY, 0, GETDATE()), 0)
      AND TIMELEFTED != '-- ::00'
      AND ARRIVAL != '-- ::00'
      
      GROUP BY ARRIVAL 
      "
    )
  )
  
  # * DB Disconnect ----
  db_disconnect(.connection = db_conn)
  
  # * Return ----
  return(query)
  
}

tot_ed_covid_visits_daily_query <- function() {
  
  # * Connect to DSS ----
  db_conn <- db_connect()
  
  # * Query ----
  query <- DBI::dbGetQuery(
    conn = db_conn
    , statement = base::paste0(
      "
      SELECT CAST(arrival AS DATE) AS [date_col]
      , COUNT(*) AS [value]
      FROM smsdss.c_ed_visits_for_covid_tbl
      GROUP BY CAST(ARRIVAL AS DATE)
      "
    )
  )
  
  # * DB Disconnect ----
  db_disconnect(.connection = db_conn)
  
  # * Return ----
  return(query)
  
}

# New York State Statewide COVID-19 Testing
# This dataset includes information on the number of tests of individuals 
# for COVID-19 infection

get_nys_cv19_data <- function() {
  
  # * URL ----
  url = "https://health.data.ny.gov/api/views/xdss-u53e/rows.csv?accessType=DOWNLOAD&bom=true&format=true"
  
  # * Destfile ----
  destfile = "00_Data/nys_data/"
  
  # * Return ----
  download.file(
    url = url
    , destfile = base::paste0(destfile,"/ny_covid_data.csv")
    )

}

get_hhs_cv19_hospital_latest_data <- function() {
  # * URL ----
  url = "https://healthdata.gov/node/3281086/download"
  
  # * Destfile ----
  destfile = "00_Data/hhs_data/hhs_hospital_latest_data.csv"
  
  # * Return ----
  download.file(url = url, destfile = destfile)
  
}

get_hhs_cv19_hospital_ts_data <- function() {
  # Webpage https://healthdata.gov/dataset/covid-19-reported-patient-impact-and-hospital-capacity-state
  
  # * URL ---- https://healthdata.gov/node/3565481/download
  # * URL ----
  url = "https://healthdata.gov/node/3565481/download"
  
  # * Destfile ----
  destfile = "00_Data/hhs_data/hhs_hospital_data.csv"
  
  # * Return ----
  download.file(url = url, destfile = destfile)
  
}

# Get test results Detect/Not-Detect Records from DSS
get_test_results_query <- function(){
  
  # * Connect to DSS ----
  db_conn <- db_connect()
  
  # * Query ----
  query <- DBI::dbGetQuery(
    conn = db_conn
    , statement = base::paste0(
      "
      SELECT Result_DTime
      , PTNO_NUM
      , RESULT_CLEAN
      FROM smsdss.c_covid_extract_tbl
      WHERE RESULT_CLEAN IN ('DETECTED','NOT-DETECTED')
      "
    )
  )
  
  # * DB Disconnect ----
  db_disconnect(.connection = db_conn)
  
  # * Return ----
  return(query)
  
}

# Total Admitted and COVID Positive
tot_adm_covid_pos_query <- function(){
  
  # * Connect to DSS ----
  db_conn <- db_connect()
  
  # * Query ----
  query <- DBI::dbGetQuery(
    conn = db_conn
    , statement = base::paste0(
      "
      SELECT CAST(Run_DateTime AS DATE) AS [date_col]
      , COUNT(*) AS [value]
      FROM smsdss.c_tot_adm_covid_pos_tbl
      GROUP BY CAST(Run_DateTime AS DATE)
      ORDER BY CAST(Run_DateTime AS DATE)
      "
    )
  ) %>%
    tibble::as_tibble()
  
  # * DB Disconnect ----
  db_disconnect(.connection = db_conn)
  
  # * Return ----
  return(query)
  
}

# Total Admitted and COVID Suspect
tot_adm_covid_sus_query <- function(){
  
  # * Connect to DSS ----
  db_conn <- db_connect()
  
  # * Query ----
  query <- DBI::dbGetQuery(
    conn = db_conn
    , statement = base::paste0(
      "
      SELECT CAST(Run_DateTime AS DATE) AS [date_col]
      , COUNT(*) AS [value]
      FROM smsdss.c_tot_adm_covid_suspect_tbl
      GROUP BY CAST(Run_DateTime AS DATE)
      ORDER BY CAST(Run_DateTime AS DATE)
      "
    )
  ) %>%
    tibble::as_tibble()
  
  # * DB Disconnect ----
  db_disconnect(.connection = db_conn)
  
  # * Return ----
  return(query)
  
}

# ALOS COVID Positive Patients Discharged Yesterday Query
covid_pos_dsch_yday_alos_query <- function(){
  
  # * Connect to DSS ----
  db_conn <- db_connect()
  
  # * Query ----
  query <- DBI::dbGetQuery(
    conn = db_conn
    , statement = base::paste0(
      "
      SELECT Run_DateTime AS [date_col]
      , DATEDIFF(DAY, Adm_Dtime, DC_DTime) AS [value]
      FROM smsdss.c_tot_dsch_yday_covid_pos_tbl
      ORDER BY Run_DateTime
      "
    )
  ) %>%
    tibble::as_tibble()
  
  # * DB Disconnect ----
  db_disconnect(.connection = db_conn)
  
  # * Return ----
  return(query)
  
}

# ALOS COVID Positive Patients In House Query
covid_pos_inhouse_alos_query <- function(){
  
  # * Connect to DSS ----
  db_conn <- db_connect()
  
  # * Query ----
  query <- DBI::dbGetQuery(
    conn = db_conn
    , statement = base::paste0(
      "
      SELECT Run_DateTime AS [date_col]
      , DATEDIFF(DAY, Adm_Dtime, CAST(GETDATE() AS DATE)) AS [value]
      FROM SMSDSS.c_tot_adm_covid_pos_tbl
      ORDER BY Run_DateTime
      "
    )
  ) %>%
    tibble::as_tibble()
  
  # * DB Disconnect ----
  db_disconnect(.connection = db_conn)
  
  # * Return ----
  return(query)
  
}

# CV+ patients who have never been in the ICU query
cv_pos_inhouse_no_icu_query <- function(){
  
  # * Connect DB ----
  db_conn <- db_connect()
  
  # * Query ----
  query <- DBI::dbGetQuery(
    conn = db_conn
    , statement = paste0(
      "
      TRUNCATE TABLE smsdss.c_covid_arrival_departure_tbl
          
      INSERT INTO smsdss.c_covid_arrival_departure_tbl
      SELECT Adm_Dtime AS [Arrival],
      DC_Dtime as [Departure],
      PTNO_NUM,
      In_House,
      positive_suspect_noncovid = CASE 
            		WHEN distinct_visit_flag = 1
            			AND result_clean = 'detected'
            			AND order_status = 'result signed'
            			THEN 'positive'
            		WHEN Distinct_Visit_Flag = '1'
            			AND pt_last_test_positive = '1'
            			AND datediff(day, last_positive_result_dtime, cast(getdate() AS DATE)) <= 30
            			AND PatientReasonforSeekingHC NOT LIKE '%non covid%'
            			AND (
            				PatientReasonforSeekingHC LIKE '%Sepsis%'
            				OR PatientReasonforSeekingHC LIKE '%SEPS%'
            				OR PatientReasonforSeekingHC LIKE '%PNEUM%'
            				OR PatientReasonforSeekingHC LIKE '%PNA%'
            				OR PatientReasonforSeekingHC LIKE '%FEVER%'
            				OR PatientReasonforSeekingHC LIKE '%CHILLS%'
            				OR PatientReasonforSeekingHC LIKE '%SOB%'
            				OR PatientReasonforSeekingHC LIKE '%SHORTNESS OF BREATH%'
            				OR PatientReasonforSeekingHC LIKE '%SHORT OF BREATH%'
            				OR PatientReasonforSeekingHC LIKE '%RESPIRATO%FAIL%'
            				OR PatientReasonforSeekingHC LIKE '%RESP%FAIL%'
            				OR PatientReasonforSeekingHC LIKE '%COUGH%'
            				OR PatientReasonforSeekingHC LIKE '%WEAKNESS%'
            				OR PatientReasonforSeekingHC LIKE '%PN%'
            				OR PatientReasonforSeekingHC LIKE '%COVID%'
            				)
            			THEN 'positive'
            		WHEN RESULT_CLEAN = 'detected'
            			AND Order_Status != 'result signed'
            			THEN 'suspect'
            		WHEN Covid_Indicator = 'covid 19 or r/o covid 19 patient'
            			THEN 'suspect'
            		ELSE 'non_covid'
            		END
      FROM smsdss.c_covid_extract_tbl
      WHERE Pt_Accomodation != 'Intensive Care'
      AND left(PTNO_NUM, 1) = '1'
      AND Distinct_Visit_Flag = '1'
      AND PTNO_NUM NOT IN (
          SELECT DISTINCT pt_id
          FROM smsdss.dly_cen_occ_fct_v
          WHERE pt_type = 'I'
      )
      ;
      "
    )
  ) %>%
    tibble::as_tibble()
  
  # * DB Disconnect ----
  db_disconnect(.connection = db_conn)

}

# LOS Data for CV+ patients who have never been in the ICU query
cv_pos_inhouse_no_icu_los_query <- function() {
  
  # * Connect DB ----
  db_conn <- db_connect()
  
  # * Query ----
  query <- DBI::dbGetQuery(
    conn = db_conn
    , statement = paste0(
      "
      TRUNCATE TABLE smsdss.c_covid_inhouse_los_final_tbl

      DECLARE @TODAY AS DATE;
      DECLARE @StartDate AS DATE;
      DECLARE @EndDate AS DATE;
          
      SET @TODAY = GETDATE();
      SET @StartDate = (SELECT MIN(ARRIVAL) FROM smsdss.c_covid_arrival_departure_tbl);
      SET @EndDate = @TODAY;
          
      WITH dates AS (
      SELECT CAST(@StartDate AS DATETIME2) AS dte
        	
      UNION ALL
        	
      SELECT DATEADD(DAY, 1, dte)
      FROM dates
      WHERE dte < @EndDate
      )
          
      INSERT INTO smsdss.c_covid_inhouse_los_final_tbl
      SELECT distinct CAST(dates.dte AS DATE) [Date],
      cast(arrival as date) as [arrival],
      cast(departure as date) as [departure],
      ptno_num,
      los = case 
      	when departure is not null
      		and cast(departure as date) <= cast(dates.dte as date) 
      		then datediff(day, arrival, departure)
      	when departure is not null
      		and cast(departure as date) >= cast(dates.dte as date)
      		then datediff(day, arrival, dates.dte)
      	when departure is null
      		then datediff(day, arrival, dates.dte)
      	end,
      in_house
      FROM dates
      LEFT JOIN smsdss.c_covid_arrival_departure_tbl AS A ON A.Arrival <= DATEADD(HOUR, 1, dates.dte)
          AND (
      		A.Departure >= dates.dte
      		OR (
      			A.Departure IS NULL
      			AND A.Arrival <= Dates.dte
      		)
      	)
      WHERE dates.dte <= @EndDate
      AND DATES.dte >= '2020-03-01'
      AND LEFT(PTNO_NUM, 1) = '1'
      AND PTNO_NUM IN (
      	SELECT DISTINCT PTNO_NUM
      	FROM SMSDSS.c_covid_arrival_departure_tbl
      	WHERE positive_suspect_noncovid = 'POSITIVE'
      )
      ORDER BY in_house, [Date]
      OPTION (MAXRECURSION 0);
      "
    )
  ) %>%
    tibble::as_tibble()
  
  # * DB Disconnect ----
  db_disconnect(.connection = db_conn)

}

# Get Suffolk County NY COVID Daily Bulletin Data
get_suffolk_cv_bulletin_query <- function(){
  
  # * URL ----
  url   <- "https://suffolkcountyny.gov/Departments/Health-Services/Health-Bulletins/Novel-Coronavirus"
  
  # * Links ----
  page  <- xml2::read_html(url)
  nodes <- page %>% 
    rvest::html_nodes(".EDN_article_content") %>% 
    rvest::html_nodes("a")
  links <- nodes %>% 
    rvest::html_attr("href") %>% 
    base::as.list()
  
  # * Link to Tbl Func ----
  from_link_to_data <- function(links){
    links %>%
      xml2::read_html() %>%
      rvest::html_nodes("li") %>%
      rvest::html_text(trim = TRUE) %>%
      tibble::as_tibble() %>%
      dplyr::slice(7, 10:29)
  }
  
  new_from_link_to_data <- function(links) {
    links %>% 
      xml2::read_html() %>% 
      rvest::html_node(".EDN_article_content") %>% 
      rvest::html_text() %>% 
      strsplit("[\r\n]+") %>% 
      tibble::as_tibble(.name_repair = "unique") %>% 
      purrr::set_names("value") %>% 
      mutate(value = stringr::str_squish(value))
  }
  
  # * Data Manip ----
  # make sql_mid func
  sql_mid <- function(text, start_num, num_char) {
    base::substr(text, start_num, start_num + num_char - 1)
  }
  
  # Clean up report date
  data_tbl <- links %>%
    purrr::map_df(new_from_link_to_data)
  
  data_tbl <- data_tbl %>%
    dplyr::mutate(
      last_update = sql_mid(
        text = value
        , start_num = 106
        , num_char = 100
      ) %>%
        lubridate::mdy()
    ) %>% view()
    dplyr::filter(value != "") %>% 
    dplyr::mutate(last_update = zoo::na.locf(last_update)) %>% 
    dplyr::select(last_update, value)
  
  # data_tbl <- links %>%
  #   purrr::map_df(from_link_to_data) %>%
  #   dplyr::mutate(rpt_date = lubridate::dmy(value)) %>%
  #   dplyr::mutate(rpt_date = zoo::na.locf(rpt_date)) %>%
  #   dplyr::select(rpt_date, value)
  
  # Get a group id for later use
  data_tbl$group_id <- data_tbl %>%
    dplyr::group_by(last_update) %>%
    dplyr::group_indices(last_update)
  
  # Get a rowid and select columns
  data_tbl <- data_tbl %>%
    dplyr::group_by(group_id) %>%
    dplyr::mutate(row_id = dplyr::row_number()) %>%
    dplyr::ungroup() %>%
    dplyr::select(row_id, last_update, value) 
  
  # Get newest report data
  data_final_tbl <- data_tbl %>%
    dplyr::arrange(dplyr::desc(last_update), row_id) %>%
    dplyr::mutate_if(is.character, stringr::str_squish) %>%
    dplyr::mutate(value = dplyr::case_when(
      value == "Report Unsafe Business Practices here." ~ "-"
      , TRUE ~ value
    )) %>%
    tidyr::pivot_wider(
      id_col        = row_id
      , names_from  = last_update
      , values_from = value
    ) %>%
    dplyr::slice(2:27) %>%
    dplyr::select(-row_id)
  
  # * Return ----
  return(data_final_tbl)
  
}
