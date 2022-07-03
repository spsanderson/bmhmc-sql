inr_glucose_query <- function() {
  
  # * DB Connect ----
  db_conn = db_connect()
  
  # * Query ----
  query <- DBI::dbGetQuery(
    conn = db_conn,
    statement = base::paste0(
      "
      DECLARE @TODAY AS DATE;
      SET @TODAY = GETDATE();
      
      SELECT A.episode_no,
      b.med_rec_no,
      a.coll_dtime,
      a.obsv_cd,
      [disp_val] = CASE 
      		WHEN CAST(a.val_no AS VARCHAR) IS NULL
      			THEN CAST(LEFT(SubString(a.dsply_val, PatIndex('%[0-9.-]%', a.dsply_val), len(a.dsply_val) - PatIndex('%[0-9.-]%', a.dsply_val) + 1), PatIndex('%[^0-9.-]%', SubString(a.dsply_val, PatIndex('%[0-9.-]%', a.dsply_val), len(a.dsply_val) - PatIndex('%[0-9.-]%', a.dsply_val) + 1))) AS varchar)
      		ELSE CAST(A.VAL_NO AS varchar)
      		END
      FROM smsmir.mir_sr_obsv_new AS A
      LEFT JOIN SMSDSS.BMH_PLM_PTACCT_V AS B ON A.episode_no = B.PtNo_Num
      WHERE (
        obsv_cd = '2012'
        OR (
          obsv_cd_name LIKE '%GLUCOSE%'
          AND dsply_val NOT LIKE 'yes%'
          AND dsply_val NOT LIKE 'out%'
          AND dsply_val NOT LIKE 'name%'
          AND dsply_val NOT LIKE 'no%'
          AND dsply_val NOT LIKE 'test%'
          AND dsply_val NOT LIKE 'call%'
          AND dsply_val NOT LIKE 'fing%'
          AND dsply_val NOT LIKE 'qns%'
          AND dsply_val NOT LIKE 'see%'
        )
      )
      AND COLL_DTIME >= DATEADD(MM, DATEDIFF(MM, 0, @TODAY) - 13, 0)
      AND COLL_DTIME < DATEADD(MM, DATEDIFF(MM, 0, @TODAY), 0)
      AND LEFT(EPISODE_NO, 1) = '1'
      AND B.Pt_Age >= 18
	    AND B.Days_Stay < 121
      AND NOT EXISTS (
		    SELECT 1
		    FROM smsmir.dx_grp AS ZZZ
		    WHERE ZZZ.dx_cd IN (
          -- PALLIATIVE CARE/HOSPICE
          'Z51.5', 'V66.7',
          -- ESRD
          'N18.6'
	      )
        AND LEFT(DX_CD_TYPE, 2) = 'DF'
		    AND ZZZ.pt_id = B.PT_NO
		    AND ZZZ.unit_seq_no = B.unit_seq_no
      )
      AND NOT EXISTS (
      	SELECT 1
      	FROM smsmir.dx_grp AS XXX
      	WHERE XXX.dx_cd BETWEEN 'COO.O' AND 'D09.9'
      	AND LEFT(DX_CD_TYPE, 2) = 'DA'
      	AND XXX.pt_id = B.PT_NO
      	AND XXX.unit_seq_no = B.unit_seq_no
      )
	   ;
    "
    )
  )
  
  # * DB Disconnect ----
  db_disconnect(.connection = db_conn)
  
  # * Return Data ----
  return(query)
  
}

diabetes_dx_cd_query <- function() {
  
  # * DB Connect ----
  db_conn = db_connect()
  
  # * Query ----
  query <- DBI::dbGetQuery(
    conn = db_conn,
    statement = base::paste0(
      "
      SELECT dx_cd,
      [diabetes_type_flag] = CASE
      	WHEN clasf_desc LIKE '%TYPE ii%'
      		THEN 'TYPE_2'
      	WHEN clasf_desc LIKE '%TYPE 2%'
      		THEN 'TYPE_2'
      	WHEN clasf_desc LIKE '%TYPE 1%'
      		THEN 'TYPE_1'
      	WHEN clasf_desc LIKE '%TYPE I%'
      		THEN 'TYPE_1'
      	ELSE 'OTHER'
      	END
      FROM SMSDSS.dx_cd_dim_v
      WHERE (
      	LEFT(DX_CD, 3) = '250'
      	OR LEFT(DX_CD, 3) = '249'
      	OR dx_cd between 'e10.1' and 'e10.9'
      	OR dx_cd BETWEEN 'E11.0' AND 'E11.9'
      	OR dx_cd BETWEEN 'E13.0' AND 'E13.9'
      )
      "
    )
  ) %>%
    tibble::as_tibble()
  
  # * DB Disconnect ----
  db_disconnect(.connection = db_conn)
  
  # * Return Data ----
  return(query)
  
}

