# Geocoding a csv column of "addresses" in R
# Lib Load ----
if(!require(pacman)) install.packages("pacman")

pacman::p_load(
  # Tidy
  "tidyverse",
  "dbplyr",
  "writexl",
  "readxl",
  
  # Mapping Tools
  "tmaptools",
  "leaflet",
  "ggmap",
  "rgdal",
  "htmltools"
)

# Get File ####
fileToLoad <- file.choose(new = TRUE)

# Read in the CSV data and store it in a variable 
origAddress <- read_csv(fileToLoad, col_names = TRUE)

# Initialize the data frame
geocoded <- data.frame(stringsAsFactors = FALSE)

origAddress <- tribble(
  ~Label, ~Name, ~FullAddress,
  "1","Brookhaven Health Care Facility","801 Gazzola Dr, East Patchogue, NY 11772",
  "2","Bellhaven Center for Rehabiliation and Nursing Care","110 Beaver Dam Rd, Brookhaven, NY 11719",
  "3","Sunrise of Holbrook","320 Patchogue-Holbrook Rd, Holbrook, NY 11741",
  "4","Meford Multicare Center","3115 Horseblock Road, Medford, NY 11763",
  "5","Island Nursing and Rehab Center Inc.","5537 Expressway Drive North, Holtsville, NY 11742",
  "6","Good Samaritan Nursing Home","101 Elm Street, Sayville, NY 11782",
  "7","Affinity Skilled Living","305 Locust Ave, Oakdale, NY 11769",
  "8","Woodhaven Nursing Home","1360 NY 112, Port Jefferson Station, NY 11776",
  "9","Woodhaven Home For Adults","1350 NY 112, POrt Jefferson Station, NY 11776",
  "10","Nesconset Center for Nusring and Rehabilition","100 Southern Boulevard, Nesconset, NY 11767",
  "11","Luxor Nursing and Rehabilitation at Mills Pond","273 Moriches Rd, St James, NY 11780",
  "12","Waters Edge Rehab and Nursing Center at Port Jefferson","150 Dark Hollow Rd, Port Jefferson, NY 11777",
  "13","Smithtown Center For Rehabilitation and Nursing Care","391 N Country Rd, Smithtown, NY 11787",
  "14","Maria Gegina Residence","1725 Brentwood Rd, Brentwood, NY 11717",
  "15","Ross Center for Health and Rehabilitation","839 Suffolk Ave, Brentwood, NY 11717",
  "16","Brookside Multicare Nursing Center","7 NY 25A, Smithtown, NY 11787",
  "17","Sunrise Manor Center for Nursing","1325 Brentwood Rd, Bay Shore, NY 11706",
  "18","Westhampton Care Center","78 Old Country Rd, Westhampton, NY 11977",
  "19","Gurwin Jewish Nursing and Rehabilitation Center","68 Hauppauge Rd, Commack, NY 11725",
  "20","Berkshire Nursing Center","10 Berkshire Rd, West Babylon, NY 11704",
  "21","East Neck Nursing and Rehabilitation Center","134 Great East Neck Road, West Babylon, NY 11704",
  "22","Apex Rehabilitation and Healthcare","78 Birchwood Drive, South Huntington, NY 11746",
  "23","Huntington Hills Center For Health and Rehabilitation","400 South Service Road, Melville, NY 11747",
  "24","Hilaire Rehab and Nursing","9 Hilaire Dr, Huntington, NY 11743",
  "25","The Hamptons Center for Rehabilitation and Nursing","321 North Sea Road, Southampton, NY 11968",
  "26","Peconic Landing","1500 Brecknock Rd, Greenport, NY 11944",
  "27","Luxor Nursing and Rehabilitation at Sayville","300 Broadway Ave, Sayville, NY 11784",
  "28","Suffolk Center for Rehabilitation and Nursing","25 Swan Lake Drive, Patchogue, NY 11772",
  "29","Carillon Nursing and Rehabilitation Center","830 Park Ave, Huntington, NY 11743",
  "30","Jeffersons Ferry Life Plan Community","1 Jefferson Ferry Dr, Centereach, NY 11720",
  "31","St Johnland Nursing Center, Inc","395 Sunken Meadow Rd, Kings Park, NY 11754",
  "32","St James Rehabilitation and Healthcare Center","275 MOriches Rd, St James, NY 11780",
  "33","Sunrise of East Setauket","1 Sunrise Dr, Setauket, NY 11733",
  "34","McPeaks Assisted Living","286 N Ocean Ave, Patchogue, NY 11772",
  "35","Our Lady of Consolation Nursing and Rehabilitation Care Center","111 Beach Drive, West Islip, NY 11795",
  "36","Acadia Center for Nursing and Rehabilitation","1146 Woodcrest Ave, Riverhead, NY 11901",
  "37","Oasis Rehabilitation and Nursing","6 Frowein Road, Center Moriches, NY 11934",
  "38","Momentum at South Bay for Rehabilitation and Nursing","340 E Main St, East Islip, NY 11730",
  "39","Gurwin Jewish - Fay J Lindner Residences","50 Hauppauge Rd, Commack, NY 11725",
  "40","The Bristal Assisted Living at Holtsville","5535 Expressway Drive North, Holtsville, NY 11742",
  "41","St Caterine of Siena Nursing and Rehabilitation Care Center","52 NY 25, Smithtown, NY 11787",
  "42","Atria Bay Shore","53 Ocean Ave, Bay Shore, NY 11706",
  "43","Sunrise of West Babylon","580 Montauk Hwy, West Babylon, NY 11704",
  "44","White Oaks Rehabilitation and Nursing Center","8565 Jericho Turnpike, Woodbury, NY 11797",
  "45","Village Walk at Patchogue","131 E Main St, Patchogue, NY 11772",
  "46","The Bristal Assisted Living at Sayville","129 Lakeland Ave, Sayville, NY 11782",
  "47","Atria East Northport","10 Cheshire Pl, East Northport, NY 11731",
  "48","Long Island State Veterans Home","101 Nicolls Road, Stony Brook, NY 11790",
  "49","The Bristal Assisted Living at Lake Grove","2995 Middle Country Rd, Lake Grove, NY 11755",
  "50","Sunrise of Smithtown","30 NY 111, Smithtown, NY 11787",
  "51","South Bay Adult Home","33 Cottontail Run, Center Moriches, NY 11934",
  "52","Cold Spring Hills Center for Nursing and Rehabilitation","378 Syosset-Woodbury Rd, Woodbury, NY 11797",
  "53","The Arbors Assisted Living Communities at Islandia East","1515 Veterans Memorial Hwy, Islandia, NY 11749",
  "54","Woodbury Center For Healthcare","8533 Jericho Turnpike, Woodbury, NY 11797",
  "55","Brandywine Living at Huntington Terrace","70 Pinelawn Rd, Melville, NY 11747",
  "56","Nursing Care Center At Medford","3115 Horseblock Road, Medford, NY 11763",
  "57","Whisper Woods of Smithtown","71 St Johnland Rd, Smithtown, NY 11787",
  "58","The Arbors Assisted Living at Hauppauge","1740 Express Dr S, Hauppauge, NY 11788",
  "59","Atria Huntington","165 Beverly Rd, Huntington, NY 11746",
  "60","The Arbors Assisted Living Communities at Bohemia","1065 Smithtown Ave, Bohemia, NY 11716",
  "61","Lake Shore Assisted Living Residence", "211 Lake Shore Rd, Lake Ronkonkoma, NY 11779",
  "62","San Simeon by the Sound, Inc.","61700 CR 48, Greenport, NY 11944",
  "63","Amber Court Of Smithtown","130 Lake Ave S, Nesconset, NY 11767",
  "64","Patchogue Senior Apartments","1 Brookwood Ln, East Patchogue, NY 11772"
  )

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

