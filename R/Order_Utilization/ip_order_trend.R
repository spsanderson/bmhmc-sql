# Lib Load ----
if(!require(pacman)) install.packages("pacman")
pacman::p_load(
    "tidyverse"
    ,"tidyquant"
    ,"DBI"
    ,"odbc"
    ,"janitor"
    ,"tsibble"
    ,"dtplyr"
    ,"data.table"
)

# DB Connection ----
db_con <- dbConnect(
    odbc(),
    Driver = "SQL Server",
    Server = "BMH-HIDB",
    Database = "SMSPHDSSS0X0",
    Trusted_Connection = T
)

# Data ----
ip_rad_tbl <- dbGetQuery(
    conn = db_con
    , statement = paste0(
        "
        SELECT A.Encounter
        , COUNT(B.ENCOUNTER) AS IP_RAD_ORDER_COUNT
        
        FROM smsdss.c_elos_bench_data AS A
        LEFT JOIN smsdss.c_LabRad_OrdUtil_by_DschDT AS B
        ON A.Encounter = B.Encounter
        
        WHERE B.ED_IP_FLAG = 'IP'
        AND B.Svc_Dept_Desc = 'RADIOLOGY'
        AND LEFT(A.ENCOUNTER, 1) IN ('1', '8')
        
        GROUP BY A.Encounter
        , B.Encounter
        "
    )
) %>% 
    as_tibble() %>%
    clean_names()

ip_lab_tbl <- dbGetQuery(
    conn = db_con
    , statement = paste0(
        "
        SELECT A.Encounter
        , COUNT(B.ENCOUNTER) AS IP_LAB_ORDER_COUNT
        
        FROM smsdss.c_elos_bench_data AS A
        LEFT JOIN smsdss.c_LabRad_OrdUtil_by_DschDT AS B
        ON A.Encounter = B.Encounter
        
        WHERE B.ED_IP_FLAG = 'IP'
        AND B.Svc_Dept_Desc = 'LABORATORY'
        AND LEFT(A.ENCOUNTER, 1) IN ('1', '8')
        
        GROUP BY A.Encounter
        , B.Encounter
        "
    )
) %>% 
    as_tibble() %>%
    clean_names()

ed_rad_tbl <- dbGetQuery(
    conn = db_con
    , statement = paste0(
        "
        SELECT A.Encounter
        , COUNT(B.ENCOUNTER) AS ED_RAD_ORDER_COUNT
        
        FROM smsdss.c_elos_bench_data AS A
        LEFT JOIN smsdss.c_LabRad_OrdUtil_by_DschDT AS B
        ON A.Encounter = B.Encounter
        
        WHERE B.ED_IP_FLAG = 'ED'
        AND B.Svc_Dept_Desc = 'RADIOLOGY'
        AND LEFT(A.ENCOUNTER, 1) IN ('1', '8')
        
        GROUP BY A.Encounter
        , B.Encounter
        "
    )
) %>%
    as_tibble() %>%
    clean_names()

ed_lab_tbl <- dbGetQuery(
    conn = db_con
    , statement = paste0(
        "
        SELECT A.Encounter
        , COUNT(B.ENCOUNTER) AS ED_LAB_ORDER_COUNT
        
        FROM smsdss.c_elos_bench_data AS A
        LEFT JOIN smsdss.c_LabRad_OrdUtil_by_DschDT AS B
        ON A.Encounter = B.Encounter
        
        WHERE B.ED_IP_FLAG = 'ED'
        AND B.Svc_Dept_Desc = 'LABORATORY'
        AND LEFT(A.ENCOUNTER, 1) IN ('1', '8')
        
        GROUP BY A.Encounter
        , B.Encounter
        "
    )
) %>%
    as_tibble() %>%
    clean_names()

encounter_tbl <- dbGetQuery(
    conn = db_con
    , statement = paste0(
        "
        SELECT DISTINCT Encounter
        , Dsch_Date
        FROM smsdss.c_elos_bench_data
        "
    )
) %>% 
    as_tibble() %>%
    clean_names()

# DB Disconnect ----
dbDisconnect(conn = db_con)

# Manipulate ----
joined_tbl <- encounter_tbl %>%
    left_join(ip_rad_tbl, by = c("encounter" = "encounter")) %>%
    left_join(ip_lab_tbl, by = c("encounter" = "encounter")) %>%
    left_join(ed_rad_tbl, by = c("encounter" = "encounter")) %>%
    left_join(ed_lab_tbl, by = c("encounter" = "encounter")) %>%
    mutate_if(is.integer, as.double) %>%
    mutate(
        ip_rad_count = case_when(
            is.na(ip_rad_order_count) ~ 0,
            TRUE ~ ip_rad_order_count
        )
        , ip_lab_count = case_when(
            is.na(ip_lab_order_count) ~ 0,
            TRUE ~ ip_lab_order_count
        )
        , ed_rad_count = case_when(
            is.na(ed_rad_order_count) ~ 0,
            TRUE ~ ed_rad_order_count
        )
        , ed_lab_count = case_when(
            is.na(ed_lab_order_count) ~ 0,
            TRUE ~ ed_lab_order_count
        )
    ) %>%
    mutate(dsch_date = lubridate::ymd(dsch_date)) %>%
    mutate(rec_cnt = 1) %>%
    arrange(dsch_date) %>%
    select(-contains("order"))

trend_tbl <- joined_tbl %>%
    mutate(month_end = EOMONTH(dsch_date)) %>%
    group_by(month_end) %>%
    summarise(
        visit_count = n()
        , ip_rad_per_pt = sum(ip_rad_count) / visit_count
        , ip_lab_per_pt = sum(ip_lab_count) / visit_count
        , ed_rad_per_pt = sum(ed_rad_count) / visit_count
        , ed_lab_per_pt = sum(ed_lab_count) / visit_count
    ) %>%
    ungroup() %>%
    filter(month_end >= '2016-01-01') %>%
    select(month_end, starts_with("ip"))

trend_long_tbl <- trend_tbl %>%
    pivot_longer(
        cols = starts_with("ip")
        , names_to = "order_type"
        , values_to = "value"
    ) %>%
    mutate(
        order_type_lbl = case_when(
            order_type == "ip_rad_per_pt" ~ "IP Rad Orders/Visit"
            , TRUE ~ "IP Lab Orders/Visit"
        )
    )

trend_long_tbl %>%
    filter(value != 0) %>%
    ggplot(mapping = aes(x = month_end, y = value, color = order_type_lbl)) +
    geom_point() +
    geom_line() +
    facet_wrap(
        facets = ~ order_type_lbl
        , scales = "free_y"
    ) +
    theme_tq() +
    scale_color_tq() +
    labs(
        title = "Orders Per Inpatient Visit"
        , color = "Order Type"
        , x = ""
        , y = ""
    ) 

writexl::write_xlsx(trend_tbl, path = "00_Data/ip_order_trend.xlsx")
