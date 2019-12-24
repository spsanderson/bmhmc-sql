# Geocoding a csv column of "addresses" in R
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
  "readxl",
  
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

# Get File ####
fileToLoad <- "S:\\Global Finance\\1 REVENUE CYCLE\\Steve Sanderson II\\ALOS_Readmit_Mapping\\daily_geocode_file.xlsx"

# Read in the CSV data and store it in a variable 
origAddress <- read_xlsx(fileToLoad, col_names = TRUE)

# Initialize the data frame
geocoded <- data.frame(stringsAsFactors = FALSE)

# Geocode File ####
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

# Clean env ----
rm(list = ls())