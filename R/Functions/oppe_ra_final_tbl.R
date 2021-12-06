oppe_ra_final_tbl <- function() {
    
    # DB Connection ----
    db_con <- dbConnect(
        odbc(),
        Driver = "SQL Server",
        Server = "LI-HIDB",
        Database = "SMSPHDSSS0X0",
        Trusted_Connection = T
    )
    
    # Get Data ----
    readmit_tbl <- ra_detail_tbl %>%
        left_join(
            ra_bench_tbl
            , by = c(
                "lihn_svc_line" = "lihn_svc_line"
                , "dsch_bench_yr" = "bench_yr"
                , "severity_of_illness" = "soi"
            )
        ) %>%
        left_join(
            ra_vst_tbl
            , by = c("pt_no_num" = "episode_no")
        ) %>%
        mutate(
            adm_date = ymd(adm_date)
            , dsch_date = ymd(dsch_date)
            , pt_count = 1
            , bench_yr = dsch_bench_yr
            , ra_sd = sd(ra_flag)
            , z_minus_score = round(
                (ra_flag - readmit_rate) / ra_sd, 4
            )
            , severity_of_illness = severity_of_illness %>%
                as.numeric()
            , proper_name =  str_to_title(pract_rpt_name)
        ) %>%
        select(
            med_rec_no
            , pt_no_num
            , adm_date
            , dsch_date
            , payor_category
            , atn_dr_no
            , pract_rpt_name
            , proper_name
            , med_staff_dept
            , lihn_svc_line
            , severity_of_illness
            , dsch_yr
            , dsch_month
            , dsch_day_name
            , dsch_disp
            , dsch_disp_desc
            , drg_cost_weight
            , hospitalist_private
            , los
            , interim
            , pt_count
            , ra_flag
            , bench_yr
            , readmit_rate
            , ra_sd
            , z_minus_score
            , ward_cd
        ) %>%
        rename(
            readmit_rate_bench = readmit_rate
            , readmit_count = ra_flag
        ) %>%
        filter(atn_dr_no == provider_id) %>%
        as_tbl_time(index = dsch_date) %>%
        arrange(dsch_date)
    
    # DB Disconnect ----
    dbDisconnect(db_con)
    
    # Return Data ----
    return(readmit_tbl)
    
}




