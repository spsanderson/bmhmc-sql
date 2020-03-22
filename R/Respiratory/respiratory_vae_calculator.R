# Lib Load ----
if(!require(pacman)) install.packages("pacman")
pacman::p_load(
    "DBI"
    , "odbc"
    , "dbplyr"
    , "tidyverse"
    , "lubridate"
    , "tidyquant"
    , "janitor"
)

# DB Connection ----
db_con <- dbConnect(
    odbc()
    , Driver = "SQL Server"
    , Server = "BMH-HIDB"
    , Database = "SMSPHDSSS0X0"
    , Trusted_Connection = TRUE
)

# Query ----
query <- dbGetQuery(
    conn = db_con
    , statement = paste0(
        "
        SELECT episode_no,
        	obsv_cd,
        	obsv_cd_name,
        	obsv_user_id,
        	dsply_val,
        	val_sts_cd,
        	CAST(perf_dtime AS DATE) AS [Perf_Date]
        FROM SMSMIR.obsv
        WHERE obsv_cd IN ('A_BMH_VFFiO2', 'A_BMH_VFPEEP')
        	AND episode_no IN ('14831689','14830434','14832877')
        	AND dsply_val != '-'
        ORDER BY obsv_cd,
        	perf_dtime
        "
    )
)
# 14831689  (1/6)
# 14830434 (1/26)
# 14832877 (1/4)


# DB Disconnect ----
dbDisconnect(db_con)

# Manip Data ----
data_tbl <- query %>% 
    as_tibble() %>%
    clean_names() %>%
    mutate(perf_date = as_date(perf_date)) %>%
    mutate(val_clean = case_when(
        !is.na(dsply_val) ~ as.numeric(dsply_val)
        , TRUE ~ NA_real_
    ))

data_long_tbl <- data_tbl %>%
    select(
        episode_no
        , obsv_cd
        , obsv_cd_name
        , obsv_user_id
        , perf_date
        , val_clean
    )

# Split tbls ----
fi02_tbl <- data_long_tbl %>%
    filter(obsv_cd == "A_BMH_VFFiO2") %>%
    filter(!is.na(val_clean)) %>%
    filter(val_clean > 10)

peep_tbl <- data_long_tbl %>%
    filter(obsv_cd != "A_BMH_VFFiO2") %>%
    filter(!is.na(val_clean))

# Fi02 Stability ----
fi02_final_tbl <- fi02_tbl %>%
    group_by(
        episode_no
        , obsv_cd
        , obsv_cd_name
        , perf_date
    ) %>%
    summarise(min_val = min(val_clean)) %>%
    ungroup() %>%
    mutate(
        l_1 = lag(min_val, n = 1, default = NA_real_)
        , l_2 = lag(min_val, n = 2, default = NA_real_)
    ) %>%
    mutate(
        delta_a = min_val - l_1
        , delta_b = l_1 - l_2
    ) %>%
    mutate(
        stable_flag = case_when(
            abs(delta_a) + abs(delta_b) >= 20 ~ 0
            , TRUE ~ 1
        )
    ) %>%
    select(
        episode_no
        , obsv_cd
        , obsv_cd_name
        , perf_date
        , min_val
        , stable_flag
    )

peep_final_tbl <- peep_tbl %>%
    group_by(
        episode_no
        , obsv_cd
        , obsv_cd_name
        , perf_date
    ) %>%
    summarise(min_val = min(val_clean)) %>%
    ungroup() %>%
    mutate(
        l_1 = lag(min_val, n = 1, default = NA_real_)
        , l_2 = lag(min_val, n = 2, default = NA_real_)
    ) %>%
    mutate(
        delta_a = min_val - l_1
        , delta_b = l_1 - l_2
    ) %>%
    mutate(
        stable_flag = case_when(
            abs(delta_a) + abs(delta_b) >= 3 ~ 0
            , TRUE ~ 1
        )
    ) %>%
    select(
        episode_no
        , obsv_cd
        , obsv_cd_name
        , perf_date
        , min_val
        , stable_flag
    )

# join tbls ----
joined_tbl <- fi02_final_tbl %>%
    left_join(
        y = peep_final_tbl
        , by = c(
            "episode_no" = "episode_no"
            , "perf_date" = "perf_date"
            )
    ) %>%
    select(
        episode_no
        , perf_date
        , min_val.x
        , stable_flag.x
        , min_val.y
        , stable_flag.y
    ) %>%
    set_names(
        "Episode_No"
        , "Perf_Date"
        , "Fi02_Min_Val"
        , "Fi02_Stability"
        , "Peep_Min_Val"
        , "Peep_Stability"
    )

joined_tbl <- joined_tbl %>%
    # filter(Episode_No == '14830434') %>%
    # filter(
    #     Perf_Date >= '2020-01-01'
    #     , Perf_Date < '2020-02-01'
    # ) %>%
    select(
        Episode_No
        , Perf_Date
        , Fi02_Min_Val
        , Fi02_Stability
        , Peep_Min_Val
        , Peep_Stability
    ) %>%
    mutate(
        fl1   = lag(Fi02_Stability, n = 1, default = NA_real_)
        , fl2 = lag(Fi02_Stability, n = 2, default = NA_real_)
    ) %>%
    mutate(
        fl_sum = fl1 + fl2
    ) %>%
    mutate(
        pl1   = lag(Peep_Stability, n = 1, default = NA_real_)
        , pl2 = lag(Peep_Stability, n = 2, default = NA_real_)
    ) %>%
    mutate(
        pl_sum = pl1 + pl2
    ) %>%
    select(-fl1,-fl2,-pl1,-pl2) %>%
    mutate(
        sum = fl_sum + pl_sum
    ) %>%
    mutate(
        VAE_Flag = case_when(
            lead(sum, n = 2) == 2 &
                lead(sum, n = 1) == 3 &
                sum == 4 ~ 'VAE'
            , TRUE ~ 'No-VAE'
        )
    ) %>%
    select(-fl_sum, -pl_sum, -sum)

# Write Data ----
write_csv(
    joined_tbl
    , "vae_test.csv"
)
