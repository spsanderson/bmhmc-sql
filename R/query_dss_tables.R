#' Get practice dimension view with ID Number and Name
#'
#' @author Steven P. Sanderson II
#'
#' @description
#' Get data from the smsdss.pract_dim_v view in DSS
#'
#' @details
#' - Requires a connection to DSS
#' - Uses the [db_connect()] function
#' - Data comes back sorted in order of Name
#'
#' @param .name Can be null in order to return all providers
#'
#' @examples
#' library(DBI)
#' library(dplyr)
#' library(tibble)
#' library(janitor)
#' library(data.table)
#'
#' pract_dim_v_query()
#'
#' pract_dim_v_query(.name = "Abadi")
#'
#' @return
#' A tibble of provider ID Numbers, Names, Med Staff Department, and Specialty
#'
#' @export
#'

pract_dim_v_query <- function(
  .name
) {

  # Tidyeval
  name_var_expr <- rlang::enquo(.name)

  # Checks
  if(rlang::quo_is_missing(name_var_expr)) {
    name_var_expr = NULL
  }

  # * DB Connection ----
  db_con_obj <- LICHospitalR::db_connect()

  # * Query ----
  provider_tbl <- DBI::dbGetQuery(
    conn = db_con_obj
    , statement = base::paste0(
      "
      SELECT pract_no,
      pract_rpt_name,
      med_staff_dept,
      spclty_desc
      from smsdss.pract_dim_v
      WHERE orgz_cd = 's0x0'
      AND pract_no != '?'
      AND src_pract_no != '?'
      AND pract_rpt_name not in ('?','Doctor Unassigned')
      ORDER BY pract_rpt_name;
      "
    )
  ) %>%
    tibble::as_tibble() %>%
    janitor::clean_names() %>%
    dplyr::mutate_if(base::is.character, stringr::str_squish) %>%
    dplyr::mutate(pract_rpt_name = stringr::str_to_title(pract_rpt_name)) %>%
    dplyr::mutate(med_staff_dept = stringr::str_to_upper(med_staff_dept)) %>%
    dplyr::mutate(spclty_desc    = stringr::str_to_upper(spclty_desc))

  # * DB Disconnect ----
  LICHospitalR::db_disconnect(.connection = db_con_obj)

  # * Filter ----
  if(is.null(name_var_expr)) {
    return(provider_tbl)
  } else {
    filtered_tbl <- provider_tbl %>%
      dplyr::filter(data.table::like(
        pract_rpt_name
        , {{name_var_expr}}
        , ignore.case = TRUE
        )
      )

    # * Return ----
    return(filtered_tbl)
  }

}

#' Denials Admits by MD
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' This query gets the admit counts by attending provider
#'
#' @details
#' - Queries DSS
#' - Uses the [db_connect()] and [db_disconnect()] functions
#' - Does not need an argument but one can be passed to filter on name if
#' desired, although this should be done as a dplyr::filter() so this funcationality
#' may be taken away in the future
#' - The data is grouped by:
#' 1. Payer_Category
#' 2. Attending Dr
#' 3. Admit Month
#' 4. Admit Year
#' 5. Primary Payer Plan Code
#' 6. Med Staff Department
#'
#' @param .name The name of the provider you want returned, leave empty for all
#'
#' @examples
#' library(DBI)
#' library(dplyr)
#' library(tibble)
#' library(janitor)
#' library(data.table)
#'
#' denials_admits_by_md_query()
#'
#' @return
#' A Tibble
#'
#' @export
#'

denials_admits_by_md_query <- function(.name) {

  # Tidyeval
  name_var_expr <- rlang::enquo(.name)

  # Checks
  if(rlang::quo_is_missing(name_var_expr)) {
    name_var_expr = NULL
  }

  # * DB Connection ----
  db_con_obj <- LICHospitalR::db_connect()

  # * Query ----
  data_tbl <- DBI::dbGetQuery(
    conn = LICHospitalR::db_connect()
    , statement = base::paste0(
      "
      DECLARE @TODAY DATE;
      DECLARE @SD DATE;
      DECLARE @ED DATE;

      SET @TODAY = CAST(GETDATE() AS DATE);
      SET @SD = '2013-01-01';
      SET @ED = DATEADD(MM, DATEDIFF(MM, 0, @TODAY) - 1, 0);

      SELECT COUNT(DISTINCT (pt_no)) AS [Pt Count],
      	CASE
      		WHEN User_Pyr1_Cat IN ('AAA', 'ZZZ')
      			THEN 'Medicare'
      		WHEN User_Pyr1_Cat = 'WWW'
      			THEN 'Medicaid'
      		WHEN User_Pyr1_Cat = 'MIS'
      			THEN 'Self Pay'
      		WHEN User_Pyr1_Cat = 'CCC'
      			THEN 'Comp'
      		WHEN User_Pyr1_Cat = 'NNN'
      			THEN 'No Fault'
      		ELSE 'Other'
      		END AS [Payer Category],
      	Atn_Dr_No,
      	b.pract_rpt_name,
      	MONTH(Adm_Date) AS [Adm_Mo],
      	YEAR(Adm_Date) AS [Adm_Yr],
      	a.Pyr1_Co_Plan_Cd,
      	UPPER(G.PRACT_RPT_NAME) AS [PROVIDER_NAME],
      	CASE
      		WHEN g.src_spclty_cd = 'hosim'
      			THEN 'Hospitalist'
      		ELSE 'Private'
      		END AS [Hosp - Pvt],
      	g.med_staff_dept
      FROM smsdss.BMH_PLM_PtAcct_V AS A
      LEFT OUTER JOIN smsmir.mir_pract_mstr AS B ON a.Atn_Dr_No = b.pract_no
      	AND b.src_sys_id = '#PMSNTX0'
      LEFT OUTER JOIN smsdss.pract_dim_v AS g ON a.Atn_Dr_No = g.src_pract_no
      	AND g.orgz_cd = 's0x0'
      WHERE A.Adm_Date >= @SD
      	AND Adm_Date < @ED
      	AND tot_chg_amt > '0'
      	AND Plm_Pt_Acct_Type = 'I'
      	AND Atn_Dr_No != '000059' -- TESTCPOE DOCTOR
      	--AND hosp_svc <> 'PSY'
      GROUP BY user_pyr1_cat,
      	Atn_Dr_No,
      	b.pract_rpt_name,
      	MONTH(Adm_Date),
      	YEAR(Adm_Date),
      	Pyr1_Co_Plan_Cd,
      	G.pract_rpt_name,
      	g.src_spclty_cd,
      	g.med_staff_dept
      "
    )
  ) %>%
    tibble::as_tibble() %>%
    janitor::clean_names() %>%
    dplyr::mutate_if(base::is.character, stringr::str_squish) %>%
    dplyr::mutate(pract_rpt_name = stringr::str_to_title(pract_rpt_name)) %>%
    dplyr::mutate(provider_name  = stringr::str_to_title(provider_name)) %>%
    dplyr::mutate(med_staff_dept = stringr::str_to_upper(med_staff_dept))

  # * DB Disconnect ----
  LICHospitalR::db_disconnect(.connection = db_con_obj)

  # * Filter ----
  if(is.null(name_var_expr)) {
    return(data_tbl)
  } else {
    filtered_tbl <- data_tbl %>%
      dplyr::filter(data.table::like(
        pract_rpt_name
        , {{name_var_expr}}
        , ignore.case = TRUE
      )
    )

    # * Return ----
    return(filtered_tbl)
  }

}

#' Denials Admits by ED
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' This query gets the admit counts by ed provider
#'
#' @details
#' - Queries DSS the linked WellSoft Report DB
#' - Uses the [db_connect()] and [db_disconnect()] functions
#' - Does not need an argument but one can be passes til filter on name if desired,
#' although this should be done as a dplyr::filter() so this funcationality
#' may be taken away in the future
#'
#' @param .name The name of the provider you want returned
#'
#' @examples
#' denials_admits_by_ed_query()
#'
#' @return
#' A tibble
#'
#' @export
#'

denials_admits_by_ed_query <- function(.name) {

  # Tidyeval
  name_var_expr <- rlang::enquo(.name)

  # Checks
  if(rlang::quo_is_missing(name_var_expr)) {
    name_var_expr = NULL
  }

  # * DB Connection ----
  db_con_obj <- LICHospitalR::db_connect()

  # * Query ----
  data_tbl <- DBI::dbGetQuery(
    conn = LICHospitalR::db_connect()
    , statement = base::paste0(
      "
      DECLARE @TODAY DATE;
      DECLARE @SD DATE;
      DECLARE @ED DATE;

      SET @TODAY = CAST(GETDATE() AS DATE);
      SET @SD = '2013-01-01';
      SET @ED = DATEADD(MM, DATEDIFF(MM, 0, @TODAY) - 1, 0);

      SELECT COUNT(ED_MD) [Inpatient Count],
      	CASE
      		WHEN User_Pyr1_Cat IN ('AAA', 'ZZZ')
      			THEN 'Medicare'
      		WHEN User_Pyr1_Cat = 'WWW'
      			THEN 'Medicaid'
      		WHEN User_Pyr1_Cat = 'MIS'
      			THEN 'Self Pay'
      		WHEN User_Pyr1_Cat = 'CCC'
      			THEN 'Comp'
      		WHEN User_Pyr1_Cat = 'NNN'
      			THEN 'No Fault'
      		ELSE 'Other'
      		END AS 'Payer Category',
      	A.EDMDID,
      	C.pract_rpt_name,
      	DATEPART(MONTH, A.ARRIVAL) AS [ARRIVAL_MONTH],
      	DATEPART(YEAR, A.ARRIVAL) AS [ARRIVAL_YR],
      	B.Pyr1_Co_Plan_Cd,
      	G.pract_rpt_name AS [PROVIDER_NAME],
      	CASE
      		WHEN G.src_spclty_cd = 'HOSIM'
      			THEN 'Hospitalist'
      		ELSE 'Private'
      		END AS [HOSP_PVT],
      	G.med_staff_dept
      FROM [SQL-WS\\REPORTING].[WellSoft_Reporting].[dbo].[c_Wellsoft_Rpt_tbl] AS A
      INNER JOIN SMSDSS.BMH_PLM_PtAcct_V AS B ON A.Account = B.PtNo_Num
      LEFT OUTER JOIN smsmir.mir_pract_mstr AS C ON a.EDMDID = C.pract_no
      	AND C.src_sys_id = '#PMSNTX0'
      LEFT OUTER JOIN smsdss.pract_dim_v AS g ON a.EDMDID = g.src_pract_no
      	AND g.orgz_cd = 's0x0'
      WHERE A.ARRIVAL >= @SD
      	AND A.ARRIVAL < @ED
      	AND B.Plm_Pt_Acct_Type = 'I'
      	AND B.PtNo_Num < '20000000'
      	AND LEFT(B.PTNO_NUM, 4) != '1999'
      	AND A.EDMDID IS NOT NULL
      GROUP BY ED_MD,
      	EDMDID,
      	B.User_Pyr1_Cat,
      	A.EDMDID,
      	C.pract_rpt_name,
      	DATEPART(MONTH, A.ARRIVAL),
      	DATEPART(YEAR, A.ARRIVAL),
      	B.Pyr1_Co_Plan_Cd,
      	G.pract_rpt_name,
      	G.src_spclty_cd,
      	G.med_staff_dept
      "
    )
  ) %>%
    tibble::as_tibble() %>%
    janitor::clean_names() %>%
    dplyr::mutate_if(base::is.character, stringr::str_squish) %>%
    dplyr::mutate(pract_rpt_name = stringr::str_to_title(pract_rpt_name)) %>%
    dplyr::mutate(provider_name  = stringr::str_to_title(provider_name)) %>%
    dplyr::mutate(med_staff_dept = stringr::str_to_upper(med_staff_dept))

  # * DB Disconnect ----
  LICHospitalR::db_disconnect(.connection = db_con_obj)

  # * Filter ----
  if(is.null(name_var_expr)) {
    return(data_tbl)
  } else {
    filtered_tbl <- data_tbl %>%
      dplyr::filter(data.table::like(
        pract_rpt_name
        , {{name_var_expr}}
        , ignore.case = TRUE
      )
      )

    # * Return ----
    return(filtered_tbl)
  }

}

