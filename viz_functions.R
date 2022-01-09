inr_ts_plot <- function(.data){
  
  # * Check ----
  if(!is.data.frame(.data)){
    stop(call. = FALSE, "(.data) is missing, please supply.")
  }
  
  # * Plot ----
  data_tbl <- tibble::as_tibble(.data)
  
  p <- data_tbl %>%
    timetk::plot_time_series(
      .date_var      = coll_dtime
      , .value       = inr_rate
      , .smooth      = FALSE
      , .interactive = FALSE
      , .line_size   = 1 
    ) +
    ggrepel::geom_label_repel(
      mapping = aes(
        label = inr_rate_txt
      )
      , direction = "y"
    ) +
    ggplot2::labs(
      title     = "Rate of INR Values >= 5"
      , caption = "Last 12 Months"
    )  +
    ggplot2::scale_y_continuous(labels = scales::percent)
  
  # * Return ----
  return(p)
  
}

glucose_ts_plt <- function(.data){
  
  # * Check ----
  if(!is.data.frame(.data)){
    stop(call. = FALSE, "(.data) is missing, please supply.")
  }
  
  # * Plot ----
  data_tbl <- tibble::as_tibble(.data)
  
  p <- data_tbl %>%
    dplyr::group_by(name) %>%
    timetk::plot_time_series(
      .date_var      = coll_dtime
      , .value       = glucose_rate
      , .interactive = FALSE
      , .smooth      = FALSE
      , .color_var   = name
    ) +
    ggrepel::geom_label_repel(
      mapping = aes(
        label = glucose_rate_text
      )
      , direction = "y"
    ) +
    ggplot2::labs(
      title      = "Rate of Glucose at or Above Threshold"
      , subtitle = "Black Line Glucose >= 200, Red Line Glucose >= 300"
      , caption  = "Last 12 Months"
    ) +
    ggplot2::theme(
      legend.position = "none"
    ) +
    ggplot2::scale_y_continuous(labels = scales::percent)
  
  # * Return ----
  return(p)
  
}

glucose_box_plt <- function(.data){
  
  # * Check ----
  if(!is.data.frame(.data)){
    stop(call. = FALSE, "(.data) is missing, please supply.")
  }
  
  # * Plot ----
  data_tbl <- tibble::as_tibble(.data)
  
  p <- data_tbl %>%
    ggplot2::ggplot(
      mapping = ggplot2::aes(
        x       = name
        , y     = glucose_rate
        , group = name
        , fill  = name
      )
    ) +
    ggplot2::geom_boxplot() +
    ggplot2::stat_summary(
      geom = "text"
      , fun = quantile
      , ggplot2::aes(
        label = sprintf("%1.2f", ..y.. * 100)
      )
      , position = position_nudge(x = 0.45)
      , size = 3.5
    ) +
    tidyquant::theme_tq() +
    ggplot2::theme(
      legend.position = "none"
    ) +
    ggplot2::labs(
      title     = "Box Plot of Rates of Glucose Over 200 and 300"
      , caption = "Last 12 Months"
      , x       = ""
      , y       = ""
    ) +
    ggplot2::scale_y_continuous(labels = scales::percent)
  
  # * Return ----
  return(p)
  
}

run_chart_plt <- function(.data) {
  
  # * Check ----
  if(!is.data.frame(.data)){
    stop(call. = FALSE, "(.data) is missing, please supply.")
  }
  
  # * Plot ----
  data_tbl <- tibble::as_tibble(.data)
  
  n_names <- c(
    "episode_no","lab_number","val","mean_val","median_val"
  )
  c_names <- colnames(data_tbl)
  
  if(!all(n_names %in% c_names)){
    stop(call. = FALSE, "You are not using the proper data set")
  }
  
  p <- data_tbl %>%
    ggplot2::ggplot(
      mapping = ggplot2::aes(
        x = lab_number
        , y = val
        , group = episode_no
      )
    ) + 
    ggplot2::geom_line(color = 'gray') + 
    ggplot2::geom_line(
      mapping = ggplot2::aes(
        x = lab_number
        , y = median_val
      )
      , color = 'red'
    ) + 
    ggplot2::geom_line(
      mapping = ggplot2::aes(
        x = lab_number
        , y = mean_val
      )
      , color = 'purple'
    ) +
    tidyquant::theme_tq()
  
  # * Return ----
  return(p)
    
}

mean_median_plt <- function(.data, .lab_number = 20){
  
  # * Check ----
  if(!is.data.frame(.data)){
    stop(call. = FALSE, "(.data) is missing, please supply")
  }

  # * Data Mainpulation ----
  data_tbl <- tibble::as_tibble(.data)
  
  data_tbl <- data_tbl %>%
    dplyr::select(diabetes_type_flag, lab_number, median_val, mean_val) %>%
    dplyr::distinct() %>%
    dplyr::filter(lab_number <= .lab_number)
  
  p <- data_tbl %>%
    ggplot2::ggplot(
      mapping = ggplot2::aes(
        x = lab_number
      )
    ) +
    ggplot2::geom_line(
      data = data_tbl
      , aes(y = mean_val)
      , color = 'purple'
    ) +
    ggplot2::geom_line(
      data = data_tbl
      , aes(y = median_val)
      , color = 'red'
    ) +
    tidyquant::theme_tq()
  
  # * Return ----
  return(p)
  
}

mean_roll_plot <- function(.data){
  
  # * Check ----
  if(!is.data.frame(.data)){
    stop(call. = FALSE, "(.data) is missing, please supply.")
  }
  
  # * Plot ----
  data_tbl <- tibble::as_tibble(.data)
  
  p <- data_tbl %>%
    ggplot2::ggplot(
      mapping = ggplot2::aes(
        x       = lab_n
        , y     = roll_mean
        , group = episode_no
      )
    ) +
    ggplot2::geom_line(color = 'gray') +
    ggplot2::geom_line(
      mapping = ggplot2::aes(
        x = lab_n
        , y = mean_roll
      )
      , color = 'red'
    ) +
    tidyquant::theme_tq()
  
  # * Return ----
  return(p)
  
}
