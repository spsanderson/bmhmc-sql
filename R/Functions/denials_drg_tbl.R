denials_drg_tbl <- function() {
    
    data <- denial_data_tbl %>%
        filter(adm_yr >= max(adm_yr) - 4) %>%
        filter(payer_category == 'Other') %>%
        filter(patient_type == "I") %>%
        select(record_flag, drg, drg_name, adm_yr) %>%
        group_by(adm_yr, drg, drg_name) %>%
        summarise(denial_count = sum(record_flag, na.rm = TRUE)) %>%
        ungroup() %>%
        group_by(adm_yr) %>%
        arrange(desc(denial_count)) %>%
        mutate(record_flag = row_number()) %>%
        ungroup() %>%
        filter(record_flag <= 10) %>%
        select(adm_yr, drg, drg_name, denial_count) %>%
        arrange(desc(adm_yr),desc(denial_count)) %>%
        set_names("Admit_Year", "DRG", "DRG Description", "Denial Count") %>%
        nest(drg_data = -Admit_Year)
    
    return(data)
    
}