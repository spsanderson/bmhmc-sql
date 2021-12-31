# Lib Load ----
if(!require(pacman)) install.packages("pacman")

pacman::p_load(
  # DB Packages
  "DBI",
  "odbc",
  
  # Tidy
  "tidyverse",
  "dbplyr",
  "writexl",
  
  # Mapping Tools
  "tmaptools"
)

# Connection Obj ----
con <- dbConnect(
  odbc(),
  Driver = "SQL Server",
  Server = "LI-HIDB",
  Database = "SMSPHDSSS0X0",
  Trusted_Connection = "TRUE"
)

# Tables ----
pav <- dplyr::tbl(
  con
  , in_schema(
    "smsdss"
    , "BMH_Plm_PtAcct_V"
  )
) %>%
  filter(
    tot_chg_amt > 0
    , Dsch_Date >= '2021-02-01'
    , Dsch_Date < '2021-03-01'
    , Plm_Pt_Acct_Type != "I"
  ) %>%
  select(
    Plm_Pt_Acct_Type
    , tot_chg_amt
    , PtNo_Num
    , Pt_No
    , Dsch_Date
    , from_file_ind
  )

pdv <- tbl(
  con
  , in_schema(
    "smsdss"
    , "c_patient_demos_v"
  )
)

# Query ----
geo_add <- tbl(
  con
  , in_schema(
    "smsdss"
    , "c_geocoded_address"
  )
)

a <- pdv %>%
  left_join(
    pav
    , by = c(
      "pt_id"="Pt_No"
      , "from_file_ind" = "from_file_ind"
    )
    #, keep = T
  ) 

add_geo <- a %>%
  left_join(
    geo_add
    , by = c(
      "PtNo_Num" = "Encounter"
    )
    #, keep = T
  ) %>% 
  select(
    PtNo_Num
    , addr_line1
    , Pt_Addr_City
    , Pt_Addr_State
    , Pt_Addr_Zip
    , ZipCode
    , Plm_Pt_Acct_Type
    , tot_chg_amt
    , Dsch_Date
  ) %>%
  filter(
    !is.na(Pt_Addr_City)
    , !is.na(addr_line1)
    , !is.na(Pt_Addr_State)
    , !is.na(Pt_Addr_Zip)
    , !is.na(Plm_Pt_Acct_Type)
    , !is.na(tot_chg_amt)
    , !is.na(Dsch_Date)
    , addr_line1 != '101 Hospital Rd'
    , is.na(ZipCode)
  )

# Make df ----
df <- add_geo %>% 
  as_tibble() %>%
  filter(str_sub(PtNo_Num, 1, 1) != 2)

origAddress <-  df %>%
  mutate(
    FullAddress = str_c(
      addr_line1
      , Pt_Addr_City
      , Pt_Addr_State
      , Pt_Addr_Zip
      , sep = ', '
    )
    , PartialAddress = str_c(
      Pt_Addr_City
      , Pt_Addr_State
      , Pt_Addr_Zip
      , sep = ', '
    )
  ) %>%
  select(
    PtNo_Num
    , FullAddress
    , Pt_Addr_Zip
    , PartialAddress
  ) %>%
  rename(
    Encounter = PtNo_Num
    , ZipCode = Pt_Addr_Zip
  )

# Geocode File ####
# Initialize the data frame
geocoded <- data.frame(stringsAsFactors = FALSE)

# First Loop ----
for(i in 1:nrow(origAddress)) {
  print(paste("Working on geocoding: ", origAddress$FullAddress[i]))
  if(
    is.null(
      suppressWarnings(
        suppressMessages(
          geocode_OSM(
            origAddress$FullAddress[i]
          )
        )
      )
    )
  ) {
    print(
      paste(
        "Could not get record for: "
        , origAddress$FullAddress[i]
        , ". Trying next record..."
      )
    )
    origAddress$lon[i] <- ''
    origAddress$lat[i] <- ''
  } else {
    print(
      paste(
        "Getting Result For: "
        , origAddress$FullAddress[i]
      )
    )
    result <- geocode_OSM(
      origAddress$FullAddress[i]
      , return.first.only = T
      , as.data.frame = T
    )
    origAddress$lon[i] <- as.numeric(result[3])
    origAddress$lat[i] <- as.numeric(result[2])
  }
}

