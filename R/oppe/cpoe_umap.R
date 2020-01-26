# Lib Load ----
if(!require(pacman)) install.packages("pacman")

pacman::p_load(
    "tidyverse"
    , "DBI"
    , "odbc"
    , "dbplyr"
    , "broom"
    , "umap"
    , "ggrepel"
    , "tidyquant"
    , "patchwork"
)

# Source functions
source("S:\\Global Finance\\1 REVENUE CYCLE\\Steve Sanderson II\\Code\\R\\Functions\\clean_names.R")

# DB Connection ----
db_con <- dbConnect(
    odbc(),
    Driver = "SQL Server",
    Server = "BMH-HIDB",
    Database = "SMSPHDSSS0X0",
    Trusted_Connection = T
)

# Get Data ----
query <- dbGetQuery(
    conn = db_con
    , paste0(
        "
        SELECT *
        FROM SMSDSS.c_CPOE_Rpt_Tbl_Rollup_v
        WHERE req_pty_cd != '000000'
        AND req_pty_cd != '000059'
        AND ent_date >= DATEADD(MONTH, DATEDIFF(MONTH, 0, CAST(GETDATE() AS DATE)) - 19, 0)
        AND ent_date <  DATEADD(MONTH, DATEDIFF(MONTH, 0, CAST(GETDATE() AS DATE)), 0)
        "
    )
)

query <- query %>% 
    clean_names()

# DB Disconnect ----
dbDisconnect(db_con)

# Agg / Normalize ----
provider_trend_tbl <- query %>%
    select(
        req_pty_cd
        , spclty_desc
        , hospitalist_np_pa_flag
        #, per_rt_protocol
        #, communication
        #, specimen_redraw
        , written
        , verbal_order
        #, unknown
        , telephone
        #, nursing_order
        , cpoe
    ) %>%
    pivot_longer(
        cols = c(
            # per_rt_protocol
            # , communication
            # , specimen_collect
            # , specimen_redraw
             written
            , verbal_order
            #, unknown
            , telephone
            #, nursing_order
            , cpoe
        )
        , names_to = "order_type"
        , values_to = "order_type_count"
    ) %>%
    group_by(
        req_pty_cd
        , spclty_desc
        , hospitalist_np_pa_flag
        , order_type
    ) %>%
    summarise(
        total_orders = sum(
            order_type_count
            , na.rm = TRUE
        )
    ) %>%
    ungroup() %>%
    # Normalization ----
    # Proportions
    group_by(req_pty_cd) %>%
    mutate(
        prop_of_total = total_orders / sum(total_orders)
    ) %>%
    ungroup()

# User-Item format ----
provider_order_type_tbl <- provider_trend_tbl %>%
    select(req_pty_cd, order_type, prop_of_total) %>%
    mutate(prop_of_total = ifelse(is.na(prop_of_total), 0, prop_of_total)) %>%
    pivot_wider(
        names_from = order_type
        , values_from = prop_of_total
        , values_fill = list(prop_of_total = 0)
    )

provider_order_type_tbl

# Model k-means ----
kmeans_obj <- provider_order_type_tbl %>%
    select(-req_pty_cd) %>%
    kmeans(
        centers = 5
        , nstart = 100
    )

kmeans_obj %>% tidy() %>% glimpse()
kmeans_obj %>% glance() %>% glimpse()
kmeans_obj %>% augment(provider_order_type_tbl) %>% select(req_pty_cd, .cluster)

# Optimal Centers ----
# Make function
kmeans_mapper <- function(centers = 5) {
    
    # Body
    provider_order_type_tbl %>%
        select(-req_pty_cd) %>%
        kmeans(
            centers = centers
            , nstart = 100
        )
}
# See if function works
kmeans_mapper(centers = 3)

# Map func to many ----
kmeans_mapped_tbl <- tibble(centers = 1:15) %>%
    mutate(k_means = centers %>% map(kmeans_mapper)) %>%
    mutate(glance = k_means %>% map(glance))

kmeans_mapped_tbl %>%
    unnest(glance) %>%
    select(centers, tot.withinss) %>%
    ggplot(
        mapping = aes(
            x = centers
            , y = tot.withinss
        )
    ) +
    geom_point() +
    geom_line() +
    geom_label_repel(mapping = aes(label = centers)) +
    theme_tq() +
    labs(
        title = "Skree Plot"
        , subtitle = "Measures the distance each of the providers are from the closest k-means cluster"
        , y = "Total Within Sum of Squares"
        , x = "Centers"
    )

# Best centers
optimal_k <- kmeans_mapped_tbl %>%
    unnest(glance) %>%
    select(centers, tot.withinss) %>%
    mutate(
        x = centers
        , y = tot.withinss
    ) %>%
    mutate(
        x2 = c(centers[-1], NA_real_)
        , y2 = c(tot.withinss[-1], NA_real_)
    ) %>%
    select(
        centers
        , tot.withinss
        , x
        , x2
        , y
        , y2
        , everything()
    ) %>%
    mutate(
        m = abs((y2 - y) / (x2 - x))
    ) %>%
    mutate(m_lag_1 = c(m[-2], NA_real_)) %>%
    filter(!is.na(x2), !is.na(y2), !is.na(m_lag_1)) %>%
    mutate(m_perc = m / m_lag_1) %>%
    mutate(
        decrease_flag = case_when(
            lag(m, n = 1) + 1 > m ~ 1
            , TRUE ~ 0
        )
    ) %>%
    filter(centers > 2) %>%
    filter(m_perc <= 1 ) %>%
    slice(1) %>%
    select(centers) %>%
    pull()