# Clean up Records ----
# Useful functions
left <- function(text, num_char) {
  substr(text, 1, num_char)
}

mid <- function(text, start_num, num_char) {
  substr(text, start_num, start_num + num_char - 1)
}

right <- function(text, num_char) {
  substr(text, nchar(text) - (num_char-1), nchar(text))
}

origAddress <- origAddress %>%
  filter(Name != "Long Island Community Hospital") %>%
  filter(
    origAddress$lat != "" | origAddress$lon != ""
  ) %>%
  mutate(ZipCode = right(FullAddress, 5))

# Map locations ----
origAddress$lat <- as.numeric(origAddress$lat)
origAddress$lon <- as.numeric(origAddress$lon)

# Get shape files
# USA level zipcode for 2015
file_loc = "S:\\Global Finance\\1 REVENUE CYCLE\\Steve Sanderson II\\ALOS_Readmit_Mapping\\USA_gis_files"
usa <- readOGR(dsn = file_loc, layer = "cb_2015_us_zcta510_500k", encoding = "UTF-8")
dim(usa)
class(usa) # the human data is located at usa@data

# change the column name of the usa@data "ZCTA5CE10" to zipcode
names(usa)[1] = "zipcode"

#url3 = "http://www.unitedstateszipcodes.org/zip_code_database.csv"
file3 <- file.choose(new = TRUE)
file3 <- read.csv(file3)
all_usa_zip <- file3

