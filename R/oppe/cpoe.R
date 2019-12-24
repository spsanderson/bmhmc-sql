# Lib Load ----
if(!require(pacman)) install.packages("pacman")
pacman::p_load(
    "tidyverse"
    , "tidyquant"
    , "lubridate"
    , "R.utils"
    , "tibbletime"
    , "knitr"
    , "kableExtra"
    , "anomalize"
    , "DBI"
    , "odbc"
    , "dbplyr"
)

# Source Functions ----
my_path <- ("S:\\Global Finance\\1 REVENUE CYCLE\\Steve Sanderson II\\Code\\R\\Functions\\")
source_files <- list.files(my_path, "*.R")
load_files <-  subset(
    source_files
    , subset = (
        str_detect(source_files, "oppe_") | 
            str_detect(source_files, "clean")
    )
)
map(paste0(my_path, load_files), source)

# DB Connection ----
db_con <- dbConnect(
    odbc(),
    Driver = "SQL Server",
    Server = "BMH-HIDB",
    Database = "SMSPHDSSS0X0",
    Trusted_Connection = T
)

# Report Parameters ----
# Dates
alos_start_date <- Sys.Date() %m-% months(18) %>%
    floor_date(unit = "months")
alos_end_date <- Sys.Date() %>%
    floor_date(unit = "months")

# Provider
provider_id = '017343'

# Tables ----
# Provider tbl ----
provider_tbl <- tbl(
    db_con,
    in_schema(
        schema = "smsdss"
        , table = "pract_dim_v"
    )
) %>%
    filter(
        orgz_cd == 'S0X0'
        , src_pract_no == provider_id
    ) %>%
    as_tibble() %>%
    select(
        src_pract_no
        , pract_rpt_name
        , src_spclty_cd
        , orgz_cd
        , med_staff_dept
    ) %>%
    mutate(
        pract_rpt_name = str_to_title(pract_rpt_name)
    ) %>%
    clean_names()

# ALOS Tables ----
alos_svc_line_tbl <- tbl(
    db_con,
    in_schema(
        schema = "smsdss"
        , table = "c_LIHN_Svc_Line_tbl "
    )
) %>%
    as_tibble() %>%
    clean_names()

alos_pav_tbl <- tbl(
    db_con,
    in_schema(
        schema = "smsdss"
        , table = "BMH_PLM_PtAcct_V"
    )
) %>%
    filter(
        Dsch_Date >= alos_start_date
        , Dsch_date < alos_end_date
        , Plm_Pt_Acct_Type == "I"
        , tot_chg_amt > 0
        , str_sub(PtNo_Num %>% as.character(), 1, 1) != '2'
        , str_sub(PtNo_Num %>% as.character(), 1, 4) != '1999'
        , !is.na(drg_no)
        , !drg_no %in% c(
            '0','981','982','983','984','985',
            '986','987','988','989','998','999'
        )
        , Atn_Dr_No == provider_id
    ) %>%
    select(
        Med_Rec_No
        , Pt_No
        , PtNo_Num
        , Adm_Date
        , Dsch_Date
        , Days_Stay
        , Atn_Dr_No
        , drg_no
        , drg_cost_weight
        , Regn_Hosp
        , Pyr1_Co_Plan_Cd
    ) %>%
    mutate(
        Dsch_Month = month(Dsch_Date)
        , Dsch_Yr = year(Dsch_Date)
        , LOS = if_else(
            Days_Stay == '0'
            , '1'
            , Days_Stay
        )
    ) %>%
    as_tibble()

alos_pav_tbl <- alos_pav_tbl %>%
    mutate(
        PtNo_Num = PtNo_Num %>% as.character()
        , Pt_No = Pt_No %>% str_squish()
    ) %>%
    clean_names()

alos_aprdrg_tbl <- tbl(
    db_con,
    in_schema(
        schema = "Customer"
        , table = "Custom_DRG"
    )
) %>%
    select(
        `PATIENT#`
        , APRDRGNO
        , SEVERITY_OF_ILLNESS
    ) %>%
    as_tibble() %>%
    rename(Encounter = `PATIENT#`) %>%
    mutate(Encounter = Encounter %>% str_squish()) %>%
    clean_names()

alos_bench_tbl <- tbl(
    db_con,
    in_schema(
        schema = "smsdss"
        , table = "c_LIHN_SPARCS_BenchmarkRates"
    )
) %>%
    filter(
        `Measure ID` == '4'
        , `Benchmark ID` == '3'
    ) %>%
    as_tibble() %>%
    clean_names()

