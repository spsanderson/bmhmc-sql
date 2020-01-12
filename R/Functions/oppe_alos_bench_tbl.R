oppe_alos_bench_tbl <- function() {
    
    # DB Connection ----
    db_con <- dbConnect(
        odbc(),
        Driver = "SQL Server",
        Server = "BMH-HIDB",
        Database = "SMSPHDSSS0X0",
        Trusted_Connection = T
    )
    
    # Get Data ----
    alos_bench_tbl <- tbl(
        db_con,
        in_schema(
            schema = "smsdss"
            , table = "c_LIHN_SPARCS_BenchmarkRates"
        )
    ) %>%
        filter(
            `Measure ID` == '4'
            , `Benchmark ID` == '3'
        ) %>%
        as_tibble() %>%
        clean_names()
    
    # DB Disconnect ----
    dbDisconnect(db_con)
    
    # Return Data ----
    return(alos_bench_tbl)
    
}




