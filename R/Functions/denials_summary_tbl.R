denials_summary_tbl <- function() {
    
    denials_count_tbl <- denial_data_tbl %>%
        filter(payer_category == "Other") %>%
        filter(patient_type == 'I') %>%
        select(
            denial_dr_no
            , denial_dr
            , adm_date
            , record_flag
        ) %>%
        mutate(adm_yr = year(adm_date)) %>%
        group_by(
            denial_dr_no
            , denial_dr
            , adm_yr
        ) %>%
        summarise(
            denials = sum(record_flag, na.rm = TRUE)
        ) %>%
        ungroup() %>%
        pivot_wider(
            values_from = denials
            , names_from = adm_yr
            , values_fill = list(
                denials = 0
            )
        ) %>%
        pivot_longer(
            cols = c(-denial_dr_no, -denial_dr)
            , names_to = "year"
            , values_to = "denials"
            , values_drop_na = FALSE
        )
    
    denials_appealed_tbl <- denial_data_tbl %>%
        filter(payer_category == "Other") %>%
        filter(patient_type == 'I') %>%
        select(
            denial_dr_no
            , denial_dr
            , adm_date
            , appl_dollars_appealed
        ) %>%
        mutate(adm_yr = year(adm_date)) %>%
        group_by(
            denial_dr_no
            , denial_dr
            , adm_yr
        ) %>%
        summarise(
            dollars_appealed = sum(appl_dollars_appealed, na.rm = TRUE)
        ) %>%
        ungroup() %>%
        pivot_wider(
            values_from = dollars_appealed
            , names_from = adm_yr
            , values_fill = list(
                dollars_appealed = 0
            )
        ) %>%
        pivot_longer(
            cols = c(-denial_dr_no, -denial_dr)
            , names_to = "year"
            , values_to = "dollars_appealed"
            , values_drop_na = FALSE
        )
    
    denials_recovered_tbl <- denial_data_tbl %>%
        filter(payer_category == "Other") %>%
        filter(patient_type == 'I') %>%
        select(
            denial_dr_no
            , denial_dr
            , adm_date
            , appl_dollars_recovered
        ) %>%
        mutate(adm_yr = year(adm_date)) %>%
        group_by(
            denial_dr_no
            , denial_dr
            , adm_yr
        ) %>%
        summarise(
            dollars_recovered = sum(appl_dollars_recovered, na.rm = TRUE)
        ) %>%
        ungroup() %>%
        pivot_wider(
            values_from = dollars_recovered
            , names_from = adm_yr
            , values_fill = list(
                dollars_recovered = 0
            )
        ) %>%
        pivot_longer(
            cols = c(-denial_dr_no, -denial_dr)
            , names_to = "year"
            , values_to = "dollars_recovered"
            , values_drop_na = FALSE
        )
    
    admits_tbl <- admits_by_md_tbl %>%
        filter(payer_category == "Other") %>%
        select(
            atn_dr_no
            , provider_name
            , adm_yr
            , hosp_pvt
            , pt_count
        ) %>%
        group_by(
            atn_dr_no
            , provider_name
            , hosp_pvt
            , adm_yr
        ) %>%
        summarise(
            ip_count = sum(pt_count, na.rm = TRUE)
        ) %>%
        ungroup() %>%
        pivot_wider(
            values_from = ip_count
            , names_from = adm_yr
            , values_fill = list(ip_count = 0)
        ) %>%
        pivot_longer(
            cols = c(-atn_dr_no, -provider_name, -hosp_pvt)
            , names_to = "year"
            , values_to = "arrival_count"
        )
    
    summary_tbl <- denials_count_tbl %>%
        left_join(
            denials_appealed_tbl %>% select(denial_dr_no, year, dollars_appealed)
            , by = c(
                "year" = "year"
                , "denial_dr_no" = "denial_dr_no"
            )
        ) %>%
        left_join(
            denials_recovered_tbl %>% select(denial_dr_no, year, dollars_recovered)
            , by = c(
                "year" = "year"
                , "denial_dr_no" = "denial_dr_no"
            )
        ) %>%
        left_join(
            admits_tbl
            , by = c(
                "year" = "year"
                , "denial_dr_no" = "atn_dr_no"
            )
        ) %>%
        mutate(
            perc_denied = case_when(
                denials > 0 ~ denials / arrival_count
                , TRUE ~ 0
            )
            , perc_recovered = case_when(
                dollars_appealed > 0 ~ dollars_recovered / dollars_appealed
                , TRUE ~ 0
            )
        ) %>% 
        select(
            year
            , hosp_pvt
            , arrival_count
            , denials
            , perc_denied
            , dollars_appealed
            , dollars_recovered
            , perc_recovered
        ) %>%
        group_by(
            year
            , hosp_pvt
        ) %>%
        summarise(
            admissions = sum(arrival_count, na.rm = TRUE)
            , denials = sum(denials, na.rm = TRUE)
            , perc_denied = denials / admissions
            , dollars_appealed = sum(dollars_appealed, na.rm = TRUE)
            , dollars_recovered = sum(dollars_recovered, na.rm = TRUE)
            , perc_recovered = dollars_recovered / dollars_appealed
        ) %>%
        ungroup() %>%
        filter(year >= 2013) %>%
        filter(!is.na(hosp_pvt))
    
    return(summary_tbl)
}
