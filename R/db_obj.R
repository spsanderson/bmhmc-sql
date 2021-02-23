#' DSS DB Connection Function
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' Connect to DSS
#'
#' @details
#' - DSS Connection function
#' - Must have a valid DSS connection object on your local pc and DSS permissions
#'
#' @examples
#' db_connect()
#'
#' @return
#' A SQL-SERVER DSS connection object
#'
#' @export
#'

#db_connect <- function() {
  #db_con <- base::source("R/db_con.R")

db_connect <- function() {
  db_con <- DBI::dbConnect(
    odbc::odbc(),
    Driver = "SQL Server",
    #Server = "LI-HIDB",
    Server = "BMH-HIDB",
    Database = "SMSPHDSSS0X0",
    Trusted_Connection = TRUE
  )

  return(db_con)

}

#' DSS DB Disconnect Function
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' Disconnect from DSS
#'
#' @details
#' - DSS Disconnect function
#' - Must have a valid DSS connection object on your local pc and DSS permissions
#'
#' @param .connection The connection object returned from [db_connect()]
#'
#' @examples
#' db_disconnect()
#'
#' @return
#' A SQL-SERVER DSS connection object
#'
#' @export
#'

db_disconnect <- function(.connection) {

  DBI::dbDisconnect(
    conn = db_connect()
  )
}
