# Geocoding a csv column of "addresses" in R
# Lib Load ####
library(readxl)
library(tmaptools)

# Get File ####
#fileToLoad <- file.choose(new = TRUE)
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

# Write a CSV file containing origAddress to the working directory
# Clean up origAddress file if lat and/or lon are missing
geocoded <- origAddress %>%
  dplyr::filter(
    origAddress$lat != "" | origAddress$lon != ""
  ) %>%
  dplyr::select(Encounter, FullAddress,ZipCode, lon, lat)

write.csv(geocoded, "geocoded_addresses.csv", row.names=FALSE)

origAddress %>%
  dplyr::filter(
    is.na(origAddress$lat)
  )

rm(list = ls())