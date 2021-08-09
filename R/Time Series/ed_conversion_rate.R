
# Lib Load ----------------------------------------------------------------

if(!require(pacman)){install.packages("pacman")}
pacman::p_load(
  "tidyverse"
  , "timetk"
  , "modeltime"
  , "odbc"
  , "DBI"
  , "LICHospitalR"
  , "lubridate"
  , "tidyquant"
  , "cowplot"
)

# Query -------------------------------------------------------------------

db_con <- db_connect()

ed_arrivals_tbl <- dbGetQuery(
  conn = db_con,
  statement = paste0(
    "
    SELECT CAST(arrival AS DATE) as date_col,
        COUNT(*) AS [ed_arrivals]
    FROM [SQL-WS\\REPORTING].[WellSoft_Reporting].[dbo].[c_Wellsoft_Rpt_tbl]
    WHERE CAST(arrival AS DATE) >= '2011-01-01'
    GROUP BY CAST(arrival AS DATE)
    ORDER BY CAST(arrival AS date)
    "
  )
) %>%
  as_tibble() %>%
  mutate(date_col = ymd(date_col))

admits_tbl <- dbGetQuery(
  conn = db_con,
  statement = paste0(
    "
    SELECT CAST(evnt_dtime AS DATE) AS [date_col],
    	COUNT(*) AS [admits]
    FROM SMSMIR.hl7_msg_hdr AS A
    WHERE A.evnt_type_cd IN ('A01', 'A47')
    	AND CAST(evnt_dtime AS DATE) >= '2011-01-01'-- CAST(GETDATE() - 1 AS DATE)
    GROUP BY CAST(evnt_dtime AS DATE)
    ORDER BY CAST(evnt_dtime AS DATE)
    "
  )
) %>%
  as_tibble() %>%
  mutate(date_col = ymd(date_col))

db_disconnect(.connection = db_con)

# Manipulate --------------------------------------------------------------

start_date <- min(admits_tbl$date_col, ed_arrivals_tbl$date_col)
end_date <- max(admits_tbl$date_col, ed_arrivals_tbl$date_col)

dates_tbl <- tk_make_timeseries(
  start_date = start_date
  , end_date = end_date
  , by = "day"
) %>%
  as_tibble() %>%
  set_names("date_col")

joined_data_tbl <- dates_tbl %>%
  left_join(ed_arrivals_tbl) %>%
  left_join(admits_tbl)

data_month_summarized_tbl <- joined_data_tbl %>%
  mutate(
    ed_convert_rate = round(admits / ed_arrivals, 4)
    , yr            = year(date_col)
    , mn            = month(date_col, label = TRUE)
  ) %>%
  group_by(yr, mn) %>%
  summarise_by_time(
    .date_var = date_col
    , .by = "month"
    , value = mean(ed_convert_rate)
  ) %>%
  ungroup() %>%
  mutate(thisyear = yr == max(yr)) %>%
  select(date_col, value, everything())

ed_summarized_tbl <- joined_data_tbl %>%
  mutate(
    yr   = year(date_col)
    , mn = month(date_col, label = TRUE)
  ) %>%
  group_by(yr, mn) %>%
  summarise_by_time(
    .date_var = date_col
    , .by = "month"
    , value = mean(ed_arrivals)
  ) %>%
  ungroup() %>%
  mutate(thisyear = yr == max(yr)) %>%
  select(date_col, value, everything())

# Viz ---------------------------------------------------------------------

# * Conversion Rate ----
data_month_summarized_tbl %>%
  filter_by_time(
    .date_var     = date_col
    , .start_date = "2015"
  ) %>%
  plot_time_series(
    .date_var    = date_col
    , .value     = value
    , .color_var = yr
    , .smooth    = FALSE
    , .title = "ED to IP Conversion Rate (Mean)"
    , .y_lab = "Rate %"
  )

p1 <- data_month_summarized_tbl %>%
  filter_by_time(
    .date_var     = date_col
    , .start_date = "2015"
  ) %>%
  ggplot(
    mapping = aes(
      x       = mn
      , y     = value
      , group = yr
    )
  ) +
  geom_line(
    mapping = aes(
      col = thisyear
    )
  ) +
  scale_color_manual(values = c("FALSE"='steelblue',"TRUE"='red')) +
  scale_y_continuous(labels = scales::percent) +
  guides(scale = "none") +
  tidyquant::theme_tq() +
  labs(
    title = "ED Conversion Rate 2015 Forward"
    , subtitle = "Redline is Current Year"
    , y = ""#"Mean ED Conversion Rate"
    , x = "Month"
  ) +
  theme(
    legend.position = "none"
  )

plotly::ggplotly(p1)

plot_seasonal_diagnostics(
  ed_arrivals_tbl %>%
    filter_by_time(
      date_col
      , "2015"
    )
  , date_col
  , ed_arrivals
  , .feature_set = c("month.lbl")
  , .title = "ED Arrivals Box Plot by Month"
)

# * Ed Arrivals ----
ed_summarized_tbl %>%
  filter_by_time(
    .date_var     = date_col
    , .start_date = "2015"
  ) %>%
  plot_time_series(
    .date_var    = date_col
    , .value     = value
    , .color_var = yr
    , .smooth    = FALSE
    , .title = "ED Arrivals (Mean)"
    , .y_lab = "Rate %"
  )

p2 <- ed_summarized_tbl %>%
  filter_by_time(
    .date_var     = date_col
    , .start_date = "2015"
  ) %>%
  ggplot(
    mapping = aes(
      x       = mn
      , y     = value
      , group = yr
    )
  ) +
  geom_line(
    mapping = aes(
      col = thisyear
    )
  ) +
  scale_color_manual(values = c("FALSE"='steelblue',"TRUE"='red')) +
  scale_y_continuous(labels = scales::number) +
  guides(scale = "none") +
  tidyquant::theme_tq() +
  labs(
    title = "ED Arrivals 2015 Forward"
    , subtitle = "Redline is Current Year"
    , y = "" #"ED Arrivals"
    , x = "Month"
  ) +
  theme(
    legend.position = "none"
  )

plotly::ggplotly(p2)

plot_grid(
  p1, p2,
  align = "h",
  nrow = 2
)
