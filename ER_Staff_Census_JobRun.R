library(rmarkdown)
Sys.setenv(RSTUDIO_PANDOC="C:/Program Files/RStudio/bin/pandoc")
# # No need to set working director since r studio projects handle that
# # already
rmarkdown::render(
 input = "C:/Users/li-reports/Documents/R_Studio_Projects/EmergencyRoom_Real_Time_Staffing/ed_census_staff_rpt.Rmd"
 , output_file = "ed_census_staff_rpt"
 , output_dir = fs::path_wd()
)
