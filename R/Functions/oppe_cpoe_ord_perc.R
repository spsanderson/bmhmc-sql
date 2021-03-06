oppe_cpoe_ord_perc <- function(data) {
    
    # OPPE Lollipop Chart
    
    # Make sure needed packages are installed and loaded
    if(!require(pacman)) install.packages("pacman")
    pacman::p_load(
        "tidyverse"
        , "tidyquant"
        , "readxl"
        , "R.utils"
        , "tibbletime"
    )
    
    oppe_data <- data
    
    if(!nrow(oppe_data) >= 10){
        return(NA)
    } else {
        
        # Order Abbreviation Type
        ord_types <- list("CPOE", "Written", "Verbal", "Telephone")
        ord_types <- unique(ord_types)
        
        # Summarize oppe_data
        oppe_summary_tbl <- oppe_data %>%
            group_by(
                proper_name
            ) %>%
            summarize(
                tot_ord     = sum(total_orders, na.rm = TRUE)
                , Telephone = sum(telephone, na.rm = TRUE) / tot_ord
                , CPOE      = sum(cpoe, na.rm = TRUE) / tot_ord
                , Written   = sum(written, na.rm = TRUE) / tot_ord
                , Verbal    = sum(verbal_order, na.rm = TRUE) / tot_ord
            ) %>%
            filter(
                tot_ord >= 10
            ) %>%
            ungroup() %>%
            pivot_longer(
                cols = c(CPOE, Written, Verbal, Telephone)
                , names_to = "order_category"
                , values_to = "order_percentage"
            )
        
        # Ord Use Perc by Cat ----
        plt <- ggplot(
            
            data = oppe_summary_tbl
            , mapping = aes(
                x = as.numeric(order_percentage)
                , y = reorder(order_category, order_percentage)
            )
        ) +
            geom_point(size = 2) +
            ggrepel::geom_label_repel(
                mapping = aes(
                    label = scales::percent(order_percentage, accuracy = 0.01)
                )
                , size = 3
            ) +
            geom_segment(
                aes(
                    yend = order_category
                )
                , xend = 0
                , color = "grey50"
            ) +
            labs(
                x = "Order Percentage"
                , y = ""
                , title = "Order Use by Percentage"
                , subtitle = "Must have 10 or more orders"
            ) +
            scale_x_continuous(labels = scales::percent) +
            theme_tq()
        
        # Print plot
        print(plt)
    }
    
}