specific_state <- all_usa_zip %>%
  filter(state == "NY") %>%
  select(zip, primary_city, county)

colnames(specific_state) <- c("zipcode", "City", "County")
specific_state$zipcode <- as.factor(specific_state$zipcode)
specific_state$County <- gsub("County", "", specific_state$County)

state_join <- full_join(usa@data, specific_state)

state_clean <- na.omit(state_join)

STATE_SHP <- sp::merge(x = usa, y = state_clean, all.x = F)
#head(STATE_SHP)
dim(STATE_SHP)

# Join Data ----
location_join <- origAddress
location_join$ZipCode <- as.character(location_join$ZipCode)
joined_data <- inner_join(location_join, state_clean, by = c("ZipCode" = "zipcode"))
head(joined_data)
dim(joined_data)

# Map ----
sv_lng <- -72.97659
sv_lat <- 40.78007
sv_zoom <- 9

# Hosp Marker ----
hospMarker <- makeAwesomeIcon(
  icon = 'glyphicon-plus'
  , markerColor = 'lightblue'
  , iconColor = 'black'
  , library = "glyphicon"
)

l <- leaflet() %>%
  setView(
    lng = sv_lng
    , lat = sv_lat
    , zoom = sv_zoom
    ) %>%
  addTiles(group = "OSM (default)") %>%
  addProviderTiles(
    providers$Stamen.Toner
    , group = "Toner"
    ) %>%
  addProviderTiles(
    providers$Stamen.TonerLite
    , group = "Toner Lite"
    ) %>%
  addControl(
    "My Health Location Map"
    , position = "topright"
    )

l <- l %>%
  addLayersControl(
    baseGroups = c("OSM (default)", "Toner", "Toner Lite"),
    options = layersControlOptions(
      collapsed = TRUE
      , position = "topright"
    )
  )

l <- l %>%
  addAwesomeMarkers(
    lng = sv_lng
    , lat = sv_lat
    , icon = hospMarker
    , label = "LI Community Hospital"
    # , labelOptions = labelOptions(
    #   noHide = FALSE
    #   , direction = "auto"
    #   )
  )

l <- l %>%
  addCircles(
    data = origAddress
    , lat = ~lat
    , lng = ~lon
    , radius = 4
    , fillOpacity = 1
    , label = ~htmlEscape(Label)
    , labelOptions = labelOptions(
      noHide = TRUE
      , direction = "auto"
      )

  )

l

origAddress %>%
  select(Label, Name, FullAddress) %>%
  knitr::kable() %>%
  kableExtra::kable_styling(
    bootstrap_options = c(
      "striped"
      , "hover"
      , "condensed"
      , "responsive"
    )
    , font_size = 12
    , full_width =  TRUE
    , position = "left"
  )

# Clean env ----
rm(list = ls())