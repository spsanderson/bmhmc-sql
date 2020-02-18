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
origAddress <- read_xlsx(fileToLoad)
origAddress$ZipCode <- as.character(origAddress$ZipCode)

# State Shp joined Data ----
joined_data <- inner_join(
  origAddress
  , state_clean
  , by = c("ZipCode" = "zipcode")
  )
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

# Summary ----
discharges_by_zipcode <- joined_data %>%
  group_by(ZipCode) %>%
  summarise(discharge_count = n()) %>%
  ungroup() %>%
  arrange(desc(discharge_count)) %>%
  mutate(prop_of_total = discharge_count / sum(discharge_count)) %>%
  mutate(cum_prop_of_total = cumsum(prop_of_total))

discharges_by_zipcode

dsch_count_by_city <- joined_data %>%
  group_by(
    ZipCode
    , AFFGEOID10
    , GEOID10
    , ALAND10
    , AWATER10
    , City
    , County
  ) %>%
  summarize(
    dsch_count = n()
  ) %>%
  ungroup() %>%
  arrange(desc(dsch_count)) %>%
  mutate(cumsum_total = cumsum(dsch_count)) %>%
  mutate(prop_of_total = dsch_count / sum(dsch_count)) %>%
  mutate(cum_prop_of_total = cumsum(prop_of_total)) %>%
  mutate(prop_of_total_lbl = scales::percent(prop_of_total, accuracy = 0.01))

dsch_count_by_city <- as.data.frame(dsch_count_by_city)

dsch_count_by_city <- dsch_count_by_city %>%
  mutate(
    #dsch_bin = ntile(dsch_count, 8)
    dsch_bin = cut(
      dsch_count, breaks = c(25,100,200,300,400,500,Inf)
    )
  )

dsch_count_shp <- sp::merge(
  x = usa
  , y = dsch_count_by_city %>% filter(dsch_count >= 25)
  , all.x = F
)

pal <- colorFactor(
  palette = "Dark2"
  , domain = dsch_count_shp$dsch_bin
  , reverse = TRUE
)

popup <- paste(
  "<strong>County: </strong>"
  , dsch_count_shp$County
  , "<br><strong>City: </strong>"
  , dsch_count_shp$City
  , "<br><strong>Discharges: </strong>"
  , dsch_count_shp$dsch_count
  , "<br><strong>Discharge Bin: </strong>"
  , dsch_count_shp$dsch_bin
)

l <- leaflet(data = dsch_count_shp) %>%
  setView(lng = sv_lng, lat = sv_lat, zoom = sv_zoom) %>%
  addTiles(group = "OSM (default)") %>%
  addProviderTiles("CartoDB.Positron") %>%
  addPolygons(
    data = dsch_count_shp
    , fillColor = ~pal(dsch_bin)
    , fillOpacity = 0.7
    , opacity = 1
    , color = "white"
    , dashArray = "3"
    , weight = 0.7
    , popup = popup
    , highlight = highlightOptions(
      weight = 5,
      color = "#666",
      dashArray = "",
      fillOpacity = 0.7,
      bringToFront = TRUE
    )
  ) %>%
  addControl(
    paste("Discharges for: 2019 - ZipCode >= 25 Discharges")
    , position = "topright"
  ) %>%
  addLayersControl(
    baseGroups = c("OSM (default)", "CartoDB.Positron")
    , options = layersControlOptions(
      collapsed = FALSE
      , position = "topright"
    )
  ) %>%
  addLegend(
    "bottomright"
    , pal = pal
    , values = ~dsch_bin
    , title = "Discharge Bin"
    , opacity = 1
  ) %>%
  addAwesomeMarkers(
    lng = sv_lng
    , lat = sv_lat
    , icon = hospMarker
    , label = "LI Community Hospital"
    , labelOptions = labelOptions(
     noHide = FALSE
     , direction = "auto"
    )
  )

l

# Test map with clusters
discharges_by_svcline_zipcode <- joined_data %>%
  group_by(LIHN_SVC_LINE,ZipCode) %>%
  summarise(discharge_count = n()) %>%
  ungroup() %>%
  arrange(desc(discharge_count)) %>%
  mutate(prop_of_total = discharge_count / sum(discharge_count)) %>%
  mutate(cum_prop_of_total = cumsum(prop_of_total))
discharges_by_svcline_zipcode

LIHNCluster.df <- split(
  discharges_by_svcline_zipcode
  , discharges_by_svcline_zipcode$LIHN_SVC_LINE
)

dsch_count_svc_line_shp <- sp::merge(
  x = usa
  , y = discharges_by_svcline_zipcode
  , all.x = F
)

ClusterMapLIHN <- leaflet() %>%
  setView(lng = sv_lng, lat = sv_lat, zoom = sv_zoom) %>%
  addTiles(group = "OSM (default)") %>%
  addProviderTiles(providers$Stamen.Toner, group = "Toner") %>%
  addProviderTiles(providers$Stamen.TonerLite, group = "Toner Lite") %>%
  addControl("LIHN Service Line Cluster Map", position = "topright")

names(LIHNCluster.df) %>%
  purrr::walk(function(df){
    ClusterMapLIHN <<- ClusterMapLIHN %>%
      addMarkers(
        data = LIHNCluster.df[[df]]
        , lng = ~lon
        , lat = ~lat
        , label = ~as.character(LIHN_Line)
        , popup = ~as.character(
          paste(
            "<br><strong>Service Line: </strong>"
            , LIHN_Line
          )
        )
        , group = df
        , clusterOptions = markerClusterOptions(
          removeOutsideVisibleBounds = F
          , labelOptions = labelOptions(
            noHide = F
            , direction = 'auto'
          )
        )
      )
  }
  )

ClusterMapLIHN <- ClusterMapLIHN %>%
  addLayersControl(
    baseGroups = c("OSM (default)", "Toner", "Toner Lite")
    , overlayGroups = names(LIHNCluster.df)
    , options = layersControlOptions(collapsed = TRUE)
  )

ClusterMapLIHN <- ClusterMapLIHN %>%
  addAwesomeMarkers(
    lng = sv_lng
    , lat = sv_lat
    , icon = hospMarker
    , label = "LI Community Hospital"
    , popup = HospPopup      
  )

ClusterMapLIHN