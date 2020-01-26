# Lib Load ----
if(!require(pacman)) install.packages("pacman")
pacman::p_load(
    "tidyverse"
    , "dbplyr"
    , "DBI"
    , "odbc"
    , "RDCOMClient"
)

# DB Connection ----
db_con <- dbConnect(
    odbc(),
    Driver = "SQL Server",
    Server = "BMH-HIDB",
    Database = "SMSPHDSSS0X0",
    Trusted_Connection = T
)

# Get Dupe Cataract Records ----

tempa <- dbGetQuery(
    conn = db_con
    , paste0(
        "
        DECLARE @TODAY DATE;
        DECLARE @START DATE;
        DECLARE @END   DATE;
        
        SET @TODAY = CAST(GETDATE() AS DATE);
        SET @START = DATEADD(MONTH, DATEDIFF(MONTH, 0, @TODAY) - 1, 0);
        SET @END   = DATEADD(MONTH, DATEDIFF(MONTH, 0, @TODAY), 0);
        
        
        SELECT PDV.pyr_group2
        , CAST(PAV.DSCH_DATE AS DATE) AS [Dsch_Date]
        , DschOrdDT.ent_dtime AS [Last_Dsch_Ord_DTime]
        , PAV.vst_end_dtime
        , PAV.dsch_disp
        , CASE
        	WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = 'HB' THEN 'Drug/Alcohol Rehab Non-Hospital Facility'
        	WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = 'HI' THEN 'Hospice at Hospice Facility, SNF or Inpatient Facility'
        	WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = 'HR' THEN 'Home, Home with Public Health Nurse, Adult Home, Assisted Living'
        	WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = 'MA' THEN 'Left Against Medical Advice, Elopement'
        	WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = 'TB' THEN 'Correctional Institution'
        	WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = 'TE' THEN 'SNF -Sub Acute'
        	WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = 'TF' THEN 'Specialty Hospital ( i.e Sloan, Schneiders)'
        	WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = 'TH' THEN 'Hospital - Med/Surg (i.e Stony Brook)'
        	WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = 'TL' THEN 'SNF - Long Term'
        	WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = 'TN' THEN 'Hospital - VA'
        	WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = 'TP' THEN 'Hospital - Psych or Drug/Alcohol (i.e BMH 1EAST, South Oaks)'
        	WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = 'TT' THEN 'Hospice at Home, Adult Home, Assisted Living'
        	WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = 'TW' THEN 'Home, Adult Home, Assisted Living with Homecare'
        	WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = 'TX' THEN 'Hospital - Acute Rehab ( I.e. St. Charles, Southside)'
        	WHEN RIGHT(RTRIM(LTRIM(PAV.dsch_disp)), 2) = '1A' THEN 'Postoperative Death, Autopsy'
        	WHEN LEFT(PAV.dsch_disp, 1) IN ('C', 'D') THEN 'Mortality'
        END AS [Dispo]
        
        FROM SMSDSS.BMH_PLM_PtAcct_V AS PAV
        -- Get last dsch ord
        LEFT OUTER JOIN (
        	SELECT B.episode_no,
        		B.ENT_DTIME,
        		B.svc_cd
        	FROM (
        		SELECT CAST(EPISODE_NO AS VARCHAR(8)) AS Episode_No,
        			svc_cd,
        			ENT_DTIME,
        			ROW_NUMBER() OVER (
        				PARTITION BY EPISODE_NO ORDER BY ORD_NO DESC
        				) AS ROWNUM
        		FROM smsmir.sr_ord
        		WHERE svc_desc = 'DISCHARGE TO'
        			AND episode_no < '20000000'
        		) B
        	WHERE B.ROWNUM = 1
        	) DschOrdDT ON PAV.PTNO_NUM = DschOrdDT.Episode_No
        LEFT OUTER JOIN SMSDSS.PYR_DIM_V AS PDV
        ON PAV.PYR1_co_PLAN_CD = PDV.SRC_PYR_CD
        	AND PAV.REGN_HOSP = PDV.ORGZ_CD
        
        WHERE PAV.tot_chg_amt > 0
        AND LEFT(PAV.PTNO_NUM, 1) != '2'
        AND LEFT(PAV.PTNO_NUM, 4) != '1999'
        AND PAV.DSCH_DATE >= @START
        AND PAV.DSCH_DATE < @END
        AND PAV.PLM_PT_ACCT_TYPE = 'I'
        AND PAV.dsch_disp IN ('AHR','ATE','ATL')
        "
    )
)

tempa <- tempa %>%
    as_tibble() %>%
    mutate(
        dsch_ord_dsch_mins = difftime(
            vst_end_dtime
            , Last_Dsch_Ord_DTime
            , units = "mins"
            )
        ) %>%
    mutate(
        dsch_ord_dsch_hrs = difftime(
            vst_end_dtime
            , Last_Dsch_Ord_DTime
            , units = "hours"
        )
    )

tempa %>% write.csv("G:\\Care Management\\dsch_ord_to_dsch.csv")

# DB Disconnect ----
dbDisconnect(db_con)

# Compose Email ----
# Open Outlook
Outlook <- COMCreate("Outlook.Application")

# Create Email
Email = Outlook$CreateItem(0)

# Set the recipeitn, subject, and body
Email[["to"]] = ""
Email[["cc"]] = ""
Email[["bcc"]] = ""
Email[["subject"]] = "Discharge Order to Discharge Time"
Email[["body"]] = "Please see the attached for the latest numbers"
Email[["attachments"]]$Add("G:\\Care Management\\dsch_ord_to_dsch.csv")

# Send the email
Email$Send()

# Clost Outlook, clear the message
rm(list = ls())
