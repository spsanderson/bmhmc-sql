oppe_cpoe_total_orders <- function(data){
    
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
        # Total Orders ----
        total_orders_trend <- oppe_data %>%
            collapse_by("monthly") %>%
            group_by(
                proper_name
                , ent_date
                , add = TRUE
            ) %>%
            summarize(
                total_orders = sum(total_orders, na.rm = TRUE)
            ) %>%
            filter(total_orders >= 10) %>%
            ungroup()
        
        # Print Data
        plt <- 
            ggplot(
                data = total_orders_trend
                , mapping = aes(
                    x = ent_date
                    , y = total_orders
                )
            ) + 
            geom_point(size = 2) +
            geom_line() +
            scale_y_continuous(labels = scales::number_format(big.mark = ",")) +
            labs(
                x = "Order Entry Date"
                , y = "Total Orders"
                , title = "Total Order Count Trend"
                , subtitle = "Must have 10 or more orders"
            ) +
            theme_tq()
        
        print(plt)
    }
}