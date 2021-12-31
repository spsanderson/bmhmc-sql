library(tidyverse)
library(tibbletime)
library(scales)
library(ggridges)

source("S:\\Global Finance\\1 REVENUE CYCLE\\Steve Sanderson II\\Code\\R\\Functions\\clean_names.R")
source("S:\\Global Finance\\1 REVENUE CYCLE\\Steve Sanderson II\\Code\\R\\Functions\\optimal_bin_size.R")

df_los <- readr::read_csv(
  "G:\\R Studio Projects\\phys_report_card\\data\\los.csv"
) %>%
  clean_names() %>%
  filter(ward_cd != "EMER") %>%
  filter(med_staff_dept != "?") %>%
  filter(med_staff_dept != "Pathology")

df_los$dsch_date <- lubridate::mdy(df_los$dsch_date)
df_los <- as_tbl_time(df_los, index = dsch_date)

df_ra <- readr::read_csv(
  "G:\\R Studio Projects\\phys_report_card\\data\\ra.csv"
) %>%
  clean_names() %>%
  filter(ward_cd != "EMER") %>%
  filter(med_staff_dept != "?") %>%
  filter(med_staff_dept != "Pathology")

df_ra <- rename(df_ra, pt_id = "pt_no_num")
df_ra$dsch_date <- lubridate::mdy(df_ra$dsch_date)
df_ra$adm_date  <- lubridate::mdy(df_ra$adm_date)
df_ra <- as_tbl_time(df_ra, index = dsch_date)
df_ra <- df_ra %>% mutate(los = dsch_date - adm_date)

df_a <- df_los %>%
  dplyr::select(
    pt_id
    , dsch_date
    , los
    , performance
    , z_minus_score
    , lihn_service_line
    , hosim
    , severity_of_illness
    , pyr_group2
    , med_staff_dept
    , ward_cd
  )
df_b <- df_ra %>%
  dplyr::select(
    pt_id
    , readmit_count
    , readmit_rate_bench
    , z_minus_score
  )
df_los_ra <- dplyr::inner_join(df_a, df_b, by = "pt_id") %>%
  as_tbl_time(index = dsch_date)

df_los_ra <- df_los_ra %>%
  collapse_by("monthly") %>%
  dplyr::group_by(dsch_date, add = T) %>%
  dplyr::summarize(
    excess_ra = round(mean(readmit_count - readmit_rate_bench), 2)
    , excess_los = round(mean(los - performance), 2)
  ) %>%
  as.data.frame()

ggplot(iris, aes(x = Sepal.Length, y = Species)) + geom_density_ridges(scale = 1)
ggplot(
  data = df_los %>% filter(outlier_flag == 0)
  , aes(
    x = los
    , y = factor(hosim)
    #, fill = ..x..
  )
) +
  geom_density_ridges(scale = 3)

df_los %>%
  filter(outlier_flag == 0) %>%
  group_by(
    lubridate::wday(
      dsch_date
      , week_start = getOption("lubridate.week.start", 7)
      , label = T
      , abbr = F)
    , pyr_group2
    , add = T) %>%
  rename(day_of_week = 'lubridate::wday(...)') %>%
  summarise(
    alos = round(mean(los), 2)
  ) %>%
  ggplot(
    mapping = aes(
      x = day_of_week
      , y = pyr_group2
      , fill = alos
    )
  ) +
  geom_tile() +
  labs(
    x = ""
    , y = ""
  )
