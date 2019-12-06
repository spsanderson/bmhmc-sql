oppe_cpoe_plot <- function(data) {
    
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
    
    # Order Abbrviation Type
    ord_types <- list("CPOE", "Written", "Verbal", "Telephone")
    ord_types <- unique(ord_types)
    
    # Summarize oppe_data
    oppe_summary_tbl <- oppe_data %>%
        group_by(
            proper_name
        ) %>%
        summarize(
            tot_ord     = sum(total_orders)
            , Telephone = sum(telephone) / tot_ord
            , CPOE      = sum(cpoe) / tot_ord
            , Written   = sum(written) / tot_ord
            , Verbal    = sum(verbal_order) / tot_ord
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
    
    # Total Orders ----
    total_orders_trend <- oppe_data %>%
        collapse_by("monthly") %>%
        group_by(
            proper_name
            , ent_date
            , add = TRUE
        ) %>%
        summarize(
            total_orders = sum(total_orders)
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
    
    # Order Percentages Trend ----
    order_percentages_trend_tbl <- df_time_tbl %>%
        collapse_by("monthly") %>%
        group_by(
            proper_name
            , ent_date
            , add = T
        ) %>%
        summarize(
            tot_ord     = sum(total_orders)
            , Telephone = sum(telephone) / tot_ord
            , CPOE      = sum(cpoe) / tot_ord
            , Written   = sum(written) / tot_ord
            , Verbal    = sum(verbal_order) / tot_ord
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
        ) +
        theme_tq()
    
    print(plt)
}
