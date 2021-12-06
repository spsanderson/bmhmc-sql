oppe_ra_bench_tbl <- function() {
    
    # DB Connection ----
    db_con <- dbConnect(
        odbc(),
        Driver = "SQL Server",
        Server = "LI-HIDB",
        Database = "SMSPHDSSS0X0",
        Trusted_Connection = T
    )
    
    # Get Data ----
    ra_bench_tbl <- tbl(
        db_con,
        in_schema(
            schema = "smsdss"
            , table = "c_Readmit_Dashboard_Bench_Tbl"
        )
    ) %>%
        as_tibble() %>%
        filter(!is.na(SOI)) %>%
        mutate(
            SOI = SOI %>% as.character()
        ) %>%
        clean_names()
    
    # DB Disconnect ----
    dbDisconnect(db_con)
    
    # Return Data ----
    return(ra_bench_tbl)
    
}




