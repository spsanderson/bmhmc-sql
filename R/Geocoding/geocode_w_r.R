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
        "Coult not get record for: "
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
# Loop through the addresses to get the latitude and longitude of each address and add it to the
# origAddress data frame in new columns lat and lon
# Google requires an API key and it is paid
# for(i in 1:nrow(origAddress)) {
#   print(paste("Working on geocoding:", origAddress$FullAddress[i]))
#   result <- geocode(
#     origAddress$FullAddress[i]
#     , output = "latlon"
#     , source = "google"
#     )
#   origAddress$lon[i] <- as.numeric(result[1])
#   origAddress$lat[i] <- as.numeric(result[2])
# }

# since the map api sucks you may need to run the below a few times
# for(i in 1:nrow(origAddress)){
#   if(is.na(origAddress[i,'lon'])){
#     print(paste("Working on geocoding:"
#       , origAddress$FullAddress[i]
#       , "there are: "
#       , geocodeQueryCheck()
#       , " geocding queries left"
#       )
#     )
#     result <- geocode(
#       origAddress$FullAddress[i]
#       , output = "latlon"
#       , source = "dsk"
#       )
#     origAddress$lon[i] <- as.numeric(result[1])
#     origAddress$lat[i] <- as.numeric(result[2])
#     #origAddress$geoAddress <- as.character(result[3])
#   } else {
#     print("Trying next record...")
#   }
# }

# Write a CSV file containing origAddress to the working directory
# Clean up origAddress file if lat and/or lon are missing
geocoded <- origAddress %>%
  dplyr::filter(
    origAddress$lat != "" | origAddress$lon != ""
  )
write.csv(geocoded, "geocoded_addresses.csv", row.names=FALSE)
