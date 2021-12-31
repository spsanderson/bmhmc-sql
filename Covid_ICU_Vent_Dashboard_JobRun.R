library(rmarkdown)
Sys.setenv(RSTUDIO_PANDOC="C:/Program Files/RStudio/bin/pandoc")
# # No need to set working director since r studio projects handle that
# # already
rmarkdown::render(
  input = "C:/Users/li-reports/Documents/R_Studio_Projects/Covid_ICU_Vent_Dashboard/covid_icu_vent_dashboard_rpt.Rmd"
  , output_file = "covid_icu_vent_dashboard_rpt"
  , output_dir = fs::path_wd()
)
