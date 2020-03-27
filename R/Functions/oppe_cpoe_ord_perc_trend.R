oppe_cpoe_ord_perc_trend <- function(data){
    # OPPE CPOE Order Plots
    
    # Make sure needed packages are installed and loaded
    if(!require(pacman)) install.packages("pacman")
    pacman::p_load(
        "tidyverse"
        , "tidyquant"
        , "readxl"
        , "R.utils"
        , "tibbletime"
    )
    
    # Get data
    oppe_data <- data
    
    if(!nrow(oppe_data) >= 10){
        return(NA)
    } else {
        # Order Percentages Trend ----
        order_percentages_trend_tbl <- oppe_data %>% #df_time_tbl
            collapse_by("monthly") %>%
            group_by(
                proper_name
                , ent_date
                , add = T
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
        
        # Plot Data
        plt <- 
            ggplot(
                data = order_percentages_trend_tbl
                , mapping = aes(
                    x = ent_date
                    , y = order_percentage
                    , color = order_category
                )
            ) +
            geom_point(size = 2) +
            geom_line() +
            scale_y_continuous(
                labels = scales::percent
            ) +
            labs(
                y = "Order Percentage"
                , x = "Order Entry Date"
                , title = "Trending Order Use Percentage by Order Category"
                , subtitle = "Must have 10 or more orders"
                , color = "Order Category"
            ) +
            theme_tq()
        
        print(plt)
    }
}