#' Denials by Inpatients
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' Get denials for inpatient visits from smsdss.c_Softmed_Denials_Detail_v and
#' smsmir.mir_pay where the left 4 digits of the pay code are '0974'. The data
#' starts at January 1st, 2013
#'
#' @details
#' - Uses the [db_connect()] and [db_disconnect()] functions
#' - Queries:
#' 1. smsdss.c_Softmed_Denials_Detail_v
#' 2. smsmir.mir_pay
#' - Includes the columns ptno_Num, bill_no, discharge_date and dollars_denied
#' - This function is intended to be used with [timetk::filter_by_time()] if data
#' needs to be filtered by time. The .date_var argument should be set equal to
#' discharge_date
#'
#'
#' @examples
#' library(timetk)
#' denials_inpatient_query()
#'
#' @return
#' A tibble
#'
#' @export
#'

denials_inpatient_query <- function() {

  # * DB Connection ----
  db_con_obj <- LICHospitalR::db_connect()

  # * Query ----
  data_tbl <- DBI::dbGetQuery(
    conn = db_con_obj
    , statement = base::paste0(
      "
      DECLARE @TODAY DATE;
      DECLARE @SD DATE;
      DECLARE @ED DATE;

      SET @TODAY = CAST(GETDATE() AS DATE);
      SET @SD = '2013-01-01';
      SET @ED = DATEADD(MM, DATEDIFF(MM, 0, @TODAY) - 1, 0);

      SELECT a.pt_id as [pt_no_num],
      	CONCAT('0000', A.bill_no) AS [pt_id],
      	a.DISCHARGED AS [discharge_date],
      	a.denials_woffs as [dollars_denied]
      FROM (
      	SELECT CAST(pt_id AS INT) AS pt_id,
      		CAST(bill_no AS INT) AS bill_no,
      		CAST(discharged AS DATE) AS discharged,
      		SUM(tot_pay_adj_amt) AS denials_woffs
      	FROM smsmir.mir_pay
      	JOIN smsdss.c_Softmed_Denials_Detail_v ON smsmir.mir_pay.pt_id = smsdss.c_Softmed_Denials_Detail_v.bill_no
      	WHERE discharged >= @sd
      		AND discharged < @ed
      		AND LEFT(smsmir.mir_pay.pay_cd, 4) = '0974'
      	GROUP BY pt_id,
      		bill_no,
      		discharged
      	) A
      "
    )
  ) %>%
    tibble::as_tibble() %>%
    janitor::clean_names() %>%
    dplyr::mutate_if(is.character, stringr::str_squish) %>%
    dplyr::mutate(discharge_date = lubridate::ymd(discharge_date))

  # * DB Disconnect ----
  LICHospitalR::db_disconnect(.connection = db_con_obj)

  # * Return ----
  return(data_tbl)

}

#' Denials by Outpatient
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' #' Get denials for outpatient visits from smsdss.c_Softmed_Denials_Detail_v and
#' smsmir.mir_pay where the left 4 digits of the pay code are '0974'. The data
#' starts at January 1st, 2013
#'
#' @details
#' - Uses the [db_connect()] and [db_disconnect()] functions
#' - Queries:
#' 1. smsdss.c_Softmed_Denials_Detail_v
#' 2. smsmir.mir_pay
#' - Includes the columns ptno_Num, bill_no, discharge_date and dollars_denied
#' - This function is intended to be used with [timetk::filter_by_time()] if data
#' needs to be filtered by time. The .date_var argument should be set equal to
#' discharge_date
#'
#'
#' @examples
#' library(timetk)
#' denials_outpatient_query()
#'
#' @return
#' A tibble
#'
#' @export
#'

denials_outpatient_query <- function() {

  # * DB Connection ----
  db_con_obj <- LICHospitalR::db_connect()

  # * Query ----
  data_tbl <- DBI::dbGetQuery(
    conn = db_con_obj
    , statement = base::paste0(
      "
      DECLARE @TODAY DATE;
      DECLARE @SD DATE;
      DECLARE @ED DATE;

      SET @TODAY = CAST(GETDATE() AS DATE);
      SET @SD = '2013-01-01';
      SET @ED = DATEADD(MM, DATEDIFF(MM, 0, @TODAY) - 1, 0);

      SELECT B.pt_id AS [pt_no_num],
      	CONCAT('0000', b.bill_no) AS [pt_id],
      	b.admission_date,
      	b.Outpatient_Denials as [dollars_denied]
      FROM (
      	SELECT CAST(pt_id AS INT) AS pt_id,
      		CAST(bill_no AS INT) AS bill_no,
      		CAST(admission_date AS DATE) AS [admission_date],
      		SUM(tot_pay_adj_amt) AS Outpatient_Denials
      	FROM smsmir.mir_pay
      	JOIN smsdss.c_Softmed_Denials_Detail_v ON smsmir.mir_pay.pt_id = smsdss.c_Softmed_Denials_Detail_v.bill_no
      	WHERE patient_type IN ('E', 'O')
      		AND admission_date >= @SD
      		AND admission_date < @ED
      		AND LEFT(smsmir.mir_pay.pay_cd, 4) = '0974'
      	GROUP BY pt_id,
      		bill_no,
      		admission_date
      ) B
      "
    )
  ) %>%
    tibble::as_tibble() %>%
    janitor::clean_names() %>%
    dplyr::mutate_if(is.character, stringr::str_squish) %>%
    dplyr::mutate(admission_date = lubridate::ymd(admission_date))

  # * DB Disconnect ----
  LICHospitalR::db_disconnect(.connection = db_con_obj)

  # * Return ----
  return(data_tbl)

}

#' Get Address for discharges that can be geocoded
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' Get discharged accounts from DSS
#'
#' @details
#' - Requires a connection to DSS, uses both [db_connect()] and [db_disconnect()]
#' - This will look back at discharges starting with a discharge date of six months prior
#' to the SQL GETEDATE() function
#'
#' @examples
#' library(DBI)
#' library(tibble)
#'
#' geocode_discharges_query()
#'
#' @return
#' A tibble
#'
#' @export
#'

geocode_discharges_query <- function() {

  # Connect to DSS ----
  db_con_obj <- LICHospitalR::db_connect()

  # Get discharges to geocode
  data_tbl <- DBI::dbGetQuery(
    conn = db_con_obj
    , statement = base::paste0(
      "
      SELECT PtNo_Num
      , a.addr_line1 + ', ' + a.Pt_Addr_City + ', ' + a.Pt_Addr_State + ', ' + a.Pt_Addr_Zip AS [FullAddress]
      , a.Pt_Addr_Zip
      , a.Pt_Addr_City + ', ' + a.Pt_Addr_State + ', ' + a.Pt_Addr_Zip AS [PartialAddress]

      FROM smsdss.c_patient_demos_v AS A
      LEFT OUTER JOIN smsdss.BMH_PLM_PtAcct_V AS B
      ON A.pt_id = B.Pt_No
      	AND A.from_file_ind = B.from_file_ind
      LEFT OUTER JOIN SMSDSS.c_geocoded_address AS C
      ON B.PtNo_Num = C.Encounter

      WHERE a.Pt_Addr_City IS NOT NULL
      AND a.addr_line1 IS NOT NULL
      AND a.Pt_Addr_State IS NOT NULL
      AND a.Pt_Addr_Zip IS NOT NULL
      AND b.Plm_Pt_Acct_Type = 'I'
      AND b.tot_chg_amt > 0
      AND LEFT(B.PTNO_NUM, 1) != '2'
      AND LEFT(B.PTNO_NUM, 4) != '1999'
      AND B.Dsch_Date >= dateadd(month, datediff(month, 0, getdate()) - 6,0)
      AND A.addr_line1 != '101 HOSPITAL RD'
      AND C.Encounter IS NULL
      "
    )
  ) %>%
    tibble::as_tibble()

  # * DB Disconnect ----
  LICHospitalR::db_disconnect(.connection = db_con_obj)

  # * Return ----
  return(data_tbl)

}

#' Get CDI QEC Numbers from DSS
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' Gets the QEC numbers for CDI
#'
#' @details
#' - Requires a connection to DSS, uses both [db_connect()] and [db_disconnect()]
#' - Has Start and End dates set dynamically in the query in order to obtain
#' for the previous month. For example if you run the query on any day in October
#' you will get data for September.
#'
#' @examples
#' library(DBI)
#' library(odbc)
#' qec_cdi_query()
#'
#' @return
#' A tibble
#'
#' @export
#'

qec_cdi_query <- function() {

  # * DB Connection ----
  db_con_obj <- LICHospitalR::db_connect()

  # * Query ----
  data_tbl <- DBI::dbGetQuery(
    conn = db_con_obj
    , statement = base::paste0(
      "
      DECLARE @ThisDate DATETIME;
        DECLARE @START DATETIME;
        DECLARE @END   DATETIME;

        SET @ThisDate = GETDATE();
        SET @START = dateadd(mm, datediff(mm, 0, @ThisDate) - 1, 0);
        SET @END   = dateadd(mm, datediff(mm, 0, @ThisDate), 0);

        -- Total Admits All Payers Including PSY
        SELECT 'Total Admits All Payers Including PSY' AS [Category]
        , DATEPART(MONTH, ADM_DATE) AS [Month]
        , COUNT(DISTINCT(PTNO_nUM)) AS [PT_Count]

        FROM smsdss.BMH_PLM_PtAcct_V

        WHERE Adm_Date >= @START
        AND Adm_Date < @END
        AND tot_chg_amt > 0
        AND LEFT(PTNO_NUM, 1) != '2'
        AND LEFT(PTNO_NUM, 4) != '1999'
        AND Plm_Pt_Acct_Type = 'I'

        GROUP BY DATEPART(MONTH, Adm_Date)

        UNION

        -- Total Admits All Payers Excluding PSY
        SELECT 'Total Admits All Payers Excluding PSY' AS [Category]
        , DATEPART(MONTH, ADM_DATE) AS [Month]
        , COUNT(DISTINCT(PTNO_nUM)) AS [PT_Count]

        FROM smsdss.BMH_PLM_PtAcct_V

        WHERE Adm_Date >= @START
        AND Adm_Date < @END
        AND tot_chg_amt > 0
        AND LEFT(PTNO_NUM, 1) != '2'
        AND LEFT(PTNO_NUM, 4) != '1999'
        AND Plm_Pt_Acct_Type = 'I'
        AND hosp_svc != 'PSY'

        GROUP BY DATEPART(MONTH, Adm_Date)

        UNION

        -- Total Admits Medicare Including PSY
        SELECT 'Total Admits Medicare Including PSY' AS [Category]
        , DATEPART(MONTH, ADM_DATE) AS [Month]
        , COUNT(DISTINCT(PTNO_nUM)) AS [PT_Count]

        FROM smsdss.BMH_PLM_PtAcct_V

        WHERE Adm_Date >= @START
        AND Adm_Date < @END
        AND tot_chg_amt > 0
        AND LEFT(PTNO_NUM, 1) != '2'
        AND LEFT(PTNO_NUM, 4) != '1999'
        AND Plm_Pt_Acct_Type = 'I'
        AND User_Pyr1_Cat IN ('AAA', 'ZZZ')

        GROUP BY DATEPART(MONTH, Adm_Date)

        UNION

        -- Total Admits Medicare Excluding PSY
        SELECT 'Total Admits Medicare Excluding PSY' AS [Category]
        , DATEPART(MONTH, ADM_DATE) AS [Month]
        , COUNT(DISTINCT(PTNO_nUM)) AS [PT_Count]

        FROM smsdss.BMH_PLM_PtAcct_V

        WHERE Adm_Date >= @START
        AND Adm_Date < @END
        AND tot_chg_amt > 0
        AND LEFT(PTNO_NUM, 1) != '2'
        AND LEFT(PTNO_NUM, 4) != '1999'
        AND Plm_Pt_Acct_Type = 'I'
        AND User_Pyr1_Cat IN ('AAA', 'ZZZ')
        AND hosp_svc != 'PSY'

        GROUP BY DATEPART(MONTH, Adm_Date)

        UNION

        -- Total Discharges All Payers Including PSY
        SELECT 'Total Discharges All Payers Including PSY' AS [Category]
        , DATEPART(MONTH, Dsch_Date) AS [Month]
        , COUNT(DISTINCT(PtNo_Num)) AS [PT_Count]

        FROM smsdss.BMH_PLM_PtAcct_V

        WHERE Dsch_Date >= @START
        AND Dsch_Date < @END
        AND tot_chg_amt > 0
        AND LEFT(PTNO_NUM, 1) != '2'
        AND LEFT(PTNO_NUM, 4) != '1999'
        AND Plm_Pt_Acct_Type = 'I'

        GROUP BY DATEPART(MONTH, Dsch_Date)

        UNION

        -- Total Discharges All Payers Excluding PSY
        SELECT 'Total Discharges All Payers Excluding PSY' AS [Category]
        , DATEPART(MONTH, Dsch_Date) AS [Month]
        , COUNT(DISTINCT(PtNo_Num)) AS [PT_Count]

        FROM smsdss.BMH_PLM_PtAcct_V

        WHERE Dsch_Date >= @START
        AND Dsch_Date < @END
        AND tot_chg_amt > 0
        AND LEFT(PTNO_NUM, 1) != '2'
        AND LEFT(PTNO_NUM, 4) != '1999'
        AND Plm_Pt_Acct_Type = 'I'
        AND hosp_svc != 'PSY'

        GROUP BY DATEPART(MONTH, Dsch_Date)

        UNION

        -- Total Discharges Medicare Including PSY
        SELECT 'Total Discharges Medicare Including PSY' AS [Category]
        , DATEPART(MONTH, Dsch_Date) AS [Month]
        , COUNT(DISTINCT(PtNo_Num)) AS [PT_Count]

        FROM smsdss.BMH_PLM_PtAcct_V

        WHERE Dsch_Date >= @START
        AND Dsch_Date < @END
        AND tot_chg_amt > 0
        AND LEFT(PTNO_NUM, 1) != '2'
        AND LEFT(PTNO_NUM, 4) != '1999'
        AND Plm_Pt_Acct_Type = 'I'
        AND User_Pyr1_Cat IN ('AAA', 'ZZZ')

        GROUP BY DATEPART(MONTH, Dsch_Date)

        UNION

        -- Total Discharges Medicare Excluding PSY
        SELECT 'Total Discharges Medicare Excluding PSY' AS [Category]
        , DATEPART(MONTH, Dsch_Date) AS [Month]
        , COUNT(DISTINCT(PtNo_Num)) AS [PT_Count]

        FROM smsdss.BMH_PLM_PtAcct_V

        WHERE Dsch_Date >= @START
        AND Dsch_Date < @END
        AND tot_chg_amt > 0
        AND LEFT(PTNO_NUM, 1) != '2'
        AND LEFT(PTNO_NUM, 4) != '1999'
        AND Plm_Pt_Acct_Type = 'I'
        AND User_Pyr1_Cat IN ('AAA', 'ZZZ')
        AND hosp_svc != 'PSY'

        GROUP BY DATEPART(MONTH, Dsch_Date)
        ;
      "
    )
  ) %>%
    tibble::as_tibble()

  # * DB Disconnect ----
  LICHospitalR::db_disconnect(.connection = db_con_obj)

  # * Return ----
  return(data_tbl)

}

