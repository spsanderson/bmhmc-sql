# Lib Load ----
if(!require(pacman)) install.packages("pacman")

pacman::p_load(
    "igraph"
    , "ggraph"
    , "tidyverse"
    , "tidygraph"
    , "network"
    , "readxl"
    , "visNetwork"
)

# Data ----
consult_network_test <- read_excel(
    "C:/Users/bha485/Desktop/consult_network_test.xlsx"
    , col_types = c(
        "text"
        , "text"
        , "text"
        , "text"
        , "text"
        , "text"
        , "date"
        , "text"
        , "numeric"
        , "numeric"
        , "numeric"
        )
    )

edge_list <- consult_network_test %>%
    select(Source, Target) %>%
    as_tibble() %>%
    set_names("from","to")
edge_list

sources <- consult_network_test %>%
    distinct(Source) %>%
    rename(label = Source)

targets <- consult_network_test %>%
    distinct(Target) %>%
    rename(label = Target)

nodes <- full_join(
    sources
    , targets
    , by = "label"
    ) %>%
    rowid_to_column("id")
nodes

consults <- nodes %>%
    left_join(
        consult_network_test %>%
            select(Source, Target, Consult_Out_Count, Consult_In_Count, Source_to_Target_Count)
        , by = c("label" = "Source")
    ) %>% 
    group_by(
        label, Target
    ) %>%
    summarise(
        Consult_Out_Count = sum(Consult_Out_Count, na.rm = TRUE)
        , Consult_In_Count = sum(Consult_In_Count, na.rm = TRUE)
        , Source_to_Target_Count = sum(Source_to_Target_Count, na.rm = TRUE)
    ) %>%
    ungroup() %>%
    filter(!is.na(Target))
consults

edges <- consults %>%
    left_join(nodes, by = c("label" = "label")) %>%
    rename(from = id)

edges <- edges %>%
    left_join(
        nodes
        , by = c("Target" = "label")
    ) %>%
    rename(to = id)

edges <- edges %>%
    select(
        from
        , to
        , Consult_Out_Count
        , Consult_In_Count
        , Source_to_Target_Count
    ) 

consult_network <- network(
    edges
    , vertex.attr = nodes
    , matrix.type = "edgelist"
    , ignore.eval = FALSE
)

consult_igraph <- graph_from_data_frame(
    d = edges
    , vertices = nodes
    , directed = TRUE
    )

consult_igraph_tidy <- as_tbl_graph(consult_igraph)

attending <- consult_igraph_tidy %>%
    activate(nodes) %>%
    filter(label == "") %>%
    mutate(color = "purple") %>%
    as_tibble()
    
consult_igraph_tidy %>% 
    mutate(deg = degree(consult_igraph_tidy)) %>%
    activate(edges) %>%
    filter(Source_to_Target_Count >= 3) %>%
    activate(nodes) %>%
    filter(!node_is_isolated()) %>%
    mutate(friends = case_when(
        deg < 15 ~ "few"
        , deg < 25 ~ "medium"
        , TRUE ~ "most"
    )) %>%
    mutate(group = node_coreness(mode = "all")) %>%
    ggraph(layout = "fr") +
    geom_edge_link(
        aes(
            alpha = .618
        )
    ) +
    geom_node_point(
        aes(
            size = deg
            , color = factor(friends)
        )
    ) +
    # geom_node_point(
    #     data = attending
    #     , mapping = aes(
    #             x = name
    #             , y = 
    #         )
    #         , color = "purple"
    # ) +
    tidyquant::theme_tq() +
    tidyquant::scale_color_tq() +
    theme(
        legend.position = "none"
    ) +
    labs(
        x = ""
        , y = ""
        , title = "Consult Network by Attending Provider"
        , subtitle = "This is a network graph of consults ordered by a provider for a specified Attending"
    )

# Vis network
vis_net_obj <- visNetwork(nodes, edges)
vis_net_obj %>%
    visConfigure(
        filter = vis_net_obj$x$edges$Source_to_Target_Count >= 5
    ) %>%
    visNodes(size = 10) %>%
    visIgraphLayout(layout = "layout_with_fr") %>%
    visEdges(arrows = "to") %>%
    visOptions(
        highlightNearest = list(
            enabled = T
            , hover = T
            )
        , nodesIdSelection = T
    )