# Clean known bad addresses ----
origAddress <- origAddress %>%
  as_tibble() %>%
  mutate(PartialAddress = case_when(
    str_detect(PartialAddress, "PORT JEFF STA")           ~ "PORT JEFFERSON STATION, NY, 11776"
    , str_detect(PartialAddress, "PORT JFFERSON STATION") ~ "PORT JEFFERSON STATION, NY, 11776"
    , str_detect(PartialAddress, "EPATCHOGUE")            ~ "EAST PATCHOGUE, NY, 11772"
    , str_detect(PartialAddress, "E PATCHOGUE")           ~ "EAST PATCHOGUE, NY, 11772"
    , str_detect(PartialAddress, "EAST PATCHOUGE")        ~ "EAST PATCHOGUE, NY, 11772"
    , str_detect(PartialAddress, "PATCHOQUE")             ~ "PATCHOGUE, NY, 11772"
    , str_detect(PartialAddress, "PATCHGOUE")             ~ "PATCHOGUE, NY, 11772"
    , str_detect(PartialAddress, "HAUPPAGE")              ~ "HAUPPAUGE, NY, 11788"
    , str_detect(PartialAddress, "HOLSTVILLE")            ~ "HOLTSVILLE, NY, 11742"
    , str_detect(PartialAddress, "HOLTSVILE")             ~ "HOLTSVILLE, NY, 11742"
    , str_detect(PartialAddress, "LAKE RONKONOMA")        ~ "LAKE RONKONKOMA, NY, 11779"
    , str_detect(PartialAddress, "LAKE RONKOMONA")        ~ "LAKE RONKONKOMA, NY, 11779"
    , str_detect(PartialAddress, "RONKONOKOMA")           ~ "RONKONKOMA, NY, 11779"
    , str_detect(PartialAddress, "SHRILEY")               ~ "SHIRLEY, NY, 11967"
    , str_detect(PartialAddress, "CTR MORICHS")           ~ "CENTER MORICHES, NY, 11934"
    , str_detect(PartialAddress, "COPIAGE")               ~ "COPIAGUE, NY, 11726"
    , str_detect(PartialAddress, "COPAIGUE")              ~ "COPIAGUE, NY, 11726"
    , str_detect(PartialAddress, "BELPORT")               ~ "BELLPORT, NY, 11713"
    , str_detect(PartialAddress, "FAR ROCKAWY")           ~ "FAR ROCKAWAY, NY, 11694"
    , str_detect(PartialAddress, "MASTICE BEACH")         ~ "MASTIC BEACH, NY, 11951"
    , str_detect(PartialAddress, "MASTCIC NEACHJ")        ~ "MASTIC BEACH, NY, 11951"
    , str_detect(PartialAddress, "BELLLPORT")             ~ "BELLPORT, NY, 11713"
    , str_detect(PartialAddress, "NESCONSETT")            ~ "NESCONSET, NY, 11767"
    , str_detect(PartialAddress, "YAHPANK")               ~ "YAPHANK, NY, 11980"
    , str_detect(PartialAddress, "ISLIP TERRANCE")        ~ "ISLIP TERRACE, 11752"
    , str_detect(PartialAddress, "PORT SAT LUCY, FL")     ~ "PORT SAINT LUCIE, FL, 34952"
    , str_detect(PartialAddress, "PATCHOUGE")             ~ "PATCHOGUE, NY, 11772"
    , str_detect(PartialAddress, "SHILREY, NY")           ~ "SHIRLEY, NY, 11967"
    , str_detect(PartialAddress, "EAST PATCHGUE, NY")     ~ "EAST PATCHOGUE, NY, 11772"
    , str_detect(PartialAddress, "AMITY HABOR, NY")       ~ "AMITY HARBOR, NY, 11701"
    , str_detect(PartialAddress, "LAKE RONKONKONA, NY")   ~ "LAKE RONKONKOMA, NY, 11779"
    , str_detect(PartialAddress, "MIDDLE ISLNAD, NY")     ~ "MIDDLE ISLAND, NY, 11953"
    , str_detect(PartialAddress, "ROCKVILLE CENTR, NY")  ~ "ROCKVILLE CENTER, NY, 11570"
    , str_detect(PartialAddress, "FARMIINGVILLE, NY")     ~ "FARMINGVILLE, NY, 11738"
    , str_detect(PartialAddress, "MI SIANI, NY")          ~ "MOUNT SINAI, NY, 11766"
    , str_detect(PartialAddress, "PATHOGUE, NY")          ~ "PATCHOGUE, NY, 11772"
    , str_detect(PartialAddress, "YHAPANK, NY")           ~ "YAPHANK, NY, 11980"
    , str_detect(PartialAddress, "SHIRELY, NY")           ~ "SHIRLEY, NY, 11967"
    , str_detect(PartialAddress, "EDLEBOROUGH, MA")       ~ "ATTLEBORO, MA, 02703"
    , str_detect(PartialAddress, "CENTERREACH, NY")       ~ "CENTEREACH, NY, 11720"
    , str_detect(PartialAddress, "BBROOKHAVEN, NY")       ~ "BROOKHAVEN, NY, 11719"
    , TRUE ~ PartialAddress
  ))

