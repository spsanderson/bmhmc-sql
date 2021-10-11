# Lib Load ----------------------------------------------------------------

if(!require(pacman)){install.packages("pacman")}
pacman::p_load(
  "dplyr"
  , "fs"
  , "purrr"
)


# File Paths --------------------------------------------------------------

main_path <- "G:/IS/C Wurtz/Sepsis/csv_files/"
file_paths <- dir_info(main_path) %>%
  pull(path)
file_list <- file_paths %>%
  map(.f = dir_info)

names(file_list) <- c(
  "Clinical","Comorbidity","Outcome_at_discharge","Outcome_during_hospitalization",
  "Severity","Treatment"
)

files <- file_list %>%
  map(path, .f = pull) %>%
  map(path, .f = as.character)

files$Clinical %>%
  map_df(read.csv) %>%
  write.csv(file = "G:/IS/C Wurtz/Sepsis/csv_files/Clinical/clincial_to_dss.csv")

files$Comorbidity %>%
  map_df(read.csv) %>%
  write.csv(file = "G:/IS/C Wurtz/Sepsis/csv_files/Comorbidity/comorbidity_to_dss.csv")

files$Outcome_at_discharge %>%
  map_df(read.csv) %>%
  write.csv(file = "G:/IS/C Wurtz/Sepsis/csv_files/Outcome_at_discharge/outcomes_at_discharge_to_dss.csv")

files$Outcome_during_hospitalization %>%
  map_df(read.csv) %>%
  write.csv(file = "G:/IS/C Wurtz/Sepsis/csv_files/Outcome_during_hospitalization/outcome_during_hospitalization_to_dss.csv")

files$Severity %>%
  map_df(read.csv) %>%
  write.csv(file = "G:/IS/C Wurtz/Sepsis/csv_files/Severity/severity_to_dss.csv")

files$Treatment %>%
  map_df(read.csv) %>%
  write.csv(file = "G:/IS/C Wurtz/Sepsis/csv_files/Treatment/treatment_to_dss.csv")