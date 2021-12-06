oppe_cpoe_detail_tbl <- function(provider_id) {
    
    # DB Connection ----
    db_con <- dbConnect(
        odbc(),
        Driver = "SQL Server",
        Server = "LI-HIDB",
        Database = "SMSPHDSSS0X0",
        Trusted_Connection = T
    )
    
    # Get Data ----
    cpoe_detail_tbl <- tbl(
        db_con,
        in_schema(
            schema = "smsdss"
            , table = "c_CPOE_Rpt_Tbl_Rollup_v"
        )
    ) %>%
        select(
            req_pty_cd
            , Hospitalist_Np_Pa_Flag
            , Ord_Type_Abbr
            , Unknown
            , Telephone
            , `Per RT Protocol`
            #, Communication
            , `Specimen Collect`
            , `Specimen Redraw`
            , CPOE
            , `Nursing Order`
            , Written
            , `Verbal Order`
            , ent_date
        ) %>%
        as_tibble() %>%
        clean_names() %>%
        mutate(ent_date = ymd(ent_date)) %>%
        filter(req_pty_cd == provider_id) %>%
        as_tbl_time(index = ent_date) %>%
        arrange(ent_date)
    
    # DB Disconnect ----
    dbDisconnect(db_con)
    
    # Return Data ----
    return(cpoe_detail_tbl)
    
}

