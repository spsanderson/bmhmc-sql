oppe_alos_aprdrg_tbl <- function() {
    
    # DB Connection ----
    db_con <- dbConnect(
        odbc(),
        Driver = "SQL Server",
        Server = "BMH-HIDB",
        Database = "SMSPHDSSS0X0",
        Trusted_Connection = T
    )
    
    # Get Data ----
    alos_aprdrg_tbl <- tbl(
        db_con,
        in_schema(
            schema = "Customer"
            , table = "Custom_DRG"
        )
    ) %>%
        select(
            `PATIENT#`
            , APRDRGNO
            , SEVERITY_OF_ILLNESS
        ) %>%
        as_tibble() %>%
        rename(Encounter = `PATIENT#`) %>%
        mutate(Encounter = Encounter %>% str_squish()) %>%
        clean_names()
    
    # DB Disconnect ----
    dbDisconnect(db_con)
    
    # Return Data ----
    return(alos_aprdrg_tbl)
    
}




