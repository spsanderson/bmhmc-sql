# DB Connection ----
db_con <- DBI::dbConnect(
  odbc::odbc(),
  Driver = "SQL Server",
  Server = "BMH-HIDB",
  Database = "SMSPHDSSS0X0",
  Trusted_Connection = T
)
