oppe_alos_outlier_tbl <- function() {
    
    # DB Connection ----
    db_con <- dbConnect(
        odbc(),
        Driver = "SQL Server",
        Server = "BMH-HIDB",
        Database = "SMSPHDSSS0X0",
        Trusted_Connection = T
    )
    
    # Get Data ----
    alos_outlier_tbl <- tbl(
        db_con,
        in_schema(
            schema = "smsdss"
            , table = "c_LIHN_APR_DRG_OutlierThresholds"
        )
    ) %>%
        as_tibble() %>%
        clean_names()
    
    # DB Disconnect ----
    dbDisconnect(db_con)
    
    # Return Data ----
    return(alos_outlier_tbl)
    
}




