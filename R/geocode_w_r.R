# Geocoding a csv column of "addresses" in R

#load ggmap
library(ggmap)
library(readxl)

# Select the file from the file chooser
fileToLoad <- file.choose(new = TRUE)

# Read in the CSV data and store it in a variable 
origAddress <- read_xlsx(fileToLoad, col_names = TRUE)

# Initialize the data frame
geocoded <- data.frame(stringsAsFactors = FALSE)

# Loop through the addresses to get the latitude and longitude of each address and add it to the
# origAddress data frame in new columns lat and lon
for(i in 1:nrow(origAddress)) {
  print(paste("Working on geocoding:", origAddress$FullAddress[i]))
  # changed to dsk as google map api's keeps returning over_query_limit
  result <- geocode(origAddress$FullAddress[i], output = "latlon", source = "google")
  origAddress$lon[i] <- as.numeric(result[1])
  origAddress$lat[i] <- as.numeric(result[2])
  #origAddress$geoAddress[i] <- as.character(result[3])
  #Sys.sleep(1)
}

# since the map api sucks you may need to run the below a few times
for(i in 1:nrow(origAddress)){
  if(is.na(origAddress[i,4])){
    print(paste("Working on geocoding:"
      , origAddress$FullAddress[i]
      , "there are: "
      , geocodeQueryCheck()
      , " geocding queries left"
      )
    )
    result <- geocode(origAddress$FullAddress[i], output = "latlon", source = "dsk")
    origAddress$lon[i] <- as.numeric(result[1])
    origAddress$lat[i] <- as.numeric(result[2])
    #origAddress$geoAddress <- as.character(result[3])
  } else {
    print("Trying next record...")
  }
}

# Write a CSV file containing origAddress to the working directory
write.csv(origAddress, "geocoded_addresses.csv", row.names=FALSE)
