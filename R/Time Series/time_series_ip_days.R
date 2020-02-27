# Lib Load ####
if(!require(pacman)) install.packages("pacman")
pacman::p_load(
  "tidyquant"
  , "fable"
  , "fabletools"
  , "feasts"
  , "tsibble"
  , "timetk"
  , "sweep"
  , "anomalize"
  , "lubridate"
  , "ggplot2"
  , "tidyverse"
)

# Get File ####
fileToLoad <- file.choose(new = TRUE)
days <- read.csv(fileToLoad)

days$Time <- mdy(days$Time)

# Make Monthly ----
df_monthly_tbl <- days %>%
  mutate(month_end = ceiling_date(Time, unit = "month") - period(1, unit = "days")) %>%
  select(month_end, Total_Days) %>%
  group_by(month_end) %>%
  summarize(Total_Days = sum(Total_Days)) %>%
  ungroup()

min.date  <- min(df_monthly_tbl$month_end)
min.year  <- year(min.date)
min.month <- month(min.date)
max.date  <- max(df_monthly_tbl$month_end)
max.year  <- year(max.date)
max.month <- month(max.date)
last.18.months <- as.Date(max.date) %m-% months(18, abbreviate = F)

# Plot Initial Data ----
df_monthly_tbl %>%
  ggplot(
    mapping = aes(
      x = month_end
      , y = Total_Days
    )
  ) +
  geom_point(
    alpha = 0.5
    , color = palette_light()[[1]]
  ) +
  geom_line(
    alpha = 0.5
  ) +
  geom_smooth(
    se = FALSE
    , method = 'loess'
    , color = 'red'
    , span = 1/12
  ) +
  labs(
    title = "IP Discharge Days: Monthly Scale"
    , subtitle = "Source: DSS"
    , caption = paste0(
      "Based on discharges from: "
      , min.date
      , " through "
      , max.date
    )
    , y = "Count"
    , x = ""
  ) +
  theme_tq()

# Anomalize ----
# Anomaly Plots
df_monthly_tbl %>%
  tibbletime::as_tbl_time(index = month_end) %>%
  arrange(month_end) %>%
  # Data Manipulation / Anomaly Detection
  time_decompose(Total_Days, method = "twitter") %>%
  anomalize(remainder, method = "gesd") %>%
  time_recompose() %>%
  # Anomaly Visualization
  plot_anomalies(
    time_recomposed = TRUE
    ,alpha_dots = 0.25
  ) +
  labs(
    title = "Total IP Days Anomalies"
    , subtitle = "Twitter + GESD Methods"
  ) 

df_monthly_tbl %>%
  tibbletime::as_tbl_time(index = month_end) %>%
  arrange(month_end) %>%
  time_decompose(Total_Days, method = "twitter") %>%
  anomalize(remainder, method = "gesd") %>%
  plot_anomaly_decomposition() +
  labs(title = "Decomposition of Anomalized Total IP Days")

df_anomalized_tbl <- df_monthly_tbl %>%
  tibbletime::as_tbl_time(index = month_end) %>%
  arrange(month_end) %>%
  time_decompose(Total_Days, method = "twitter") %>%
  anomalize(remainder, method = "gesd") %>%
  clean_anomalies() %>%
  time_recompose() %>%
  select(month_end, observed, observed_cleaned)

# Coerce to tsibble ----
# This should be done only before modeling data
df_tsbl <- df_anomalized_tbl %>%
  mutate(year_month = yearmonth(month_end)) %>%
  select(year_month, observed, observed_cleaned) %>%
  as_tsibble(index = year_month)

df_tsbl
interval(df_tsbl)
count_gaps(df_tsbl)

# Visualize ----
df_tsbl %>% gg_tsdisplay(y = observed_cleaned)

dcmp <- df_tsbl %>% 
  model(STL(observed_cleaned ~ season(window = Inf)))

components(dcmp) %>%
  autoplot()

df_tsbl %>%
  gg_subseries(y = observed_cleaned)

