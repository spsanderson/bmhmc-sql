# Queries ----
# Total Admitted Positive Query
tot_adm_pos_query <- function() {
  
  # * Connect to DSS ----
  db_conn <- db_connect()
  
  # * Query ----
  query <- DBI::dbGetQuery(
    conn = db_conn
    , statement = base::paste0(
      "
      SELECT *
      FROM smsdss.c_tot_adm_covid_pos_tbl
      WHERE run_datetime = (
      		SELECT max(run_datetime)
      		FROM smsdss.c_tot_adm_covid_pos_tbl
      		);
      "
    )
  )
  
  # * DB Disconnect ----
  db_disconnect(.connection = db_conn)
  
  # * Return ----
  return(query)
  
}

tot_adm_suspect_query <- function() {
  
  # * Connect to DSS ----
  db_conn <- db_connect()
  
  # * Query ----
  query <- DBI::dbGetQuery(
    conn = db_conn
    , statement = base::paste0(
      "
      SELECT *
      FROM smsdss.c_tot_adm_covid_suspect_tbl
      WHERE run_datetime = (
      		SELECT max(run_datetime)
      		FROM smsdss.c_tot_adm_covid_suspect_tbl
      		);
      "
    )
  )
  
  # * DB Disconnect ----
  db_disconnect(.connection = db_conn)
  
  # * Return ----
  return(query)
  
}

tot_dsch_positive_yesterday_query <- function() {
  
  # * Connect to DSS ----
  db_conn <- db_connect()
  
  # * Query ----
  query <- DBI::dbGetQuery(
    conn = db_conn
    , statement = base::paste0(
      "
      SELECT *
      FROM smsdss.c_tot_dsch_yday_covid_pos_tbl
      WHERE run_datetime = (
      		SELECT max(run_datetime)
      		FROM smsdss.c_tot_dsch_yday_covid_pos_tbl
      		);
      "
    )
  )
  
  # * DB Disconnect ----
  db_disconnect(.connection = db_conn)
  
  # * Return ----
  return(query)
  
}

tot_dsch_suspect_yesterday_query <- function() {
  
  # * Connect to DSS ----
  db_conn <- db_connect()
  
  # * Query ----
  query <- DBI::dbGetQuery(
    conn = db_conn
    , statement = base::paste0(
      "
      SELECT *
      FROM smsdss.c_tot_dsch_yday_covid_suspect_tbl
      WHERE run_datetime = (
      		SELECT max(run_datetime)
      		FROM smsdss.c_tot_dsch_yday_covid_suspect_tbl
      		);
      "
    )
  )
  
  # * DB Disconnect ----
  db_disconnect(.connection = db_conn)
  
  # * Return ----
  return(query)
  
}

tot_hhs_adm_pos_query <- function(){
  
  # * Connect to DSS ----
  db_conn <- db_connect()
  
  # * Query ----
  query <- DBI::dbGetQuery(
    conn = db_conn
    , statement = base::paste0(
      "
      SELECT *
      FROM smsdss.c_covid_hhs_tbl
      WHERE SP_Run_DateTime = (
      		SELECT max(sp_run_datetime)
      		FROM smsdss.c_covid_hhs_tbl
      		)
      	AND positive_suspect_noncovid = 'positive'
      	AND in_house = '1'
      "
    )
  )
  
  # * DB Disconnect ----
  db_disconnect(.connection = db_conn)
  
  # * Return ----
  return(query)
  
}

admit_dx_query <- function(){
  
  # * Connect to DSS ----
  db_conn <- db_connect()
  
  # * Query ----
  query <- DBI::dbGetQuery(
    conn = db_conn
    , statement = base::paste0(
      "
      SELECT PTNO_NUM,
      	Dx_Order,
      	Dx_Order_Abbr,
      	LEFT(Dx_Order_Abbr, 1) AS [Abbr_1]
      FROM smsdss.c_covid_hhs_tbl
      WHERE SP_Run_DateTime = (
          SELECT max(sp_run_datetime)
          FROM smsdss.c_covid_hhs_tbl
          )
      AND positive_suspect_noncovid = 'positive'
      AND in_house = '1'
      ORDER BY Dx_Order;
      "
    )
  )
  
  # * DB Disconnect ----
  db_disconnect(.connection = db_conn)
  
  # * Return ----
  return(query)
  
}

