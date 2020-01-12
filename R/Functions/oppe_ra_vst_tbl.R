oppe_ra_vst_tbl <- function() {
    
    # DB Connection ----
    db_con <- dbConnect(
        odbc(),
        Driver = "SQL Server",
        Server = "BMH-HIDB",
        Database = "SMSPHDSSS0X0",
        Trusted_Connection = T
    )
    
    # Get Data ----
    ra_vst_tbl <- tbl(
        db_con,
        in_schema(
            schema = "smsmir"
            , table = "vst_rpt"
        )
    ) %>%
        filter(
            vst_type_cd == "I"
        ) %>%
        select(
            pt_id
            , ward_cd
        ) %>%
        as_tibble() %>%
        mutate(
            pt_id = pt_id %>% str_squish()
            , episode_no = str_sub(pt_id, 5)
        ) %>%
        filter(!is.na(ward_cd)) %>%
        clean_names()
    
    # DB Disconnect ----
    dbDisconnect(db_con)
    
    # Return Data ----
    return(ra_vst_tbl)
    
}




