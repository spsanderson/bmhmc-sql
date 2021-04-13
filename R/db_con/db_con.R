# DB Connection ----
db_con <- dbConnect(
  odbc(),
  Driver = "SQL Server",
  Server = "LI-HIDB",
  Database = "SMSPHDSSS0X0",
  Trusted_Connection = T
)