df_tsbl %>%
  features(observed_cleaned, feat_stl) %>%
  pivot_longer(cols = everything(), names_to = "Metric")

# Model ----
models <- df_tsbl %>%
  model(
    ets      = ETS(observed_cleaned)
    , arima  = ARIMA(observed_cleaned)
    , nnetar = NNETAR(observed_cleaned, n_nodes = 10)
    , rw     = RW(observed_cleaned)
  )

models_acc <- accuracy(models) %>% 
  arrange(MAE) %>%
  mutate(model = .model %>% as_factor()) %>%
  mutate(model_numeric = .model %>% as_factor() %>% as.numeric())

models_tidy <- augment(models) %>%
  mutate(key = "actual") %>%
  set_names(
    "Model"
    ,"Year_Month"
    ,"Count"
    ,"Fitted"
    ,"Residuals"
    , "key"
  ) %>%
  as_tibble()

model_desc <- models %>% 
  as_tibble() %>%
  gather() %>%
  mutate(model_desc = print(value)) %>%
  select(key, model_desc) %>%
  set_names("model", "model_desc")

print_mod_desc <- function(x) {
  
  model <- model_desc %>%
    select(model_desc)
  
  return(print(paste0(model,"\n")))
  
}

print_mod_desc(model_desc)
model_descriptions <- model_desc$model_desc

# Plot residuals ----
models_tidy %>%
  inner_join(models_acc, by = c("Model" = ".model")) %>%
  inner_join(model_desc, by = c("Model" = "model")) %>%
  select(Model, Year_Month, model, model_desc, Residuals, key) %>%
  ggplot(
    mapping = aes(
      x = Year_Month
      , y = Residuals
      , group = model
    )
  ) +
  geom_hline(yintercept = 0) +
  geom_line(color = palette_light()[[2]]) +
  facet_wrap(
    ~ model
    , ncol = 1
    , scales = "free_y"
  ) +
  theme_tq() +
  labs(x = "", caption = map(model_desc, print_mod_desc))

models_fcast <- models %>% 
  forecast(h = "12 months") %>%
  as_tibble() %>%
  select(.model, year_month, observed_cleaned) %>%
  mutate(key = "forecast") %>%
  set_names("Model", "Year_Month","Count", "key")

winning_model_label <- models_acc %>%
  filter(model_numeric == 1) %>%
  left_join(model_desc, by = c(".model" = "model")) %>%
  select(model_desc)

# Forecast Plot ----
models_tidy %>%
  filter(year(Year_Month) > 2014) %>%
  ggplot(
    mapping = aes(
      x = Year_Month
      , y = Count
      , group = Model
    )
  ) +
  geom_point(    
    alpha = 0.5
    , color = palette_light()[[1]]
  ) +
  geom_line(
    alpha = 0.5
    , size = 1
  ) +
  geom_point(
    data = models_fcast
    , mapping = aes(
      x = Year_Month
      , y = Count
      , group = Model
      , color = Model
    )
  ) +
  geom_line(
    data = models_fcast
    , mapping = aes(
      x = Year_Month
      , y = Count
      , group = Model
      , color = Model
    )
    , size = 1
  ) +
  theme_tq() +
  scale_color_tq() +
  labs(
    title = "Total IP Days Monthly Scale"
    , subtitle = 
      paste0(
        "Source: DSS - 12 Month Forecast\n"
        ,"Winning Model - "
        , winning_model_label
        , "\n"
        , "MAE - "
        , round(
          models_acc %>% 
            filter(model_numeric == 1) %>% 
            select(MAE)
          , 4
        )
        , "\n"
        , "Forecast: "
        , models_fcast %>% 
          filter(
            str_sub(Model, 1, 2) == winning_model_label %>% 
              pull() %>% 
              str_to_lower() %>% 
              str_sub(1, 2)) %>% 
          head(1) %>% 
          select(Count) %>% 
          pull() %>%
          round(digits = 0)
      )
    , caption = paste0(
      "Based on discharges from: "
      , min.date
      , " through "
      , max.date
    )
    , y = "Count"
    , x = ""
  )