alos_outlier_tbl <- tbl(
    db_con,
    in_schema(
        schema = "smsdss"
        , table = "c_LIHN_APR_DRG_OutlierThresholds"
    )
) %>%
    as_tibble() %>%
    clean_names()

alos_pyr_dim_tbl <- tbl(
    db_con,
    in_schema(
        schema = "smsdss"
        , table = "pyr_dim_v"
    )
) %>%
    as_tibble() %>%
    select(
        pyr_cd
        , orgz_cd
        , pyr_group2
    ) %>%
    clean_names()

alos_vst_rpt_tbl <- tbl(
    db_con,
    in_schema(
        schema = "smsmir"
        , table = "vst_rpt"
    )
) %>%
    filter(
        vst_end_date >= alos_start_date
        , vst_end_date < alos_end_date
        , vst_type_cd == "I"
    ) %>%
    select(
        pt_id
        , ward_cd
    ) %>%
    as_tibble() %>%
    mutate(pt_id = pt_id %>% str_squish()) %>%
    clean_names()

# Final ALOS Table
alos_tbl <- alos_svc_line_tbl %>%
    # joins
    inner_join(
        alos_pav_tbl
        , by = c("encounter" = "pt_no")
        , keep = T
    ) %>%
    left_join(
        alos_aprdrg_tbl
        , by = c("pt_no_num" = "encounter")
        , keep = T
    ) %>%
    left_join (
        alos_bench_tbl
        , by = c(
            "lihn_svc_line" = "lihn_service_line"
            , "aprdrgno" = "aprdrg_code"
            , "severity_of_illness" = "soi"
        )
        , keep = T
    ) %>%
    left_join(
        provider_tbl
        , by = c(
            "atn_dr_no" = "src_pract_no"
            , "regn_hosp" = "orgz_cd"
        )
        , keep = T
    ) %>%
    left_join(
        alos_outlier_tbl
        , by = c("aprdrgno" = "apr_minus_drg_code")
        , keep = T
    ) %>%
    left_join(
        alos_pyr_dim_tbl
        , by = c(
            "pyr1_co_plan_cd" = "pyr_cd"
            , "regn_hosp" = "orgz_cd"
        )
        , keep = T
    ) %>%
    left_join(
        alos_vst_rpt_tbl
        , by = c("encounter" = "pt_id")
        , keep = T
    ) %>%
    # select statement
    select(
        med_rec_no
        , encounter
        , pt_no_num
        , adm_date
        , dsch_date
        , dsch_month
        , dsch_yr
        , days_stay
        , atn_dr_no
        , pract_rpt_name
        , drg_no
        , lihn_svc_line
        , src_spclty_cd
        , aprdrgno
        , severity_of_illness
        , performance
        , outlier_threshold
        , drg_cost_weight
        , pyr_group2
        , med_staff_dept
        , ward_cd
    ) %>%
    # mutate statements
    mutate(
        los = if_else(
            days_stay == 0
            , 1.0
            , days_stay
        )
        , hosim = if_else(
            src_spclty_cd == 'HOSIM'
            , "Hospitalist"
            , "Private"
        )
        , performance = case_when(
            performance == 0 ~ 1.0
            , (is.na(performance) & los == 0) ~ 1.0
            , (is.na(performance) & los != 0) ~ (los %>% as.numeric())
            , T ~ performance
        )
        , outlier_flag = if_else(
            los > outlier_threshold
            , 1
            , 0
        )
        , case_var = round((los - performance), 4)
        , case_index = round(los / performance, 4)
        , los_sd = sd(los)
        , z_minus_score = round((los - performance) / los_sd, 4)
        , zscore_ul = 1.96
        , zscore_ll = -1.96
        , last_rpt_month = if_else(
            dsch_month < 10
            , str_c(dsch_yr, 0, dsch_month)
            , str_c(dsch_yr, dsch_month)
        )
        , proper_name = str_to_title(pract_rpt_name)
    ) %>%
    as_tbl_time(index = dsch_date) %>%
    arrange(dsch_date)

# Readmit Tables ----
ra_detail_tbl <- tbl(
    db_con,
    in_schema(
        schema = "smsdss"
        , table = "C_READMIT_DASHBOARD_DETAIL_TBL"
    )
) %>%
    as_tibble() %>%
    mutate(
        dsch_bench_yr = (Dsch_YR - 1) %>% as.character()
        , SEVERITY_OF_ILLNESS = SEVERITY_OF_ILLNESS %>% as.character()
    ) %>%
    clean_names()

