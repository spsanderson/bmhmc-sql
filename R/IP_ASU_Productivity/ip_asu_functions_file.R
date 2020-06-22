# Functions ---------------------------------------------------------------
# Lib Load ----
if(!require(pacman)) install.packages("pacman")
pacman::p_load(
    "odbc",
    "DBI",
    "janitor",
    "tidyverse"
)

# DB Connection Funcs -----------------------------------------------------
# DB Connection ----
db_connect <- function(){
    db_con <- odbc::dbConnect(
        odbc::odbc(),
        Driver = "SQL Server",
        Server = "BMH-HIDB",
        Database = "SMSPHDSSS0X0",
        Trusted_Connection = T
    )
    return(db_con)
}

# DB Disconnect ----
db_disconnect <- function(connection) {
    odbc::dbDisconnect(connection)
}


# Queries -----------------------------------------------------------------
# IP Queries ----
ip_orsos_rm_tbl <- function() {
    query <- DBI::dbGetQuery(
      conn = db_connect()
      , statement = paste0(
          "
          DECLARE @BMH_START_1 AS DATETIME;
          DECLARE @BMH_END_1   AS DATETIME;
          DECLARE @TODAY       AS DATETIME;
          DECLARE @START       AS DATETIME;
          DECLARE @END         AS DATETIME;
          
          SET @TODAY = GETDATE();
          SET @START = DATEADD(MONTH, DATEDIFF(MONTH, 0, @TODAY) -1,0);
          SET @END   = DATEADD(MONTH, DATEDIFF(MONTH, 0, @TODAY), 0);
          SET @BMH_START_1   = @START;
          SET @BMH_END_1     = @END;
  
        	SELECT A.CASE_NO AS [ORSOS_CASE_NO]
        	, C.FACILITY_ACCOUNT_NO AS [DSS_CASE_NO]
        	, REPLACE(E.RESOURCE_ID, '-', '') AS [ORSOS_MD_ID]
        	, F.DESCRIPTION AS [ORSOS_DESCRIPTION]
        	, CAST(A.START_DATE AS DATE) AS [ORSOS_START_DATE]
        	, A.ROOM_ID AS [ORSOS_ROOM_ID]
        	, A.DELETE_FLAG AS [ORSOS_DELETE_FLAG]
        	, CAST(A.ENTER_PROC_ROOM_TIME AS TIME(0)) AS [ENTER_PROC_ROOM_TIME]
        	, CAST(A.LEAVE_PROC_ROOM_TIME AS TIME(0)) AS [LEAVE_PROC_ROOM_TIME]
        	, B.DESCRIPTION AS [PROCEDURE]
        	, CAST(D.ANES_START_DATE AS DATE)         AS [ANES_START_DATE]
        	, CAST(D.ANES_START_TIME AS TIME(0))      AS [ANES_START_TIME]
        	, CAST(D.ANES_STOP_DATE AS DATE)          AS [ANES_END_DATE]
        	, CAST(D.ANES_STOP_TIME AS TIME(0))       AS [ANES_END_TIME]
        	, C.PATIENT_TYPE
        	, CAST(A.ADMIT_RECOVERY_DATE AS DATE)     AS [ADMIT_RECOVERY_DATE]
        	, CAST(A.ADMIT_RECOVERY_TIME AS TIME(0))  AS [ADMIT_RECOVERY_TIME]
        	, CAST(A.LEAVE_RECOVERY_DATE AS DATE)     AS [LEAVE_RECOVERY_DATE]
        	, CAST(A.LEAVE_RECOVERY_TIME AS TIME(0))  AS [LEAVE_RECOVERY_TIME]
        	, G.src_pract_no                          AS [DSS_SRC_PRACT_NO_A]
        	, G.src_spclty_cd                         AS [DSS_SRC_SPCLTY_CD_A]
        	, G.spclty_desc                           AS [DSS_SPCLTY_DESC_A]
        	, ZZZ.ORSOS_STAFF_ID                      AS [ORSOS_CROSSWALK_ID]
        	, ZZZ.DSS_STAFF_ID                        AS [DSS_CROSSWALK_ID]
        
        	FROM 
        	(
        		(
        			[BMH-ORSOS].[ORSPROD].[ORSPROD].[POST_CASE]              AS A
        			INNER JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[PROCEDURES]  AS B
        			ON A.MAIN_PROCEDURE_ID = B.PROCEDURE_ID
        		)
        		INNER JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[CLINICAL]        AS C
        		ON A.ACCOUNT_NO = C.ACCOUNT_NO
        	)
        	LEFT OUTER JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[POST_ANES_TYPE] AS D
        	ON A.CASE_NO = D.CASE_NO
        	LEFT OUTER JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[POST_RESOURCE]  AS E
        	ON A.CASE_NO = E.CASE_NO
        		AND E.ROLE_CODE = '1'
        	LEFT OUTER JOIN [BMH-ORSOS].[ORSPROD].[ORSPROD].[CODES_ROLE]     AS F
        	ON E.ROLE_CODE = F.CODE
        	
        	-- use the crosswalk table to get miss matches
        	LEFT OUTER JOIN smsdss.C_ORSOS_TO_DSS_MISSING_IDS                AS ZZZ
        	ON REPLACE(E.RESOURCE_ID, '-', '') = ZZZ.ORSOS_STAFF_ID COLLATE SQL_LATIN1_GENERAL_CP1_CI_AS
        	
        	-- TRY TO GET DSS PROVIDER ID MATCH UP
        	LEFT OUTER JOIN smsdss.pract_dim_v AS G
        	ON REPLACE(E.RESOURCE_ID, '-', '') = G.SRC_PRACT_NO COLLATE SQL_Latin1_General_CP1_CI_AS
        		AND G.orgz_cd = 'S0X0'
        
        	WHERE (
        		A.DELETE_FLAG IS NULL
        		OR 
        		(
        			A.DELETE_FLAG = ''
        			OR
        			A.DELETE_FLAG = 'Z'
        		)
        	)
        	AND A.START_DATE >= @START
        	AND A.START_DATE < @END
        	AND RIGHT(C.FACILITY_ACCOUNT_NO, 1) != 'J'
          "
      )
    ) %>%
      as_tibble() %>%
      clean_names() %>%
      mutate(md_id = case_when(
        is.na(dss_crosswalk_id) ~ dss_src_pract_no_a
        , TRUE ~ dss_crosswalk_id
        ))
    
    return(query)
}

# Save Functions ----------------------------------------------------------

function_names <- c(
    "db_connect",
    "db_disconnect",
    "ip_orsos_rm_tbl"
)

dump(
    list = function_names
    , file = "S:/Global Finance/1 REVENUE CYCLE/Steve Sanderson II/Code/R/Functions/IP_ASU_Productivity/ip_asu_functions.R"
)