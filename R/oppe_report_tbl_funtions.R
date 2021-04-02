#' OPPE CPOE Detail Tibble
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' Get the CPOE Detail data for use in CPOE for a specified provider.
#'
#' @details
#' - Requires a connection to DSS, uses both [db_connect()] and [db_disconnect()]
#'
#' @param .data The data to be passed into the tibble function, should be the results
#' from [oppe_cpoe_query()]
#' @param .provider_id The provider id number you are looking for
#' @param .provider_name If you do not know the providers id, then you can use their name
#' to get a match. You can also use the [pract_dim_v_query()] to find the id number
#' before using this function, or you can use it inside of the id number parameter. Be
#' careful with this approach as providers can have the same last name. It is better to
#' use the function on it's own and select the appropriate id number.
#' Uses [stringr::str_to_lower()] so that you can use all lower case letters to
#' describe the name you are looking for.
#'
#' @examples
#' \dontrun{
#' oppe_cpoe_query() %>%
#'   oppe_cpoe_tbl()
#'
#' oppe_cpoe_query() %>%
#'   oppe_cpoe_tbl(.provider_id = "009142")
#'
#' oppe_cpoe_query() %>%
#'   oppe_cpoe_tbl(.provider_name = "rakesh")
#'}
#'
#' @return
#' A tibble
#'
#' @export
#'

oppe_cpoe_tbl <- function(.data, .provider_id, .provider_name){

  # * Tidyeval Setup ----
  resp_party_var_expr <- rlang::enquo(.provider_id)
  name_var_expr       <- rlang::enquo(.provider_name)

  # * Checks ----
  if(!is.data.frame(.data)){
    stop(call. = FALSE, "(.data) is not a data.frame/tibble. Please supply.")
  }

  if(rlang::quo_is_missing(resp_party_var_expr)){
    resp_party_var_expr = NULL
  }

  if(rlang::quo_is_missing(name_var_expr)){
    name_var_expr = NULL
  }

  # * Manipulate ----
  data_tbl <- tibble::as_tibble(.data)

  # Get total orders
  data_tbl <- data_tbl %>%
    # reorder
    dplyr::select(
      ent_date, req_pty_cd, pract_rpt_name, spclty_desc:ord_type_abbr, dplyr::everything()
    ) %>%
    # filter out na names
    dplyr::filter(!is.na(pract_rpt_name))

  # Get total orders
  data_tbl$total_orders = data_tbl %>%
    dplyr::select(where(is.numeric)) %>%
    base::rowSums(.)

  # * Filter ---
  if(!is.null(resp_party_var_expr)){
    data_tbl <- data_tbl %>%
      dplyr::filter(req_pty_cd == {{ resp_party_var_expr }})

    return(data_tbl)
  }

  if(!is.null(name_var_expr)){
    data_tbl <- data_tbl %>%
      dplyr::mutate(pract_rpt_name = stringr::str_to_lower(pract_rpt_name)) %>%
      dplyr::filter(stringr::str_detect(pract_rpt_name, {{ name_var_expr }}))

    return(data_tbl)
  }

  # * Return ----
  return(data_tbl)

}

