# Map the practice 

library(ggmap)
library(rworldmap)
library(rworldxtra)
library(leaflet)
library(readxl)
library(rgdal)
library(htmltools)
library(dplyr)
library(magrittr)
library(readr)
library(knitr)

# Select the file from the file chooser
fileToLoad <- file.choose(new = TRUE)

# Read in the CSV/xlsx data and store it in a variable 
origAddress <- read_csv(fileToLoad, col_names = TRUE)
rm(fileToLoad)

# Setview
sv_lng <- -72.97659
sv_lat <- 40.78007
sv_zoom <- 9

# Hosp Marker
hospMarker <- makeAwesomeIcon(
  icon = 'glyphicon-plus'
  , markerColor = 'red'
  , iconColor = 'black'
  , library = "glyphicon"
)

practiceMarker <- makeAwesomeIcon(
  icon = 'fa-user-md'
  , markerColor = 'lightblue'
  , iconColor = 'black'
  , library = 'fa'
)

HospPopup <- paste(
  "<b><a href='http://www.licommunityhospital.org/'>Long Island Community Hospital</a></b>"
  , "<br><strong>Address: </strong>"
  , "101 Hospital Road, Patchogue, NY"
  , "<br><strong>Phone: </strong>"
  , "631-654-7100"
  , "<br><strong><a href='http://www.brookhavenhospital.org/general-directory.cfm'>Contact Us</a></strong>"
  
)

# leaflet map
l <- leaflet() %>%
  setView(lng = sv_lng, lat = sv_lat, zoom = sv_zoom) %>%
  addTiles(group = "OSM (default)") %>%
  addProviderTiles("CartoDB.Positron") %>%

  addAwesomeMarkers(
    data = origAddress
    , lng = ~lon
    , lat = ~lat
    , clusterOptions = markerClusterOptions(
        showCoverageOnHover = TRUE
    )
    , icon = practiceMarker
    , options = markerOptions(
        opacity = 1
      )
    , label = ~as.character(origAddress$`Practice Name`)
    , popup = ~as.character(
      paste(
        "<strong>Practice Name: </strong>"
        , origAddress$`Practice Name`
        , "<br><strong>Med Staff: </strong>"
        , origAddress$`DSS Med Staff Dept`
        , "<br><strong>Provider: </strong>"
        , origAddress$`Doc Name`
      )
    )
  ) %>%
  
  addControl(
    paste("Practice Location Map")
    , position = "topright"
  ) %>%
  
  addLayersControl(
    baseGroups = c("OSM (default)", "CartoDB.Positron")
    , options = layersControlOptions(
      collapsed = FALSE
      , position = "topright"
    )
  ) %>%
  
  addAwesomeMarkers(
    lng = sv_lng
    , lat = sv_lat
    , icon = hospMarker
    , label = "LICH"
    , popup = HospPopup      
  )

l

##### Med Staff map
# Get unique list of specialties
msl <- unique(origAddress$`DSS Med Staff Dept`)

# Create color palette
msPal <- colorFactor(
  palette = "Dark2"
  , domain = origAddress$`DSS Med Staff Dept`
)

# Create initial leaflet
msMap <- leaflet() %>%
  setView(lng = sv_lng, lat = sv_lat, zoom = sv_zoom) %>%
  addTiles(group = "OSM (default)") %>%
  addProviderTiles("CartoDB.Positron") %>%
  addControl("Practice Map", position = "topright")

for (i in 1:length(msl)) {
  l <- msl[i]
  msMap <- msMap %>%
    addAwesomeMarkers(
      data = subset(origAddress, origAddress$`DSS Med Staff Dept` == l)
      , group = l
      , lng = ~lon
      , lat = ~lat
      , clusterOptions = markerClusterOptions(
        showCoverageOnHover = TRUE
      )
      , icon = practiceMarker
      , label = ~htmlEscape(`Practice Name`)
      , popup = ~as.character(
        paste(
          "<strong>Practice Name: </strong>"
          , `Practice Name`
          , "<br><strong>Med Staff: </strong>"
          , `DSS Med Staff Dept`
          , "<br><strong>Provider: </strong>"
          , `Doc Name`
          , "<br><strong>Address: </strong>"
          , FullAddress
        )
      )
    )
}

# Add layer control
msMap <- msMap %>%
  addLayersControl(
    baseGroups = c("OSM (default)", "CartoDB.Positron")
    , overlayGroups = msl
    , options = layersControlOptions(
      collapsed = TRUE
      , position = "topright"
    )
  ) %>%
  
  addAwesomeMarkers(
    lng = sv_lng
    , lat = sv_lat
    , icon = hospMarker
    , label = "LICH"
    , popup = HospPopup
  )

msMap
