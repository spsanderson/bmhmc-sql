# DSS Connection 
db_connect <- function() {
  db_con <- DBI::dbConnect(
    odbc::odbc(),
    Driver = "SQL Server",
    Server = "LI-HIDB",
    Database = "SMSPHDSSS0X0",
    Trusted_Connection = TRUE
  )
  
  return(db_con)
  
}

# Disconnect from Database
db_disconnect <- function(.connection) {
  
  DBI::dbDisconnect(
    conn = db_connect()
  )
}
