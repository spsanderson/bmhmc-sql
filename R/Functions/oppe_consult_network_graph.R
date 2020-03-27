oppe_consult_network_graph <- function(provider_id
                                       , min_weight
) {
    
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
        , "odbc"
        , "dbplyr"
        , "DBI"
        , "patchwork"
    )
    
    # DB Connection ----
    db_con <- dbConnect(
        odbc(),
        Driver = "SQL Server",
        Server = "BMH-HIDB",
        Database = "SMSPHDSSS0X0",
        Trusted_Connection = T
    )
    
    # Testing ----
    # provider_id = "012740"
    # year = 2019
    # min_weight = 3
    
    # Data ----
    consult_network_tbl <- dbGetQuery(
        conn = db_con
        , paste0(
            "
            DECLARE @TODAY DATETIME;
            DECLARE @START DATETIME;
            DECLARE @END   DATETIME;
            
            SET @TODAY = GETDATE();
            SET @START = DATEADD(MONTH, DATEDIFF(MONTH, 0, @TODAY) -18, 0)
            SET @END   = DATEADD(MONTH, DATEDIFF(MONTH, 0, @TODAY), 0) 
            
            SELECT [Source]
            , [Target]
            , Attending_ID
            , Attending
            , Hospitalist_Private
            , Ordering_Provider_ID
            , ent_dtime
            , episode_no
            , [Record_Flag] = 1
            FROM SMSDSS.c_ordered_consult_network_v
            WHERE Attending_ID = '", provider_id ,"'
            AND ent_dtime >= @START
            AND ent_dtime < @END
            "
        )
    )
    
    if(!nrow(consult_network_tbl) >= 10){
        return(NA)
    } else {
        attending_md <- dbGetQuery(
            conn = db_con
            , paste0(
                "
                SELECT HSTAFF.STAFFSIGNATURE
                FROM [SC_server].[Soarian_Clin_Prd_1].DBO.HSTAFF AS HSTAFF
                WHERE HSTAFF.MSINUMBER = '", provider_id, "'
                "
            )
        ) %>%
            pull()
        
        # DB Disconnect ----
        dbDisconnect(db_con)
        
        # Edge List ----
        edge_list <- consult_network_tbl %>%
            select(Source, Target) %>%
            as_tibble() %>%
            set_names("from","to")
        #edge_list
        
        # Source List ----
        sources <- consult_network_tbl %>%
            distinct(Source) %>%
            rename(label = Source)
        
        # Target List ----
        targets <- consult_network_tbl %>%
            distinct(Target) %>%
            rename(label = Target)
        
        # Nodes ----
        nodes <- full_join(
            sources
            , targets
            , by = "label"
        ) %>%
            rowid_to_column("id")
        #nodes
        
        # Network ----
        consults <- nodes %>%
            left_join(
                consult_network_tbl %>%
                    select(
                        Source
                        , Target
                        , Record_Flag
                    )
                , by = c("label" = "Source")
            ) %>% 
            # Consult Count by Source to Target
            group_by(
                label, Target
            ) %>%
            summarise(
                weight = sum(Record_Flag, na.rm = TRUE)
            ) %>%
            ungroup() %>%
            filter(!is.na(Target))
        #consults
        
        edges <- consults %>%
            left_join(nodes, by = c("label" = "label")) %>%
            # Rename the from column in Nodes to id
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
                , weight
            ) 
        
        consult_network <- network(
                edges
                , vertex.attr = nodes
                , matrix.type = "edgelist"
                , ignore.eval = FALSE
            )
        
        # Convert to igraph obj
        consult_igraph <- graph_from_data_frame(
            d = edges
            , vertices = nodes
            , directed = TRUE
        )
        
        # convert to tidygraph obj
        consult_igraph_tidy <- as_tbl_graph(consult_igraph)
        
        # Viz ----
        graph_obj <- consult_igraph_tidy %>% 
            mutate(deg = degree(consult_igraph_tidy)) %>%
            activate(edges) %>%
            filter(weight >= min_weight) %>%
            activate(nodes) %>%
            filter(!node_is_isolated()) %>%
            mutate(friends = case_when(
                deg < 15 ~ "few"
                , deg < 25 ~ "medium"
                , TRUE ~ "most"
            )) %>%
            mutate(friends = as_factor(friends)) %>%
            mutate(group = group_walktrap())
        
        layout <- create_layout(
            graph_obj
            , layout = 'igraph'
            , algorithm = 'fr'
        )
        
        graph_plt <- graph_obj %>%
            ggraph(layout = "fr") +
            geom_edge_link(
                aes(
                    alpha = 0.618
                )
            ) +
            geom_node_point(
                aes(
                    size = deg
                    , color = friends
                )
            ) +
            geom_node_label(
                aes(
                    filter = (label == attending_md)
                    , label = label
                )
                    , repel = TRUE
            ) +
            tidyquant::scale_color_tq() +
            theme_graph() +
            theme(
                legend.position = "none"
            ) +
            labs(
                x = ""
                , y = ""
                , title = paste0(
                    "Consult Network for: "
                    , attending_md
                )
                , subtitle = paste0(
                    "Minimum Consults from Source to Target: "
                    , min_weight
                )
                , caption = "Consults may have been placed by someone other than the Attending"
            )
        
        print(graph_plt)
        
        # Ordering Trends ----
        # Non Attending
        non_atn_plt <- consult_network_tbl %>% 
            filter(Ordering_Provider_ID != Attending_ID) %>% 
            group_by(Source) %>%
            summarise(consult_count = sum(Record_Flag)) %>%
            ungroup() %>%
            mutate(Source = Source %>% fct_reorder(consult_count)) %>%
            mutate(lbl_txt = str_glue("Consults Ordered: {consult_count}")) %>%
            dplyr::top_n(n = 10) %>%
            ggplot(
                mapping = aes(
                    x = consult_count
                    , y = Source
                )
            ) +
            geom_segment(
                mapping = aes(
                    xend = 0
                    , yend = Source
                )
            ) +
            geom_point() +
            geom_label(
                mapping = aes(
                    label = lbl_txt
                )
                , hjust = "inward"
                , size = 3
            ) +
            tidyquant::theme_tq() +
            tidyquant::scale_color_tq() +
            labs(
                x = ""
                , y = ""
                , title = "Consults Ordered by Provider - Top 10"
                , subtitle = paste0("Provider is not Attending\nMore Rows will be shown if there are ties")
            )
        
        # Attending vs Non %
        atn_nonatn_perc_plt <- consult_network_tbl %>%
            as_tibble() %>%
            mutate(
                ord_flag_txt = case_when(
                    Ordering_Provider_ID == Attending_ID ~ "Attending"
                    , TRUE ~ "Non-Attending"
                )
                , ord_flag = 1
            ) %>%
            group_by(ord_flag_txt) %>%
            summarise(
                ord_count = sum(ord_flag, na.rm = TRUE)
            ) %>%
            ungroup() %>%
            mutate(
                ord_flag_txt = ord_flag_txt %>%
                    fct_reorder(ord_count)
            ) %>%
            mutate(
                ord_perc = ord_count / sum(ord_count, na.rm = TRUE)
                , ord_perc_txt = ord_perc %>% scales::percent(accuracy = 0.01)
            ) %>%
            mutate(
                lbl_txt = str_glue("Order Percentage: {ord_perc_txt}")
            ) %>%
            ggplot(
                mapping = aes(
                    x = ord_perc
                    , y = ord_flag_txt
                )
            ) +
            geom_segment(
                aes(
                    xend = 0
                    , yend = ord_flag_txt
                )
            ) +
            geom_point() +
            geom_label(
                mapping = aes(
                    label = lbl_txt
                )
                , hjust = "inward"
                , size = 3
            ) +
            tidyquant::theme_tq() +
            tidyquant::scale_fill_tq() +
            scale_x_continuous(labels = scales::percent) +
            labs(
                x = ""
                , y = ""
                , title = "Consult Order Percentage by Attending vs. Non-Attending"
            )
        
        print(non_atn_plt)
        print(atn_nonatn_perc_plt)
        
        # Vis network ----
        # vis_net_obj <- visNetwork(nodes, edges)
        # vis_plt <- vis_net_obj %>%
        #     visConfigure(
        #         filter = vis_net_obj$x$edges$weight >= 5
        #     ) %>%
        #     visNodes(size = 10) %>%
        #     visIgraphLayout(layout = "layout_with_fr") %>%
        #     visEdges(arrows = "to") %>%
        #     visOptions(
        #         highlightNearest = list(
        #             enabled = T
        #             , hover = T
        #         )
        #         , nodesIdSelection = T
        #     )
        # 
        # return(vis_plt)
    }
}
