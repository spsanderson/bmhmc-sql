library(taskscheduleR)

taskscheduler_create(
  taskname = "RStudio_Covid_Dashboard"
  , rscript = "99_Automations/Covid_Dashboard_JobRun.R"
  , schedule = "DAILY"
  , starttime = "07:30"
)