tot_hhs_adm_sus_query <- function(){
  
  # * Connect to DSS ----
  db_conn <- db_connect()
  
  # * Query ----
  query <- DBI::dbGetQuery(
    conn = db_conn
    , statement = base::paste0(
      "
      SELECT *
      FROM smsdss.c_covid_hhs_tbl
      WHERE SP_Run_DateTime = (
      		SELECT max(sp_run_datetime)
      		FROM smsdss.c_covid_hhs_tbl
      		)
      	AND positive_suspect_noncovid = 'suspect'
      	AND in_house = '1'
      "
    )
  )
  
  # * DB Disconnect ----
  db_disconnect(.connection = db_conn)
  
  # * Return ----
  return(query)
  
}

tot_hhs_adm_sus_7day_query <- function(){
  
  # * Connect to DSS ----
  db_conn <- db_connect()
  
  # * Query ----
  query <- DBI::dbGetQuery(
    conn = db_conn
    , statement = base::paste0(
      "
      DECLARE @START AS DATE;
      SET @START = DATEADD(DAY, - 7, CAST(GETDATE() AS DATE));
      
      SELECT *
      FROM smsdss.c_covid_hhs_tbl
      WHERE SP_Run_DateTime >= @START
      AND positive_suspect_noncovid = 'suspect'
      AND in_house = '1'
      "
    )
  )
  
  # * DB Disconnect ----
  db_disconnect(.connection = db_conn)
  
  # * Return ----
  return(query)
  
}

tot_hhs_adm_sus_30day_query <- function(){
  
  # * Connect to DSS ----
  db_conn <- db_connect()
  
  # * Query ----
  query <- DBI::dbGetQuery(
    conn = db_conn
    , statement = base::paste0(
      "
      DECLARE @START AS DATE;
      SET @START = DATEADD(DAY, - 30, CAST(GETDATE() AS DATE));
      
      SELECT *
      FROM smsdss.c_covid_hhs_tbl
      WHERE SP_Run_DateTime >= @START
      AND positive_suspect_noncovid = 'suspect'
      AND in_house = '1'
      "
    )
  )
  
  # * DB Disconnect ----
  db_disconnect(.connection = db_conn)
  
  # * Return ----
  return(query)
  
}

tot_hhs_dsch_pos_yday_query <- function(){
  
  # * Connect to DSS ----
  db_conn <- db_connect()
  
  # * Query ----
  query <- DBI::dbGetQuery(
    conn = db_conn
    , statement = base::paste0(
      "
      SELECT *
      FROM smsdss.c_covid_hhs_tbl
      WHERE PT_ADT = 'discharged'
        AND DATEDIFF(DAY, DC_DTIME, GETDATE()) <= 1
        AND positive_suspect_noncovid = 'positive'
      "
    )
  )
  
  # * DB Disconnect ----
  db_disconnect(.connection = db_conn)
  
  # * Return ----
  return(query)
  
}

tot_covid_7day_avg_dsch_query <- function(){
  
  # * Connect to DSS ----
  db_conn <- db_connect()
  
  # * Query ----
  query <- DBI::dbGetQuery(
    conn = db_conn
    , statement = base::paste0(
      "
      DECLARE @START DATE;
      DECLARE @END DATE;
      SET @START = DATEADD(DAY, - 7, CAST(GETDATE() AS DATE));
      SET @END   = DATEADD(DAY, - 1, CAST(GETDATE() AS DATE));
      SELECT ROUND(COUNT(DISTINCT PTNO_NUM) / 7.00, 2) AS [rec_count]
      FROM smsdss.c_covid_hhs_tbl
      WHERE CAST(DC_DTime AS DATE) >= @START
        AND CAST(DC_DTime AS DATE) <= @END
        AND Distinct_Visit_Flag = '1'
        AND PT_ADT = 'discharged'
        AND positive_suspect_noncovid IN ('positive')
      "
    )
  )
  
  # * DB Disconnect ----
  db_disconnect(.connection = db_conn)
  
  # * Return ----
  return(query)
  
}

tot_covid_30day_avg_dsch_query <- function(){
  
  # * Connect to DSS ----
  db_conn <- db_connect()
  
  # * Query ----
  query <- DBI::dbGetQuery(
    conn = db_conn
    , statement = base::paste0(
      "
      DECLARE @START DATE;
      DECLARE @END DATE;
      SET @START = DATEADD(DAY, - 30, CAST(GETDATE() AS DATE));
      SET @END   = DATEADD(DAY, - 1, CAST(GETDATE() AS DATE));
      SELECT ROUND(COUNT(DISTINCT PTNO_NUM) / 30.00, 2) AS [rec_count]
      FROM smsdss.c_covid_hhs_tbl
      WHERE CAST(DC_DTime AS DATE) >= @START
        AND CAST(DC_DTime AS DATE) <= @END
        AND Distinct_Visit_Flag = '1'
        AND PT_ADT = 'discharged'
        AND positive_suspect_noncovid IN ('positive')
      "
    )
  )
  
  # * DB Disconnect ----
  db_disconnect(.connection = db_conn)
  
  # * Return ----
  return(query)
  
}

