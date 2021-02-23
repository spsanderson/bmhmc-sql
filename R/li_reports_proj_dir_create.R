if(!require(fs)) {
  install.packages("fs")
}
suppressPackageStartupMessages(library(fs))

folders <- c(
  "00_Scripts"
  , "00_Data"
  , "01_Queries"
  , "02_Data_Manipulation"
  , "03_Viz"
  , "04_TS_Modeling"
  , "99_Automations"
)

fs::dir_create(
  path = folders
)
