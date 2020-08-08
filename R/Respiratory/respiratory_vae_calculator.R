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
    , "RDCOMClient"
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
        --AND episode_no IN ('14831689','14830434','14832877')
        AND dsply_val != '-'
        AND LEFT(episode_no, 1) != '7'
        AND perf_date >= @YESTERDAY
        ORDER BY obsv_cd,
        perf_dtime
        "
    )
)

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
    filter(val_clean >= 10)

peep_tbl <- data_long_tbl %>%
    filter(obsv_cd != "A_BMH_VFFiO2") %>%
    filter(!is.na(val_clean))

# Peep Stability ----
peep_tbl_a <- peep_tbl %>%
    group_by(
        episode_no
        , obsv_cd
        , obsv_cd_name
        , perf_date
    ) %>%
    summarise(min_val = min(val_clean)) %>%
    # PEEP values from 0-5 cmH2O are considered equivalent
    mutate(peep_equivalent = case_when(
        min_val <= 5 ~ 5,
        TRUE ~ min_val
    )) %>%
    ungroup() %>%
    select(-obsv_cd, -min_val)

peep_final_tbl <- peep_tbl_a %>%
    mutate(
        stable_flag =  case_when(
            (peep_equivalent > 5) &
                (lag(peep_equivalent, n = 1) <= 5) &
                (lag(peep_equivalent, n = 2) <= 5) ~ 0,
            TRUE ~ 1
        )
    ) %>%
    select(
        episode_no
        , obsv_cd_name
        , perf_date
        , peep_equivalent
        , stable_flag
    )

# Fi02 Stability ----
fi02_tbl_a <- fi02_tbl %>%
    group_by(
        episode_no
        , obsv_cd
        , obsv_cd_name
        , perf_date
    ) %>%
    summarise(min_val = min(val_clean)) %>%
    ungroup() %>%
    select(-obsv_cd)
    
fi02_final_tbl <- fi02_tbl_a %>% 
    group_by(episode_no) %>%
    mutate(row_id = row_number()) %>%
    ungroup() %>%
    mutate(
        exclude_row = case_when(
            row_id <= 2 ~ 1,
            TRUE ~ 0
        )
    ) %>%
    mutate(
        l_1 = lag(min_val, n = 1, default = NA_real_)
        , l_2 = lag(min_val, n = 2, default = NA_real_)
    ) %>%
    mutate(
        delta_a = min_val - l_1
        , delta_b = min_val - l_2
    ) %>% 
    mutate(
        stable_flag = case_when(
            #abs(delta_a) + abs(delta_b) >= 20 ~ 0
            (
                (delta_a >= 20) & 
                    (delta_b >= 20) &
                    row_id >= 3
            )~ 0
            , TRUE ~ 1
        )
    ) %>%
    select(
        episode_no
        , obsv_cd_name
        , perf_date
        , min_val
        , stable_flag
    )

# Join Tbls ----
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
        , min_val
        , stable_flag.x
        , peep_equivalent
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

pre_vae_tbl <- joined_tbl %>%
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
    rowid_to_column(var = "row_id") %>%
    mutate(
        VAE_Flag = case_when(
            lead(sum, n = 2) %in% c(2,3) &
                lead(sum, n = 1) == 3 &
                sum == 4 ~ 'VAE'
            , TRUE ~ 'No-VAE'
        )
    ) %>%
    select(-fl_sum, -pl_sum, -sum)

tst <- pre_vae_tbl %>%
    group_by(Episode_No) %>%
    mutate(last_event_flag = case_when(
        VAE_Flag == "VAE" ~ 1, 
        TRUE ~ 0
    )) %>%
    mutate(
        last_event_index = cumsum(last_event_flag) + 1
    ) %>%
    mutate(
        last_event_index = c(
            1,
            last_event_index[1:length(last_event_index) - 1]
        )
    ) %>%
    ungroup()

tst <- tst %>%
    group_by(Episode_No) %>%
    mutate(
        last_event_date = c(
            as.Date(NA),
            tst[which(tst$last_event_flag == 1), "Perf_Date"]
        )[last_event_index]
    ) %>%
    mutate(
        tae = Perf_Date - last_event_date
    ) %>%
    ungroup()

final_tbl <- tst %>%
    mutate(VAE_Flag_Final = case_when(
        ((VAE_Flag == "VAE") & (tae > 13)) ~ "VAE-Positive",
        ((VAE_Flag == "VAE") & (is.na(tae))) ~ "VAE-Positive",
        TRUE ~ "VAE-Negative"
    )) %>%
    select(
        Episode_No,
        Perf_Date,
        Fi02_Min_Val,
        Peep_Min_Val,
        VAE_Flag_Final
    )

# Write Data ----
f_name <- str_c(
    "VAE_"
    , str_sub(Sys.Date(), 6, 7)
    ,"_"
    , str_sub(Sys.Date(), 9, 10)
    ,"_"
    , str_sub(Sys.Date(), 1, 4)
    , ".csv"
)
f_path <- "G:\\Respiratory\\Elena L\\VAE Reports\\"
email_file_path <- paste0(f_path, f_name)
write_csv(
    final_tbl
    , paste0(f_path, f_name)
)

# Compose Email ----
# Open Outlook
Outlook <- COMCreate("Outlook.Application")

# Create Email
Email = Outlook$CreateItem(0)

# Set the recipeitn, subject, and body
Email[["to"]] = "ELennon@LICommunityHospital.org"
Email[["cc"]] = ""
Email[["bcc"]] = ""
Email[["subject"]] = "VAE File"
Email[["body"]] = "
Please see the attached for the lastest VAE data.
                
Thank you,

Steven Sanderson, MPH
Data Scientist / IT Manager
Long Island Community Hospital
101 Hospital Road Patchogue, NY 11772
Office: 631.687.2995
Email: ssanderson@LICommunityHospital.org
www.LICommunityHospital.org
"
Email[["attachments"]]$Add(email_file_path)

# Send the email
Email$Send()

# Clost Outlook, clear the message
rm(list = ls())