tot_hhs_dsch_sus_yday_query <- function(){
  
  # * Connect to DSS ----
  db_conn <- db_connect()
  
  # * Query ----
  query <- DBI::dbGetQuery(
    conn = db_conn
    , statement = base::paste0(
      "
      SELECT *
      FROM smsdss.c_covid_hhs_tbl
      WHERE PT_ADT = 'discharged'
        AND DATEDIFF(DAY, DC_DTIME, GETDATE()) <= 1
        AND positive_suspect_noncovid = 'suspect'
      "
    )
  )
  
  # * DB Disconnect ----
  db_disconnect(.connection = db_conn)
  
  # * Return ----
  return(query)
  
}

seven_day_avg_pos_ip_query <- function(){
  
  # * Connect to DSS ----
  db_conn <- db_connect()
  
  # * Query ----
  query <- DBI::dbGetQuery(
    conn = db_conn
    , statement = base::paste0(
      "
      DECLARE @START AS DATE;
      SET @START = DATEADD(DAY, - 7, CAST(GETDATE() AS DATE));
      SELECT ROUND(COUNT(*) / 7.00, 2) AS [REC_COUNT]
      FROM smsdss.c_covid_hhs_tbl
      WHERE positive_suspect_noncovid = 'positive'
      AND LEFT(PTNO_NUM, 1) = '1'
      AND In_House = '1'
      AND CAST(SP_Run_DateTime AS DATE) >= @START
      "
    )
  )
  
  # * DB Disconnect ----
  db_disconnect(.connection = db_conn)
  
  # * Return ----
  return(query)
  
}

thirty_day_avg_pos_ip_query <- function(){
  
  # * Connect to DSS ----
  db_conn <- db_connect()
  
  # * Query ----
  query <- DBI::dbGetQuery(
    conn = db_conn
    , statement = base::paste0(
      "
      DECLARE @START AS DATE;
      SET @START = DATEADD(DAY, - 30, CAST(GETDATE() AS DATE));
      SELECT ROUND(COUNT(*) / 30.00, 2) AS [REC_COUNT]
      FROM smsdss.c_covid_hhs_tbl
      WHERE positive_suspect_noncovid = 'positive'
      AND LEFT(PTNO_NUM, 1) = '1'
      AND In_House = '1'
      AND CAST(SP_Run_DateTime AS DATE) >= @START
      "
    )
  )
  
  # * DB Disconnect ----
  db_disconnect(.connection = db_conn)
  
  # * Return ----
  return(query)
  
}

seven_day_avg_cv_related_admissions <- function(){
  
  # * Connect to DSS ----
  db_conn <- db_connect()
  
  # * Query ----
  query <- DBI::dbGetQuery(
    conn = db_conn
    , statement = base::paste0(
      "
      DECLARE @START DATE;
      DECLARE @END DATE;
      SET @START = DATEADD(DAY, - 7, CAST(GETDATE() AS DATE));
      SET @END   = DATEADD(DAY, - 1, CAST(GETDATE() AS DATE));
      SELECT ROUND(COUNT(DISTINCT PTNO_NUM) / 7.00, 2) AS [rec_count]
      FROM smsdss.c_covid_hhs_tbl
      WHERE CAST(Adm_Dtime AS DATE) >= @START
      AND CAST(Adm_Dtime AS DATE) <= @END
      AND Distinct_Visit_Flag = '1'
      AND In_House = '1'
      AND positive_suspect_noncovid IN ('positive','suspect')
      "
    )
  )
  
  # * DB Disconnect ----
  db_disconnect(.connection = db_conn)
  
  # * Return ----
  return(query)
}

