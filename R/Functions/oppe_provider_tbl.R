oppe_provider_tbl <- function(provider_id) {
    
    # DB Connection ----
    db_con <- dbConnect(
        odbc(),
        Driver = "SQL Server",
        Server = "BMH-HIDB",
        Database = "SMSPHDSSS0X0",
        Trusted_Connection = T
    )
    
    # Get Data ----
    provider_tbl <- tbl(
        db_con,
        in_schema(
            schema = "smsdss"
            , table = "pract_dim_v"
        )
    ) %>%
        filter(
            orgz_cd == 'S0X0'
            , src_pract_no == provider_id
        ) %>%
        as_tibble() %>%
        select(
            src_pract_no
            , pract_rpt_name
            , src_spclty_cd
            , orgz_cd
            , med_staff_dept
        ) %>%
        mutate(
            pract_rpt_name = str_to_title(pract_rpt_name)
        ) %>%
        clean_names()
    
    # DB Disconnect ----
    dbDisconnect(db_con)
    
    # Return data ----
    return(provider_tbl)
}