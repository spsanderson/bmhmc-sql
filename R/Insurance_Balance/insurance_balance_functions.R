db_conn <-
new("Microsoft SQL Server", ptr = <pointer: 0x000001e66b02bd70>, 
    quote = "\"", info = structure(list(dbname = "SMSPHDSSS0X0", 
        dbms.name = "Microsoft SQL Server", db.version = "13.00.5865", 
        username = "dbo", host = "", port = "", sourcename = "", 
        servername = "LI-HIDB", drivername = "SQLSRV32.DLL", 
        odbc.version = "03.80.0000", driver.version = "10.00.19041", 
        odbcdriver.version = "03.52", supports.transactions = TRUE, 
        getdata.extensions.any_column = FALSE, getdata.extensions.any_order = FALSE), class = c("Microsoft SQL Server", 
    "driver_info", "list")), encoding = "")
db_dconn <-
function(connection) {
  dbDisconnect(connection)
}
insbal_age_pvt_tbl <-
function(
                               .data,
                               .rows_col) {
  data_tbl <- .data

  row_expr <- rlang::enquo(.rows_col)

  data_pvt <- data_tbl %>%
    group_by((!!row_expr), age_group) %>%
    summarise(ins_bal_amt = sum(ins_bal_amt, na.rm = TRUE)) %>%
    ungroup() %>%
    pivot_wider(
      id_cols = (!!row_expr),
      names_from = age_group,
      values_from = ins_bal_amt,
      names_sort = TRUE,
      values_fill = 0
    ) %>%
    as_tibble()

  return(data_pvt)
}
insbal_age_pct_tbl <-
function(
                               .data,
                               .rows_col) {
  data_tbl <- .data

  row_expr <- rlang::enquo(.rows_col)

  data_pvt <- data_tbl %>%
    group_by((!!row_expr), age_group) %>%
    summarise(ins_bal_amt = sum(ins_bal_amt, na.rm = TRUE)) %>%
    ungroup() %>%
    group_by(!!row_expr) %>%
    mutate(ins_bal_pct = ins_bal_amt / sum(ins_bal_amt)) %>%
    mutate(ins_bal_pct = case_when(
      is.nan(ins_bal_pct) ~ 0,
      TRUE ~ ins_bal_pct
    )) %>%
    pivot_wider(
      id_cols = (!!row_expr),
      names_from = age_group,
      values_from = ins_bal_pct,
      names_sort = TRUE,
      values_fill = 0
    ) %>%
    as_tibble()

  return(data_pvt)
}
fin_class_query <-
function() {

  # Db Conn
  db_connection <- db_conn()

  # Query
  query <- dbGetQuery(
    conn = db_connection,
    statement = paste0(
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
        fc %in% c(1:9) ~ "BAD DEBT",
        TRUE ~ fc_group
      ),
      fc_desc = case_when(
        fc %in% c(1:9) ~ "BAD DEBT",
        TRUE ~ fc_desc
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
    conn = db_connection,
    statement = paste0(
      "
    SELECT [pt_id]
          ,[unit_seq_no]
          ,[from_file_ind]
          ,[fc]
          ,[credit_rating]
          ,[hosp_svc]
          ,[pyr_cd]
          ,[pyr_cd_DESC]
          ,[pyr_group2]
          , UPPER([ins_carrier]) AS [ins_carrier]
          ,[pyr_seq_no]
          ,[ins_bal_amt]
          ,[IP_OP]
          ,[Age_In_Days]
          ,[Age_Group]
          ,[Age_Group_Flag]
          ,[Unitized_Flag]
          ,[RunDate]
          ,[RunDateTime]
      FROM [smsdss].[c_ins_bal_amt_vectorized_v]
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
ins_bal_trend_query <-
function() {

  # DB Conn
  db_connection <- db_conn()

  # Query
  query <- dbGetQuery(
    conn = db_connection,
    statement = paste0(
      "
SELECT a.rundate,
	a.fc,
	a.hosp_svc,
	a.pyr_cd,
	a.pyr_cd_desc,
	UPPER(A.pyr_group) AS [pyr_group2],
	CASE 
		WHEN B.carrier IS NULL
			AND LEFT(a.pyr_cd, 1) = 'A'
			THEN 'MEDICARE'
		WHEN A.pyr_cd = '*'
			THEN 'SELF PAY'
		WHEN b.Carrier IS NULL
			THEN pyr_group2
		ELSE b.Carrier
		END AS ins_carrier,
	CASE 
		WHEN LEFT(PT_ID, 5) = '00001'
			THEN 'IP'
		ELSE 'OP'
		END AS [IP_OP],
	CASE 
		WHEN AGE_IN_DAYS < 31
			THEN '0-30'
		WHEN AGE_IN_DAYS BETWEEN 31
				AND 60
			THEN '31-60'
		WHEN AGE_IN_DAYS BETWEEN 61
				AND 90
			THEN '61-90'
		WHEN AGE_IN_DAYS BETWEEN 91
				AND 120
			THEN '91-120'
		WHEN AGE_IN_DAYS BETWEEN 121
				AND 180
			THEN '121-180'
		WHEN AGE_IN_DAYS BETWEEN 181
				AND 365
			THEN '181-365'
		ELSE '366+'
		END AS [Age_Group],
	CASE 
		WHEN AGE_IN_DAYS < 31
			THEN 'A'
		WHEN AGE_IN_DAYS BETWEEN 31
				AND 60
			THEN 'B'
		WHEN AGE_IN_DAYS BETWEEN 61
				AND 90
			THEN 'C'
		WHEN AGE_IN_DAYS BETWEEN 91
				AND 120
			THEN 'D'
		WHEN AGE_IN_DAYS BETWEEN 121
				AND 180
			THEN 'E'
		WHEN AGE_IN_DAYS BETWEEN 181
				AND 365
			THEN 'F'
		ELSE 'G'
		END AS [Age_Group_Flag],
	[Unitized_Flag] = CASE 
		WHEN LEFT(a.PT_ID, 5) = '00007'
			THEN 1
		ELSE 0
		END,
	SUM(a.ins_cd_bal) AS [ins_bal_amt]
FROM SMSDSS.c_ins_cd_bal_tbl AS A
LEFT OUTER JOIN SMSDSS.c_ins_plan_cd_w_carrier AS B ON A.pyr_cd = B.plan_cd
LEFT OUTER JOIN SMSDSS.PYR_DIM_V AS C ON A.pyr_cd = C.pyr_cd
	AND C.orgz_cd = 'S0X0'
GROUP BY a.rundate,
	a.fc,
	a.hosp_svc,
	a.pyr_cd,
	a.pyr_cd_desc,
	UPPER(A.pyr_group),
	CASE 
		WHEN B.carrier IS NULL
			AND LEFT(a.pyr_cd, 1) = 'A'
			THEN 'MEDICARE'
		WHEN A.pyr_cd = '*'
			THEN 'SELF PAY'
		WHEN b.Carrier IS NULL
			THEN pyr_group2
		ELSE b.Carrier
		END,
	CASE 
		WHEN LEFT(PT_ID, 5) = '00001'
			THEN 'IP'
		ELSE 'OP'
		END,
	CASE 
		WHEN AGE_IN_DAYS < 31
			THEN '0-30'
		WHEN AGE_IN_DAYS BETWEEN 31
				AND 60
			THEN '31-60'
		WHEN AGE_IN_DAYS BETWEEN 61
				AND 90
			THEN '61-90'
		WHEN AGE_IN_DAYS BETWEEN 91
				AND 120
			THEN '91-120'
		WHEN AGE_IN_DAYS BETWEEN 121
				AND 180
			THEN '121-180'
		WHEN AGE_IN_DAYS BETWEEN 181
				AND 365
			THEN '181-365'
		ELSE '366+'
		END,
	CASE 
		WHEN AGE_IN_DAYS < 31
			THEN 'A'
		WHEN AGE_IN_DAYS BETWEEN 31
				AND 60
			THEN 'B'
		WHEN AGE_IN_DAYS BETWEEN 61
				AND 90
			THEN 'C'
		WHEN AGE_IN_DAYS BETWEEN 91
				AND 120
			THEN 'D'
		WHEN AGE_IN_DAYS BETWEEN 121
				AND 180
			THEN 'E'
		WHEN AGE_IN_DAYS BETWEEN 181
				AND 365
			THEN 'F'
		ELSE 'G'
		END,
	CASE 
		WHEN LEFT(a.PT_ID, 5) = '00007'
			THEN 1
		ELSE 0
		END
            "
    )
  ) %>%
    tibble::as_tibble() %>%
    mutate(rundate = as_date(rundate)) %>%
    mutate_if(is.character, str_squish) %>%
    clean_names() %>%
    mutate(age_group_flag = factor(age_group_flag)) %>%
    mutate(age_group_flag_n = as.integer(age_group_flag)) %>%
    mutate(pyr_group = pyr_group2) %>%
    mutate(
      age_group = factor(age_group) %>%
        fct_reorder(age_group_flag_n)
    ) %>%
    select(-age_group_flag_n) %>%
    mutate_if(is.character, str_squish)

  db_dconn(connection = db_connection)

  return(query)
}
ins_trend_tbl <-
function(
                          .data,
                          .date_col,
                          .value_col,
                          ...) {

  # Tidyeval Setup
  date_var_expr <- rlang::enquo(.date_col)
  value_var_expr <- rlang::enquo(.value_col)
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

  if (length(group_vars_expr) == 0) {
    message("A grouping variable was not selected so picking the first column in the data.frame")
    group_vars_expr <- rlang::list2(rlang::sym(colnames(.data)[[1]]))

    data_grouped <- tibble::as_tibble(.data) %>%
      dplyr::group_by(!!!group_vars_expr) %>%
      dplyr::summarise(.value_mod = sum(!!value_var_expr)) %>%
      dplyr::ungroup()

    return(data_grouped)
  }

  # Data setup
  data_grouped <- tibble::as_tibble(.data) %>%
    dplyr::group_by(!!date_var_expr, !!!group_vars_expr) %>%
    dplyr::summarise(.value_mod = sum(!!value_var_expr)) %>%
    dplyr::ungroup()

  return(data_grouped)
}
