#' OPPE ALOS Plots
#' @author Steven P. Sanderson II, MPH
#'
#' @description Get plots for a single providers length of stay data.
#'
#' @details Takes data in from the [oppe_alos_tbl()] function.
#'
#' @param .data The data that you would pass from [oppe_alos_tbl()]
#' @param .date_col The column holding the date value
#' @param .by_time How you want the data time aggregated, the default is __"month"__
#'
#' @examples
#' oppe_alos_query() %>%
#'   oppe_alos_tbl(.provider_id = "017236") %>%
#'   oppe_alos_plt(.date_col = dsch_date)
#'
#' @return
#' A patchwork time series plot
#'
#' @export
#'
oppe_alos_plt <- function(.data, .date_col, .by_time = "month"){

  requireNamespace(package = "patchwork")

  # * Tidyeval Setup ----
  by_time_var_expr     <- .by_time
  interactive_var_expr <- FALSE
  date_var_expr        <- rlang::enquo(.date_col)

  # * Checks ----
  if(!is.data.frame(.data)){
    stop(call. = FALSE, "(.data) is not a data.frame/tibble. Please supply.")
  }

  if(rlang::quo_is_missing(date_var_expr)){
    stop(call. = FALSE, "(.date_col) is missing. Please supply.")
  }

  # * Data ----
  data_tbl <- tibble::as_tibble(.data)
  provider <- base::unique(data_tbl$pract_rpt_name)

  # Check how many providers are in list
  if(base::length(base::unique(data_tbl$pract_rpt_name)) > 1){
    stop(call. = FALSE, "There is more than one provider name in the data.
         Please choose one and then run this function")
  }

  # * Manipulate ----
  data_tbl <- data_tbl %>%
    timetk::summarise_by_time(
      .date_var      = {{ date_var_expr }}
      , .by          = by_time_var_expr
      , alos         = mean(los, na.rm = TRUE)
      , elos         = mean(elos, na.rm = TRUE)
      , mean_var     = mean(excess, na.rm = TRUE)
      , mean_soi     = mean(as.numeric(severity_of_illness), na.rm = TRUE)
      , mean_cmi     = mean(drg_cost_weight, na.rm = TRUE)
      , mean_z_score = mean(z_score, na.rm = TRUE)
      , visit_count  = dplyr::n()
    ) %>%
    dplyr::rename(date_col = dsch_date)

  los_tbl <- data_tbl %>%
    dplyr::select(date_col, alos, elos) %>%
    tidyr::pivot_longer(alos:elos)

  aelos_plt <- timetk::plot_time_series(
    .data          = los_tbl
    , .date_var    = date_col
    , .value       = value
    , .color_var   = name
    , .title       = provider
    , .interactive = FALSE
    , .smooth      = FALSE
    , .legend_show = FALSE
  ) +
    ggplot2::labs(
      subtitle = "Red is ELOS, Blue is ALOS"
    )

  visit_plt <- data_tbl %>%
    dplyr::select(date_col, visit_count) %>%
    ggplot2::ggplot(
      mapping = ggplot2::aes(
        x = date_col
        , y = visit_count
        )
      ) +
    ggplot2::geom_col(fill = "#2C3E50") +
    tidyquant::theme_tq() +
    ggplot2::labs(
      x = ""
      , y = ""
      , title = "Discharge Count"
    )

  los_z_plt <- data_tbl %>%
    healthyR.ts::ts_qc_run_chart(
      .date_col    = date_col
      , .value_col = mean_z_score
      , .llcl      = TRUE
      , .lc        = TRUE
      , .lmcl      = TRUE
    ) +
    ggplot2::labs(
      title = "Mean ALOS Z-Score"
      , x = ""
      , y = ""
    ) +
    tidyquant::theme_tq()

  # SOI/CMI
  soi_cmi_tbl <- data_tbl %>%
    dplyr::select(date_col, mean_soi, mean_cmi) %>%
    tidyr::pivot_longer(-date_col)

  cmi_soi_plt <- timetk::plot_time_series(
    .data = soi_cmi_tbl
    , .date_var      = date_col
    , .value         = value
    , .color_var     = name
    , .title         = "CMI/SOI Trend"
    , .interactive   = FALSE
    , .smooth        = TRUE
    , .smooth_size   = .5
    , .smooth_degree = 0
    , .legend_show   = FALSE
  ) +
    ggplot2::labs(
      subtitle = "Red is CMI, Blue is SOI"
    )

  # * Return ----
  (aelos_plt + visit_plt) / (los_z_plt + cmi_soi_plt)

}

#' OPPE CPOE K-Means Scree Plot
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description Create a scree-plot from the [kmeans_mapped_tbl()] function.
#'
#' @details Outputs a scree-plot
#'
#' @seealso
#' \url{https://en.wikipedia.org/wiki/Scree_plot}
#'
#' @param .data The data from the [kmeans_mapped_tbl()] function
#'
#' @examples
#' df <- oppe_cpoe_query() %>%
#'         oppe_cpoe_tbl() %>%
#'         oppe_cpoe_user_item_tbl()
#'
#' kmeans_nested_tbl <- kmeans_mapped_tbl(.data = df)
#'
#' kmeans_scree_plt(.data = kmeans_nested_tbl)
#'
#' @return
#' A ggplot2 plot
#'
#' @export
#'

kmeans_scree_plt <- function(.data){

  # * Checks ----
  if(!is.data.frame(.data)){
    stop(call. = FALSE,"(.data) is not a data.frame/tibble. Please supply.")
  }

  # * Manipulate ----
  data_tbl <- tibble::as_tibble(.data)

  data_tbl <- data_tbl %>%
    tidyr::unnest(glance) %>%
    dplyr::select(centers, tot.withinss)

  # * Plot
  p <- data_tbl %>%
    ggplot2::ggplot(
      mapping = ggplot2::aes(
        x   = centers
        , y = tot.withinss
        )
    ) +
    ggplot2::geom_point() +
    ggplot2::geom_line() +
    ggrepel::geom_label_repel(mapping = aes(label = centers)) +
    tidyquant::theme_tq() +
    ggplot2::labs(
      title      = "Scree Plot"
      , subtitle = "Measures the distance each of the providers are from the closest k-means cluster"
      , y        = "Total Withing Sum of Squares"
      , x        = "Centers"
    )

  # * Return ----
  return(p)
}

#' OPPE CPOE K-Means UMAP Projection Plot
#'
#' @author Steven P. Sanderson II, MPH
#'
#' @description Using the `uwot` library we visualize the UMAP: Uniform Manifold
#' Approximation and Projection for Dimension Reduction. \url{https://arxiv.org/abs/1802.03426}
#'
#' UMAP (Uniform Manifold Approximation and Projection) is a novel manifold
#' learning technique for dimension reduction. UMAP is constructed from a
#' theoretical framework based in Riemannian geometry and algebraic topology.
#' The result is a practical scalable algorithm that applies to real world data.
#' The UMAP algorithm is competitive with t-SNE for visualization quality, and
#' arguably preserves more of the global structure with superior run time
#' performance. Furthermore, UMAP has no computational restrictions on embedding
#'  dimension, making it viable as a general purpose dimension reduction technique for machine learning.
#'
#' @details Requires the user item table/matrix that is output from the [oppe_cpoe_user_item_tbl()]
#' function.
#'
#' @param .data Takes data from the [oppe_cpoe_umap()] function. You simply pass
#' in the list object and it will automatically take the cluster results tibble
#' @param .point_size The size of the `ggplot2::geom_point()` size.
#'
#' @examples
#' ui_tbl <- oppe_cpoe_query() %>%
#'   oppe_cpoe_tbl() %>%
#'   oppe_cpoe_user_item_tbl()
#'
#' km_map_tbl <- kmeans_mapped_tbl(ui_tbl)
#' kmeans_scree_plt(km_map_tbl)
#'
#' umap_obj <- oppe_cpoe_umap(ui_tbl, km_map_tbl, 3)
#'
#' oppe_cpoe_umap_plt(umap_obj)
#'
#' @export
#'

oppe_cpoe_umap_plt <- function(.data, .point_size = 2){

  data_list <- .data
  point_size <- .point_size

  # * Checks ----
  # Make sure a list
  if(class(data_list) != "list"){
    stop(call. = FALSE, "(.data) must be a list from oppe_cpoe_umap() function")
  }

  # Make sure kmeans object is in position [[3]] of list
  if(class(data_list[[3]]) != "kmeans"){
    stop(call. = FALSE, "(.data) must be a list from oppe_cpoe_umap() function. It looks like the kmeans obj is mising.")
  }

  # * Manipulate ----
  data <- tibble::as_tibble(data_list[[5]])

  p <- data %>%
    ggplot2::ggplot(
      mapping = ggplot2::aes(
        x = x
        , y = y
        , color = .cluster
      )
    ) +
    ggplot2::geom_point(size = point_size) +
    tidyquant::theme_tq() +
    tidyquant::scale_color_tq() +
    ggplot2::labs(
      title = "Provider Segmentation: 2D Projection UMAP"
      , subtitle = "UMAP 2D Projection with K-Means Cluster Assignment"
    )

  # * Return ----
  return(p)

}
