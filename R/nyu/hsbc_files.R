library(tidyverse)
library(readxl)

f_path <- "G://IS//M Shortell//HBCS_Test_Files//"
f_list <- dir(f_path, pattern = "\\.xlsx$", full.names = TRUE)

files <- f_list %>% map(read_xlsx)

file_names <- f_list %>%
  str_remove(f_path) %>%
  str_replace(pattern = ".xlsx",
              replacement = ".txt")

names(files) <- file_names

for (i in 1:length(files)){
  write_delim(
    x = files[[i]],
    delim = "|",
    file = paste0(f_path, names(files[i]))
  )
}
