# Lib Load ----
if(!require(pacman)) install.packages("pacman")
pacman::p_load(
    # Tidy
    "tidyverse",

    # Mapping Tools
    "tmaptools",
    "leaflet",
    "ggmap",
    "rgdal",
    "htmltools"
)

# Make tibble of hospitals
geocoded <- data.frame(stringsAsFactors = FALSE)

origAddress <- tribble(
    ~HospSystem, ~Name, ~FullAddress,
    "SBUH", "Stony Brook University Hospital", "101 Nicolls Road, Stony Brook, NY 11794",
    "SBUH", "Long Island Community Hospital", "101 Hospital Road, East Patchogue, NY 11772",
    "SBUH", "Stony Brook Eastern Long Island Hospital", "201 Manor Place, Greenport, NY 11944",
    "SBUH", "Stony Brook Southampton Hospital", "240 Meeting House Lane, Southampton, NY 11968",
    "CHS", "St. Catherine of Siena Medical Ctr.","50 Route NY-25A, Smithtown, NY 11787",
    "CHS", "St. Charles Hospital and Rehab Ctr.", "200 Belle Terre Road, Port Jefferson, NY 11777",
    "Northwell", "Peconic Bay Medical Ctr.","1300 Roanoke Avenue, Riverhead, NY 11901",
    "Northwell", "Mather Memorial Hospital", "75 North Country Road, Port Jefferson, NY 11777",
    "Northwell", "Southside Hospital", "301 East Main Street, Bay Shore, NY 11706"
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
file3_path <- "S:\\Global Finance\\1 REVENUE CYCLE\\Steve Sanderson II\\ALOS_Readmit_Mapping\\zip_code_database.csv"
file3 <- read.csv(file3_path)
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

# Add zip to origAddress
origAddress <- origAddress %>%
    mutate(ZipCode = right(FullAddress, 5))

# Join Data ----
location_join <- origAddress
location_join$ZipCode <- as.character(location_join$ZipCode)
joined_data <- inner_join(location_join, state_clean, by = c("ZipCode" = "zipcode"))
head(joined_data)
dim(joined_data)

# Map Center and Zoom----
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


# Make Map ----------------------------------------------------------------
text_size = "15px"

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
        "Hospital Locations Map"
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

# Add LICH glyphicon
l <- l %>%
    addAwesomeMarkers(
        lng = sv_lng
        , lat = sv_lat
        , icon = hospMarker
        , label = "LI Community Hospital"
    )

# Add SBU system
l <- l %>%
    addCircleMarkers(
        data = origAddress %>% filter(HospSystem == "SBUH")
        , lat = ~lat
        , lng = ~lon
        , radius = 4
        , fillOpacity = 1
        , label = ~htmlEscape(Name)
        , color = "blue"
        , labelOptions = labelOptions(
            noHide = TRUE
            , direction = "auto"
            , textsize = text_size
        )
        
    )

# Add CHS St Charles
l <- l %>%
  addCircleMarkers(
    data = origAddress %>% 
      filter(HospSystem == "CHS") %>%
      filter(Name != "St. Charles Hospital and Rehab Ctr.")
    , lat = ~lat
    , lng = ~lon
    , radius = 4
    , fillOpacity = 1
    , label = ~htmlEscape(Name)
    , color = "green"
    , labelOptions = labelOptions(
      noHide = TRUE
      , direction = "auto"
      , textsize = text_size
    )
  ) %>%
  addCircleMarkers(
    data = origAddress %>%
      filter(Name == "St. Charles Hospital and Rehab Ctr.")
    , lat = ~lat
    , lng = ~lon
    , radius = 4
    , fillOpacity = 1
    , label = ~htmlEscape(Name)
    , color = "green"
    , labelOptions = labelOptions(
      noHide = TRUE
      , direction = "top"
      , textsize = text_size
    )
  )

# Add Northwell Health
l <- l %>%
    addCircleMarkers(
        data = origAddress %>% 
            filter(HospSystem == "Northwell") %>%
            filter(Name != "Mather Memorial Hospital")
        , lat = ~lat
        , lng = ~lon
        , radius = 4
        , fillOpacity = 1
        , label = ~htmlEscape(Name)
        , color = "black"
        , labelOptions = labelOptions(
            noHide = TRUE
            , direction = "auto"
            , textsize = text_size
        )
        
    )

# Add Mather
l <- l %>%
    addCircleMarkers(
        data = origAddress %>%
            filter(Name == "Mather Memorial Hospital")
        , lat = ~lat
        , lng = ~lon
        , radius = 4
        , fillOpacity = 1
        , label = ~htmlEscape(Name)
        , color = "black"
        , labelOptions = labelOptions(
            noHide = TRUE
            , direction = "bottom"
            , textsize = text_size
        )
    )

# Table of addresses ----
origAddress %>%
    select(HospSystem, Name, FullAddress) %>%
    set_names("Hospital System","Hospital Name","Address") %>%
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