optimal_k

# Viz UMAP ----
# use umap() to get 2d projection
umap_obj <- provider_order_type_tbl %>%
    select(-req_pty_cd) %>%
    umap()

umap_results_tbl <- umap_obj$layout %>%
    as_tibble() %>%
    set_names("x","y") %>%
    bind_cols(
        provider_order_type_tbl %>% select(req_pty_cd)
    )

# umap_results_tbl %>%
#     ggplot(
#         mapping = aes(
#             x = x
#             , y = y
#         )
#     ) +
#     geom_point() +
#     theme_tq()

# Use K-means cluster restults
umap_results_tbl
kmeans_obj <- kmeans_mapped_tbl %>%
    pull(k_means) %>%
    # skree showd 5 clusters
    pluck(optimal_k)

kmeans_clusters_tbl <- kmeans_obj %>% 
    augment(provider_order_type_tbl) %>% 
    select(req_pty_cd, .cluster)

umap_kmeans_cluster_results_tbl <- umap_results_tbl %>%
    left_join(kmeans_clusters_tbl, by = c("req_pty_cd" = "req_pty_cd"))

# Viz umap projection with cluster assignments
umap_plt <- .


# Analyze Trends ----
cluster_trends_tbl <- provider_trend_tbl %>%
    # Join cluster assignment by provider
    left_join(umap_kmeans_cluster_results_tbl) %>%
    select(.cluster, order_type, total_orders) %>%
    group_by(.cluster, order_type) %>%
    #or group_by_at(.vars = vars(.cluster:order_type))
    summarise(total_orders = sum(total_orders, na.rm = TRUE)) %>%
    ungroup() %>%
    # Calculate prop of total
    group_by(.cluster) %>%
    mutate(prop_of_total = total_orders / sum(total_orders, na.rm = TRUE)) %>%
    ungroup()

# Cluster 1
cluster_trends_tbl %>%
    filter(.cluster == 1) %>%
    arrange(desc(prop_of_total)) %>%
    mutate(cum_prop = cumsum(prop_of_total))


get_cluster_trends <- function(cluster = 1) {
 
    cluster_trends_tbl %>%
        filter(.cluster == cluster) %>%
        arrange(desc(prop_of_total)) %>%
        mutate(cum_prop = cumsum(prop_of_total))
       
}
get_cluster_trends(3)

# Update viz ----
provider_id <- "019554"
provider_cluster <- umap_kmeans_cluster_results_tbl %>%
    filter(req_pty_cd == provider_id) %>%
    select(.cluster) %>%
    pull()

cluster_trend_plt <- get_cluster_trends(provider_cluster) %>%
    mutate(order_type = order_type %>% as_factor()) %>%
    mutate(order_type_num = order_type %>% as.numeric()) %>%
    ggplot(
        mapping = aes(
            x = order_type
            , y = prop_of_total
            , group = order_type
        )
    ) +
    geom_col(color = "black") +
    geom_label_repel(
        mapping = aes(
            label = scales::percent(prop_of_total, accuracy = 0.01)
        )
        , size = 3
    ) +
    theme_tq() +
    scale_fill_tq() +
    labs(
        x = ""
        , y = "Proportion of Total Orders"
        , title = "Proportion of Total Orders by Order Type Cluster Trend"
        , subtitle = paste0(
            "Provider ID: "
            , provider_id
            , " is in Cluster: "
            , provider_cluster
            , " these are the trends for that cluster"
        )
    ) +
    theme(
        legend.position = "none"
        , axis.text.x = element_text(angle = 45, hjust = 1)
    )

provider_trend_plt <- provider_trend_tbl %>%
    filter(req_pty_cd == provider_id) %>%
    arrange(desc(prop_of_total)) %>%
    mutate(order_type = order_type %>% as_factor()) %>%
    mutate(order_type_num = order_type %>% as.numeric()) %>% 
    ggplot(
        mapping = aes(
            x = order_type
            , y = prop_of_total
            , group = order_type
        )
    )  +
    geom_col(color = "black") +
    geom_label_repel(
        mapping = aes(
            label = scales::percent(prop_of_total, accuracy = 0.01)
        )
        , size = 3
    ) +
    theme_tq() +
    scale_fill_tq() +
    labs(
        x = ""
        , y = "Proportion of Total Orders"
        , title = "Proportion of Order Types Provider Trend"
        , subtitle = paste0(
            "Provider ID: "
            , provider_id
            , " is in Cluster: "
            , provider_cluster
            , " These are the trends for this provider"
        )
    ) +
    theme(
        legend.position = "none"
        , axis.text.x = element_text(angle = 45, hjust = 1)
    )

# Patchwork Viz ----
umap_plt + (cluster_trend_plt / provider_trend_plt)