#' Code 64 Charged Accounts
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description Get accounts that have a code 64 charged to them
#'
#' @details
#' - Requires a connection to DSS, uses both [db_connect()] and [db_disconnect()]
#' - Has Start and End dates set dynamically in the query in order to obtain
#' for the previous month. For example if you run the query on any day in October
#' you will get data for September.
#'
#' @examples
#' library(DBI)
#' library(dplyr)
#' library(janitor)
#' code64_charged_accounts_query()
#'
#' @return
#' A tibble
#'
#' @export
#'

code64_charged_accounts_query <- function() {

  # * DB Connection ----
  db_con_obj <- LICHospitalR::db_connect()

  # * Query ----
  query <- DBI::dbGetQuery(
    conn = db_con_obj
    , statement = base::paste0(
      "
      DECLARE @START_DATE DATE;
      DECLARE @END_DATE   DATE;

      SET @START_DATE = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 1, 0)
      SET @END_DATE   = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0)

      SELECT B.Med_Rec_No,
      B.PtNo_Num,
      A.unit_seq_no,
      A.from_file_ind,
      CAST(A.actv_date AS DATE) AS [actv_date],
      sum(actv_tot_qty) AS [tot_qty],
      sum(chg_tot_amt) AS [tot_code_chg]
      FROM smsmir.actv AS A
      INNER MERGE JOIN SMSDSS.BMH_PLM_PtAcct_V AS B
      ON A.PT_ID = B.PT_NO
      	AND A.unit_seq_no = B.unit_seq_no
      	AND A.from_file_ind = B.from_file_ind
      WHERE A.actv_cd IN ('01000504', '01000553')
      AND A.actv_date >= @START_DATE
      AND A.actv_date < @END_DATE
      GROUP BY B.Med_Rec_No,
      B.PtNo_Num,
      A.unit_seq_no,
      A.from_file_ind,
      actv_date
      ORDER BY B.PtNo_Num,
      A.actv_date
      "
    )
  ) %>%
    tibble::as_tibble() %>%
    janitor::clean_names()

  # * DB Disconnect ----
  LICHospitalR::db_disconnect(.connection = db_con_obj)

  # Manipulation
  data_tbl <- base::subset(query, query$tot_qty > 0)

  # * Return ----
  return(data_tbl)

}

#' ORSOS to SPROC Case Reconcilliation Query
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' This function gets a list of accounts from smsdss.c_ORSOS_Post_Case_Rpt_Tbl
#' and then looks for the encounter numbers in smsmir.sproc to see if the case
#' was coded to a provider by HIM.
#'
#' The start and end dates are set dynamically in order to ensure there is a two
#' week lag in the looking for cases so that they get through the HIM coding process.
#'
#' For example if we are running the report on November 5th, 2020 a Thursday, then
#' the report will pull records from 2020-10-11 00:00:00 through 2020-10-17 23:59:00
#'
#' @details
#' - Requires a connection to DSS, uses both [db_connect()] and [db_disconnect()]
#' - Has start and end dates set dynamically to look back on data to ensure it has
#' gone through the coding process.
#'
#' @examples
#' orsos_to_sproc_query()
#'
#' @return
#' A tibble
#'
#' @export
#'

orsos_to_sproc_query <- function() {

  # * DB Connection ----
  #base::source("R/db_con.R")
  db_con_obj <- LICHospitalR::db_connect()

  # * Query ----
  temp_a_tbl <- DBI::dbGetQuery(
    conn = db_con_obj
    , statement = base::paste0(
      "
      DECLARE @ThisDate DATE;
      DECLARE @Start    DATE;
      DECLARE @End      DATE;

      SET @ThisDate = GETDATE();
      SET @Start    = DATEADD(WEEK, DATEDIFF(WEEK, -1, @ThisDate) - 3, -1)
      SET @End      = DATEADD(WEEK, DATEDIFF(WEEK, -1, @ThisDate) - 2, -1)

      SELECT DISTINCT Encounter
      , COALESCE(DSS_SRC_PRACT_NO, ORSOS_MD_ID) AS [resp_pty_cd]
      FROM smsdss.c_ORSOS_Post_Case_Rpt_Tbl
      WHERE ORSOS_Start_Date >= @START
      AND ORSOS_Start_Date < @END
      ORDER BY Encounter
      "
    )
  ) %>%
    tibble::as_tibble() %>%
    dplyr::filter(!resp_pty_cd == "\\") %>%
    janitor::clean_names() %>%
    dplyr::mutate(
      proc_cd_prio     = ""
      , pract_rpt_name = ""
      , proc_eff_date  = ""
      , grouping       ="ORSOS"
    ) %>%
    dplyr::select(
      encounter
      , proc_cd_prio
      , resp_pty_cd
      , pract_rpt_name
      , proc_eff_date
      , grouping
    )

  temp_b_tbl <- DBI::dbGetQuery(
    conn = db_con_obj
    , statement = base::paste0(
      "
      SELECT SUBSTRING(A.pt_id, 5, 8) AS [Encounter]
      , A.proc_cd_prio
      , A.resp_pty_cd
      , B.pract_rpt_name
      , A.proc_eff_date
      FROM SMSMIR.sproc AS A
      INNER JOIN SMSMIR.pract_mstr AS B
      ON A.resp_pty_cd = B.pract_no
      AND A.orgz_cd = B.iss_orgz_cd
      AND proc_cd_type != 'C'
      --AND proc_cd_prio = '01'
      ORDER BY A.pt_id
      , A.proc_cd_prio
      "
    )
  ) %>%
    tibble::as_tibble() %>%
    janitor::clean_names() %>%
    dplyr::mutate_if(is.character, stringr::str_squish) %>%
    dplyr::filter(encounter %in% temp_a_tbl$encounter) %>%
    dplyr::mutate(grouping = "SPROC") %>%
    dplyr::select(
      encounter
      , proc_cd_prio
      , resp_pty_cd
      , pract_rpt_name
      , proc_eff_date
      , grouping
    )

  # * DB Disconnect ----
  LICHospitalR::db_disconnect(.connection = db_con_obj)

  # * Return ----
  data_tbl <- base::rbind(temp_a_tbl, temp_b_tbl) %>%
    dplyr::select(-proc_eff_date)

  return(data_tbl)

}

#' Discharge Order to Discharge Date Time Query
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' This query will get information on the last discharge order written for a patient
#' and the time that was input into the system Soarian/Invision as the discharge date time.
#'
#' @details
#' - Requires a connection to DSS, uses both [db_connect()] and [db_disconnect()]
#' - Has start and end dates set dynamically
#'
#' @examples
#' \dontrun{
#' discharge_order_to_discharge_query()
#' }
#'
#' @return
#' A tibble
#'
#' @export
#'

discharge_order_to_discharge_query <- function() {

  # * DB Connection ----
  db_con_obj <- LICHospitalR::db_connect()

  # * Query ----
  data_tbl <- DBI::dbGetQuery(
    conn = db_con_obj
    , statement = base::paste0(
      "
      DECLARE @TODAY DATE;
      DECLARE @START DATE;
      DECLARE @END   DATE;

      SET @TODAY = CAST(GETDATE() AS DATE);
      SET @START = DATEADD(MONTH, DATEDIFF(MONTH, 0, @TODAY) - 1, 0);
      SET @END   = DATEADD(MONTH, DATEDIFF(MONTH, 0, @TODAY), 0);


      SELECT PAV.PtNo_Num
      , PDV.pyr_group2
      , CAST(PAV.DSCH_DATE AS DATE) AS [Dsch_Date]
      , DschOrdDT.ent_dtime AS [Last_Dsch_Ord_DTime]
      , PAV.vst_end_dtime
      , PAV.dsch_disp
      , CASE
      	WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = 'HB' THEN 'Drug/Alcohol Rehab Non-Hospital Facility'
      	WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = 'HI' THEN 'Hospice at Hospice Facility, SNF or Inpatient Facility'
      	WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = 'HR' THEN 'Home, Home with Public Health Nurse, Adult Home, Assisted Living'
      	WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = 'MA' THEN 'Left Against Medical Advice, Elopement'
      	WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = 'TB' THEN 'Correctional Institution'
      	WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = 'TE' THEN 'SNF -Sub Acute'
      	WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = 'TF' THEN 'Specialty Hospital ( i.e Sloan, Schneiders)'
      	WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = 'TH' THEN 'Hospital - Med/Surg (i.e Stony Brook)'
      	WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = 'TL' THEN 'SNF - Long Term'
      	WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = 'TN' THEN 'Hospital - VA'
      	WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = 'TP' THEN 'Hospital - Psych or Drug/Alcohol (i.e BMH 1EAST, South Oaks)'
      	WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = 'TT' THEN 'Hospice at Home, Adult Home, Assisted Living'
      	WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = 'TW' THEN 'Home, Adult Home, Assisted Living with Homecare'
      	WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = 'TX' THEN 'Hospital - Acute Rehab ( I.e. St. Charles, Southside)'
      	WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = '1A' THEN 'Postoperative Death, Autopsy'
      	WHEN LEFT(PAV.dsch_disp, 1) IN ('C', 'D') THEN 'Mortality'
      END AS [Dispo]

      FROM SMSDSS.BMH_PLM_PtAcct_V AS PAV
      -- Get last dsch ord
      LEFT OUTER JOIN (
      	SELECT B.episode_no,
      		B.ENT_DTIME,
      		B.svc_cd
      	FROM (
      		SELECT CAST(EPISODE_NO AS VARCHAR(8)) AS Episode_No,
      			svc_cd,
      			ENT_DTIME,
      			ROW_NUMBER() OVER (
      				PARTITION BY EPISODE_NO ORDER BY ORD_NO DESC
      				) AS ROWNUM
      		FROM smsmir.sr_ord
      		WHERE svc_desc = 'DISCHARGE TO'
      			AND episode_no < '20000000'
      		) B
      	WHERE B.ROWNUM = 1
      	) DschOrdDT ON PAV.PTNO_NUM = DschOrdDT.Episode_No
      LEFT OUTER JOIN SMSDSS.PYR_DIM_V AS PDV
      ON PAV.PYR1_co_PLAN_CD = PDV.SRC_PYR_CD
      	AND PAV.REGN_HOSP = PDV.ORGZ_CD

      WHERE PAV.tot_chg_amt > 0
      AND LEFT(PAV.PTNO_NUM, 1) != '2'
      AND LEFT(PAV.PTNO_NUM, 4) != '1999'
      AND PAV.DSCH_DATE >= @START
      AND PAV.DSCH_DATE < @END
      AND PAV.PLM_PT_ACCT_TYPE = 'I'
      AND PAV.dsch_disp IN ('AHR','ATE','ATL')
      "
    )
  ) %>%
    tibble::as_tibble() %>%
    janitor::clean_names()

  data_tbl <- data_tbl %>%
    dplyr::mutate(
      dsch_ord_dsch_mins = base::difftime(
        vst_end_dtime
        , last_dsch_ord_d_time
        , units = "mins"
      )
    ) %>%
    dplyr::mutate(
      dsch_ord_dsch_hrs = base::difftime(
        vst_end_dtime
        , last_dsch_ord_d_time
        , units = "hours"
      )
    )

  # * DB Disconnect ----
  LICHospitalR::db_disconnect(.connection = db_con_obj)

  # * Return ----
  return(data_tbl)

}

