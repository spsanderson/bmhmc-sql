denials_govt_ip <- function(admit_yr) {
    
    data <- denial_data_tbl %>%
        filter(payer_category %in% c("Medicare", "Medicaid")) %>%
        filter(patient_type == 'I') %>%
        filter(adm_yr == admit_yr) %>%
        select(
            adm_yr
            , payer_category
            , appl_dollars_appealed
            , appl_dollars_recovered
            , record_flag
        ) %>%
        group_by(adm_yr, payer_category) %>%
        summarise(
            denials = sum(record_flag, na.rm = TRUE)
            , dollars_appealed = sum(appl_dollars_appealed, na.rm = TRUE)
            , dollars_recovered = sum(appl_dollars_recovered, na.rm = TRUE)
        ) %>%
        ungroup() %>%
        adorn_totals() %>%
        mutate(
            denials = denials %>% 
                scales::number(big.mark = ",", accuracy = 1)
            , dollars_appealed = dollars_appealed %>%
                scales::dollar()
            , dollars_recovered = dollars_recovered %>%
                scales::dollar()
        ) %>%
        set_names(
            "Admit Year"
            , "Payer Category"
            , "Denials"
            , "Dollars Appealed"
            , "Dollars Recovered"
        ) %>%
        kable() %>%
        kable_styling(kable_style)
    
    return(data)
    
}