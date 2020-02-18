denials_admit_by_md <- function() {
    
    admits_tbl <- read_excel(
            path = "denials_data.xlsx"
            , sheet = "adm_md"
        ) %>%
        clean_names()

    return(admits_tbl)

}