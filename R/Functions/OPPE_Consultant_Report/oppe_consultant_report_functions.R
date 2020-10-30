coded_consults_query <-
  function(.resp_party) {

    # Tidyeval Setup
    resp_party_var_expr <- rlang::enquo(.resp_party)

    # Check
    # Missing?
    if (rlang::quo_is_missing(resp_party_var_expr)) {
      stop(call. = FALSE, "(resp_party_var_expr) is missing. Please provide one.")
    }

    # Length of 6?
    if (nchar(resp_party_var_expr)[[2]] != 6) {
      stop(call. = FALSE, ".resp_party is not of length six. Check leading zero.")
    }

    # DB Connection
    db_con_obj <- DBI::dbConnect(
      odbc::odbc(),
      Driver = "SQL Server",
      Server = "BMH-HIDB",
      Database = "SMSPHDSSS0X0",
      Trusted_Connection = TRUE
    )

    # Query
    coded_consults_tbl <- DBI::dbGetQuery(
      conn = db_con_obj,
      statement = paste0(
        "
    SELECT *
    , [record_flag] = 1
    FROM smsdss.c_Coded_Consults_v
    --WHERE RespParty = 
    WHERE Dsch_Date >= DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) -6, 0)
    ORDER BY Dsch_Date
    "
      )
    ) %>%
      dplyr::filter(RespParty == (!!resp_party_var_expr))

    # DB Disconnect
    DBI::dbDisconnect(db_con_obj)

    # Data Clean - Manip
    coded_consults_ts_tbl <- coded_consults_tbl %>%
      tibble::as_tibble() %>%
      janitor::clean_names() %>%
      dplyr::mutate_if(is.character, str_squish) %>%
      dplyr::mutate_if(is.character, str_to_title) %>%
      dplyr::mutate(
        adm_date = lubridate::ymd(adm_date),
        dsch_date = lubridate::ymd(dsch_date)
      ) %>%
      timetk::pad_by_time(.date_var = dsch_date) %>%
      timetk::tk_augment_timeseries_signature(.date_var = dsch_date) %>%
      dplyr::select(
        med_rec_no:clasf_cd,
        year,
        month,
        month.lbl,
        day,
        wday,
        wday.lbl,
        week.iso,
        record_flag
      ) %>%
      dplyr::mutate(
        end_of_month = tidyquant::EOMONTH(dsch_date),
        end_of_week = tidyquant::CEILING_WEEK(dsch_date)
      ) %>%
      dplyr::mutate(
        record_flag = ifelse(is.na(record_flag), NA_real_, record_flag)
        , consultant = ifelse(is.na(consultant), zoo::na.locf(consultant), consultant)
      )

    return(coded_consults_ts_tbl)
  }
coded_consults_top_providers <-
  function(.data, .top_n, .attending_col, .consultant_col) {

    # Tidyeval Setup
    top_n_var_expr <- rlang::enquo(.top_n)
    attending_var_expr <- rlang::enquo(.attending_col)
    consultant_var_expr <- rlang::enquo(.consultant_col)

    # Checks
    if (!is.data.frame(.data)) {
      stop(call. = FALSE, "(data) is not a data-frame/tibble. Please provide.")
    }

    if (rlang::quo_is_missing(top_n_var_expr)) {
      stop(call. = FALSE, "(top_n_var_expr) is missing. Please provide.")
    }

    if (rlang::quo_is_missing(attending_var_expr)) {
      stop(call. = FALSE, "(attending_var_expr) is missing. Please provide attending md column name")
    }

    if (rlang::quo_is_missing(consultant_var_expr)) {
      stop(call. = FALSE, "(consultant_var_expr) is missing. Please provide consultant column name.")
    }

    # Consultant
    consultant <- tibble::as_tibble(.data) %>%
      dplyr::distinct(!!consultant_var_expr) %>%
      dplyr::pull()

    # Get tp_n attending providers that asked consultant to consult
    top_n_tbl <- dplyr::count(.data, !!attending_var_expr) %>%
      dplyr::arrange(dplyr::desc(n)) %>%
      dplyr::slice(1:(!!top_n_var_expr)) %>%
      dplyr::mutate(
        attending_md = forcats::as_factor(!!attending_var_expr) %>%
          forcats::fct_reorder(n)
      ) %>%
      dplyr::select(attending_md, n) %>%
      dplyr::mutate(consultant = consultant)

    return(top_n_tbl)
  }