# Get Non Found Records ----
# Get all records that were not found and geocode on city/town, state, zip
for(i in 1:nrow(origAddress)) {
  if(origAddress[i,'lon'] == ""){
    print(
      paste(
        "Working on geocoding:"
        , origAddress$PartialAddress[i]
      )
    )
    result <- tryCatch(
      suppressWarnings(
        geocode_OSM(
          origAddress$PartialAddress[i]
          , return.first.only = T
          , as.data.frame = T
        )
      )
      , warning = function(w) {
        print("Can't get record"); geocode_OSM(origAddress$PartialAddress[i])
      }
      , error = function(e) {
        print("geocode_OSM() function failed to produce result");
        NaN
      }
    )
    origAddress$lon[i] <- as.numeric(result[3])
    origAddress$lat[i] <- as.numeric(result[2])
  } else {
    print("Trying next record...")
  }
}

# Clean up Records ----
geocoded <- origAddress %>%
  filter(
    origAddress$lat != "" | origAddress$lon != ""
  ) %>%
  select(Encounter, FullAddress,ZipCode, lon, lat)

# Missing? ----
origAddress %>%
  filter(is.na(lat))

# Insert into tbl ----
dbWriteTable(
  con
  , Id(
    schema = "smsdss"
    , table = "c_geocoded_address"
  )
  , geocoded
  , append = T
)

# Delete Dupes ----
dbGetQuery(
  conn = con
  , paste0(
    "
    DELETE X
    FROM (
    	SELECT Encounter
    	, FullAddress
    	, ZipCode
    	, lon
    	, lat
    	, RN = ROW_NUMBER() OVER(
    		PARTITION BY Encounter
    	, FullAddress
    	, ZipCode
    	, lon
    	, lat
    	ORDER BY Encounter
    	, FullAddress
    	, ZipCode
    	, lon
    	, lat
    	)
    	FROM SMSDSS.c_geocoded_address
    ) X
    WHERE X.RN > 1
    "
  )
)

# DB Disconnect ----
dbDisconnect(conn = con)

# Save missing ----
origAddress %>%
  filter(is.na(lat) | lat == "") %>%
  select(Encounter, FullAddress, ZipCode, PartialAddress) %>%
  write_xlsx(
    path = "S:\\Global Finance\\1 REVENUE CYCLE\\Steve Sanderson II\\ALOS_Readmit_Mapping\\daily_geocode_file.xlsx"
    , col_names = T
  )

# Clean env ----
rm(list = ls())
