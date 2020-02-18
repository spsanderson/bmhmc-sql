denials_ed_md <- function() {
    
    ed_tbl <- read_excel(
        path = "denials_data.xlsx"
        , sheet = "ed_md"
    ) %>%
        clean_names()

    return(ed_tbl)
    
}