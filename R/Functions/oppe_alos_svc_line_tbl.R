oppe_alos_svc_line_tbl <- function() {
    
    # DB Connection ----
    db_con <- dbConnect(
        odbc(),
        Driver = "SQL Server",
        Server = "BMH-HIDB",
        Database = "SMSPHDSSS0X0",
        Trusted_Connection = T
    )
    
    # Get Data ----
    alos_svc_line_tbl <- tbl(
        db_con,
        in_schema(
            schema = "smsdss"
            , table = "c_LIHN_Svc_Line_tbl "
        )
    ) %>%
        as_tibble() %>%
        clean_names()
    
    # DB Disconnect ----
    dbDisconnect(db_con)
    
    # Return Data ----
    return(alos_svc_line_tbl)
    
}




