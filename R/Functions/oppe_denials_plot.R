oppe_denials_plot <- function(){
    
    # Yearly Summary ----
    if(!nrow(denials_tbl) >= 10){
        return(NA)
    } else {
    # summary tbl
    denials_y_tbl <- denials_tbl %>%
        mutate(adm_date = ymd(adm_date)) %>%
        arrange(adm_date) %>%
        collapse_by("yearly") %>%
        group_by(adm_date, add = T) %>%
        summarize(
            admits = n()
            , tot_chgs = sum(tot_chg_amt)
            , denials = sum(denial_flag)
            , denied_dollars = sum(dollars_appealed, na.rm = T)
            , recovered_dollars = sum(dollars_recovered, na.rm = T)
            , recovery_pct = (recovered_dollars / denied_dollars)
        ) %>%
        ungroup() %>%
        mutate(
            denial_lag_1 = lag(denied_dollars, n = 1)
            , denial_lag_1 = case_when(
                is.na(denial_lag_1) ~ denied_dollars
                , TRUE ~ denial_lag_1
            )
            , diff_1 = denied_dollars
            , pct_diff_1 = if_else(
                is.infinite(diff_1 / denial_lag_1)
                , 0
                , diff_1 /denial_lag_1
            )
            , pct_diff_1_chr = pct_diff_1 %>% scales::percent()
            , cum_denied_dollars = cumsum(denied_dollars)
            , cum_recovered_dollars = cumsum(recovered_dollars)
            , recovery_pct_chr = recovery_pct %>% scales::percent()
        ) %>%
        select(
            adm_date
            , admits
            , denials
            , denied_dollars
            , recovered_dollars
            , pct_diff_1
            , pct_diff_1_chr
            , cum_denied_dollars
            , cum_recovered_dollars
            , recovery_pct
            , recovery_pct_chr
        )
    
    # YOY pct chg denied ----
    yoy_denied_pct_chng <- denials_y_tbl %>%
        ggplot(
        mapping = aes(
            x = year(adm_date)
            , y = pct_diff_1
            )
        ) +
        geom_col(
            fill = palette_light()[[1]]
        ) +
        geom_label(
            mapping = aes(
                label = pct_diff_1_chr
            )
        ) +
        theme_tq() +
        scale_y_continuous(
            labels = scales::percent
        ) +
        labs(
            title = "YoY Denial Dollars % Change"
            , x = "Admit Year"
            , y = "Percent Change"
        )
    
    # Dollars denied by year ----
    dollars_denied_y <- denials_y_tbl %>%
        ggplot(
            mapping = aes(
                x = year(adm_date)
                , y = denied_dollars
            )
        ) +
        geom_col(
            fill = palette_light()[[1]]
        ) +
        theme_tq() +
        scale_y_continuous(
            labels = scales::dollar
        ) +
        labs(
            title = "Dollars Denied by Year"
            , x = "Admit Year"
            , y = "Dollars Denied"
        )
    
    # Cumulative Denied Dollars ----
    cum_denied_dollars <- denials_y_tbl %>% 
        ggplot(
        mapping = aes(
            x = year(adm_date)
            , y = cum_denied_dollars
            )
        ) +
        geom_col(
            fill = palette_light()[[1]]
        ) +
        theme_tq() +
        scale_y_continuous(
            labels = scales::dollar
        ) +
        labs(
            title = "Dollars Denied"
            , subtitle = "Cumulative Dollars Denied"
            , x = "Admit Year"
            , y = "Dollars Denied"
        )
    
    # Cumulative Recovered Dollars ----
    cum_recovered_dollars <- denials_y_tbl %>% 
        ggplot(
            mapping = aes(
                x = year(adm_date)
                , y = cum_recovered_dollars
            )
        ) +
        geom_col(
            fill = palette_light()[[1]]
        ) +
        theme_tq() +
        scale_y_continuous(
            labels = scales::dollar
        ) +
        labs(
            title = "Dollars Recovered"
            , subtitle = "Cumulative Dollars Recovered"
            , x = "Admit Year"
            , y = "Dollars Recovered"
        )
    
    gridExtra::grid.arrange(
        yoy_denied_pct_chng
        , dollars_denied_y
        , cum_denied_dollars
        , cum_recovered_dollars
        , ncol = 2
        , nrow = 2
        )
    
    # Percentage Plots ----
    rec_pct <- denials_y_tbl %>% 
        ggplot(
            mapping = aes(
                x = year(adm_date)
                , y = recovery_pct
            )
        ) +
        geom_col(
            fill = palette_light()[[1]]
        ) +
        theme_tq() +
        geom_label(
            mapping = aes(
                label = recovery_pct_chr
            )
        ) +
        theme_tq() +
        scale_y_continuous(
            labels = scales::percent
        ) +
        labs(
            title = "Recovery Percent by Year"
            , subtitle = "Percentage of Dollars Denied that were subsequently Recovered"
            , x = "Admit Year"
            , y = "Yearly Recovery Percent"
        )
        
    print(rec_pct)
    }
}