#' Congenital Malformations Query for HIM
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' This query will get the information for congenital malformations that must
#' be sent to HIM on a monthly basis.
#'
#' @details
#' - Requires a connection to DSS, uses both [db_connect()] and [db_disconnect()]
#' - Has start and end dates set dynamically
#'
#' @examples
#' \dontrun{
#' congenital_malformation_query()
#' }
#'
#' @export
#'

congenital_malformation_query <- function() {

  # * DB Connection ----
  db_con_obj <- LICHospitalR::db_connect()

  # * Query ----
  data_tbl <- DBI::dbGetQuery(
    conn = db_con_obj
    , statement = base::paste0(
      "
        DECLARE @ThisDate DATE;
        DECLARE @START DATE;
        DECLARE @END DATE;

        SET @ThisDate = GETDATE();
        SET @START = dateadd(mm, datediff(mm, 0, @ThisDate) - 1, 0);
        SET @END = dateadd(mm, datediff(mm, 0, @ThisDate), 0);
        SELECT Med_Rec_No,
        	PtNo_Num,
        	Adm_Date,
        	Dsch_Date,
        	Pt_Age
        FROM smsdss.BMH_PLM_PtAcct_V
        WHERE Pt_No IN (
        		SELECT pt_id
        		FROM smsmir.dx_grp
        		WHERE dx_cd IN (
        				'D82.1', 'E25.0', 'E25.8', 'E25.9', 'E34.3', 'E34.50', 'E34.51', 'E34.52', 'E78.72', 'G12.0', 'G12.1', 'G12.9', 'G60.0', 'G60.1', 'G60.2', 'G71.00', 'G71.01', 'G71.02', 'G71.09', 'G71.11', 'G71.12', 'G71.13', 'G71.19', 'G71.2', 'G71.3', 'G71.8', 'G71.9', 'K40.00', 'K40.10', 'K40.20', 'K40.30', 'K40.40', 'K40.90', 'K41.00', 'K41.10', 'K41.20', 'K41.30', 'K41.40', 'K41.90', 'L05.91', 'L05.92', 'L81.3', 'L81.4', 'L81.9', 'M26.01', 'M26.02', 'M26.03', 'M26.04', 'M26.05', 'M26.06', 'M26.09', 'M26.19', 'O36.4XX0', 'O36.4XX1', 'O36.4XX2', 'O36.4XX3', 'O36.4XX4', 'O36.4XX5', 'O36.4XX9', 'P02.8', 'P35.0', 'P35.1', 'P35.2', 'P35.3', 'P35.4', 'P35.8', 'P35.9', 'P37.0', 'P37.1', 'P95', 'Q00.0', 'Q00.1', 'Q00.2', 'Q01.0', 'Q01.1', 'Q01.2', 'Q01.8', 'Q01.9', 'Q02', 'Q03.0', 'Q03.1', 'Q03.8', 'Q03.9', 'Q04.0', 'Q04.1', 'Q04.2', 'Q04.3', 'Q04.4', 'Q04.5', 'Q04.6', 'Q04.8', 'Q04.9', 'Q05.0', 'Q05.1', 'Q05.2', 'Q05.3', 'Q05.4', 'Q05.5', 'Q05.6', 'Q05.7', 'Q05.8', 'Q05.9', 'Q06.0', 'Q06.1', 'Q06.2', 'Q06.3', 'Q06.4', 'Q06.8', 'Q06.9', 'Q07.00', 'Q07.01', 'Q07.02', 'Q07.03', 'Q07.8', 'Q07.9', 'Q10.0',
        				'Q10.1', 'Q10.2', 'Q10.3', 'Q10.4', 'Q10.5', 'Q10.6', 'Q10.7', 'Q11.0', 'Q11.1', 'Q11.2', 'Q11.3', 'Q12.0', 'Q12.1', 'Q12.2', 'Q12.3', 'Q12.4', 'Q12.8', 'Q12.9', 'Q13.0', 'Q13.1', 'Q13.2', 'Q13.3', 'Q13.4', 'Q13.5', 'Q13.81', 'Q13.89', 'Q13.9', 'Q14.0', 'Q14.1', 'Q14.2', 'Q14.3', 'Q14.8', 'Q14.9', 'Q15.0', 'Q15.8', 'Q15.9', 'Q16.0', 'Q16.1', 'Q16.2', 'Q16.3', 'Q16.4', 'Q16.5', 'Q16.9', 'Q17.0', 'Q17.1', 'Q17.2', 'Q17.3', 'Q17.4', 'Q17.5', 'Q17.8', 'Q17.9', 'Q18.0', 'Q18.1', 'Q18.2', 'Q18.3', 'Q18.4', 'Q18.5', 'Q18.6', 'Q18.7', 'Q18.8', 'Q18.9', 'Q20.0', 'Q20.1', 'Q20.2', 'Q20.3', 'Q20.4', 'Q20.5', 'Q20.6', 'Q20.8', 'Q20.9', 'Q21.0', 'Q21.1', 'Q21.2', 'Q21.3', 'Q21.4', 'Q21.8', 'Q21.9', 'Q22.0', 'Q22.1', 'Q22.2', 'Q22.3', 'Q22.4', 'Q22.5', 'Q22.6', 'Q22.8', 'Q22.9', 'Q23.0', 'Q23.1', 'Q23.2', 'Q23.3', 'Q23.4', 'Q23.8', 'Q23.9', 'Q24.0', 'Q24.1', 'Q24.2', 'Q24.3', 'Q24.4', 'Q24.5', 'Q24.6', 'Q24.8', 'Q24.9', 'Q25.0', 'Q25.1', 'Q25.21', 'Q25.29', 'Q25.3', 'Q25.40', 'Q25.41', 'Q25.42', 'Q25.43', 'Q25.44', 'Q25.45', 'Q25.46', 'Q25.47', 'Q25.48', 'Q25.49', 'Q25.5', 'Q25.6', 'Q25.71', 'Q25.72'
        				, 'Q25.79', 'Q25.8', 'Q25.9', 'Q26.0', 'Q26.1', 'Q26.2', 'Q26.3', 'Q26.4', 'Q26.5', 'Q26.6', 'Q26.8', 'Q26.9', 'Q27.0', 'Q27.1', 'Q27.2', 'Q27.30', 'Q27.31', 'Q27.32', 'Q27.33', 'Q27.34', 'Q27.39', 'Q27.4', 'Q27.8', 'Q27.9', 'Q28.0', 'Q28.1', 'Q28.2', 'Q28.3', 'Q28.8', 'Q28.9', 'Q30.0', 'Q30.1', 'Q30.2', 'Q30.3', 'Q30.8', 'Q30.9', 'Q31.0', 'Q31.1', 'Q31.2', 'Q31.3', 'Q31.5', 'Q31.8', 'Q31.9', 'Q32.0', 'Q32.1', 'Q32.2', 'Q32.3', 'Q32.4', 'Q33.0', 'Q33.1', 'Q33.2', 'Q33.3', 'Q33.4', 'Q33.5', 'Q33.6', 'Q33.8', 'Q33.9', 'Q34.0', 'Q34.1', 'Q34.8', 'Q34.9', 'Q35.1', 'Q35.3', 'Q35.5', 'Q35.7', 'Q35.9', 'Q36.0', 'Q36.1', 'Q36.9', 'Q37.0', 'Q37.1', 'Q37.2', 'Q37.3', 'Q37.4', 'Q37.5', 'Q37.8', 'Q37.9', 'Q38.0', 'Q38.1', 'Q38.2', 'Q38.3', 'Q38.4', 'Q38.5', 'Q38.6', 'Q38.7', 'Q38.8', 'Q39.0', 'Q39.1', 'Q39.2', 'Q39.3', 'Q39.4', 'Q39.5', 'Q39.6', 'Q39.8', 'Q39.9', 'Q40.0', 'Q40.1', 'Q40.2', 'Q40.3', 'Q40.8', 'Q40.9', 'Q41.0', 'Q41.1', 'Q41.2', 'Q41.8', 'Q41.9', 'Q42.0', 'Q42.1', 'Q42.2', 'Q42.3', 'Q42.8', 'Q42.9', 'Q43.0', 'Q43.1', 'Q43.2', 'Q43.3', 'Q43.4', 'Q43.5', 'Q43.6', 'Q43.7', 'Q43.8', 'Q43.9'
        				, 'Q44.0', 'Q44.1', 'Q44.2', 'Q44.3', 'Q44.4', 'Q44.5', 'Q44.6', 'Q44.7', 'Q45.0', 'Q45.1', 'Q45.2', 'Q45.3', 'Q45.8', 'Q45.9', 'Q50.01', 'Q50.02', 'Q50.1', 'Q50.2', 'Q50.31', 'Q50.32', 'Q50.39', 'Q50.4', 'Q50.5', 'Q50.6', 'Q51.0', 'Q51.10', 'Q51.11', 'Q51.20', 'Q51.21', 'Q51.22', 'Q51.28', 'Q51.3', 'Q51.4', 'Q51.5', 'Q51.6', 'Q51.7', 'Q51.810', 'Q51.811', 'Q51.818', 'Q51.820', 'Q51.821', 'Q51.828', 'Q51.9', 'Q52.0', 'Q52.10', 'Q52.11', 'Q52.120', 'Q52.121', 'Q52.122', 'Q52.123', 'Q52.124', 'Q52.129', 'Q52.3', 'Q52.4', 'Q52.5', 'Q52.6', 'Q52.70', 'Q52.71', 'Q52.79', 'Q52.8', 'Q52.9', 'Q53.00', 'Q53.01', 'Q53.02', 'Q53.10', 'Q53.111', 'Q53.112', 'Q53.12', 'Q53.13', 'Q53.20', 'Q53.211', 'Q53.212', 'Q53.22', 'Q53.23', 'Q53.9', 'Q54.0', 'Q54.1', 'Q54.2', 'Q54.3', 'Q54.4', 'Q54.8', 'Q54.9', 'Q55.0', 'Q55.1', 'Q55.20', 'Q55.21', 'Q55.22', 'Q55.23', 'Q55.29', 'Q55.3', 'Q55.4', 'Q55.5', 'Q55.61', 'Q55.62', 'Q55.63', 'Q55.64', 'Q55.69', 'Q55.7', 'Q55.8', 'Q55.9', 'Q56.0', 'Q56.1', 'Q56.2', 'Q56.3', 'Q56.4', 'Q60.0', 'Q60.1', 'Q60.2', 'Q60.3', 'Q60.4', 'Q60.5', 'Q60.6', 'Q61.00', 'Q61.01',
        				'Q61.02', 'Q61.11', 'Q61.19', 'Q61.2', 'Q61.3', 'Q61.4', 'Q61.5', 'Q61.8', 'Q61.9', 'Q62.0', 'Q62.10', 'Q62.11', 'Q62.12', 'Q62.2', 'Q62.31', 'Q62.32', 'Q62.39', 'Q62.4', 'Q62.5', 'Q62.60', 'Q62.61', 'Q62.62', 'Q62.63', 'Q62.69', 'Q62.7', 'Q62.8', 'Q63.0', 'Q63.1', 'Q63.2', 'Q63.3', 'Q63.8', 'Q63.9', 'Q64.0', 'Q64.10', 'Q64.11', 'Q64.12', 'Q64.19', 'Q64.2', 'Q64.31', 'Q64.32', 'Q64.33', 'Q64.39', 'Q64.4', 'Q64.5', 'Q64.6', 'Q64.70', 'Q64.71', 'Q64.72', 'Q64.73', 'Q64.74', 'Q64.75', 'Q64.79', 'Q64.8', 'Q64.9', 'Q65.00', 'Q65.01', 'Q65.02', 'Q65.1', 'Q65.2', 'Q65.30', 'Q65.31', 'Q65.32', 'Q65.4', 'Q65.5', 'Q65.6', 'Q65.81', 'Q65.82', 'Q65.89', 'Q65.9', 'Q66.00', 'Q66.01', 'Q66.02', 'Q66.10', 'Q66.11', 'Q66.12', 'Q66.211', 'Q66.212', 'Q66.219', 'Q66.221', 'Q66.222', 'Q66.229', 'Q66.30', 'Q66.31', 'Q66.32', 'Q66.40', 'Q66.41', 'Q66.42', 'Q66.50', 'Q66.51', 'Q66.52', 'Q66.6', 'Q66.70', 'Q66.71', 'Q66.72', 'Q66.80', 'Q66.81', 'Q66.82', 'Q66.89', 'Q66.90', 'Q66.91', 'Q66.92', 'Q67.0', 'Q67.1', 'Q67.2', 'Q67.3', 'Q67.4', 'Q67.5', 'Q67.6', 'Q67.7', 'Q67.8', 'Q68.0', 'Q68.1', 'Q68.2',
        				'Q68.4', 'Q68.5', 'Q68.6', 'Q68.8', 'Q69.0', 'Q69.1', 'Q69.2', 'Q69.9', 'Q70.00', 'Q70.01', 'Q70.02', 'Q70.03', 'Q70.10', 'Q70.11', 'Q70.12', 'Q70.13', 'Q70.20', 'Q70.21', 'Q70.22', 'Q70.23', 'Q70.30', 'Q70.31', 'Q70.32', 'Q70.33', 'Q70.4', 'Q70.9', 'Q71.00', 'Q71.01', 'Q71.02', 'Q71.03', 'Q71.10', 'Q71.11', 'Q71.12', 'Q71.13', 'Q71.20', 'Q71.21', 'Q71.22', 'Q71.23', 'Q71.30', 'Q71.31', 'Q71.32', 'Q71.33', 'Q71.40', 'Q71.41', 'Q71.42', 'Q71.43', 'Q71.50', 'Q71.51', 'Q71.52', 'Q71.53', 'Q71.60', 'Q71.61', 'Q71.62', 'Q71.63', 'Q71.811', 'Q71.812', 'Q71.813', 'Q71.819', 'Q71.891', 'Q71.892', 'Q71.893', 'Q71.899', 'Q71.90', 'Q71.91', 'Q71.92', 'Q71.93', 'Q72.00', 'Q72.01', 'Q72.02', 'Q72.03', 'Q72.10', 'Q72.11', 'Q72.12', 'Q72.13', 'Q72.20', 'Q72.21', 'Q72.22', 'Q72.23', 'Q72.30', 'Q72.31', 'Q72.32', 'Q72.33', 'Q72.40', 'Q72.41', 'Q72.42', 'Q72.43', 'Q72.50', 'Q72.51', 'Q72.52', 'Q72.53', 'Q72.60', 'Q72.61', 'Q72.62', 'Q72.63', 'Q72.70', 'Q72.71', 'Q72.72', 'Q72.73', 'Q72.811', 'Q72.812', 'Q72.813', 'Q72.819', 'Q72.891', 'Q72.892', 'Q72.893', 'Q72.899', 'Q72.90', 'Q72.91',
        				'Q72.92', 'Q72.93', 'Q73.0', 'Q73.1', 'Q73.8', 'Q74.0', 'Q74.1', 'Q74.2', 'Q74.3', 'Q74.8', 'Q74.9', 'Q75.0', 'Q75.1', 'Q75.2', 'Q75.3', 'Q75.4', 'Q75.5', 'Q75.8', 'Q75.9', 'Q76.0', 'Q76.1', 'Q76.2', 'Q76.3', 'Q76.411', 'Q76.412', 'Q76.413', 'Q76.414', 'Q76.415', 'Q76.419', 'Q76.425', 'Q76.426', 'Q76.427', 'Q76.428', 'Q76.429', 'Q76.49', 'Q76.5', 'Q76.6', 'Q76.7', 'Q76.8', 'Q76.9', 'Q77.0', 'Q77.1', 'Q77.2', 'Q77.3', 'Q77.4', 'Q77.5', 'Q77.6', 'Q77.7', 'Q77.8', 'Q77.9', 'Q78.0', 'Q78.1', 'Q78.2', 'Q78.3', 'Q78.4', 'Q78.5', 'Q78.6', 'Q78.8', 'Q78.9', 'Q79.0', 'Q79.1', 'Q79.2', 'Q79.3', 'Q79.4', 'Q79.51', 'Q79.59', 'Q79.60', 'Q79.61', 'Q79.62', 'Q79.63', 'Q79.69', 'Q79.8', 'Q79.9', 'Q80.0', 'Q80.1', 'Q80.2', 'Q80.3', 'Q80.4', 'Q80.8', 'Q80.9', 'Q81.0', 'Q81.1', 'Q81.2', 'Q81.8', 'Q81.9', 'Q82.0', 'Q82.1', 'Q82.2', 'Q82.3', 'Q82.4', 'Q82.5', 'Q82.6', 'Q82.8', 'Q82.9', 'Q83.0', 'Q83.1', 'Q83.2', 'Q83.3', 'Q83.8', 'Q83.9', 'Q84.0', 'Q84.1', 'Q84.2', 'Q84.3', 'Q84.4', 'Q84.5', 'Q84.6', 'Q84.8', 'Q84.9', 'Q85.00', 'Q85.01', 'Q85.02', 'Q85.03', 'Q85.09', 'Q85.1', 'Q85.8', 'Q85.9', 'Q86.0',
        				'Q86.1', 'Q86.2', 'Q86.8', 'Q87.0', 'Q87.11', 'Q87.19', 'Q87.2', 'Q87.3', 'Q87.40', 'Q87.410', 'Q87.418', 'Q87.42', 'Q87.43', 'Q87.5', 'Q87.81', 'Q87.82', 'Q87.89', 'Q89.01', 'Q89.09', 'Q89.1', 'Q89.2', 'Q89.3', 'Q89.4', 'Q89.7', 'Q89.8', 'Q89.9', 'Q90.0', 'Q90.1', 'Q90.2', 'Q90.9', 'Q91.0', 'Q91.1', 'Q91.2', 'Q91.3', 'Q91.4', 'Q91.5', 'Q91.6', 'Q91.7', 'Q92.0', 'Q92.1', 'Q92.2', 'Q92.5', 'Q92.61', 'Q92.62', 'Q92.7', 'Q92.8', 'Q92.9', 'Q93.0', 'Q93.1', 'Q93.2', 'Q93.3', 'Q93.4', 'Q93.51', 'Q93.59', 'Q93.7', 'Q93.81', 'Q93.82', 'Q93.88', 'Q93.89', 'Q93.9', 'Q95.0', 'Q95.1', 'Q95.2', 'Q95.3', 'Q95.5', 'Q95.8', 'Q95.9', 'Q96.0', 'Q96.1', 'Q96.2', 'Q96.3', 'Q96.4', 'Q96.8', 'Q96.9', 'Q97.0', 'Q97.1', 'Q97.2', 'Q97.3', 'Q97.8', 'Q97.9', 'Q98.0', 'Q98.1', 'Q98.3', 'Q98.4', 'Q98.5', 'Q98.6', 'Q98.7', 'Q98.8', 'Q98.9', 'Q99.0', 'Q99.1', 'Q99.2', 'Q99.8', 'Q99.9', 'Z37.1', 'Z37.3', 'Z37.4', 'Z37.6', 'Z37.60', 'Z37.61', 'Z37.62', 'Z37.63', 'Z37.64', 'Z37.69', 'Z37.7'
        				)
        			AND dx_cd_type = 'df'
        		)
        	AND Dsch_Date >= @START
        	AND Dsch_Date < @END
        	AND Pt_Age <= 2
        "
    )
  ) %>%
    tibble::as_tibble() %>%
    janitor::clean_names()

  # * DB Disconnect ----
  LICHospitalR::db_disconnect(.connection = db_con_obj)

  # * Return ----
  return(data_tbl)

}

