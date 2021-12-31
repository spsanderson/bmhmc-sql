library(rmarkdown)
Sys.setenv(RSTUDIO_PANDOC="C:/Program Files/RStudio/bin/pandoc")
# # No need to set working director since r studio projects handle that
# # already
rmarkdown::render(
  input = "C:/Users/li-reports/Documents/R_Studio_Projects/Executive_Dashboard/executive_dashboard.Rmd"
  , output_file = "executive_dashboard"
  , output_dir = fs::path_wd()
)