# Lib Load ----
library(tidyverse)
library(readxl)
library(lubridate)
library(LICHospitalR)
library(DBI)

# File path ----
input_path <- "I://Global Finance//1 REVENUE CYCLE//Steve Sanderson II//Code//R//beaker_reconcilliation//input//"
output_path <- "I://Global Finance//1 REVENUE CYCLE//Steve Sanderson II//Code//R//beaker_reconcilliation//output//"

# Process the Text File ----
log_file_list <- dir(input_path, pattern = "\\.log$", full.names = TRUE)

# Read log files
log_files <- log_file_list %>%
  map(read_log) %>%
  map(as_tibble)

# Clean File Names
log_file_names <- log_file_list %>%
  str_remove(input_path) %>%
  str_replace(pattern = ".log", replacement = "")

# Name the list files
names(log_files) <- log_file_names

# Process the list files
# function to process files
process_text_file <- function(.data){
  
  txt_file <- .data
  number_of_columns <- ncol(txt_file)
  
  txt_file_processed <- txt_file %>%
    filter(!X1 == "") %>%
    filter(!X1 == "--------") %>%
    slice(3:n()) %>%
    set_names(
      "ptno_num", str_c("service_cd_", 1:(number_of_columns - 1))
    ) %>%
    pivot_longer(cols = -ptno_num) %>%
    filter(!is.na(value)) %>%
    filter(!value == "") %>%
    mutate(across(everything(), str_squish))
  
  return(txt_file_processed)
}

# Log File Tibble ----
log_files_processed_tbl <- log_files %>%
  map(.f = ~ .x %>% process_text_file()) %>%
  map_df(as_tibble, .id = "source") %>%
  filter(ptno_num != "Log") %>%
  filter(nchar(value) == 8)
  
# Process the CSV File ----
csv_file_list <- dir(input_path, pattern = "\\.CSV$", full.names = TRUE)
flow_file_list <- dir(input_path, pattern = "\\PRDLICH_FLOW", full.names = TRUE)
surg_file_list <- dir(input_path, pattern = "\\PRDLICH_SURG", full.names = TRUE)

# Read log files
flow_files <- flow_file_list %>%
  map(.f = ~ .x %>% read_csv(col_names = FALSE)) %>%
  map(as_tibble)

surg_files <- surg_file_list %>%
  map(.f = ~ .x %>% read_csv(col_names = FALSE)) %>%
  map(as_tibble)

# Clean File Names
flow_file_names <- flow_file_list %>%
  str_remove(input_path) %>%
  str_replace(pattern = ".CSV", replacement = "")

surg_file_names <- surg_file_list %>%
  str_remove(input_path) %>%
  str_replace(pattern = ".CSV", replacement = "")

# Name the list files
names(flow_files) <- flow_file_names
names(surg_files) <- surg_file_names

# Compact lists
flow_files <- flow_files %>% compact()
surg_files <- surg_files %>% compact()

# function to process the CSV file
process_surg_file <- function(.data){
  
  csv_file <- .data
  
  csv_file_processed <- csv_file %>%
    mutate(X3 = mdy(X3)) %>%
    select(X2, X3, everything()) %>%
    mutate(X2 = substr(X2, 21, 29)) %>%
    mutate(X1 = str_replace_all(X1, " ", ",")) %>%
    separate(
      col = X1,
      into = str_c("name_", 1:20),
      sep = "[,]"
    ) %>%
    pivot_longer(
      cols = -c(X2, X3)
    ) %>%
    filter(!is.na(value)) %>%
    select(-name) %>%
    filter(!value %in% c("CPT:","QTY:")) %>%
    mutate(name = rep(c("CPT","QTY"), length.out = n())) %>%
    group_by(X2, name) %>%
    mutate(rn = row_number()) %>%
    ungroup() %>%
    pivot_wider(
      id_cols = c(rn, X2, X3),
      names_from = name,
      values_from = value
    ) %>%
    select(-rn) %>%
    set_names("ptno_num","actv_date","cpt","qty")
  
  return(csv_file_processed)
}

