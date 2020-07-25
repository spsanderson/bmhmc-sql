oppe_alos_final_tbl <- function() {
    
    # Final ALOS Table ----
    alos_tbl <- alos_svc_line_tbl %>%
        # joins
        inner_join(
            alos_pav_tbl
            , by = c("encounter" = "pt_no")
            , keep = T
        ) %>%
        left_join(
            alos_aprdrg_tbl
            , by = c("pt_no_num" = "encounter")
            , keep = T
        ) %>%
        left_join (
            alos_bench_tbl
            , by = c(
                "lihn_svc_line" = "lihn_service_line"
                , "aprdrgno" = "aprdrg_code"
                , "severity_of_illness" = "soi"
            )
            , keep = T
        ) %>%
        left_join(
            provider_tbl
            , by = c(
                "atn_dr_no" = "src_pract_no"
                , "regn_hosp" = "orgz_cd"
            )
            , keep = T
        ) %>%
        left_join(
            alos_outlier_tbl
            , by = c("aprdrgno" = "apr_minus_drg_code")
            , keep = T
        ) %>%
        left_join(
            alos_pyr_dim_tbl
            , by = c(
                "pyr1_co_plan_cd" = "pyr_cd"
                , "regn_hosp" = "orgz_cd"
            )
            , keep = T
        ) %>%
        left_join(
            alos_vst_rpt_tbl
            , by = c("encounter.x" = "pt_id")
            , keep = T
        ) %>%
        rename(encounter = encounter.x) %>%
        # select statement
        select(
            med_rec_no
            , encounter
            , pt_no_num
            , adm_date
            , dsch_date
            , dsch_month
            , dsch_yr
            , days_stay
            , atn_dr_no
            , pract_rpt_name
            , drg_no
            , lihn_svc_line
            , src_spclty_cd
            , aprdrgno
            , severity_of_illness
            , performance
            , outlier_threshold
            , drg_cost_weight
            , pyr_group2
            , med_staff_dept
            , ward_cd
        ) %>%
        # mutate statements
        mutate(
            los = if_else(
                days_stay == 0
                , 1.0
                , days_stay
            )
            , hosim = if_else(
                src_spclty_cd == 'HOSIM'
                , "Hospitalist"
                , "Private"
            )
            , performance = case_when(
                performance == 0 ~ 1.0
                , (is.na(performance) & los == 0) ~ 1.0
                , (is.na(performance) & los != 0) ~ (los %>% as.numeric())
                , T ~ performance
            )
            , outlier_flag = if_else(
                los > outlier_threshold
                , 1
                , 0
            )
            , case_var = round((los - performance), 4)
            , case_index = round(los / performance, 4)
            , los_sd = sd(los)
            , z_minus_score = round((los - performance) / los_sd, 4)
            , zscore_ul = 1.96
            , zscore_ll = -1.96
            , last_rpt_month = if_else(
                dsch_month < 10
                , str_c(dsch_yr, 0, dsch_month)
                , str_c(dsch_yr, dsch_month)
            )
            , proper_name = str_to_title(pract_rpt_name)
        ) %>%
        as_tbl_time(index = dsch_date) %>%
        arrange(dsch_date)
    
    # Return Data ----
    return(alos_tbl)
    
}




