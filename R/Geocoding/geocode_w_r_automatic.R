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
    Server = "BMH-HIDB",
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
        , Dsch_Date >= '2019-01-01'
        , Plm_Pt_Acct_Type == "I"
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
        , keep = T
    ) 

add_geo <- a %>%
    left_join(
        geo_add
        , by = c(
            "PtNo_Num" = "Encounter"
        )
        , keep = T
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
df <- tibble() # Necessary?
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

# Save missing to clean and use orig geocode script
origAddress %>%
  filter(is.na(lat)) %>%
  select(Encounter, FullAddress, ZipCode, PartialAddress) %>%
  write_xlsx("daily_geocode_file.xlsx", col_names = T)

# Clean env ----
rm(list = ls())
