db_conn <-
function() {
    db_con <- dbConnect(
        odbc()
        , Driver = "SQL Server"
        , Server = "BMH-HIDB"
        , Database = "SMSPHDSSS0X0"
        , Trusted_Connection = TRUE
    )
    
    return(db_con)
}
db_dconn <-
function(connection) {
    dbDisconnect(connection)
}
insbal_age_pvt_tbl <-
function(
    .data
    , .rows_col
) {
    data_tbl   <- .data

    row_expr   <- rlang::enquo(.rows_col)
    
    data_pvt <- data_tbl %>%
        group_by((!! row_expr), age_group) %>%
        summarise(ins_bal_amt = sum(ins_bal_amt, na.rm = TRUE)) %>%
        ungroup() %>%
        pivot_wider(
            id_cols = (!! row_expr)
            , names_from = age_group
            , values_from = ins_bal_amt
            , names_sort = TRUE
            , values_fill = 0
        )
    
    return(data_pvt)
}
insbal_age_pct_tbl <-
function(
    .data
    , .rows_col
) {
    data_tbl   <- .data

    row_expr   <- rlang::enquo(.rows_col)
    
    data_tbl %>%
        group_by((!! row_expr), age_group) %>%
        summarise(ins_bal_amt = sum(ins_bal_amt, na.rm = TRUE)) %>%
        ungroup() %>%
        group_by(!! row_expr) %>%
        mutate(ins_bal_pct = ins_bal_amt / sum(ins_bal_amt)) %>%
        pivot_wider(
            id_cols = (!! row_expr)
            , names_from = age_group
            , values_from = ins_bal_pct
            , names_sort = TRUE
            , values_fill = 0
        )
}
fin_class_query <-
function() {
    
    # Db Conn
    db_connection <- db_conn()
    
    # Query
    query <- dbGetQuery(
        conn = db_connection
        , statement = paste0(
            "
            SELECT pvt.fc
            , pvt.S0X0 AS [fc_group]
            , pvt.NTX0 AS [fc_desc]
            FROM (
            	SELECT fc
            	, fc_name
            	, orgz_cd
            	FROM smsdss.fc_dim_v
            	WHERE orgz_cd != 'xnt'
            ) AS A
            
            PIVOT (
            	MAX([fc_name])
            	FOR [orgz_cd] in (\"S0X0\",\"NTX0\")
            ) AS PVT
            
            ORDER BY PVT.FC
            "
        )
    ) %>%
        tibble::as_tibble() %>%
        clean_names() %>%
        mutate_if(is.character, str_squish) %>%
        mutate(
            fc_group = case_when(
                fc  %in% c(1:9) ~ "BAD DEBT"
                , TRUE ~ fc_group
            )
            , fc_desc = case_when(
                fc %in% c(1:9) ~ "BAD DEBT"
                , TRUE ~ fc_desc
            )
        )
    
    db_dconn(connection = db_connection)
    
    return(query)
}
ins_bal_age_query <-
function() {
    
    # DB Conn
    db_connection <- db_conn()
    
    # Query
    query <- dbGetQuery(
        conn = db_connection
        , statement = paste0(
            "
            SELECT *
            FROM SMSDSS.c_ins_bal_amt_vectorized_v
            "
        )
    ) %>%
        tibble::as_tibble() %>%
        clean_names() %>%
        mutate_if(is.character, str_squish) %>%
        mutate(age_group_flag = factor(age_group_flag)) %>%
        mutate(age_group_flag_n = as.integer(age_group_flag)) %>%
        mutate(pyr_group = pyr_group2) %>%
        mutate(
            age_group = factor(age_group) %>% 
                fct_reorder(age_group_flag_n)
        ) %>%
        select(-age_group_flag_n)
    
    db_dconn(connection = db_connection)
    
    return(query)
}
ins_trend_tbl <-
function(
    .data
    , .date_col
    , .value_col
    , ...
) {
    
    # Tidyeval Setup
    date_var_expr   <- rlang::enquo(.date_col)
    value_var_expr  <- rlang::enquo(.value_col)
    group_vars_expr <- rlang::quos(...)
    
    # Checks
    if (!is.data.frame(.data)) {
        stop(call. = FALSE, "(data) is not a data-frame or tibble. Please supply a data.frame or tibble.")
    }
    if (rlang::quo_is_missing(date_var_expr)) {
        stop(call. = FALSE, "(date_var_expr) is missing. Please supply a date or date-time column.")
    }
    if (rlang::quo_is_missing(value_var_expr)) {
        stop(call. = FALSE, "(value_var_expr) is missing. Please supply a numeric column.")
    }
    
    if(length(group_vars_expr) == 0) {
        stop(call. = FALSE, "(group_vars_expr) is missing. Please supply at least one grouping variable.")
    }
    
    # if(length(group_vars_expr) <= 2 & length(group_vars_expr) > 0)
    #     group_vars_expr <- rlang::quos(rlang::sym(colnames(.data)[[7]]))
    
        
    # Data setup
    data_grouped <- tibble::as_tibble(.data) %>%
        dplyr::group_by(!! date_var_expr, !!! group_vars_expr) %>%
        dplyr::summarise(.value_mod = sum(!! value_var_expr)) %>%
        dplyr::ungroup() 
    
    return(data_grouped)
}