process_flow_file <-  function(.data){
  
  csv_file <- .data
  
  csv_file_processed <- csv_file %>%
    select(1:5) %>%
    mutate(X1 = mdy(X1)) %>%
    select(X2, X3, everything()) %>%
    mutate(X2 = substr(X2, 21, 29)) %>%
    select(X1, X2, everything()) %>%
    mutate(X3 = str_replace_all(X3, " ", ",")) %>%
    mutate(X4 = str_replace(X4, "CPT ", "CPT: ") %>%
             str_c(" ", X5) %>%
             str_replace_all(" ", ",")
    ) %>%
    select(-X5) %>%
    separate(
      col = X3,
      into = str_c("name_a", 1:20),
      sep = "[,]"
    ) %>%
    separate(
      col = X4,
      into = str_c("name_b", 1:20),
      sep = "[,]"
    ) %>% 
    pivot_longer(
      cols = -c(X1, X2)
    ) %>%
    filter(!is.na(value)) %>%
    filter(!value %in% c("","CPT","QTY")) %>%
    select(-name) %>%
    filter(!value %in% c("CPT:","QTY:")) %>%
    mutate(name = rep(c("CPT","QTY"), length.out = n())) %>%
    group_by(X2, name) %>%
    mutate(rn = row_number()) %>%
    ungroup() %>%
    pivot_wider(
      id_cols = c(rn, X1, X2),
      names_from = name,
      values_from = value
    ) %>%
    select(X2, X1, CPT, QTY) %>%
    set_names("ptno_num","actv_date","cpt","qty")
  
  return(csv_file_processed)
}

# CSV File Tibble ----
surg_files_processed_tbl <- surg_files %>%
  map(.f = ~ .x %>% process_surg_file()) %>%
  map_df(as_tibble, .id = "source") %>%
  filter(ptno_num != "")

flow_files_processed_tbl <- flow_files %>%
  map(.f = ~ .x %>% process_flow_file()) %>%
  map_df(as_tibble, .id = "source") 
#  filter(ptno_num != "")

# Get DSS Data ----
accounts_tbl <- union_all(
  x = surg_files_processed_tbl,
  y = flow_files_processed_tbl
) %>%
  distinct(ptno_num) %>%
  mutate(ptno_num = str_remove_all(ptno_num, ','))

db_con <- db_connect()

# send accts to dss
dbWriteTable(
  conn = db_con,
  Id(
    schema = "smsdss",
    table = "c_beaker_recon_tbl"
  ),
  accounts_tbl,
  overwrite = TRUE
)

query <- dbGetQuery(
  conn = db_con,
  statement = paste0(
    "
    SELECT substring(a.pt_id, 5, 8) AS [ptno_num],
        a.actv_cd,
        a.actv_tot_qty,
        a.chg_tot_amt,
        CAST(a.actv_dtime AS DATE) AS [actv_date],
        CAST(a.actv_entry_date AS DATE) AS [actv_entry_date],
        b.clasf_cd
    FROM smsmir.actv as a
    LEFT OUTER JOIN smsmir.mir_actv_proc_seg_xref AS b ON a.actv_cd = b.actv_cd
        AND b.proc_pyr_ind = 'H'
    INNER JOIN smsdss.c_beaker_recon_tbl AS C ON substring(a.pt_id, 5, 8) = C.ptno_num
    WHERE LEFT(A.actv_cd, 3) = '004'
    	AND A.chg_tot_amt != 0
      AND LEFT(B.clasf_cd, 2) = '88'
    "
  )
) %>%
  as_tibble()

db_disconnect(db_con)

# Fix CPT 88315 since it's not in our charge master
query <- query %>%
  mutate(clasf_cd = case_when(
    clasf_cd == "84999" ~ "88315",
    TRUE ~ clasf_cd
  ))

# Reconciliation ----
csv_files_processed_tbl <- union_all(
  x = surg_files_processed_tbl,
  y = flow_files_processed_tbl
) %>%
  mutate(across(everything(), as.character))

