library(taskscheduleR)

taskscheduler_create(
  taskname = "RStudio_ER_RealTime_Census_Staffing_15Minutes"
  , rscript = "99_Automations/ER_Staff_Census_JobRun.R"
  , schedule = "MINUTE"
  , starttime = "15:33"
  , modifier = 15
)

taskscheduler_delete(taskname = "RStudio_ER")