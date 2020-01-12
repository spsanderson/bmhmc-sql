oppe_cpoe_tbl <- function() {
    
    # Get Data ----
    cpoe_tbl <- cpoe_detail_tbl %>%
        left_join(
            provider_tbl
            , by = c(
                "req_pty_cd" = "src_pract_no"
            )
        ) %>% 
        filter(orgz_cd == "S0X0") %>%
        mutate(
            proper_name = str_to_title(pract_rpt_name)
            , total_orders = 
                unknown +
                telephone +
                per_rt_protocol +
                communication +
                specimen_collect +
                specimen_redraw +
                cpoe +
                nursing_order +
                written +
                verbal_order
        )
    
    return(cpoe_tbl)
}