denials_data <- function() {
    
    denial_data <- read_excel(
        path = "denials_data.xlsx"
        , sheet = "denials"
    ) %>%
        clean_names()
    
    denial_data <- denial_data %>%
        select(
            tmbptbl_bill_no
            , attend_dr_no
            , attend_dr
            , attend_spclty
            , adm_dr_no
            , adm_dr
            , edmdid
            , ed_md
            , last_name
            , first_name
            , patient_type
            , appl_dollars_appealed
            , appl_dollars_recovered
            , s_cpm_dollars_not_appealed
            , denial_dr_no
            , denial_dr
            , denial_spclty
            , length_of_stay
            , short_stay_indicator
            , long_stay_indicator
            , short_stay_appeal_indicator
            , long_stay_appeal_indicator
            , visit_admit_diag
            , admit_diag_description
            , admission_date
            , adm_yr
            , adm_month
            , discharged
            , dsch_yr
            , dsch_mo
            , pyr_cd
            , pyr_name
            , appeal_year
            , denials
            , drg
            , drg_name
            , ward_cd
        ) %>%
        mutate(
            denial_dr_no = right(denial_dr_no, 6)
            , attend_dr_no = right(attend_dr_no, 6)
        ) %>%
        mutate(
            adm_date = anytime::anydate(admission_date)
            , dsch_date = anytime::anydate(discharged)
        ) %>%
        mutate(
            record_flag = 1
        ) %>%
        mutate(
            payer_category = case_when(
                left(pyr_cd, 1) == 'A' ~ 'Medicare'
                , left(pyr_cd, 1) == 'Z' ~ 'Medicare'
                , left(pyr_cd, 1) == 'W' ~ 'Medicaid'
                , pyr_cd == '*' ~ 'Self Pay'
                , left(pyr_cd, 1) == 'C' ~ 'Comp'
                , left(pyr_cd, 1) == 'N' ~ 'No Fault'
                , TRUE ~ 'Other'
            )
        )
    
    return(denial_data)
}