csv_summary_tbl <- csv_files_processed_tbl %>%
  group_by(ptno_num, actv_date, cpt) %>%
  summarise(qty = sum(as.numeric(qty))) %>%
  ungroup() %>%
  mutate(across(everything(), as.character))

query_summary_tbl <- query %>%
  select(ptno_num, actv_date, clasf_cd, actv_tot_qty) %>%
  group_by(ptno_num, actv_date, clasf_cd) %>%
  summarise(actv_tot_qty = sum(actv_tot_qty)) %>%
  mutate(actv_date = ymd(actv_date)) %>%
  ungroup() %>%
  mutate(across(everything(), as.character))

# Error reporting ----
## Make directory if not exists ----
# file date time
file_date_time <- Sys.time() %>% 
  str_replace_all(pattern = "[- ]", "_") %>% 
  str_replace_all(pattern = ":","")

folder_name <- paste0("processed_files_", file_date_time)
full_output_path <- paste0(output_path, folder_name, "//")
if(!dir.exists(full_output_path)){
  print("File Folder Path Does Not Exists...Creating")
  dir.create(path = full_output_path)
}

## Report File Path ----
report_file_path <- paste0(full_output_path, "outputs//")
if(!dir.exists(report_file_path)){
  print("Creating folder")
  dir.create(path = report_file_path)
}
input_files_path <- paste0(full_output_path, "inputs//")
if(!dir.exists(input_files_path)){
  print("Creating folder")
  dir.create(path = input_files_path)
}

## Accounts on the beaker file but not in DSS ----
accounts_not_in_dss <- setdiff(csv_files_processed_tbl$ptno_num, query$ptno_num)

csv_files_processed_tbl %>%
  filter(ptno_num %in% accounts_not_in_dss) %>%
  write_csv(
    file = paste0(
      report_file_path, 
      "beaker_not_in_dss_",
      file_date_time,
      ".csv"
    )
  )

## Find records with quantities that don't match ----
summary_joined_tbl <- inner_join(
  x = csv_summary_tbl,
  y = query_summary_tbl,
  by = c("ptno_num"="ptno_num","cpt"="clasf_cd", "actv_date"="actv_date"),
  keep = TRUE
) %>%
  select(-ptno_num.y) %>%
  set_names("ptno_num","actv_date","cpt","beaker_qty","dss_actv_date","clasf_cd",
            "soarian_qty")

summary_joined_tbl %>%
  filter(beaker_qty != soarian_qty) %>%
  distinct() %>%
  write_csv(
    file = paste0(
      report_file_path, 
      "beaker_summarised_dss_qty_mismatch_",
      file_date_time,
      ".csv"
    )
  )

joined_tbl <- inner_join(
  # x = csv_summary_tbl,
  # y = query_summary_tbl,
  x = csv_files_processed_tbl,
  y = query,
  by = c("ptno_num"="ptno_num","cpt"="clasf_cd", "actv_date"="actv_date"),
  keep = TRUE
) %>%
  select(
    source,ptno_num.x, actv_date.x, cpt, qty, actv_date.y, clasf_cd, actv_tot_qty,
    actv_entry_date
  ) %>% 
  set_names(
    "source",
    "ptno_num","actv_date","cpt","beaker_qty","dss_actv_date","clasf_cd",
    "soarian_qty","soarian_actv_entry_date"
  ) 

joined_tbl %>%
  filter(beaker_qty != soarian_qty) %>% 
  distinct() %>%
  write_csv(
    file = paste0(
      report_file_path, 
      "beaker_dss_qty_mismatch_",
      file_date_time,
      ".csv"
    )
  )

# Copy input files to output folder path ----
## Emue Log Files ----
file.copy(
  from = log_file_list,
  to = input_files_path
)

## Beaker Log Files ----
### Flow Files ----
file.copy(
  from = flow_file_list,
    to = input_files_path
)

### Surg Files ----
file.copy(
  from = surg_file_list,
  to = input_files_path
)

# Remove processed files ----
file.remove(log_file_list)
file.remove(flow_file_list)
file.remove(surg_file_list)
