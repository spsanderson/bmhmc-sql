denials_by_provider_op <- function(admit_yr) {
    
    # Denial Counts ----
    denials_count_tbl <- denial_data_tbl %>%
        filter(payer_category == "Other") %>%
        filter(patient_type != 'I') %>%
        select(
            denial_dr_no
            , denial_dr
            , adm_date
            , denial_spclty
            , record_flag
        ) %>%
        mutate(adm_yr = year(adm_date)) %>%
        group_by(
            denial_dr_no
            , denial_dr
            , denial_spclty
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
            cols = c(-denial_dr_no, -denial_dr, -denial_spclty)
            , names_to = "year"
            , values_to = "denials"
            , values_drop_na = FALSE
        )
    
    # Dollars Appealed ----
    denials_appealed_tbl <- denial_data_tbl %>%
        filter(payer_category == "Other") %>%
        filter(patient_type != 'I') %>%
        select(
            denial_dr_no
            , denial_dr
            , adm_date
            , denial_spclty
            , appl_dollars_appealed
        ) %>%
        mutate(adm_yr = year(adm_date)) %>%
        group_by(
            denial_dr_no
            , denial_dr
            , denial_spclty
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
            cols = c(-denial_dr_no, -denial_dr, -denial_spclty)
            , names_to = "year"
            , values_to = "dollars_appealed"
            , values_drop_na = FALSE
        )
    
    # Dollars Recovered ----
    denials_recovered_tbl <- denial_data_tbl %>%
        filter(payer_category == "Other") %>%
        filter(patient_type != 'I') %>%
        select(
            denial_dr_no
            , denial_dr
            , adm_date
            , denial_spclty
            , appl_dollars_recovered
        ) %>%
        mutate(adm_yr = year(adm_date)) %>%
        group_by(
            denial_dr_no
            , denial_dr
            , denial_spclty
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
            cols = c(-denial_dr_no, -denial_dr, -denial_spclty)
            , names_to = "year"
            , values_to = "dollars_recovered"
            , values_drop_na = FALSE
        )
    
    # Summary Tbl
    provider_summary_tbl <- denials_count_tbl %>%
        left_join(
            denials_appealed_tbl %>% 
                select(
                    denial_dr_no
                    , year
                    , dollars_appealed
                )
            , by = c(
                "year" = "year"
                , "denial_dr_no" = "denial_dr_no"
            )
        ) %>%
        left_join(
            denials_recovered_tbl %>% 
                select(
                    denial_dr_no
                    , year
                    , dollars_recovered
                )
            , by = c(
                "year" = "year"
                , "denial_dr_no" = "denial_dr_no"
            )
        ) %>%
        mutate(
            perc_recovered = case_when(
                dollars_appealed > 0 ~ dollars_recovered / dollars_appealed
                , TRUE ~ 0
            )
        ) %>% 
        select(
            year
            , denial_dr_no
            , denial_dr
            , denial_spclty
            , denials
            , dollars_appealed
            , dollars_recovered
            , perc_recovered
        ) %>%
        group_by(
            year
            , denial_dr_no
            , denial_dr
            , denial_spclty
        ) %>%
        summarise(
            denials = sum(denials, na.rm = TRUE)
            , dollars_appealed = sum(dollars_appealed, na.rm = TRUE)
            , dollars_recovered = sum(dollars_recovered, na.rm = TRUE)
            , perc_recovered = case_when(
                dollars_recovered > 0 ~ dollars_recovered / dollars_appealed
                , TRUE ~ 0.0
            )
        ) %>%
        ungroup() %>%
        filter(year == admit_yr) %>%
        filter(!is.na(denial_dr_no)) %>%
        filter(dollars_appealed > 0)
    
    return(provider_summary_tbl)
    
}