#' Duplicate Coded Cataracts Query for HIM
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' This query will get the accounts that have been duplicate coded for a cataract
#'
#' @details
#' - Requires a connection to DSS, uses both [db_connect()] and [db_disconnect()]
#' - Has start and end dates set dynamically
#'
#' @examples
#' \dontrun{
#' duplicate_coded_cataract_query()
#' }
#'
#' @return
#' A tibble
#'
#' @export
#'

duplicate_coded_cataract_query <- function() {

  # * DB Connection ----
  db_con_obj <- LICHospitalR::db_connect()

  # * Query ----
  temp_a <- DBI::dbGetQuery(
    conn = db_con_obj
    , statement = base::paste0(
      "
        SELECT B.Pt_Name
        , B.Pt_Birthdate
        , B.Med_Rec_No
        , A.pt_id
        , A.proc_eff_date
        , A.proc_cd
        , A.proc_cd_modf1

        FROM smsmir.sproc AS A
        LEFT JOIN smsdss.BMH_PLM_PtAcct_V AS B
        ON A.PT_ID = B.Pt_No

        WHERE A.proc_eff_date >= dateadd(MM, datediff(MM, 0, GETDATE()), 0)
        AND A.proc_cd IN ('66820', '66821', '66830', '66982', '66983', '66984')
        AND LEFT(pt_id, 4) = '0000'

        ORDER BY B.MED_REC_NO
        , A.proc_eff_date
        "
    )
  ) %>%
    tibble::as_tibble() %>%
    janitor::clean_names()

  # If no data then return out of function
  if(nrow(temp_a) == 0) {
    return(print("No data - exiting function"))
  }

  temp_b <- DBI::dbGetQuery(
    conn = db_con_obj
    , statement = base::paste0(
      "
      SELECT B.Pt_Name
    	, B.Pt_Birthdate
    	, B.Med_Rec_No
    	, A.pt_id
    	, A.proc_eff_date
    	, A.proc_cd
    	, A.proc_cd_modf1

    	FROM smsmir.sproc AS A
    	LEFT JOIN smsdss.BMH_PLM_PtAcct_V AS B
    	ON A.PT_ID = B.Pt_No

    	WHERE A.proc_cd IN ('66820', '66821', '66830', '66982', '66983', '66984')
    	AND LEFT(A.PT_ID, 4) = '0000'
      "
    )
  ) %>%
    tibble::as_tibble() %>%
    janitor::clean_names() %>%
    dplyr::filter(med_rec_no %in% temp_a$med_rec_no) %>%
    dplyr::filter(!pt_id %in% temp_a$pt_id)

  # * DB Disconnect ----
  LICHospitalR::db_disconnect(.connection = db_con_obj)

  # * Return ----
  unioned_tbl <- base::rbind(temp_a, temp_b) %>%
    tibble::as_tibble()

  data_tbl <- unioned_tbl %>%
    dplyr::group_by(med_rec_no, proc_cd_modf1) %>%
    dplyr::mutate(
      rn = dplyr::with_order(
        order_by = proc_eff_date
        , fun    = dplyr::row_number
        , x      = proc_eff_date
      )
    ) %>%
    dplyr::ungroup() %>%
    dplyr::arrange(med_rec_no, proc_eff_date) %>%
    dplyr::filter(rn > 1)

  return(data_tbl)

}

