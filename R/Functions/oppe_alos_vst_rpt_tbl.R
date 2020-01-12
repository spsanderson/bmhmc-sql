oppe_alos_vst_rpt_tbl <- function() {
    
    # DB Connection ----
    db_con <- dbConnect(
        odbc(),
        Driver = "SQL Server",
        Server = "BMH-HIDB",
        Database = "SMSPHDSSS0X0",
        Trusted_Connection = T
    )
    
    # Get Data ----
    alos_vst_rpt_tbl <- tbl(
        db_con,
        in_schema(
            schema = "smsmir"
            , table = "vst_rpt"
        )
    ) %>%
        filter(
            vst_end_date >= alos_start_date
            , vst_end_date < alos_end_date
            , vst_type_cd == "I"
        ) %>%
        select(
            pt_id
            , ward_cd
        ) %>%
        as_tibble() %>%
        mutate(pt_id = pt_id %>% str_squish()) %>%
        clean_names()
    
    # DB Disconnect ----
    dbDisconnect(db_con)
    
    # Return Data ----
    return(alos_vst_rpt_tbl)
    
}