ra_bench_tbl <- tbl(
    db_con,
    in_schema(
        schema = "smsdss"
        , table = "c_Readmit_Dashboard_Bench_Tbl"
    )
) %>%
    as_tibble() %>%
    filter(!is.na(SOI)) %>%
    mutate(
        SOI = SOI %>% as.character()
    ) %>%
    clean_names()

ra_vst_tbl <- tbl(
    db_con,
    in_schema(
        schema = "smsmir"
        , table = "vst_rpt"
    )
) %>%
    filter(
        vst_type_cd == "I"
    ) %>%
    select(
        pt_id
        , ward_cd
    ) %>%
    as_tibble() %>%
    mutate(
        pt_id = pt_id %>% str_squish()
        , episode_no = str_sub(pt_id, 5)
    ) %>%
    filter(!is.na(ward_cd)) %>%
    clean_names()

# Final RA Table
readmit_tbl <- ra_detail_tbl %>%
    left_join(
        ra_bench_tbl
        , by = c(
            "lihn_svc_line" = "lihn_svc_line"
            , "dsch_bench_yr" = "bench_yr"
            , "severity_of_illness" = "soi"
        )
    ) %>%
    left_join(
        ra_vst_tbl
        , by = c("pt_no_num" = "episode_no")
    ) %>%
    mutate(
        adm_date = ymd(adm_date)
        , dsch_date = ymd(dsch_date)
        , pt_count = 1
        , bench_yr = dsch_bench_yr
        , ra_sd = sd(ra_flag)
        , z_minus_score = round(
            (ra_flag - readmit_rate) / ra_sd, 4
        )
        , severity_of_illness = severity_of_illness %>% as.numeric()
        , proper_name = str_to_title(pract_rpt_name)
    ) %>%
    select(
        med_rec_no
        , pt_no_num
        , adm_date
        , dsch_date
        , payor_category
        , atn_dr_no
        , pract_rpt_name
        , proper_name
        , med_staff_dept
        , lihn_svc_line
        , severity_of_illness
        , dsch_yr
        , dsch_month
        , dsch_day_name
        , dsch_disp
        , dsch_disp_desc
        , drg_cost_weight
        , hospitalist_private
        , los
        , interim
        , pt_count
        , ra_flag
        , bench_yr
        , readmit_rate
        , ra_sd
        , z_minus_score
        , ward_cd
    ) %>%
    rename(
        readmit_rate_bench = readmit_rate
        , readmit_count = ra_flag
    ) %>%
    filter(atn_dr_no == provider_id) %>%
    as_tbl_time(index = dsch_date) %>%
    arrange(dsch_date)

# CPOE Tables ----
cpoe_detail_tbl <- tbl(
    db_con,
    in_schema(
        schema = "smsdss"
        , table = "c_CPOE_Rpt_Tbl_Rollup_v"
    )
) %>%
    select(
        req_pty_cd
        , Hospitalist_Np_Pa_Flag
        , Ord_Type_Abbr
        , Unknown
        , Telephone
        , `Per RT Protocol`
        , Communication
        , `Specimen Collect`
        , `Specimen Redraw`
        , CPOE
        , `Nursing Order`
        , Written
        , `Verbal Order`
        , ent_date
    ) %>%
    as_tibble() %>%
    clean_names() %>%
    mutate(ent_date = ymd(ent_date)) %>%
    filter(req_pty_cd == provider_id) %>%
    as_tbl_time(index = ent_date) %>%
    arrange(ent_date)

cpoe_tbl <- cpoe_detail_tbl %>%
    left_join(
        provider_tbl
        , by = c(
            "req_pty_cd" = "src_pract_no"
        )
    ) %>% 
    filter(orgz_cd == "S0X0") %>%
    mutate(
        proper_name = str_to_title(pract_rpt_name)
        , total_orders = 
            unknown +
            telephone +
            per_rt_protocol +
            communication +
            specimen_collect +
            specimen_redraw +
            cpoe +
            nursing_order +
            written +
            verbal_order
    )

