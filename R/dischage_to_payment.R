
# Lib Load ----------------------------------------------------------------

pacman::p_load(
  "LICHospitalR"
  , "tidyverse"
  , "tidyquant"
  , "odbc"
  , "DBI"
)

# Load Data ---------------------------------------------------------------

db_conn <- db_connect()

query <- dbGetQuery(
  conn = db_conn
  , statement = paste0(
    "
    DECLARE @START_DATE DATE
    DECLARE @END_DATE DATE
    
    SET @START_DATE = '2019-01-01'
    SET @END_DATE = '2020-01-01';
    
    SELECT CAST(PAV.Dsch_Date AS DATE) AS [Dsch_Date],
    CAST(PAY.pay_date AS DATE) AS [Pay_Date],
    [age_bucket] = CASE
    	WHEN DATEDIFF(DAY, PAV.Dsch_Date, PAY.pay_date) < 31
    		THEN '0_30'
    	WHEN DATEDIFF(DAY, PAV.Dsch_Date, PAY.pay_date) < 61
    		THEN '31_60'
    	WHEN DATEDIFF(DAY, PAV.Dsch_Date, PAY.pay_date) < 91
    		THEN '61_90'
    	WHEN DATEDIFF(DAY, PAV.Dsch_Date, PAY.pay_date) < 121
    		THEN '91_120'
    	WHEN DATEDIFF(DAY, PAV.Dsch_Date, PAY.pay_date) < 161
    		THEN '121_160'
    	WHEN DATEDIFF(DAY, PAV.Dsch_Date, PAY.pay_date) < 181
    		THEN '161_180'
    	WHEN DATEDIFF(DAY, PAV.Dsch_Date, PAY.pay_date) < 211
    		THEN '181_210'
    	WHEN DATEDIFF(DAY, PAV.Dsch_Date, PAY.pay_date) < 241
    		THEN '211_240'
    	WHEN DATEDIFF(DAY, PAV.Dsch_Date, PAY.pay_date) < 271
    		THEN '241_270'
    	WHEN DATEDIFF(DAY, PAV.Dsch_Date, PAY.pay_date) < 301
    		THEN '271_300'
    	WHEN DATEDIFF(DAY, PAV.Dsch_Date, PAY.pay_date) < 331
    		THEN '301_330'
    	WHEN DATEDIFF(DAY, PAV.Dsch_Date, PAY.pay_date) < 361
    		THEN '331_360'
    		ELSE '360_+'
    	END,
    PAV.PtNo_Num,
    pav.tot_chg_amt,
    SUM(PAY.tot_pay_adj_amt) AS [tot_pay_w_pip]
    FROM SMSDSS.BMH_PLM_PtAcct_V AS PAV
    INNER JOIN SMSMIR.pay AS PAY ON PAV.PT_NO = PAY.pt_id
    	AND PAV.unit_seq_no = PAY.unit_seq_no
    WHERE PAY.PAY_CD IN (
    	SELECT pay_cd
    	FROM SMSDSS.pay_cd_dim_v
    	WHERE pay_dept_cd IN ('096','099','009') --'098'
    )
    AND PAV.Dsch_Date >= @START_DATE
    AND PAV.Dsch_Date <  @END_DATE
    AND PAY.pay_date  >= @START_DATE
    --AND PAY.pay_date  <  DATEADD(YEAR, 1, @END_DATE)
    AND PAV.plm_pt_acct_type = 'I'
    GROUP BY Dsch_Date,
    pay_date,
    PAV.PtNo_Num,
  	pav.tot_chg_amt
    ORDER BY Dsch_Date,
    PAY.pay_date
    "
  )
)

db_disconnect(.connection = db_conn)


# Data Manipulation -------------------------------------------------------

