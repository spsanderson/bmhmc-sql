# Lib Load ----
if(!require(pacman)) install.packages("pacman")
pacman::p_load(
    "DBI",
    "odbc",
    "janitor"
)

# DB Con ----
db_con <- dbConnect(
    odbc(),
    Driver = "SQL Server",
    Server = "BMH-HIDB",
    Database = "SMSPHDSSS0X0",
    Trusted_Connection = T
)

# Get Data ----
query <- dbGetQuery(
    conn = db_con,
    paste0(
        "
        SELECT CAST(A.ADM_DATE AS DATE) AS [Adm_Date]
        , CAST(A.DSCH_DATE AS DATE) AS [Dsch_Date]
        , A.PtNo_Num
        , D.LIHN_Svc_Line
        , CAST(A.Days_Stay AS INT) AS [LOS]
        , C.Performance AS [ELOS]
        , 1 AS [Visit_Flag]
        , CASE
        	WHEN B.READMIT IS NULL
        		THEN 0
        		ELSE 1
          END AS [READMIT_FLAG]
        , F.READMIT_RATE
        
        FROM SMSDSS.BMH_PLM_PTACCT_V AS A
        LEFT OUTER JOIN SMSDSS.vReadmits AS B
        ON A.PtNo_Num = B.[INDEX]
        	AND B.[INTERIM] < 31
        INNER MERGE JOIN SMSDSS.c_elos_bench_data AS C
        ON A.PtNo_Num = C.Encounter
        INNER JOIN SMSDSS.c_LIHN_Svc_Line_Tbl AS D
        ON A.PtNo_Num = D.Encounter
        INNER JOIN Customer.Custom_DRG AS E
        ON A.PtNo_Num = E.PATIENT#
        INNER JOIN SMSDSS.C_READMIT_DASHBOARD_BENCH_TBL AS F
        ON D.LIHN_Svc_Line = F.LIHN_SVC_LINE
        	AND (DATEPART(YEAR, A.DSCH_DATE) - 1) = F.BENCH_YR
        	AND E.SEVERITY_OF_ILLNESS = F.SOI
        
        WHERE A.tot_chg_amt > 0
        AND LEFT(A.PTNO_NUM, 1) != '2'
        AND LEFT(A.PTNO_NUM, 4) != '1999'
        AND A.Dsch_Date >= '2001-01-01'
        AND A.Plm_Pt_Acct_Type = 'I'
        "
    )
)

# DB Disconnect ----
dbDisconnect(db_con)

# As Tibble ----
query_tbl <- query %>%
    as_tibble() %>%
    clean_names()

# Write Data ----
write_csv(query_tbl, path = "01_data/data.csv")

# Clean env ----
rm(list = ls())