#' Inpatient Coding Lag Query for HIM
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' This query will get results for the inpatient coding lag report for HIM
#'
#' @details
#' - Requires a connection to DSS, uses both [db_connect()] and [db_disconnect()]
#' - Has start and end dates set dynamically
#'
#' @examples
#' \dontrun{
#' inpatient_coding_lag_query()
#' }
#'
#' @return
#' A tibble
#'
#' @export
#'

inpatient_coding_lag_query <- function(){

  # * DB Connection ----
  db_con_obj <- LICHospitalR::db_connect()

  # * Query ----
  data_tbl <- DBI::dbGetQuery(
    conn = db_con_obj
    , statement = base::paste0(
      "
      DECLARE @ThisDate DATETIME2;
      SET @ThisDate = GETDATE();

      SELECT [Patient_ID]
      , [episode_no]
      , [Coder]
      , [Date_Coded]
      , b.adm_dtime
      , b.dsch_dtime
      , DATEDIFF(dd,b.dsch_dtime, a.date_coded) As [Lag]
      , DATEPART(YEAR, A.[Date_Coded]) AS [Year_Coded]
      , DATEPART(MONTH, A.[Date_Coded]) AS [Month_Coded]

      FROM [SMSPHDSSS0X0].[smsdss].[c_bmh_coder_activity_v] as a
      left outer join smsmir.mir_acct as b
      ON a.Patient_ID = b.pt_id

      where Date_Coded >= dateadd(mm, datediff(mm, 0, @ThisDate) - 1, 0)
      AND Date_Coded < dateadd(mm, datediff(mm, 0, @ThisDate), 0)
      AND LEFT(patient_id,5) = '00001'
      "
    )
  ) %>%
    tibble::as_tibble() %>%
    janitor::clean_names()

  # * DB Disconnect ----
  LICHospitalR::db_disconnect(.connection = db_con_obj)

  # * Return ----
  return(data_tbl)

}

#' Monthly Admit Trauma File Query
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' This query is used to grab all possible Trauma related accounts. There are two
#' queries that are run, one for accounts by admit_date and one for accounts
#' by discharge_date.
#'
#' There are no parameters to this function as of yet, it may be introduced in the
#' future if there is a strong need for it. The dates are set dynamically in the
#' SQL so that data is always run for the previous third month in which the query is run.
#' For example if the query is run in any day of November 2020 then the data will
#' be pulled for August of 2020
#'
#' @details
#' - Need a valid DSS connection and rights to query.
#' - Utilizes both [db_connect()] and [db_disconnect()] functions
#' - Returns data as a tibble
#'
#' @examples
#' \dontrun{
#' monthly_admit_trauma_query()
#' }
#'
#' @return
#' A tibble
#'
#' @export
#'

monthly_admit_trauma_query <- function() {

  # * DB Connection ----
  db_con_obj <- LICHospitalR::db_connect()

  # * Query ----
  # Admit Queries
  admit_query_a <- DBI::dbGetQuery(
    conn = db_con_obj
    , statement = base::paste0(
      "
      DECLARE @ThisDate DATETIME;
      DECLARE @START DATETIME;
      DECLARE @END   DATETIME;

      SET @ThisDate = GETDATE();
      SET @START = dateadd(mm, datediff(mm, 0, @ThisDate) - 3, 0);
      SET @END   = dateadd(mm, datediff(mm, 0, @ThisDate) - 2, 0);

      SELECT PAV.PT_NO
      , PAV.PtNo_Num
      , PAV.unit_seq_no
      , PAV.from_file_ind
      , PAV.Med_Rec_No
      , PAV.Pt_Name
      , PAV.Pt_Age
      , CAST(PAV.ADM_DATE AS DATE) AS [ADM_DATE]
      , CAST(PAV.DSCH_DATE AS DATE) AS [DSCH_DATE]
      , PAV.Plm_Pt_Acct_Type
      , PAV.dsch_disp

      FROM SMSDSS.BMH_PLM_PtAcct_V AS PAV

      WHERE Adm_Date >= @START
      AND Adm_Date < @END
      AND LEFT(PAV.PTNO_NUM, 1) != '2'
      AND LEFT(PAV.PTNO_NUM, 4) != '1999'
      AND PAV.tot_chg_amt > 0
      AND PAV.Plm_Pt_Acct_Type = 'I'
      "
    )
  ) %>%
    tibble::as_tibble() %>%
    janitor::clean_names() %>%
    dplyr::mutate(pt_no = pt_no %>% stringr::str_squish())

  admit_query_b <- DBI::dbGetQuery(
    conn = db_con_obj
    , statement = base::paste0(
      "
      SELECT pt_id
    	, unit_seq_no
    	, from_file_ind
    	, dx_cd
    	, dx_cd_prio

    	FROM SMSMIR.dx_grp AS DX

    	WHERE PT_ID IN (
    		SELECT DX.pt_id
    		FROM SMSMIR.DX_GRP AS DX
    		WHERE (
    			    LEFT(DX.dx_cd, 2) IN (
    				    'S0','S1','S2','S3','S4','S5','S6','S7','S8','S9'
    			    )
        			AND RIGHT(DX.DX_CD, 1) IN ('A', 'B', 'C')
                )

    		    OR LEFT(Dx.dx_cd, 3) IN (
        			'T07','T14','T30','T31','T32'
    		    )

    		    OR (
    			    LEFT(DX.DX_CD, 3) IN (
    				    'T20','T21','T22','T23','T24',
        				'T25','T26','T27','T28'
    			    )
    			    AND SUBSTRING(DX.DX_CD, 8, 1) = 'A'
        		)

    		    OR (
    			    LEFT(DX.dx_cd, 5) = 'T79.A'
        			AND RIGHT(DX.DX_CD, 1) = 'A'
    		    )
    	    )

    	    AND PT_ID IN (
    		    SELECT PT_ID
    		    FROM SMSMIR.dx_grp AS DX
    	    	WHERE LEFT(DX.DX_CD, 3) BETWEEN 'V00' AND 'Y38'
        		AND RIGHT(DX.DX_CD, 1) = 'A'
        	)

    	    AND LEFT(DX.DX_CD_TYPE, 2) = 'DF'
    	    AND DX.dx_cd_prio < 11
      "
    )
  ) %>%
    tibble::as_tibble() %>%
    dplyr::mutate_if(is.character, stringr::str_squish) %>%
    dplyr::filter(pt_id %in% admit_query_a$pt_no) %>%
    dplyr::arrange(pt_id, dx_cd_prio) %>%
    tidyr::pivot_wider(
      names_from    = dx_cd_prio
      , values_from = dx_cd
    ) %>%
    dplyr::rename(
      "DX01" = "01",
      "DX02" = "02",
      "DX03" = "03",
      "DX04" = "04",
      "DX05" = "05",
      "DX06" = "06",
      "DX07" = "07",
      "DX08" = "08",
      "DX09" = "09",
      "DX10" = "10"
    )

  admit_query_c <- DBI::dbGetQuery(
    conn = db_con_obj
    , statement = base::paste0(
      "
      SELECT [Readmit]
      , INTERIM

      FROM smsdss.vReadmits

      WHERE INTERIM < 31
      AND [READMIT SOURCE DESC] != 'SCHEDULED ADMISSION'
      "
    )
  ) %>%
    tibble::as_tibble() %>%
    janitor::clean_names() %>%
    dplyr::mutate_if(is.character, stringr::str_squish) %>%
    dplyr::filter(readmit %in% admit_query_a$pt_no_num)

  # * DB Disconnect ----
  LICHospitalR::db_disconnect(.connection = db_con_obj)

  # Pull it all together
  data_tbl <- admit_query_a %>%
    dplyr::inner_join(
      admit_query_b
      , by = c(
        "pt_no"           = "pt_id"
        , "unit_seq_no"   = "unit_seq_no"
        , "from_file_ind" = "from_file_ind"
      )
    ) %>%
    dplyr::left_join(
      admit_query_c, by = c("pt_no_num" = "readmit")
    ) %>%
    dplyr::select(
      pt_no_num
      , med_rec_no
      , pt_name
      , pt_age
      , adm_date
      , dsch_date
      , plm_pt_acct_type
      , dsch_disp
      , DX01
      , DX02
      , DX03
      , DX04
      , DX05
      , DX06
      , DX07
      , DX08
      , DX09
      , DX10
      , interim
    ) %>%
    dplyr::mutate(readmit_flag = dplyr::if_else(!is.na(interim), 1, 0))

  # * Return ----
  return(data_tbl)

}

#' Monthly Discharge Trauma File Query
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' This query is used to grab all possible Trauma related accounts. There are two
#' queries that are run, one for accounts by admit_date and one for accounts
#' by discharge_date.
#'
#' There are no parameters to this function as of yet, it may be introduced in the
#' future if there is a strong need for it. The dates are set dynamically in the
#' SQL so that data is always run for the previous third month in which the query is run.
#' For example if the query is run in any day of November 2020 then the data will
#' be pulled for August of 2020
#'
#' @details
#' - Need a valid DSS connection and rights to query.
#' - Utilizes both [db_connect()] and [db_disconnect()] functions
#' - Returns data as a tibble
#'
#' @examples
#' \dontrun{
#' monthly_discharge_trauma_query()
#' }
#'
#' @return
#' A tibble
#'
#' @export
#'

monthly_discharge_trauma_query <- function() {

  # * DB Connection ----
  db_con_obj <- LICHospitalR::db_connect()

  # * Query ----
  # Discharge Queries
  dsch_query_a <- DBI::dbGetQuery(
    conn = db_con_obj
    , statement = base::paste0(
      "
        DECLARE @ThisDate DATETIME;
        DECLARE @START DATETIME;
        DECLARE @END   DATETIME;

        SET @ThisDate = GETDATE();
        SET @START = dateadd(mm, datediff(mm, 0, @ThisDate) - 3, 0);
        SET @END   = dateadd(mm, datediff(mm, 0, @ThisDate) - 2, 0);

        SELECT PAV.PT_NO
        , PAV.PtNo_Num
        , PAV.unit_seq_no
        , PAV.from_file_ind
        , PAV.Med_Rec_No
        , PAV.Pt_Name
        , PAV.Pt_Age
        , CAST(PAV.ADM_DATE AS DATE) AS [ADM_DATE]
        , CAST(PAV.DSCH_DATE AS DATE) AS [DSCH_DATE]
        , PAV.Plm_Pt_Acct_Type
        , PAV.dsch_disp

        FROM SMSDSS.BMH_PLM_PtAcct_V AS PAV

        WHERE Dsch_Date >= @START
        AND Dsch_Date < @END
        AND LEFT(PAV.PTNO_NUM, 1) != '2'
        AND LEFT(PAV.PTNO_NUM, 4) != '1999'
        AND PAV.tot_chg_amt > 0
        AND PAV.Plm_Pt_Acct_Type = 'I'
        "
    )
  ) %>%
    tibble::as_tibble() %>%
    janitor::clean_names() %>%
    dplyr::mutate(pt_no = pt_no %>% stringr::str_squish())

  dsch_query_b <- DBI::dbGetQuery(
    conn = db_con_obj
    , base::paste0(
      "
    	SELECT pt_id
    	, unit_seq_no
    	, from_file_ind
    	, dx_cd
    	, dx_cd_prio

    	FROM SMSMIR.dx_grp AS DX

    	WHERE PT_ID IN (
    		SELECT DX.pt_id
    		FROM SMSMIR.DX_GRP AS DX
    		WHERE (
    			    LEFT(DX.dx_cd, 2) IN (
    				    'S0','S1','S2','S3','S4','S5','S6','S7','S8','S9'
    			    )
        			AND RIGHT(DX.DX_CD, 1) IN ('A', 'B', 'C')
                )

    		    OR LEFT(Dx.dx_cd, 3) IN (
        			'T07','T14','T30','T31','T32'
    		    )

    		    OR (
    			    LEFT(DX.DX_CD, 3) IN (
    				    'T20','T21','T22','T23','T24',
        				'T25','T26','T27','T28'
    			    )
    			    AND SUBSTRING(DX.DX_CD, 8, 1) = 'A'
        		)

    		    OR (
    			    LEFT(DX.dx_cd, 5) = 'T79.A'
        			AND RIGHT(DX.DX_CD, 1) = 'A'
    		    )
    	    )

    	    AND PT_ID IN (
    		    SELECT PT_ID
    		    FROM SMSMIR.dx_grp AS DX
    	    	WHERE LEFT(DX.DX_CD, 3) BETWEEN 'V00' AND 'Y38'
        		AND RIGHT(DX.DX_CD, 1) = 'A'
        	)

    	    AND LEFT(DX.DX_CD_TYPE, 2) = 'DF'
    	    AND DX.dx_cd_prio < 11
        "
    )
  ) %>%
    tibble::as_tibble() %>%
    dplyr::mutate_if(is.character, stringr::str_squish) %>%
    dplyr::filter(pt_id %in% dsch_query_a$pt_no) %>%
    dplyr::arrange(pt_id, dx_cd_prio) %>%
    tidyr::pivot_wider(
      names_from = dx_cd_prio
      , values_from = dx_cd
    ) %>%
    dplyr::rename(
      "DX01" = "01",
      "DX02" = "02",
      "DX03" = "03",
      "DX04" = "04",
      "DX05" = "05",
      "DX06" = "06",
      "DX07" = "07",
      "DX08" = "08",
      "DX09" = "09",
      "DX10" = "10"
    )

  dsch_query_c <- DBI::dbGetQuery(
    conn = db_con_obj
    , statement = base::paste0(
      "
        SELECT [Readmit]
        , INTERIM

        FROM smsdss.vReadmits

        WHERE INTERIM < 31
        AND [READMIT SOURCE DESC] != 'SCHEDULED ADMISSION'
        "
    )
  ) %>%
    tibble::as_tibble() %>%
    janitor::clean_names() %>%
    dplyr::mutate_if(is.character, stringr::str_squish) %>%
    dplyr::filter(readmit %in% dsch_query_a$pt_no_num)

  # * DB Disconnect ----
  LICHospitalR::db_disconnect(.connection = db_con_obj)

  # Pull it all together
  data_tbl <- dsch_query_a %>%
    dplyr::inner_join(
      dsch_query_b
      , by = c(
        "pt_no"           = "pt_id"
        , "unit_seq_no"   = "unit_seq_no"
        , "from_file_ind" = "from_file_ind"
      )
    ) %>%
    dplyr::left_join(dsch_query_c, by = c("pt_no_num"="readmit")) %>%
    dplyr::select(
      pt_no_num
      , med_rec_no
      , pt_name
      , pt_age
      , adm_date
      , dsch_date
      , plm_pt_acct_type
      , dsch_disp
      , DX01
      , DX02
      , DX03
      , DX04
      , DX05
      , DX06
      , DX07
      , DX08
      , DX09
      , DX10
      , interim
    ) %>%
    dplyr::mutate(readmit_flag = dplyr::if_else(!is.na(interim), 1, 0))

  # * Return ----
  return(data_tbl)

}