# Denials Tables ----
denials_tbl <- dbGetQuery(
    db_con
    , paste0("
    DECLARE @TODAY DATE;
DECLARE @START DATE;
DECLARE @END   DATE;

SET @TODAY = CAST(GETDATE() AS date);
SET @START = DATEADD(YY, DATEDIFF(YY, 0, @TODAY) - 5, 0);
SET @END   = DATEADD(MM, DATEDIFF(MM, 0, @TODAY), 0);

SELECT PAV.Med_Rec_No,
	PAV.PtNo_Num,
	CAST(PAV.ADM_DATE AS DATE) AS [Adm_Date],
	CAST(PAV.Dsch_Date AS DATE) AS [Dsch_Date],
	CAST(PAV.DAYS_STAY AS INT) AS [Days_Stay],
	PAV.drg_no,
	DRG.drg_name,
	PAV.drg_cost_weight,
	PAV.Atn_Dr_No,
	PDV.pract_rpt_name,
	CASE 
		WHEN PAV.Plm_Pt_Acct_Type != 'I'
			THEN LIHNOP.LIHN_Svc_Line
		ELSE LIHNIP.LIHN_Svc_Line
		END AS [Svc_Line],
	CASE 
		WHEN DENIALS.pt_no IS NOT NULL
			THEN 1
		ELSE 0
		END AS [Denial_Flag],
	DENIALS.UM_Days_Denied,
	DENIALS.Dollars_Appealed,
	DENIALS.Dollars_Recovered,
	PAV.tot_chg_amt,
    PAV.Plm_Pt_Acct_Type
FROM SMSDSS.BMH_PLM_PtAcct_V AS PAV
INNER JOIN SMSDSS.pract_dim_v AS PDV ON PAV.Atn_Dr_No = PDV.src_pract_no
	AND PAV.Regn_Hosp = PDV.orgz_cd
LEFT OUTER JOIN SMSDSS.drg_dim_v AS DRG ON PAV.DRG_NO = DRG.DRG_NO
	AND DRG.drg_vers = 'MS-V25'
LEFT OUTER JOIN SMSDSS.c_LIHN_Svc_Line_Tbl AS LIHNIP ON PAV.PtNo_Num = LIHNIP.Encounter
LEFT OUTER JOIN SMSDSS.c_LIHN_OP_Svc_Line_Tbl AS LIHNOP ON PAV.PtNo_Num = LIHNOP.Encounter
LEFT OUTER JOIN (
	SELECT CAST(rtrim(ltrim('0000' + CAST(a.bill_no AS CHAR(13)))) AS CHAR(13)) COLLATE SQL_LATIN1_GENERAL_PREF_CP1_CI_AS AS [Pt_No],
		e.appl_dollars_appealed AS [Dollars_Appealed],
		e.appl_dollars_recovered AS [Dollars_Recovered],
		d.rvw_Dys_dnd AS [UM_Days_Denied]
	FROM [BMH-3MHIS-DB].MMM_COR_BMH_LIVE.dbo.visit_view AS a
	LEFT JOIN [BMH-3MHIS-DB].MMM_COR_BMH_LIVE.dbo.CTC_VISIT AS b ON a.visit_id = b._fk_visit
	LEFT JOIN [BMH-3MHIS-DB].MMM_COR_BMH_LIVE.dbo.CTC_INSURANCE AS c ON a.visit_id = c._fk_visit
	LEFT JOIN [BMH-3MHIS-DB].[MMM_COR_BMH_LIVE].[dbo].[CTC_UM_Denial] AS d ON c._pk = d._fk_insurance
	LEFT OUTER JOIN [BMH-3MHIS-DB].MMM_COR_BMH_LIVE.dbo.CTC_UM_APPEAL AS e ON d._pk = e._fk_UM_Denial
	WHERE E.APPL_doLLARS_APPEALED IS NOT NULL
	) AS DENIALS ON PAV.Pt_NO = DENIALS.Pt_No
WHERE Adm_Date >= @START
	AND Adm_Date < @END
	AND PAV.tot_chg_amt > 0
	AND LEFT(PAV.PTNO_NUM, 1) != '2'
	AND LEFT(PAV.PTNO_NUM, 4) != '1999'
	AND PAV.Atn_Dr_No = '", provider_id ,"'
	AND (
		(
			PAV.Plm_Pt_Acct_Type = 'I'
			AND PAV.drg_no IS NOT NULL
			)
		OR (
			PAV.Plm_Pt_Acct_Type != 'I'
			AND PAV.drg_no IS NULL
			)
		)
ORDER BY PAV.Plm_Pt_Acct_Type,
	PAV.Adm_Date
    ")
)

# Final Denials Table
denials_tbl <- denials_tbl %>%
    clean_names() %>%
    mutate(
        adm_date = adm_date %>% ymd()
        , dsch_date = dsch_date %>% ymd()
    ) %>%
    as_tbl_time(index = adm_date) %>%
    arrange(adm_date)

# Disconnect DB ----
dbDisconnect(db_con)

# Viz ----
oppe_cpoe_plot(cpoe_tbl)
oppe_alos_plot(alos_tbl)
oppe_readmit_plot(readmit_tbl)
oppe_denials_plot()
oppe_gartner_magic_plot()