coded_consults_top_plt <-
  function(.data) {

    # check
    if (!is.data.frame(.data)) {
      stop(call. = FALSE, "(data) is not a data-frame/tibble. Please provide.")
    }

    consultant <- tibble::as_tibble(.data) %>%
      dplyr::select(3) %>%
      dplyr::distinct() %>%
      dplyr::pull()

    total_consults <- tibble::as_tibble(.data) %>%
      dplyr::select(n) %>%
      sum(na.rm = TRUE)

    # Plot
    g <- tibble::as_tibble(.data) %>%
      ggplot2::ggplot(
        mapping = aes(
          x = n,
          y = attending_md,
          fill = "blue"
        )
      ) +
      ggplot2::geom_col() +
      tidyquant::scale_fill_tq() +
      tidyquant::theme_tq() +
      ggplot2::labs(
        x = "",
        y = "",
        title = paste0(
          "Top Attending Providers that consulted ",
          consultant
        ),
        subtitle = paste0(
          "Total Consults for Top Attending Providers: ",
          total_consults
        )
      ) +
      ggplot2::theme(legend.position = "none")

    return(g)
  }
coded_consults_trend_plt <-
  function(
           .data,
           .consultant_col) {

    # Tidyeval Setup
    consultant_var_expr <- rlang::enquo(.consultant_col)

    # Checks
    if (!is.data.frame(.data)) {
      stop(call. = FALSE, "(data) is not a data-frame/tibble. Please provide.")
    }

    if (rlang::quo_is_missing(consultant_var_expr)) {
      stop(call. = FALSE, "(consultant_var_expr) is missing. Please provide column.")
    }

    # Data Manip
    df_tbl <- tibble::as_tibble(.data) %>%
      dplyr::select(
        dsch_date,
        month.lbl,
        week.iso,
        wday.lbl,
        end_of_month,
        end_of_week
      ) %>%
      dplyr::group_by(month.lbl) %>%
      dplyr::summarise(total_consults = n()) %>%
      dplyr::ungroup() %>%
      purrr::set_names("ts", "value")

    # Consultant
    consultant <- tibble::as_tibble(.data) %>%
      dplyr::distinct(!!consultant_var_expr) %>%
      dplyr::pull()

    # Plot
    g <- df_tbl %>%
      ggplot2::ggplot(
        mapping = aes(
          x = ts,
          y = value,
          fill = "blue"
        )
      ) +
      ggplot2::geom_col() +
      tidyquant::scale_fill_tq() +
      tidyquant::theme_tq() +
      ggplot2::labs(
        x = "",
        y = "",
        title = paste0("Consult Trend For: ", consultant),
        subtitle = "Last Six Months"
      ) +
      ggplot2::theme(legend.position = "none")

    # Return plot
    return(g)
  }
coded_consults_seasonal_diagnositcs <-
  function(
           .data,
           .date_col,
           .value_col) {

    # Tidyeval Setup
    date_col_var_expr <- rlang::enquo(.date_col)
    value_col_var_expr <- rlang::enquo(.value_col)

    # Checks
    if (!is.data.frame(.data)) {
      stop(call. = FALSE, "(data) is not a data-frame/tibble. Please provide.")
    }

    if (rlang::quo_is_missing(date_col_var_expr)) {
      stop(call. = FALSE, "(date_col_var_expr) is missing. Please provide.")
    }

    if (rlang::quo_is_missing(value_col_var_expr)) {
      stop(call. = FALSE, "(value_col_var_expr) is missing. Please provide.")
    }

    # Data Manip
    df_tbl <- tibble::as_tibble(.data) %>%
      dplyr::select(!!date_col_var_expr, !!value_col_var_expr) %>%
      dplyr::group_by(!!date_col_var_expr) %>%
      dplyr::summarise(value = sum(!!value_col_var_expr, na.rm = TRUE)) %>%
      dplyr::ungroup()

    # Pad by time
    df_tbl <- df_tbl %>%
      timetk::pad_by_time(.date_var = !!date_col_var_expr, .pad_value = 0)

    # Plot ts season dx
    g <- df_tbl %>%
      timetk::plot_seasonal_diagnostics(
        .date_var = !!date_col_var_expr,
        .value = value,
        .interactive = FALSE
      )

    return(g)
  }
