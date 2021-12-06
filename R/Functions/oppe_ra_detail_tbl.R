oppe_ra_detail_tbl <- function() {
    
    # DB Connection ----
    db_con <- dbConnect(
        odbc(),
        Driver = "SQL Server",
        Server = "LI-HIDB",
        Database = "SMSPHDSSS0X0",
        Trusted_Connection = T
    )
    
    # Get Data ----
    ra_detail_tbl <- tbl(
        db_con,
        in_schema(
            schema = "smsdss"
            , table = "C_READMIT_DASHBOARD_DETAIL_TBL"
        )
    ) %>%
        as_tibble() %>%
        mutate(
            dsch_bench_yr = (Dsch_YR - 1) %>% as.character()
            , SEVERITY_OF_ILLNESS = SEVERITY_OF_ILLNESS %>% as.character()
        ) %>%
        clean_names()
    
    # DB Disconnect ----
    dbDisconnect(db_con)
    
    # Return Data ----
    return(ra_detail_tbl)
    
}




