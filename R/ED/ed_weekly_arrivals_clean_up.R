library(tidyverse)
library(timetk)
library(readxl)
library(writexl)
library(lubridate)
library(xlsx)

data_raw_tbl <- read_excel(
  path = "C:/Users/bha485/Desktop/Weekly arrivals.xlsx"
)

data_working_tbl <- data_raw_tbl
colnames(data_working_tbl) <- c(
  "hour","Monday","Tuesday","Wednesday","Thursday",
  "Friday","Saturday","Sunday","drop_col"
)

data_working_tbl <- data_working_tbl %>%
  filter(is.na(drop_col)) %>%
  select(-drop_col)

hours_vector <- c("0000","0100","0200","0300","0400","0500","0600","0700","0800",
                  "0900","1000","1100","1200","1300","1400","1500","1600","1700",
                  "1800","1900","2000","2100","2200","2300")

df1 <- data_working_tbl %>%
  filter(hour %in% hours_vector) %>%
  mutate(week_num = rep(1:(nrow(.)/24), each=24)) %>%
  mutate(hour = as.numeric(hour)/100) %>%
  pivot_longer(c(-hour, -week_num), names_to = "WeekDay", values_to = "value") %>%
  mutate(WeekDay = WeekDay %>% fct_inorder()) %>%
  arrange(week_num, WeekDay, hour)

start_date <- ymd_hms("2018-04-09 00:00:00")

df_final_tbl <- df1 %>% 
  mutate(
    DateTime = start_date + 
               ddays((week_num - 1) * 7 + 
               as.numeric(WeekDay) - 1) + 
      dhours(hour)
  ) %>%
  select(DateTime, value) %>%
  mutate(value = ifelse(is.na(value), 0, value)) %>%
  mutate(value = as.numeric(value))

summary_tbl <- summarise_by_time(
  df_final_tbl,
  .date_var = DateTime,
  .by = "month",
  value = sum(value, na.rm = TRUE)
)

# Write excel file
wb              <- createWorkbook(type = "xlsx")
data_sheet      <- createSheet(wb, sheetName = "original_data")
long_data_sheet <- createSheet(wb, sheetName = "fixed_data")
summary_sheet   <- createSheet(wb, sheetName = "summary_data")
addDataFrame(x = data_raw_tbl, sheet = data_sheet)
addDataFrame(x = df_final_tbl, sheet = long_data_sheet)
addDataFrame(x = summary_tbl,  sheet = summary_sheet)
saveWorkbook(wb, file = "C:/Users/bha485/Desktop/ed_weekly_arrivals.xlsx")