#' OPPE ALOS Tibble
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' Get the OPPE ALOS data for a provider if specified.
#'
#' @details
#' - Requires a connection to DSS, uses both [db_connect()] and [db_disconnect()]
#' - Returns the provider id and name, actual los, expected los and excess
#'
#' @param .data The data to be passed into the tibble function, should be the results
#' from [oppe_alos_query()]
#' @param .provider_id The provider id number you are looking for
#' @param .provider_name If you do not know the providers id, then you can use their name
#' to get a match. You can also use the [pract_dim_v_query()] to find the id number
#' before using this function, or you can use it inside of the id number parameter. Be
#' careful with this approach as providers can have the same last name. It is better to
#' use the function on it's own and select the appropriate id number.
#' Uses [stringr::str_to_lower()] so that you can use all lower case letters to
#' describe the name you are looking for.
#'
#' @examples
#' oppe_alos_query() %>%
#'   oppe_alos_tbl()
#'
#' oppe_alos_query() %>%
#'   oppe_alos_tbl(.provider_id = "017236")
#'
#' oppe_alos_query() %>%
#'   oppe_alos_tbl(.provider_name = "ashraf ahad")
#'
#' @return
#' A tibble
#'
#' @export
#'
oppe_alos_tbl <- function(.data, .provider_id, .provider_name){

  # * Tidyeval Setup ----
  resp_party_var_expr <- rlang::enquo(.provider_id)
  name_var_expr       <- rlang::enquo(.provider_name)

  # * Checks ----
  if(!is.data.frame(.data)){
    stop(call. = FALSE, "(.data) is not a data.frame/tibble. Please supply.")
  }

  if(rlang::quo_is_missing(resp_party_var_expr)){
    resp_party_var_expr = NULL
  }

  if(rlang::quo_is_missing(name_var_expr)){
    name_var_expr = NULL
  }

  # * Manipulate ----
  data_tbl <- tibble::as_tibble(.data) %>%
    dplyr::select(
      atn_dr_no
      , pract_rpt_name
      , dsch_date
      , lihn_service_line
      , severity_of_illness
      , drg_cost_weight
      , z_score
      , los
      , elos
    ) %>%
    dplyr::mutate(excess = (los - elos))

  # * Filter ---
  if(!is.null(resp_party_var_expr)){
    data_tbl <- data_tbl %>%
      dplyr::filter(atn_dr_no == {{ resp_party_var_expr }})

    return(data_tbl)
  }

  if(!is.null(name_var_expr)){
    data_tbl <- data_tbl %>%
      dplyr::mutate(pract_rpt_name = stringr::str_to_lower(pract_rpt_name)) %>%
      dplyr::filter(stringr::str_detect(pract_rpt_name, {{ name_var_expr }}))

    return(data_tbl)
  }

  # * Return ----
  return(data_tbl)

}

#' OPPE CPOE K-Means
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' Takes data from the [oppe_cpoe_tbl()] and transforms it into an aggregated/normalized
#'  user-item tibble of order proportions.
#'
#' @details This function requires that the [oppe_cpoe_query()] and [oppe_cpoe_tbl()]
#' functions be run and takes the output of that work flow as its input. This function
#' should be used before using a k-mean model. This is commonly referred to as a user_item
#' matrix because "users" (e.g. providers) tend to be on the rows and "tems" (e.g. orders)
#' on the columns.
#'
#' At present this function only selects the following types of orders:
#'  * Written
#'  * Verbal
#'  * Telephone, and
#'  * CPOE
#'
#' @param .data The data that is passed from [oppe_cpoe_tbl()]
#'
#' @examples
#' oppe_cpoe_query() %>%
#'   oppe_cpoe_tbl() %>%
#'   oppe_cpoe_user_item_tbl()
#'
#' @return
#' A aggregated/normalized user item tibble
#'
#' @export
#'

oppe_cpoe_user_item_tbl <- function(.data){

  # * Checks ----
  if(!is.data.frame(.data)){
    stop(call. = FALSE, "(.data) is not a data.frame/tibble. Please supply.")
  }

  # * Manipulate ----
  # Agg/normalize
  query <- tibble::as_tibble(.data)

  data_tbl <- query %>%
    dplyr::select(req_pty_cd, spclty_desc, hospitalist_np_pa_flag,
           written, verbal_order, telephone, cpoe) %>%
    tidyr::pivot_longer(
      written:cpoe
      , names_to  = "order_type"
      , values_to = "order_type_count"
    ) %>%
    dplyr::group_by(
      req_pty_cd
      , spclty_desc
      , hospitalist_np_pa_flag
      , order_type
    ) %>%
    dplyr::summarise(total_orders = sum(order_type_count, na.rm = TRUE)) %>%
    dplyr::ungroup() %>%
    # Normalization
    # Proportions
    dplyr::group_by(req_pty_cd) %>%
    dplyr::mutate(prop_of_total = total_orders / sum(total_orders)) %>%
    dplyr::ungroup()

  # User/Item format
  user_item_tbl <- data_tbl %>%
    dplyr::select(req_pty_cd, order_type, prop_of_total) %>%
    dplyr::mutate(prop_of_total = base::ifelse(
      base::is.na(prop_of_total), 0, prop_of_total
    )) %>%
    tidyr::pivot_wider(
      names_from    = order_type
      , values_from = prop_of_total
      , values_fill = list(prop_of_total = 0)
    )

  # * Return ----
  return(user_item_tbl)

}

