# Queries ----
# Total Admitted Positive Query
tot_icu_pos_pts_query <- function() {
  
  # * Connect to DSS ----
  db_conn <- db_connect()
  
  # * Query ----
  query <- DBI::dbGetQuery(
    conn = db_conn
    , statement = base::paste0(
      "
      SELECT *
      FROM SMSDSS.c_covid_hhs_tbl
      WHERE SP_Run_DateTime = (
      	SELECT MAX(SP_Run_DateTime)
      	FROM SMSDSS.c_covid_hhs_tbl
      )
      AND positive_suspect_noncovid = 'positive'
      AND Pt_Accomodation = 'Intensive Care'
      AND Distinct_Visit_Flag = '1'
      AND DC_DTime IS NULL
      AND In_House = '1';
      "
    )
  )
  # query <- DBI::dbGetQuery(
  #   conn = db_conn
  #   , statement = base::paste0(
  #     "
  #     SELECT *
  #     FROM smsdss.c_tot_adm_covid_pos_tbl
  #     WHERE Run_DateTime = (
  #     	SELECT MAX(run_datetime)
  #     	FROM smsdss.c_tot_adm_covid_pos_tbl
  #     	)
  #     AND Pt_Accomodation = 'Intensive Care'
  #     "
  #   )
  # )
  
  # * DB Disconnect ----
  db_disconnect(.connection = db_conn)
  
  # * Return ----
  return(query)
  
}

tot_vent_pos_pts_query <- function() {
  
  # * Connect to DSS ----
  db_conn <- db_connect()
  
  # * Query ----
  query <- DBI::dbGetQuery(
    conn = db_conn
    , statement = base::paste0(
      "
      SELECT *
      FROM SMSDSS.c_covid_hhs_tbl
      WHERE SP_Run_DateTime = (
      	SELECT MAX(SP_Run_DateTime)
      	FROM SMSDSS.c_covid_hhs_tbl
      )
      AND positive_suspect_noncovid = 'positive'
      AND Pt_Accomodation = 'Intensive Care'
      AND Distinct_Visit_Flag = '1'
      AND DC_DTime IS NULL
      AND In_House = '1'
      AND Vented = 'Vented';
      "
    )
  )
  # query <- DBI::dbGetQuery(
  #   conn = db_conn
  #   , statement = base::paste0(
  #     "
  #     SELECT *
  #     FROM smsdss.c_tot_adm_covid_pos_tbl
  #     WHERE Run_DateTime = (
  #     	SELECT MAX(run_datetime)
  #     	FROM smsdss.c_tot_adm_covid_pos_tbl
  #     	)
  #     AND Vented = 'Vented'
  #     "
  #   )
  # )
  
  # * DB Disconnect ----
  db_disconnect(.connection = db_conn)
  
  # * Return ----
  return(query)
  
}

total_vented_pts_query <- function(){
  
  #* Connect to DSS ----
  db_conn <- db_connect()
  
  # * Query ----
  query <- DBI::dbGetQuery(
    conn = db_conn
    , statement = base::paste0(
      "
      SELECT *
      FROM SMSDSS.c_covid_hhs_tbl
      WHERE SP_Run_DateTime = (
      	SELECT MAX(SP_Run_DateTime)
      	FROM SMSDSS.c_covid_hhs_tbl
      )
      AND Distinct_Visit_Flag = '1'
      AND DC_DTime IS NULL
      AND In_House = '1'
      AND Vented = 'Vented';
      "
    )
  )
  # query <- DBI::dbGetQuery(
  #   conn = db_conn
  #   , statement = base::paste0(
  #     "
  #     SELECT *
  #     FROM smsdss.c_tot_adm_covid_tbl
  #     WHERE Vented = 'Vented'
  #     	AND RunDateTime = (
  #     		SELECT MAX(rundatetime)
  #     		FROM smsdss.c_tot_adm_covid_tbl
  #     		)
  #     "
  #   )
  # )
  
  # * DB Disconnect ----
  db_disconnect(.connection = db_con)
  
  # * Return ----
  return(query)
}

total_icu_pts_query <- function(){
  
  #* Connect to DSS ----
  db_conn <- db_connect()
  
  # * Query ----
  query <- DBI::dbGetQuery(
    conn = db_conn
    , statement = base::paste0(
      "
      SELECT *
      FROM SMSDSS.c_covid_hhs_tbl
      WHERE SP_Run_DateTime = (
      	SELECT MAX(SP_Run_DateTime)
      	FROM SMSDSS.c_covid_hhs_tbl
      )
      AND Distinct_Visit_Flag = '1'
      AND DC_DTime IS NULL
      AND In_House = '1'
      AND Pt_Accomodation = 'Intensive Care';
      "
    )
  )
  # query <- DBI::dbGetQuery(
  #   conn = db_conn
  #   , statement = base::paste0(
  #     "
  #     SELECT *
  #     FROM smsdss.c_tot_adm_covid_tbl
  #     WHERE Pt_Accomodation = 'Intensive Care'
  #     	AND RunDateTime = (
  #     		SELECT MAX(rundatetime)
  #     		FROM smsdss.c_tot_adm_covid_tbl
  #     		)
  #     "
  #   )
  # )
  
  # * DB Disconnect ----
  db_disconnect(.connection = db_con)
  
  # * Return ----
  return(query)
  
}