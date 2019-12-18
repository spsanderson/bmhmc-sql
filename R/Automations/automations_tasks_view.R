library(taskscheduleR)
library(tidyverse)
library(lubridate)

tasks <- taskscheduler_ls()

task_view <- tasks %>%
    as_tibble() %>%
    filter(str_detect(Author, pattern = "bha485")) %>%
    filter(str_detect(TaskName, pattern = ".R")) %>%
    mutate(RunDTime = `Next Run Time`) %>%
    mutate(RunDTime = RunDTime %>% mdy_hms()) %>%
    select(TaskName, RunDTime) %>%
    arrange(RunDTime)

task_view