#' OPPE CPOE K-Means
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#' Takes the output of the [oppe_cpoe_user_item_tbl()] function and applies the
#' k-means algorithm to it using [stats::kmeans()]
#'
#' @details Uses the [stats::kmeans()] function and creates a wrapper around it.
#'
#' @param .data The data that gets passed from [oppe_cpoe_user_item_tbl()]
#' @param .centers How many initial centers to start with
#'
#' @examples
#' oppe_cpoe_query() %>%
#'   oppe_cpoe_tbl() %>%
#'   oppe_cpoe_user_item_tbl() %>%
#'   oppe_cpoe_kmeans()
#'
#' @return
#' A stats k-means object
#'
#' @export
#'

oppe_cpoe_kmeans <- function(.data, .centers = 5){

  # * Tidyeval Setup ----
  centers_var_expr <- .centers

  # * Checks ----
  if(!is.data.frame(.data)){
    stop(call. = FALSE("(.data) is missing. Please supply."))
  }

  # Default to 5
  if(is.null(centers_var_expr)){centers_var_expr = 5}

  # * Data ----
  data <- tibble::as_tibble(.data)

  # * k-means ----
  kmeans_tbl <- data %>%
    dplyr::select(-req_pty_cd)

  kmeans_obj <- kmeans_tbl %>%
    stats::kmeans(
      centers = centers_var_expr
      , nstart = 100
    )

  return(kmeans_obj)

}

#' K-Means tidy Functions
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description
#'  K-Means tidy functions
#'
#' @details
#' Takes in a k-means object and returns one of the items asked
#' for. Either the [broom::tidy()] [broom::glance()] or [broom::augment()]. The
#' function defaults to [broom::tidy()]
#'
#' @param .kmeans_obj A [stats::kmeans()] object
#' @param .tidy_type "tidy","glance", or "augment"
#'
#' @examples
#' oppe_cpoe_query() %>%
#'   oppe_cpoe_tbl() %>%
#'   oppe_cpoe_user_item_tbl() %>%
#'   oppe_cpoe_kmeans() %>%
#'   kmeans_tidy()
#'
#' @return
#' A tibble
#'
#' @export
#'

kmeans_tidy <- function(.kmeans_obj, .tidy_type = "tidy"){

  # * Tidyeval Setup ----
  kmeans_obj <- .kmeans_obj
  tidy_type  <- .tidy_type

  # * Checks ----
  if(!class(kmeans_obj) == "kmeans"){
    stop(call. = FALSE,"(.kmeans_obj) is not of class 'kmeans'")
  }

  if(!tidy_type %in% c("tidy","augment","glance")){
    stop(call. = FALSE,"(.tidy_type) must be either tidy, glance, or augment")
  }

  # * Manipulate ----
  if(tidy_type == "tidy"){
    km_tbl <- kmeans_obj %>% broom::tidy()
  } else if(tidy_type == "glance") {
    km_tbl <- kmeans_obj %>% broom::glance()
  } else if(tidy_type == "augment") {
    km_tbl <- kmeans_obj %>% broom::augment(
      oppe_cpoe_query() %>%
        oppe_cpoe_tbl() %>%
        oppe_cpoe_user_item_tbl()
    ) %>%
      dplyr::select(req_pty_cd, .cluster) %>%
      dplyr::rename("cluster" = .cluster)
  }

  # * Return ----
  return(km_tbl)

}

