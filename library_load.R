library_load <-
function(){
  
  if(!require(pacman)){install.packages("pacman")}
  pacman::p_load(
    "DBI"
    , "odbc"
    , "janitor"
    , "dplyr"
    , "tibble"
    , "tidyr"
    , "LICHospitalR"
    , "timetk"
    , "modeltime"
    , "modeltime.resample"
    , "modeltime.h2o"
    , "modeltime.ensemble"
    , "tidyquant"
    , "ggplot2"
    , "ggrepel"
    , "gt"
    , "ggExtra"
  )
  
}