#' Monthly PSY Admits Query
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' This query is used to grab all hospital service PSY admits for the previous
#' month. There are no parameters to this function as of yet, it may be introduce
#' in the future if there is a strong need for it.
#'
#' This information is used to send to Elizabeth Saporito
#'
#' @details
#' - Need a valid DSS connection and rights to query.
#' - Utilizes both [db_connect()] and [db_disconnect()] functions
#' - Returns data as a tibble
#'
#' @examples
#' \dontrun{
#' monthly_psy_admits_query()
#' }
#'
#' @return
#' A tibble
#'
#' @export
#'

monthly_psy_admits_query <- function() {

  # * DB Connection ----
  db_con_obj <- LICHospitalR::db_connect()

  # * Query ----
  # Admit Queries
  data_tbl <- DBI::dbGetQuery(
    conn = db_con_obj
    , statement = base::paste0(
      "
      DECLARE @START DATE;
      DECLARE @END   DATE;

      SET @START = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) -1, 0);
      SET @END   = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0);

      SELECT A.Med_Rec_No
      , A.Adm_Date
      , A.Pyr1_Co_Plan_Cd
      , B.pyr_name
      , B.pyr_group2
      FROM smsdss.BMH_PLM_PtAcct_V AS A
      LEFT OUTER JOIN smsdss.pyr_dim_v AS B
      ON A.Pyr1_Co_Plan_Cd = B.pyr_cd
      AND A.Regn_Hosp = B.orgz_cd
      WHERE A.hosp_svc = 'PSY'
      AND LEFT(A.PtNo_Num, 1) != '2'
      AND LEFT(A.PtNo_Num, 4) != '1999'
      AND A.Adm_Date >= @START
      AND A.Adm_Date < @END
      ORDER BY A.Med_Rec_No
      , A.Adm_Date

      "
    )
  ) %>%
    tibble::as_tibble() %>%
    janitor::clean_names()

  # * DB Disconnect ----
  LICHospitalR::db_disconnect(.connection = db_con_obj)

  # * Return ----
  return(data_tbl)

}

#' Monthly PSY Discharges Query
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' This query is used to grab all hospital service PSY discharges for the previous
#' month. There are no parameters to this function as of yet, it may be introduce
#' in the future if there is a strong need for it.
#'
#' This information is used to send to Elizabeth Saporito
#'
#' @details
#' - Need a valid DSS connection and rights to query.
#' - Utilizes both [db_connect()] and [db_disconnect()] functions
#' - Returns data as a tibble
#'
#' @examples
#' \dontrun{
#' monthly_psy_discharges_query()
#' }
#'
#' @return
#' A tibble
#'
#' @export
#'

monthly_psy_discharges_query <- function() {

  # * DB Connection ----
  db_con_obj <- LICHospitalR::db_connect()

  # * Query ----
  # Admit Queries
  data_tbl <- DBI::dbGetQuery(
    conn = db_con_obj
    , statement = base::paste0(
      "
      DECLARE @START DATE;
      DECLARE @END   DATE;

      SET @START = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) -1, 0);
      SET @END   = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0);

      SELECT A.Med_Rec_No
      , A.Dsch_Date
      , A.Pyr1_Co_Plan_Cd
      , B.pyr_name
      , B.pyr_group2
      FROM smsdss.BMH_PLM_PtAcct_V AS A
      LEFT OUTER JOIN smsdss.pyr_dim_v AS B
      ON A.Pyr1_Co_Plan_Cd = B.pyr_cd
      AND A.Regn_Hosp = B.orgz_cd
      WHERE A.hosp_svc = 'PSY'
      AND A.tot_chg_amt > 0
      AND LEFT(A.PtNo_Num, 1) != '2'
      AND LEFT(A.PtNo_Num, 4) != '1999'
      AND A.Dsch_Date >= @START
      AND A.Dsch_Date < @END
      AND A.tot_chg_amt > 0
      ORDER BY A.Med_Rec_No
      , A.Adm_Date
      "
    )
  ) %>%
    tibble::as_tibble() %>%
    janitor::clean_names()

  # * DB Disconnect ----
  LICHospitalR::db_disconnect(.connection = db_con_obj)

  # * Return ----
  return(data_tbl)

}

#' MyHealth Monthly Surgery File
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' This query will generate the data needed to produce the monthly MyHealth Surgery
#' file and send to MyHealth.
#'
#' @details
#' - Need a valid DSS connection and rights to query.
#' - Utilizes both [db_connect()] and [db_disconnect()] functions
#' - Returns data as a tibble
#' - This query contains the following fields:
#' 1. Facilty Account Number
#' 2. Provider_ID
#' 3. Provider Short Name
#' 4. Room ID
#' 5. Start Date
#' 6. Enter Procedure Room Time
#' 7. Leave Procedure Room Time
#' 8. Procedure Description (from ORSOS)
#' 9. Anesthesia Start Date
#' 10. Anesthesia Start Time
#' 11. Anesthesia Stop Date
#' 12. Anesthesia Stop Time
#' 13. Patient Type
#' 14. Admit Recovery Date
#' 15. Admit Recovery Time
#' 16. Leave Recovery Date
#' 17. Leave Recovery Time
#'
#' The date fields are dynamically set to look back one month. There are no
#' parameters to this function
#'
#' @examples
#' \dontrun{
#'   myhealth_monthly_surgery_query()
#' }
#'
#' @return
#' A tibble
#'
#' @export
#'

myhealth_monthly_surgery_query <- function() {

  # * DB Connection ----
  db_con_obj <- LICHospitalR::db_connect()

  # * Query ----
  # Admit Queries
  data_tbl <- DBI::dbGetQuery(
    conn = db_con_obj
    , statement = base::paste0(
      "
      DECLARE @ThisDate DATETIME;
      DECLARE @START DATETIME;
      DECLARE @END   DATETIME;

      SET @ThisDate = GETDATE();
      SET @START = dateadd(mm, datediff(mm, 0, @ThisDate) - 1, 0);
      SET @END   = dateadd(mm, datediff(mm, 0, @ThisDate), 0);

      WITH CTE AS (
      SELECT A.CASE_NO
      , C.FACILITY_ACCOUNT_NO
      , E.RESOURCE_ID
      , A.PROVIDER_SHORT_NAME
      , A.ROOM_ID
      , CAST(A.START_DATE AS DATE)              AS [START_DATE]
      , CAST(A.ENTER_PROC_ROOM_TIME AS TIME(0)) AS [ENTER_PROC_ROOM_TIME]
      , CAST(A.LEAVE_PROC_ROOM_TIME AS TIME(0)) AS [LEAVE_PROC_ROOM_TIME]
      , B.[DESCRIPTION] AS PROCEDURE_DESCRIPTION
      , CAST(D.ANES_START_DATE AS DATE)         AS [ANES_START_DATE]
      , CAST(D.ANES_START_TIME AS TIME(0))      AS [ANES_START_TIME]
      , CAST(D.ANES_STOP_DATE AS DATE)          AS [ANES_STOP_DATE]
      , CAST(D.ANES_STOP_TIME AS TIME(0))       AS [ANES_STOP_TIME]
      , C.PATIENT_TYPE
      , CAST(A.ADMIT_RECOVERY_DATE AS DATE)     AS [ADMIT_RECOVERY_DATE]
      , CAST(A.ADMIT_RECOVERY_TIME AS TIME(0))  AS [ADMIT_RECOVERY_TIME]
      , CAST(A.LEAVE_RECOVERY_DATE AS DATE)     AS [LEAVE_RECOVERY_DATE]
      , CAST(A.LEAVE_RECOVERY_TIME AS TIME(0))  AS [LEAVE_RECOVERY_TIME]

      FROM
      (
      (
      [BMH-ORSOS].[ORSPROD].[ORSPROD].[POST_CASE]              AS A
      INNER JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[PROCEDURES]  AS B
      ON A.MAIN_PROCEDURE_ID = B.PROCEDURE_ID
      )
      INNER JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[CLINICAL]        AS C
      ON A.ACCOUNT_NO = C.ACCOUNT_NO
      )
      LEFT OUTER JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[POST_ANES_TYPE] AS D
      ON A.CASE_NO = D.CASE_NO
      LEFT OUTER JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[POST_RESOURCE]  AS E
      ON A.CASE_NO = E.CASE_NO
      AND E.ROLE_CODE = '1'
      LEFT OUTER JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[CODES_ROLE]     AS F
      ON E.ROLE_CODE = F.CODE

      WHERE (
      A.DELETE_FLAG IS NULL
      OR
      (
      A.DELETE_FLAG = ''
      OR
      A.DELETE_FLAG = 'Z'
      )
      )
      AND (
      (A.START_DATE >= @START AND A.START_DATE < @END)
      )
      AND RIGHT(C.FACILITY_ACCOUNT_NO, 1) != 'J'
      AND E.RESOURCE_ID IN ('00593','014241')
      )

      SELECT * FROM CTE;
      "
    )
  ) %>%
    tibble::as_tibble() %>%
    janitor::clean_names()

  # * DB Disconnect ----
  LICHospitalR::db_disconnect(.connection = db_con_obj)

  # * Return ----
  return(data_tbl)

}

#' Weekly PSY Discharges Query
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' A query to get the Weekly PSY discharges for the previous week.
#'
#' @details
#' - Requires a connection to DSS, uses both [db_connect()] and [db_disconnect()]
#' - Has Start and End dates set dynamically in the query in order to obtain data
#' for the previous week.
#'
#' @examples
#' \dontrun{
#' weekly_psy_discharges_query()
#' }
#'
#' @return
#' A tibble
#'
#' @export
#'