#' OPPE CPOE K-Means Mapper
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description Create a tibble that maps the [oppe_cpoe_kmeans()] using [purrr::map()
#' to create a nested data.frame/tibble that holds n centers. This tibble will be
#' used to help create a scree plot.
#'
#' @seealso
#' \url{https://en.wikipedia.org/wiki/Scree_plot}
#'
#' @details Takes in a single parameter of .centers. This is used to create the tibble
#' and map the [oppe_cpoe_kmeans()] function down the list creating a nested tibble.
#'
#' @param .centers How many different centers do you want to try
#' @param .data You must have a tibble in the working environment that is produced
#' by using the following work flow: oppe_cpoe_query() %>% oppe_cpoe_tbl() %>%
#' oppe_cpoe_user_item_tbl()
#'
#' @examples
#' ui_tbl <- oppe_cpoe_query() %>%
#'   oppe_cpoe_tbl() %>%
#'   oppe_cpoe_user_item_tbl()
#'
#' kmeans_mapped_tbl(ui_tbl)
#'
#' @return
#' A nested tibble
#'
#' @export
#'
kmeans_mapped_tbl <- function(.data, .centers = 15){

  # * Tidy ----
  centers_var_expr <- .centers

  # * Checks ----
  if(!is.data.frame(.data)){
    stop(call. = FALSE, "(.data) is not a data.frame/tibble. Please supply.")
  }

  input_data <- tibble::as_tibble(.data)

  km_mapper <- function(centers = 3){
    input_data %>%
      dplyr::select(-req_pty_cd) %>%
      stats::kmeans(
        centers = centers
        , nstart = 100
      )
  }

  # * Manipulate ----
  data_tbl <- tibble::tibble(centers = 1:centers_var_expr) %>%
    dplyr::mutate(k_means = centers %>%
                    purrr::map(km_mapper)
    ) %>%
    dplyr::mutate(glance = k_means %>%
                    purrr::map(broom::glance))

  # * Return ----
  return(data_tbl)

}

#' OPPE CPOE UMAP Projection
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description Create an umap object from the [uwot::umap()] function.
#'
#' @seealso
#' *  \url{https://cran.r-project.org/package=uwot} (CRAN)
#' *  \url{https://github.com/jlmelville/uwot} (GitHub)
#' *  \url{https://github.com/jlmelville/uwot} (arXiv paper)
#'
#' @details This takes in the user item table/matix that is produced by [oppe_cpoe_user_item_tbl()]
#' function. This function uses the defaults of [uwot::umap()]
#'
#' @param .data The data from the [oppe_cpoe_user_item_tbl()] function
#' @param .kmeans_map_tbl The data from the [kmeans_mapped_tbl()]
#' @param .k_cluster Pick the desired amount of clusters from your analysis of the scree plot
#'
#' @examples
#' ui_tbl <- oppe_cpoe_query() %>%
#'   oppe_cpoe_tbl() %>%
#'   oppe_cpoe_user_item_tbl()
#'
#' kmm_tbl <- kmeans_mapped_tbl(ui_tbl)
#'
#' oppe_cpoe_umap(.data = ui_tbl, kmm_tbl, 3)
#'
#' @return A list of tibbles and the umap object
#'
#' @export
#'
oppe_cpoe_umap <- function(.data
                          , .kmeans_map_tbl
                          , .k_cluster = 5){

  # * Tidyeval Setup ----
  k_cluster_var_expr <- .k_cluster

  # * Checks ----
  if(!is.data.frame(.data)){
    stop(call. = FALSE, "(.data) is not a data.frame/tibble. Please supply.")
  }

  if(!is.data.frame(.kmeans_map_tbl)){
    stop(call. = FALSE, "(.kmeans_map_tbl) is not a data.frame/tibble. Please supply.")
  }

  # * Data ----
  data           <- tibble::as_tibble(.data)
  kmeans_map_tbl <- tibble::as_tibble(.kmeans_map_tbl)

  # * Manipulation ----
  umap_obj <- data %>%
    dplyr::select(-req_pty_cd) %>%
    uwot::umap()

  umap_results_tbl <- umap_obj %>%
    tibble::as_tibble() %>%
    purrr::set_names("x","y") %>%
    dplyr::bind_cols(
      data %>% dplyr::select(req_pty_cd)
    )

  kmeans_obj <- kmeans_map_tbl %>%
    dplyr::pull(k_means) %>%
    purrr::pluck(k_cluster_var_expr)

  kmeans_cluster_tbl <- kmeans_obj %>%
    broom::augment(data) %>%
    dplyr::select(req_pty_cd, .cluster)

  umap_kmeans_cluster_results_tbl <- umap_results_tbl %>%
    dplyr::left_join(kmeans_cluster_tbl, by = c("req_pty_cd"="req_pty_cd"))

  # * Data List ----
  list_names <-
  df_list <- list(
    umap_obj                        = umap_obj,
    umap_results_tbl                = umap_results_tbl,
    kmeans_obj                      = kmeans_obj,
    kmeans_cluster_tbl              = kmeans_cluster_tbl,
    umap_kmeans_cluster_results_tbl = umap_kmeans_cluster_results_tbl
  )

  return(df_list)

}

#' OPPE CPOE Provider Order Trend Table
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description Gets the oppe cpoe order trend table for all providers
#'
#' @details Takes in the data from the [oppe_cpoe_query()] and [oppe_cpoe_tbl()]
#' functions.
#'
#' @param .data The data from the workflow of `oppe_cpoe_query() %>% oppe_cpoe_tbl()`
#'
#' @examples
#' oppe_cpoe_query() %>%
#'   oppe_cpoe_tbl() %>%
#'   oppe_cpoe_trend_tbl()
#'
#' @return A tibble
#'
#' @export
#'

oppe_cpoe_trend_tbl <- function(.data){

  # * Checks ----
  if(!is.data.frame(.data)){
    stop(call. = FALSE, "(.data) is not a data.frame/tibble. Please supply.")
  }

  # * Manipulate ----
  data <- tibble::as_tibble(.data)

  provider_oppe_cpoe_trend_tbl <- data %>%
    dplyr::select(req_pty_cd, spclty_desc, hospitalist_np_pa_flag,
                  written, verbal_order, telephone, cpoe) %>%
    tidyr::pivot_longer(
      written:cpoe
      , names_to  = "order_type"
      , values_to = "order_type_count"
    ) %>%
    dplyr::group_by(
      req_pty_cd
      , spclty_desc
      , hospitalist_np_pa_flag
      , order_type
    ) %>%
    dplyr::summarise(total_orders = sum(order_type_count, na.rm = TRUE)) %>%
    dplyr::ungroup() %>%
    # Normalization
    # Proportions
    dplyr::group_by(req_pty_cd) %>%
    dplyr::mutate(prop_of_total = total_orders / sum(total_orders)) %>%
    dplyr::ungroup()

  # * Return ----
  return(provider_oppe_cpoe_trend_tbl)

}

#' OPPE CPOE Cluster Trends Table
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description This function takes the data from the [oppe_cpoe_trend_tbl()] function
#' and creates from that data along with the umap_kmeans_cluster_results_tbl from the
#' [oppe_cpoe_umap()] function.
#'
#' @details Requires data from the [oppe_cpoe_trend_tbl()] and [oppe_cpoe_umap()]
#' functions. This data is later used to show how a particular provider stacks up
#' against others in the same cluster.
#'
#' @param .data The data that needs to be passed to the function from the [oppe_cpoe_trend_tbl()]
#' function
#' @param .umap_data The umap_kmeans_cluster_results_tbl from the [oppe_cpoe_umap()]
#' function
#' @param ... Any extra columns you want passed to the function. By default the following
#' are selected:
#'   * .cluster
#'   * order_type
#'
#' You can choose the from the following as extra:
#'   * hospitalist_np_pa_flag
#'   * spclty_desc
#'
#' @examples
#' q <- oppe_cpoe_query() %>%
#'   oppe_cpoe_tbl()
#'
#' trend_tbl <- q %>%
#'   oppe_cpoe_trend_tbl()
#'
#' ui_tbl <- q %>%
#'   oppe_cpoe_user_item_tbl()
#'
#' kmm_tbl <- ui_tbl %>%
#'   kmeans_mapped_tbl()
#'
#' umap_obj <- oppe_cpoe_umap(ui_tbl, kmm_tbl, 3)
#'
#' oppe_cpoe_cluster_trends_tbl(trend_tbl, umap_obj)
#' oppe_cpoe_cluster_trends_tbl(trend_tbl, umap_obj, hospitalist_np_pa_flag)
#'
#' @return A tibble
#'
#' @export
#'

oppe_cpoe_cluster_trends_tbl <- function(.data, .umap_data
                                         , ...){

  # * Tidyeval Setup ----
  extra_var_expr <- rlang::quos(...)

  # * Checks ----
  umap_obj  <- umap_obj
  trend_tbl <- tibble::as_tibble(trend_tbl)
  ukcrt_tbl <- tibble::as_tibble(umap_obj$umap_kmeans_cluster_results_tbl)

  if(class(umap_obj) != "list"){
    stop(call. = FALSE, "(.umap_data) is not in list form. You must use the oppe_cpoe_umap() function to create.")
  }

  if(!is.data.frame(ukcrt_tbl)){
    stop(call. = FALSE, "Please supply umap_kmeans_cluster_results_tbl")
  }

  # * Manipulate ----
  cluster_trends_tbl <- trend_tbl %>%
    dplyr::left_join(ukcrt_tbl) %>%
    dplyr::select(.cluster, order_type, total_orders, ...) %>%
    dplyr::group_by(.cluster, order_type, ...) %>%
    dplyr::summarise(total_orders = sum(total_orders, na.rm = TRUE)) %>%
    dplyr::ungroup() %>%
    # Calculate proportion of total
    dplyr::group_by(.cluster) %>%
    dplyr::mutate(prop_of_total = total_orders / sum(total_orders, na.rm = TRUE)) %>%
    dplyr::ungroup()

  # * Return ----
  return(cluster_trends_tbl)

}