df_tbl <- query %>%
  as_tibble() %>%
  set_names(
    "dsch_date","pay_date","age_bucket"
    ,"ptno_num","tot_chg_amt","tot_pay_w_pip"
  ) %>%
  mutate(
    dsch_date  = lubridate::ymd(dsch_date)
    , pay_date = lubridate::ymd(pay_date)
  ) %>%
  mutate(
    age_bucket = as_factor(age_bucket) %>% 
      fct_relevel(
        "0_30","31_60","61_90","91_120","121_160","161_180","181_210"
        ,"211_240","241_270","271_300","301_330","331_360","360_+")
    ) %>%
  mutate(fct_num = as.numeric(age_bucket)) %>%
  mutate(dsch_floor_date = FLOOR_MONTH(dsch_date)) %>%
  mutate(pay_floor_date = FLOOR_MONTH(pay_date)) %>%
  mutate(exp_reimb = -0.18 * tot_chg_amt)

exp_reimb_tbl <- df_tbl %>%
  select(month_start, exp_reimb) %>%
  group_by(month_start) %>%
  summarise(exp_reimb = sum(exp_reimb, na.rm = TRUE)) %>%
  ungroup()

df_pvt_tbl <- df_tbl %>%
  pivot_table(
    .rows      = ~ month_start
    , .columns = ~ age_bucket
    , .values  = ~ sum(tot_pay_w_pip)
    , fill_na  = 0 
  ) %>%
  left_join(exp_reimb_tbl, by = c("month_start"="month_start"))
  #mutate(gt = rowSums(across(where(is.numeric))))

pcts <- lapply(df_pvt_tbl[,-1], function(x){
  x / df_pvt_tbl$exp_reimb
  #x / df_pvt_tbl$gt
})
pcts_tbl <- pcts %>% 
  as_tibble() %>%
  mutate(month_start = df_pvt_tbl$month_start) %>%
  select(month_start, everything())
  
pcts_data_tbl <- pcts_tbl %>%
  pivot_longer(cols = -month_start) %>%
  filter(name != "exp_reimb") %>%
  #filter(name != "gt") %>%
  mutate(val_txt = scales::percent(value, .1)) %>%
  group_by(month_start) %>%
  mutate(cum_pct = cumsum(value)) %>%
  ungroup() %>%
  mutate(cum_pct_txt = scales::percent(cum_pct, .1)) %>%
  mutate(
    name = as_factor(name) %>% 
      fct_relevel(
        "0_30","31_60","61_90","91_120","121_160","161_180","181_210"
        ,"211_240","241_270","271_300","301_330","331_360","360_+")
  )

pcts_data_tbl %>%
  ggplot(
    mapping = aes(
      x = name
      , y = month_start
    )
  ) +
  geom_tile(
    mapping = aes(
      fill = value
    )
  ) +
  geom_text(
    mapping = aes(
      label = val_txt
    )
    , size = 3
  ) +
  scale_fill_gradient(
    low = "red"
    , high = "green"
  ) +
  theme_minimal() +
  labs(
    y = "Discharge Month"
    , x = "Age Bucket"
    , title = "Percentage of Payments recieved by Age Bucket"
  ) +
  theme(
    legend.position = "none"
    , axis.text.x = element_text(angle = 45, hjust = 1)
  )

pcts_data_tbl %>%
  ggplot(
    mapping = aes(
      x = name
      , y = month_start
    )
  ) +
  geom_tile(
    mapping = aes(
      fill = cum_pct
    )
  ) +
  geom_text(
    mapping = aes(
      label = cum_pct_txt
    )
    , size = 3
  ) +
  scale_fill_gradient(
    low = "red"
    , high = "green"
  ) +
  theme_minimal()

pcts_tbl %>% 
  #select(-c(month_start, gt)) %>% 
  select(-c(month_start, exp_reimb)) %>%
  summarise(across(.fns = mean)) %>% 
  pivot_longer(cols = everything()) %>% 
  mutate(value = round(value, 4)) %>%
  mutate(name = as_factor(name)) %>%
  ggplot(
    mapping = aes(
      x = name,
      y = value
    )
  ) +
  geom_col() +
  theme_tq() +
  theme(
    legend.position = "none"
    , axis.text.x = element_text(angle = 45, hjust = 1)
  )