weekly_psy_discharges_query <- function() {

  # * DB Connection ----
  db_con_obj <- LICHospitalR::db_connect()

  # * Query ----
  # Admit Queries
  data_tbl <- DBI::dbGetQuery(
    conn = db_con_obj
    , statement = base::paste0(
      "
      DECLARE @TODAY DATE;
      DECLARE @START DATE;
      DECLARE @END   DATE;

      SET @TODAY = GETDATE();
      SET @START = DATEADD(WEEK, DATEDIFF(WEEK, 0, @TODAY) - 1, -1);
      SET @END   = DATEADD(WEEK, DATEDIFF(WEEK, 0, @TODAY), -1);

      SELECT PAV.Med_Rec_No
      , CAST(PAV.DSCH_DATE AS date) AS [Discharge_Date]

      FROM SMSDSS.BMH_PLM_PTACCT_V AS PAV

      WHERE PAV.hosp_svc = 'PSY'
      AND LEFT(PAV.PTNO_NUM, 1) != '2'
      AND LEFT(PAV.PTNO_NUM, 4) != '1999'
      AND PAV.Dsch_Date >= @START
      AND PAV.Dsch_Date < @END

      ORDER BY CAST(PAV.DSCH_DATE AS DATE)
      "
    )
  ) %>%
    tibble::as_tibble() %>%
    janitor::clean_names()

  # * DB Disconnect ----
  LICHospitalR::db_disconnect(.connection = db_con_obj)

  # * Return ----
  return(data_tbl)

}

#' ORSOS J Accounts Query
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' This will pull in all of the "J" accounts from ORSOS in order for the amb surg
#' department to rectify
#'
#' @details
#' - Requires a connection to DSS, uses both [db_connect()] and [db_disconnect()]
#' - Has Start and End dates set dynamically in the query in order to obtain data
#' for the previous week.
#'
#' @examples
#' \dontrun{
#' orsos_j_accounts_query()
#' }
#'
#' @return
#' A tibble
#'
#' @export
#'

orsos_j_accounts_query <- function() {

  # * DB Connection ----
  db_con_obj <- LICHospitalR::db_connect()

  # * Query ----
  # Admit Queries
  data_tbl <- DBI::dbGetQuery(
    conn = db_con_obj
    , statement = base::paste0(
      "
      DECLARE @ThisDate       DATETIME;
      DECLARE @ORSOS_START_DT DATETIME;
      DECLARE @ORSOS_END_DT   DATETIME;

      SET @ThisDate       = GETDATE();
      SET @ORSOS_START_DT = dateadd(yy, datediff(yy, 0, @ThisDate), 0);
      SET @ORSOS_END_DT   = dateadd(wk, datediff(wk, 0, @ThisDate),  -1);

      SELECT A.CASE_NO
      , C.FACILITY_ACCOUNT_NO

      FROM
      (
      	(
      		[BMH-ORSOS].[ORSPROD].[ORSPROD].[POST_CASE] AS A
      		INNER JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[PROCEDURES] AS B
      		ON A.MAIN_PROCEDURE_ID = B.PROCEDURE_ID
      	)
      	INNER JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[CLINICAL] AS C
      	ON A.ACCOUNT_NO = C.ACCOUNT_NO
      )
      LEFT JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[POST_ANES_TYPE] AS D
      ON A.CASE_NO = D.CASE_NO
      LEFT OUTER JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[CODES_ANES_TYPE] AS E
      ON D.ANES_TYPE_CODE = E.CODE

      WHERE (
      	A.DELETE_FLAG IS NULL
      	OR
      	(
      		A.DELETE_FLAG = ''
      		OR
      		A.DELETE_FLAG = 'Z'
      	)
      )
      AND (
      	A.START_DATE >= @ORSOS_START_DT
      	AND
      	A.START_DATE <  @ORSOS_END_DT
      )

      AND RIGHT(c.FACILITY_ACCOUNT_NO, 1) = 'J'

      ORDER BY C.FACILITY_ACCOUNT_NO
      "
    )
  ) %>%
    tibble::as_tibble() %>%
    janitor::clean_names()

  # * DB Disconnect ----
  LICHospitalR::db_disconnect(.connection = db_con_obj)

  # * Return ----
  return(data_tbl)

}

#' Patient Days for Infection Prevention Query
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' This gets the data necessary for infection prevention. This is used for a variety
#' of reasons, one being total vent days against total days.
#'
#' @details
#' - Requires a connection to DSS, uses both [db_connect()] and [db_disconnect()]
#' - Has Start and End dates set dynamically in the query in order to obtain data
#' for the previous month.
#'
#' @examples
#' \dontrun{
#' infection_prevention_patient_days_query()
#' }
#'
#' @return
#' A tibble
#'
#' @export
#'

infection_prevention_patient_days_query <- function() {

  # * DB Connection ----
  db_con_obj <- LICHospitalR::db_connect()

  # * Query ----
  # Admit Queries
  data_tbl <- DBI::dbGetQuery(
    conn = db_con_obj
    , statement = base::paste0(
      "
      DECLARE @ThisDate DATETIME2;
      DECLARE @SD DATETIME2;
      DECLARE @ED DATETIME2;

      SET @ThisDate = GETDATE();
      SET @SD = dateadd(mm, datediff(mm, 0, @ThisDate) - 1, 0);
      SET @ED = dateadd(mm, datediff(mm, 0, @ThisDate), 0);

      SELECT A.pt_id
      , a.hosp_svc
      , a.nurs_sta
      , CAST(a.cen_date AS date) AS [cen_date]
      , DATEPART(YEAR, A.CEN_DATE) AS [cen_yr]
      , DATEPART(MONTH, A.CEN_DATE) AS [cen_mo]
      , a.tot_cen
      , a.pract_no AS [Attending_ID]
      , UPPER(B.pract_rpt_name) AS [Attending_Name]
      , CASE
      	WHEN B.src_spclty_cd = 'HOSIM'
      		THEN 'Hospitalist'
      		ELSE 'Private'
        END AS [Hospitalist_Private]
      , CASE
      	WHEN B.src_spclty_cd = 'HOSIM'
      		THEN '1'
      		ELSE '0'
        END AS [Hospitalist_Atn_Flag]
      , CASE
      	WHEN B.src_spclty_cd != 'HOSIM'
      		THEN '1'
      		ELSE '0'
        END AS [Private_Atn_Flag]
      , CAST(C.Adm_Date AS date) AS [Adm_Date]
      , CAST(C.Dsch_Date AS date) AS [Dsch_Date]
      -- IF THE DSCH_DATE IS NOT NULL AND THERE ARE $0.00 CHARGES KICK IT OUT
      , CASE
      	WHEN C.Dsch_Date IS NOT NULL
      	AND C.tot_chg_amt <= 0
      		THEN 1
      		ELSE 0
        END AS [Kick_Out_Flag]

      FROM smsdss.dly_cen_occ_fct_v AS A
      LEFT OUTER JOIN smsdss.pract_dim_v AS B
      ON A.pract_no = B.src_pract_no
      	AND B.orgz_cd = 's0x0'
      LEFT OUTER JOIN smsdss.BMH_PLM_PtAcct_V AS C
      ON A.pt_id = C.Pt_No

      WHERE cen_date >= @SD
      AND cen_date < @ED

      ORDER BY pt_id
      , cen_date
      ;
      "
    )
  ) %>%
    tibble::as_tibble() %>%
    janitor::clean_names()

  # * DB Disconnect ----
  LICHospitalR::db_disconnect(.connection = db_con_obj)

  # * Return ----
  return(data_tbl)
}

#' Respiratory VAE Query
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' This query gets the data necessary to perform the VAE (Ventilator Associated Events)
#' calculation for the FiO2 and PEEP values for respiratory therapy.
#'
#' @details
#' - Requires a connection to DSS, uses both [db_connect()] and [db_disconnect()]
#' - Has Start and End dates set dynamically in the query in order to obtain data
#' for the previous 7 days.
#'
#' @seealso
#' Infromational Link:
#' \url{https://www.ahrq.gov/hai/tools/mvp/modules/vae/tool.html}
#'
#' AHRQ Calculator (Javascript must be enabled):
#' \url{https://nhsn.cdc.gov/VAECalculator/vaecalc_v7.html}
#'
#' @examples
#' \dontrun{
#' respiratory_vae_query()
#' }
#'
#' @return
#' A tibble
#'
#' @export
#'

respiratory_vae_query <- function() {

  # * DB Connection ----
  db_con_obj <- LICHospitalR::db_connect()

  # * Query ----
  # Admit Queries
  data_tbl <- DBI::dbGetQuery(
    conn = db_con_obj
    , statement = base::paste0(
      "
      DECLARE @TODAY DATE;
      DECLARE @YESTERDAY DATE;

      SET @TODAY = CAST(GETDATE() AS date);
      SET @YESTERDAY = DATEADD(DAY, -7, @TODAY);

      SELECT episode_no,
      obsv_cd,
      obsv_cd_name,
      obsv_user_id,
      dsply_val,
      val_sts_cd,
      CAST(perf_dtime AS DATE) AS [Perf_Date]
      FROM SMSMIR.obsv
      WHERE obsv_cd IN ('A_BMH_VFFiO2', 'A_BMH_VFPEEP')
      AND dsply_val != '-'
      AND LEFT(episode_no, 1) != '7'
      AND perf_date >= @YESTERDAY
      ORDER BY obsv_cd,
      perf_dtime
      "
    )
  ) %>%
    tibble::as_tibble() %>%
    janitor::clean_names()

  # * DB Disconnect ----
  LICHospitalR::db_disconnect(.connection = db_con_obj)

  # * Return ----
  return(data_tbl)

}

#' Psych to Psych Readmit Query
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' This query gets the data for psy to psy readmits.
#'
#' @details
#' - Requires a connection to DSS, uses both [db_connect()] and [db_disconnect()]
#' - Has Start and End dates set dynamically in the query in order to obtain data
#' for the previous 1 month.
#'
#' @examples
#' \dontrun{
#' readmit_psy_to_psy_query()
#' }
#'
#' @return
#' A tibble
#'
#' @export
#'

readmit_psy_to_psy_query <- function() {

  # * DB Connection ----
  db_con_obj <- LICHospitalR::db_connect()

  # * Query ----
  # Admit Queries
  data_tbl <- DBI::dbGetQuery(
    conn = db_con_obj
    , statement = base::paste0(
      "
      DECLARE @ThisDate DATETIME;
      DECLARE @START DATETIME;
      DECLARE @END   DATETIME;

      SET @ThisDate = GETDATE();
      SET @START = dateadd(mm, datediff(mm, 0, @ThisDate) - 2, 0);
      SET @END   = dateadd(mm, datediff(mm, 0, @ThisDate) - 1, 0);

      WITH CTE AS (
      	SELECT Med_Rec_No
      	, PtNo_Num
      	, Adm_Date
      	, Dsch_Date
      	, Days_Stay
      	, hosp_svc
      	, vst_start_dtime
      	, RN = ROW_NUMBER() OVER(PARTITION BY MED_REC_NO ORDER BY VST_START_DTIME)

      	FROM smsdss.BMH_PLM_PtAcct_V

      	WHERE hosp_svc = 'PSY'
      	AND Dsch_Date >= @START
      	AND Dsch_Date < @END
      )

      SELECT C1.Med_Rec_No
      , C1.PtNo_Num AS [INDEX ENC]
      , C1.Adm_Date AS [INDEX ADM DATE]
      , C1.Dsch_Date AS [INDEX DSCH DATE]
      , DATEPART(MONTH, C1.DSCH_DATE) AS [INDEX DSCH MONTH]
      , C2.PtNo_Num AS [READMIT ENC]
      , C2.Adm_Date AS [READMIT ADM DATE]
      , C2.Dsch_Date AS [READMIT DSCH DATE]
      , DATEDIFF(D, C1.DSCH_DATE, C2.ADM_DATE) AS [INTERIM]

      FROM CTE AS C1
      INNER JOIN CTE AS C2
      ON C1.Med_Rec_No = C2.Med_Rec_No

      WHERE C1.vst_start_dtime < C2.vst_start_dtime
      AND C1.RN + 1 = C2.RN
      AND DATEDIFF(D, C1.DSCH_DATE, C2.Adm_Date) > 0
      AND DATEDIFF(D, C1.DSCH_DATE, C2.ADM_DATE) < 31

      ORDER BY C1.Dsch_Date

      OPTION(FORCE ORDER);
      "
    )
  ) %>%
    tibble::as_tibble() %>%
    janitor::clean_names()

  # * DB Disconnect ----
  LICHospitalR::db_disconnect(.connection = db_con_obj)

  # If no data then return out of function
  if(nrow(data_tbl) == 0){
    return(print("No data - exiting function."))
  }

  # * Return ----
  return(data_tbl)

}
