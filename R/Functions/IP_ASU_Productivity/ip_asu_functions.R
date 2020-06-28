db_connect <-
function(){
    db_con <- dbConnect(
        odbc(),
        Driver = "SQL Server",
        Server = "BMH-HIDB",
        Database = "SMSPHDSSS0X0",
        Trusted_Connection = T
    )
    return(db_con)
}
db_disconnect <-
function(connection) {
    dbDisconnect(connection)
}
orsos_data_query <-
function() {
    query <- dbGetQuery(
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
      mutate_if(is.character, str_squish) %>%
      mutate(md_id = case_when(
        is.na(dss_crosswalk_id) ~ dss_src_pract_no_a
        , TRUE ~ dss_crosswalk_id
        ))
    
    db_disconnect(connection = db_connect())
    return(query)
}
amb_surg_activity_query <-
function() {
  query <- dbGetQuery(
    conn = db_connect()
    , statement = paste0(
      "
      SELECT pt_id
    	, SUM(actv_tot_qty) AS total_quantity
    	, SUM(chg_tot_amt)  AS total_charge
    
    	FROM smsmir.actv
    
    	WHERE actv_cd = '01800010'
    
    	GROUP BY pt_id
    
    	HAVING SUM(actv_tot_qty) > 0
    	AND SUM(chg_tot_amt) > 0
      "
    )
  ) %>%
    as_tibble() %>%
    clean_names() %>%
    mutate_if(is.character, str_squish) %>%
    mutate(encounter = str_sub(pt_id, 5, 13))
  
  db_disconnect(connection = db_connect())
  return(query)
}
or_time_query <-
function() {
  query <- dbGetQuery(
    conn = db_connect()
    , statement = paste0(
      "
      SELECT pt_id
    	, SUM(actv_tot_qty) AS total_quantity
    	, SUM(chg_tot_amt)  AS total_charge
    
    	FROM smsmir.actv
    
    	WHERE actv_cd IN (
    		'01800010', '00800011', '00800029', '00800037', '00800045', 
    		'00800052', '00800060', '00800078', '00800086', '00800094', 
    		'00800102', '00800110', '00800128', '00800136', '00800144', 
    		'00800151', '00800169', '00800177', '00800185', '00800193', 
    		'00800201', '00800219', '00800227', '00800235', '00800243', 
    		'00800250', '00800268', '00800276', '00800284', '00800292', 
    		'00800300', '00800318', '00800326'
    	)
    
    	GROUP BY pt_id
    
    	HAVING SUM(actv_tot_qty) > 0
    	AND SUM(chg_tot_amt) > 0
      "
    )
  ) %>%
    as_tibble() %>%
    clean_names() %>%
    mutate_if(is.character, str_squish) %>%
    mutate(encounter = str_sub(pt_id, 5, 13))
  
  db_disconnect(connection = db_connect())
  return(query)
}
rn_query <-
function() {
  
  orsos_tbl    <- orsos_data_query()
  amb_surg_tbl <- amb_surg_activity_query()
  or_time      <- or_time_query()
  
  data_tbl <- orsos_tbl %>% 
    left_join(amb_surg_tbl, by = c("dss_case_no" = "encounter")) %>% 
    select(-pt_id) %>% 
    rename(
      "tot_amb_surg_quantity" = "total_quantity"
      , "tot_amb_surg_chg" = "total_charge"
      ) %>% 
    left_join(or_time, by = c("dss_case_no" = "encounter")) %>% 
    select(-pt_id) %>% 
    rename(
      "total_or_quantity" = "total_quantity"
      , "total_or_chg" = "total_charge"
      ) %>%
    group_by(orsos_case_no) %>%
    mutate(rn = row_number()) %>%
    ungroup() %>%
    filter(rn == 1) %>%
    mutate(dss_case_no = as.character(dss_case_no))
  
  return(data_tbl)
}
pract_mstr_query <-
function(){
  
  data_tbl <- dbGetQuery(
    conn = db_connect()
    , statement = paste0(
      "
      SELECT A.pract_no
      , A.pract_rpt_name
      , A.spclty_cd1
      , B.spclty_cd_desc
      , B.med_staff_dept
      from smsmir.pract_mstr AS A
      LEFT JOIN smsdss.pract_spclty_mstr AS B
      ON A.spclty_cd1 = B.spclty_cd
      AND A.iss_orgz_cd = B.orgz_cd
      WHERE A.ISS_ORGZ_CD = 'S0X0'
      "
    )
  ) %>%
    as_tibble() %>%
    clean_names() %>%
    mutate_if(is.character, str_squish) %>%
    mutate(pract_rpt_name = str_to_title(pract_rpt_name))
  
  db_disconnect(connection = db_connect())
  return(data_tbl)
}
