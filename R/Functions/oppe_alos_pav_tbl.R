oppe_alos_pav_tbl <- function(provider_id) {
    
    # DB Connection ----
    db_con <- dbConnect(
        odbc(),
        Driver = "SQL Server",
        Server = "BMH-HIDB",
        Database = "SMSPHDSSS0X0",
        Trusted_Connection = T
    )
    
    # Get Data ----
    alos_svc_line_tbl <- tbl(
        db_con,
        in_schema(
            schema = "smsdss"
            , table = "c_LIHN_Svc_Line_tbl "
        )
    ) %>%
        as_tibble() %>%
        clean_names()
    
    alos_pav_tbl <- tbl(
        db_con,
        in_schema(
            schema = "smsdss"
            , table = "BMH_PLM_PtAcct_V"
        )
    ) %>%
        filter(
            Dsch_Date >= alos_start_date
            , Dsch_date < alos_end_date
            , Plm_Pt_Acct_Type == "I"
            , tot_chg_amt > 0
            , str_sub(PtNo_Num %>% as.character(), 1, 1) != '2'
            , str_sub(PtNo_Num %>% as.character(), 1, 4) != '1999'
            , !is.na(drg_no)
            , !drg_no %in% c(
                '0','981','982','983','984','985',
                '986','987','988','989','998','999'
            )
            , Atn_Dr_No == provider_id
        ) %>%
        select(
            Med_Rec_No
            , Pt_No
            , PtNo_Num
            , Adm_Date
            , Dsch_Date
            , Days_Stay
            , Atn_Dr_No
            , drg_no
            , drg_cost_weight
            , Regn_Hosp
            , Pyr1_Co_Plan_Cd
        ) %>%
        mutate(
            Dsch_Month = month(Dsch_Date)
            , Dsch_Yr = year(Dsch_Date)
            , LOS = if_else(
                Days_Stay == '0'
                , '1'
                , Days_Stay
            )
        ) %>%
        as_tibble()
    
    alos_pav_tbl <- alos_pav_tbl %>%
        mutate(
            PtNo_Num = PtNo_Num %>% as.character()
            , Pt_No = Pt_No %>% str_squish()
        ) %>%
        clean_names()
    
    # DB Disconnect ----
    dbDisconnect(db_con)
    
    # Return Data ----
    return(alos_pav_tbl)
    
}