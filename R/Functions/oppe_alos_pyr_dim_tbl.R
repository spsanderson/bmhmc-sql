oppe_alos_pyr_dim_tbl <- function() {
    
    # DB Connection ----
    db_con <- dbConnect(
        odbc(),
        Driver = "SQL Server",
        Server = "LI-HIDB",
        Database = "SMSPHDSSS0X0",
        Trusted_Connection = T
    )
    
    # Get Data ----
    alos_pyr_dim_tbl <- tbl(
        db_con,
        in_schema(
            schema = "smsdss"
            , table = "pyr_dim_v"
        )
    ) %>%
        as_tibble() %>%
        select(
            pyr_cd
            , orgz_cd
            , pyr_group2
        ) %>%
        clean_names()
    
    # DB Disconnect ----
    dbDisconnect(db_con)
    
    # Return Data ----
    return(alos_pyr_dim_tbl)
    
}