thirty_day_avg_cv_related_admissions <- function(){
  
  # * Connect to DSS ----
  db_conn <- db_connect()
  
  # * Query ----
  query <- DBI::dbGetQuery(
    conn = db_conn
    , statement = base::paste0(
      "
      DECLARE @START DATE;
      DECLARE @END DATE;
      SET @START = DATEADD(DAY, - 30, CAST(GETDATE() AS DATE));
      SET @END   = DATEADD(DAY, - 1, CAST(GETDATE() AS DATE));
      SELECT ROUND(COUNT(DISTINCT PTNO_NUM) / 30.00, 2) AS [rec_count]
      FROM smsdss.c_covid_hhs_tbl
      WHERE CAST(Adm_Dtime AS DATE) >= @START
      AND CAST(Adm_Dtime AS DATE) <= @END
      AND Distinct_Visit_Flag = '1'
      AND In_House = '1'
      AND positive_suspect_noncovid IN ('positive','suspect')
      "
    )
  )
  
  # * DB Disconnect ----
  db_disconnect(.connection = db_conn)
  
  # * Return ----
  return(query)
}

# Stored Procedures ----
# Total Admitted Covid Table Wrapper SP
tot_adm_cv_wrapper_sp <- function(){
  
  # * Connect to DSS ----
  db_conn <- db_connect()
  
  # * Query ----
  query <- DBI::dbGetQuery(
    conn = db_conn
    , statement = base::paste0(
      "
      execute dbo.c_total_admitted_covid_wrapper_sp
      "
    )
  )
  
  # * DB Disconnect ----
  db_disconnect(.connection = db_conn)
  
  # * Return ----
  return(query)
  
}

# Total Admitted Covid Positive Wrapper SP
tot_adm_cv_pos_wrapper_sp <- function(){
  
  # * Connect to DSS ----
  db_conn <- db_connect()
  
  # * Query ----
  query <- DBI::dbGetQuery(
    conn = db_conn
    , statement = base::paste0(
      "
      execute dbo.c_total_admitted_covid_positive_wrapper_sp
      "
    )
  )
  
  # * DB Disconnect ----
  db_disconnect(.connection = db_conn)
  
  # * Return ----
  return(query)
  
}

# Total Admitted Covid Suspect Wrapper SP
tot_adm_cv_sus_wrapper_sp <- function(){
  
  # * Connect to DSS ----
  db_conn <- db_connect()
  
  # * Query ----
  query <- DBI::dbGetQuery(
    conn = db_conn
    , statement = base::paste0(
      "
      execute dbo.c_total_admitted_covid_suspect_wrapper_sp
      "
    )
  )
  
  # * DB Disconnect ----
  db_disconnect(.connection = db_conn)
  
  # * Return ----
  return(query)
  
}

# Total Discharged Covid Table Wrapper SP
tot_dsch_cv_wrapper_sp <- function(){
  
  # * Connect to DSS ----
  db_conn <- db_connect()
  
  # * Query ----
  query <- DBI::dbGetQuery(
    conn = db_conn
    , statement = base::paste0(
      "
      execute dbo.c_total_discharged_covid_wrapper_sp
      "
    )
  )
  
  # * DB Disconnect ----
  db_disconnect(.connection = db_conn)
  
  # * Return ----
  return(query)
  
}

# Total Discharged Yesterday Positive Wrapper SP
tot_dsch_y_pos_wrapper_sp <- function(){
  
  # * Connect to DSS ----
  db_conn <- db_connect()
  
  # * Query ----
  query <- DBI::dbGetQuery(
    conn = db_conn
    , statement = base::paste0(
      "
      execute dbo.c_total_discharged_yesterday_covid_pos_wrapper_sp
      "
    )
  )
  
  # * DB Disconnect ----
  db_disconnect(.connection = db_conn)
  
  # * Return ----
  return(query)
  
}

# Total Discharged Yesterday Suspect Wrapper SP
tot_dsch_y_sus_wrapper_sp <- function(){
  
  # * Connect to DSS ----
  db_conn <- db_connect()
  
  # * Query ----
  query <- DBI::dbGetQuery(
    conn = db_conn
    , statement = base::paste0(
      "
      execute dbo.c_total_discharged_yesterday_covid_suspect_wrapper_sp
      "
    )
  )
  
  # * DB Disconnect ----
  db_disconnect(.connection = db_conn)
  
  # * Return ----
  return(query)
  
}

# HHS Covid Table SP
c_covid_hhs_sp <- function(){
  
  # * Connect to DSS ----
  db_conn <- db_connect()
  
  # * Query ----
  query <- DBI::dbGetQuery(
    conn = db_conn
    , statement = base::paste0(
      "
      execute dbo.c_covid_hhs_wrapper_sp
      "
    )
  )
  
  # * DB Disconnect ----
  db_disconnect(.connection = db_conn)
  
  # * Return ----
  return(query)

}