distinct_mrn_query <- function() {
  
  # * DB Connect ----
  db_conn = db_connect()
  
  # * Query ----
  query <- DBI::dbGetQuery(
    conn = db_conn,
    statement = base::paste0(
      "
      SELECT DISTINCT Med_Rec_No,
      PtNo_Num,
      Pt_No
      FROM smsdss.bmh_plm_PtAcct_V
      "
    )
  ) %>%
    tibble::as_tibble() %>%
    dplyr::mutate(PtNo_Num = stringr::str_squish(PtNo_Num)) %>%
    dplyr::mutate(Pt_No = stringr::str_squish(Pt_No)) %>%
    dplyr::filter(PtNo_Num %in% data_tbl$episode_no) %>%
    dplyr::filter(!is.na(Med_Rec_No))
  
  # * DB Disconnect ----
  db_disconnect(.connection = db_conn)
  
  # * Return Data ----
  return(query)
  
}
  
diabetes_query <- function() {
  
  # * DB Connect ----
  db_conn = db_connect()
  
  dx_cd_tbl <- diabetes_dx_cd_query()
  mrn_tbl   <- distinct_mrn_query()
  
  # * Query ----
  query <- DBI::dbGetQuery(
    conn = db_conn,
    statement = base::paste0(
      "
      SELECT DISTINCT B.Med_Rec_No,
      [episode_no] = SUBSTRING(a.pt_id, 5, 8),
      LTRIM(RTRIM(a.dx_cd)) AS [dx_cd]
      FROM smsmir.dx_grp AS A
      INNER JOIN smsdss.bmh_plm_ptacct_v AS B ON A.pt_id = B.pt_no
      WHERE LEFT(a.dx_cd_type, 2) = 'DF'
      "
    )
  ) %>%
    tibble::as_tibble() %>%
    dplyr::filter(Med_Rec_No %in% mrn_tbl$Med_Rec_No) %>%
    dplyr::filter(dx_cd %in% dx_cd_tbl$dx_cd) %>%
    dplyr::inner_join(dx_cd_tbl, by = c("dx_cd"="dx_cd")) %>%
    dplyr::distinct(Med_Rec_No, diabetes_type_flag)
  
  # * DB Disconnect ----
  db_disconnect(.connection = db_conn)
  
  # * Return Data ----
  return(query)
  
}

insulin_drip_query <- function() {
  
  # * DB Connect ----
  db_conn = db_connect()
  
  # * Query ----
  query <- DBI::dbGetQuery(
    conn = db_conn,
    statement = base::paste0(
      "
      SELECT SUBSTRING(pt_id, 5, 8) AS [episode_no]
      FROM smsmir.actv
      WHERE actv_cd = '00329607'
      GROUP BY pt_id
      "
    )
  ) %>%
    tibble::as_tibble()
  
  # * DB Disconnect ----
  LICHospitalR::db_disconnect(.connection = db_conn)
  
  # * Return Data ----
  return(query)
  
}

insulin_warfarin_query <- function() {
  
  # * DB Connect ----
  db_conn = db_connect()
  
  # * Query ----
  query <- DBI::dbGetQuery(
    conn = db_conn,
    statement = base::paste0(
      "
      DECLARE @TODAY AS DATE;
      SET @TODAY = GETDATE();
      
      SELECT PV.PATIENTACCOUNTID,
      	PV.VISITSTARTDATETIME,
      	PV.PATIENTLOCATIONNAME,
      	PV.PATIENTREASONFORSEEKINGHC,
      	PV.FINANCIALCLASS,
      	PV.LATESTBEDNAME,
      	HO.PatientVisit_OID,
      	HO.OrderID,
      	HO.OrderAbbreviation,
      	HO.CreationTime AS [Order_Creation_DTime],
      	HO.OrderDescAsWritten,
      	HO.OrderStatusModifier,
      	HO.OrderStatusModifierCode,
      	HO.CommonDefName,
      	MA.ActualDateTime,
      	MA.ActualDose
      FROM smsmir.sc_PatientVisit AS PV
      INNER JOIN smsmir.sc_Order AS HO ON PV.OBJECTID = HO.PATIENTVISIT_OID
      INNER JOIN smsmir.sc_MedDispOrder AS MO ON HO.ObjectID = MO.InternalID
      INNER JOIN smsmir.sc_MedAdministration AS MA ON PV.OBJECTID = MA.Visit_oid
      	AND MO.ObjectID = MA.MedDispOrder_oid
      	AND MA.AdministrationStatus = '1'
      WHERE HO.CommonDefName IN (
      		'warfarinMED',
      		'insulinMED','INSULIN LISPRO','InsulinDetMED'
      	)
      	AND PV.VisitEndDateTime >= DATEADD(MM, DATEDIFF(MM, 0, @TODAY) - 16, 0)
      	AND PV.VisitEndDateTime < @TODAY
      ORDER BY PV.PatientAccountID,
      	MA.ActualDateTime
      "
    )
  ) %>%
    tibble::as_tibble() %>%
    dplyr::mutate(dplyr::across(where(is.character), stringr::str_squish))
  
  # * DB Disconnect ----
  LICHospitalR::db_disconnect(.connection = db_conn)
  
  # * Return Data ----
  return(query)
  
}
