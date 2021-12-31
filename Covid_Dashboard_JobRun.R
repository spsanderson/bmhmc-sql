library(rmarkdown)
Sys.setenv(RSTUDIO_PANDOC="C:/Program Files/RStudio/bin/pandoc")
# # No need to set working director since r studio projects handle that
# # already
rmarkdown::render(
  input = "C:/Users/li-reports/Documents/R_Studio_Projects/Covid_Dashboard/covid_dashboard_rpt_v3.Rmd"
  , output_file = "covid_dashboard_rpt_v3"
  , output_dir = fs::path_wd()
)

rmarkdown::render(
  input = "C:/Users/li-reports/Documents/R_Studio_Projects/Covid_Dashboard/covid_dashboard_rpt_v4.Rmd"
  , output_file = "covid_dashboard_rpt_v4"
  , output_dir = fs::path_wd()  
)
