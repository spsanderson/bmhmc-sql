# ALOS Mapping File
# Mapping a geocoded csv column of "addresses" in R

# Lib Load ####
# load libraries
if(!require(pacman)) {
  install.packages("pacman")
  pacman::p_load(
    "ggmap"
    , "leaflet"
    , "readxl"
    , "htmltools"
    , "dplyr"
    , "readr"
    , "rgdal"
  )
} else {
  pacman::p_load(
    "ggmap"
    , "leaflet"
    , "readxl"
    , "htmltools"
    , "dplyr"
    , "readr"
    , "rgdal"
  )
}

# Select the file ----
fileToLoad <- "S:\\Global Finance\\1 REVENUE CYCLE\\Steve Sanderson II\\ALOS_Readmit_Mapping\\ALOS_Mapping_File.xlsx"

# Read in the CSV/xlsx data and store it in a variable 
origAddress <- read_xlsx(fileToLoad, col_names = TRUE)
rm(fileToLoad)

# Add some structure to the data
origAddress$LIHN_Line <- as.factor(origAddress$LIHN_Service_Line)
origAddress$SOI <- as.factor(origAddress$SEVERITY_OF_ILLNESS)
origAddress$ZipCode <- as.factor(origAddress$ZipCode)
origAddress$Var[origAddress$Case_Var <= 0] <- 0
origAddress$Var[origAddress$Case_Var > 0] <- 1
origAddress <- origAddress %>%
  filter(is.na(lat) == F) %>%
  filter(is.na(lon) == F) %>%
  filter(lat != 'NULL') %>%
  filter(lon != 'NULL')
origAddress$lat <- as.numeric(origAddress$lat)
origAddress$lon <- as.numeric(origAddress$lon)

# number of discharges
discharges <- nrow(origAddress)
MaxRpt <- max(origAddress$Last_Rpt_Month)
MaxRptYr <- substr(MaxRpt, 1, 4)
MaxRptMonth <- substr(MaxRpt, 5, 6)

# Run SHP Script ----
# at this point run the file get_usa_zipcode_level_2015.R Script
# when done, inner join data together
alos_join <- origAddress
alos_join$ZipCode <- as.character(alos_join$ZipCode)
joined_data <- inner_join(alos_join, state_clean, by = c("ZipCode" = "zipcode"))
head(joined_data)
dim(joined_data)

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
    )
dsch_count_by_city <- as.data.frame(dsch_count_by_city)

dsch_count_by_city <- dsch_count_by_city %>%
  mutate(
    #dsch_bin = ntile(dsch_count, 5)
     dsch_bin = cut(
      dsch_count, breaks = c(0,25,50,75,100,125,150,Inf)
      )
  )

dsch_count_shp <- sp::merge(
  x = usa
  , y = dsch_count_by_city
  , all.x = F
)

# Test Map
sv_lng <- -72.97659
sv_lat <- 40.78007
sv_zoom <- 9

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
    # , color = "#BDBDC3"
    , weight = 0.7
    , popup = popup
    ) %>%
  addControl(
    paste("Discharges for:",MaxRptMonth,MaxRptYr)
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
    "topright"
    , pal = pal
    , values = ~dsch_bin
    , title = "Discharge Bin"
    , opacity = 1
  )

l
# End Test Map

# test map of ALOS
dsch_alos_city <- joined_data %>%
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
    ALOS = round(mean(LOS), 2)
  )
dsch_alos_city <- as.data.frame(dsch_alos_city)

dsch_alos_shp <- sp::merge(
  x = usa
  , y = dsch_alos_city
  , all.x = F
)

palAlos <- colorBin(
  palette = "Dark2"
  , domain = dsch_alos_shp$ALOS
  #, bins = 5
  , reverse = TRUE
)

popup <- paste(
  "<strong>County: </strong>"
  , dsch_alos_shp$County
  , "<br><strong>City: </strong>"
  , dsch_alos_shp$City
  , "<br><strong>Discharges: </strong>"
  , dsch_count_shp$dsch_count
  , "<br><strong>ALOS: </strong>"
  , dsch_alos_shp$ALOS
)

alosl <- leaflet(data = dsch_alos_shp) %>%
  setView(lng = sv_lng, lat = sv_lat, zoom = sv_zoom) %>%
  addTiles(group = "OSM (default)") %>%
  addProviderTiles("CartoDB.Positron") %>%
  addPolygons(
    data = dsch_alos_shp
    , fillColor = ~palAlos(ALOS)
    , fillOpacity = 0.7
    , weight = 0.7
    , popup = popup
  ) %>%
  addControl(
    paste("ALOS Map for:",MaxRptMonth, MaxRptYr)
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
    "topright"
    , pal = palAlos
    , values = ~ALOS
    , title = "ALOS Bin"
    , opacity = 1
  )
alosl
# end of ALOS map

# SOI Map
# Get the mean SOI
dsch_soi_city <- joined_data %>%
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
    avgSOI = round(mean(as.numeric(SOI)), 2)
  )
dsch_soi_city <- as.data.frame(dsch_soi_city)

dsch_soi_shp <- sp::merge(
  x = usa
  , y = dsch_soi_city
  , all.x = F
)

palSOI <- colorBin(
  palette = "Dark2"
  , domain = dsch_soi_shp$avgSOI
  , bins = 8
  , reverse = TRUE
)

popup <- paste(
  "<strong>County: </strong>"
  , dsch_soi_shp$County
  , "<br><strong>City: </strong>"
  , dsch_soi_shp$City
  , "<br><strong>Discharges: </strong>"
  , dsch_count_shp$dsch_count
  , "<br><strong>Avg SOI: </strong>"
  , dsch_soi_shp$avgSOI
)

soil <- leaflet(data = dsch_soi_shp) %>%
  setView(lng = sv_lng, lat = sv_lat, zoom = sv_zoom) %>%
  addTiles(group = "OSM (default)") %>%
  addProviderTiles("CartoDB.Positron") %>%
  addPolygons(
    data = dsch_soi_shp
    , fillColor = ~palSOI(avgSOI)
    , fillOpacity = 0.7
    , weight = 0.7
    , popup = popup
  ) %>%
  addControl(
    paste("SOI Map for:",MaxRptMonth, MaxRptYr)
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
    "topright"
    , pal = palSOI
    , values = ~avgSOI
    , title = "SOI Bin"
    , opacity = 1
  )
soil
# End of SOI Map

# Case Variance Map
dsch_cvar_city <- joined_data %>%
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
    avgVar = round(mean(Case_Var), 2)
  )
dsch_cvar_city <- as.data.frame(dsch_cvar_city)

dsch_cvar_shp <- sp::merge(
  x = usa
  , y = dsch_cvar_city
  , all.x = F
)

palcvar <- colorBin(
  palette = "Paired"
  , domain = dsch_cvar_shp$avgVar
  , bins = 5
  , reverse = FALSE
)

popup <- paste(
  "<strong>County: </strong>"
  , dsch_cvar_shp$County
  , "<br><strong>City: </strong>"
  , dsch_cvar_shp$City
  , "<br><strong>Discharges: </strong>"
  , dsch_count_shp$dsch_count
  , "<br><strong>Avg Case Variance: </strong>"
  , dsch_cvar_shp$avgVar
)

cvarl <- leaflet(data = dsch_cvar_shp) %>%
  setView(lng = sv_lng, lat = sv_lat, zoom = sv_zoom) %>%
  addTiles(group = "OSM (default)") %>%
  addProviderTiles("CartoDB.Positron") %>%
  addPolygons(
    data = dsch_cvar_shp
    , fillColor = ~palcvar(avgVar)
    , fillOpacity = 0.7
    , weight = 0.7
    , popup = popup
  ) %>%
  addControl(
    paste("Avg Variance Map for:",MaxRptMonth, MaxRptYr)
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
    "topright"
    , pal = palcvar
    , values = ~avgVar
    , title = "SOI Bin"
    , opacity = 1
  )
cvarl
# End of Case Variance Map

# Multi-layered Choropleth map ----
popup <- paste(
  "<strong>County: </strong>"
  , dsch_cvar_shp$County
  , "<br><strong>City: </strong>"
  , dsch_cvar_shp$City
  , "<br><strong>Discharges: </strong>"
  , dsch_count_shp$dsch_count
  , "<br><strong>ALOS: </strong>"
  , dsch_alos_shp$ALOS
  , "<br><strong>Avg SOI: </strong>"
  , dsch_soi_shp$avgSOI
  , "<br><strong>Avg Case Variance: </strong>"
  , dsch_cvar_shp$avgVar
)

mlmap <- leaflet(data = dsch_cvar_shp) %>%
  setView(lng = sv_lng, lat = sv_lat, zoom = sv_zoom) %>%
  addTiles(group = "OSM (default)") %>%
  addProviderTiles("CartoDB.Positron") %>%
  
  addPolygons(
    data = dsch_count_shp
    , fillColor = ~pal(dsch_bin)
    , fillOpacity = 0.7
    , weight = 0.7
    , popup = popup
    , group = "Discharges"
  ) %>%
  
  addPolygons(
    data = dsch_alos_shp
    , fillColor = ~palAlos(ALOS)
    , fillOpacity = 0.7
    , weight = 0.7
    , popup = popup
    , group = "ALOS"
  ) %>%
  
  addPolygons(
    data = dsch_soi_shp
    , fillColor = ~palSOI(avgSOI)
    , fillOpacity = 0.7
    , weight = 0.7
    , popup = popup
    , group = "SOI"
  ) %>%
  
  addPolygons(
    data = dsch_cvar_shp
    , fillColor = ~palcvar(avgVar)
    , fillOpacity = 0.7
    , weight = 0.7
    , popup = popup
    , group = "ALOS_Variance"
  ) %>%
  
  addControl(
    paste("Discharge Map for:",MaxRptMonth, MaxRptYr)
    , position = "topright"
  ) %>%
  
  addLayersControl(
    baseGroups = c("OSM (default)", "CartoDB.Positron")
    , overlayGroups = c("Discharges", "ALOS", "SOI", "ALOS_Variance")
    , options = layersControlOptions(
      collapsed = FALSE
      , position = "topright"
    )
  ) %>%
  
  addLegend(
    "topright"
    , pal = pal
    , values = dsch_count_shp$dsch_bin
    , title = "Dsch Bin"
    , opacity = 1
  ) %>%
  
  addLegend(
    "topright"
    , pal = palAlos
    , values = dsch_alos_shp$ALOS
    , title = "ALOS Bin"
    , opacity = 1
  ) %>%
  
  addLegend(
    "topright"
    , pal = palSOI
    , values = dsch_soi_shp$avgSOI
    , title = "SOI Bin"
    , opacity = 1
  ) %>%
  
  addLegend(
    "topright"
    , pal = palcvar
    , values = dsch_cvar_shp$avgVar
    , title = "Var Bin"
    , opacity = 1
  )

mlmap
# end of multi-layered choropleth

######################################
# leaflet maps
# Cluster Maps
# Hospital Marker ----
hospMarker <- makeAwesomeIcon(
      icon = 'glyphicon-plus'
    , markerColor = 'lightblue'
    , iconColor = 'black'
    , library = "glyphicon"
  )

mcluster <- leaflet() %>%
  setView(lng = sv_lng, lat = sv_lat, zoom = sv_zoom) %>%
  addTiles() %>%
  addMarkers(
    lng = origAddress$lon
    , lat = origAddress$lat
    , clusterOptions = markerClusterOptions()
  ) %>%
  addControl("Discharges", position = "topright")

mcluster <- mcluster %>%
  addAwesomeMarkers(
    lng = sv_lng
    , lat = sv_lat
    , icon = hospMarker
    , label = "LI Community Hospital"
    , popup = paste(
      "<b><a href='http://www.licommunityhospital.org/'>LI Community Hospital</a></b>"
      , "<br><strong>Discharges for: </strong>"
      , MaxRptMonth,"/",MaxRptYr
      , "<br><strong>Discharges: </strong>"
      , discharges
    )      
  )
  
mcluster

#####################################
# Service Line map
# Get unique list of groups needed
# Hospital Popup ----
HospPopup <- paste(
  "<b><a href='http://www.licommunityhospital.org/'>LI Community Hospital</a></b>"
  , "<br><strong>Discharges for: </strong>"
  , MaxRptMonth,"/",MaxRptYr
  , "<br><strong>Discharges: </strong>"
  , discharges
)

lsl <- unique(origAddress$LIHN_Line)

# Create color palette
lihnpal <- colorFactor(
  palette = 'Dark2'
  , domain = origAddress$LIHN_Line
)
# create initial leaflet
LIHNMap <- leaflet() %>%
  setView(lng = sv_lng, lat = sv_lat, zoom = sv_zoom) %>%
  addTiles(group = "OSM (default)") %>%
  addProviderTiles(providers$Stamen.Toner, group = "Toner") %>%
  addProviderTiles(providers$Stamen.TonerLite, group = "Toner Lite") %>%
  addControl("LIHN Service Line Point Map", position = "topright")

# for loop to cycle through adding layers
for(i in 1:length(lsl)){
  #l <- lsl[i]
  LIHNMap <- LIHNMap %>%
    addCircles(
      data = subset(origAddress, origAddress$LIHN_Line == lsl[i])
      , group = lsl[i]
      , lat = ~lat
      , lng = ~lon
      , radius = 3
      , fillOpacity = 1
      , color = ~lihnpal(LIHN_Line)
      , label = ~htmlEscape(LIHN_Line)
      , popup = ~as.character(
        paste(
          "<strong>Hospitalist/Private: </strong>"
          , hosim
          , "<br><strong>Address: </strong>"
          , FullAddress
          , "<br><strong>Service Line: </strong>"
          , LIHN_Line
          , "<br><strong>LOS: </strong>"
          , LOS
          , "<br><strong>SOI: </strong>"
          , SOI
          , "<br><strong>Encounter: </strong>"
          , pt_id
          , "<br><strong>Payer Group:</strong>"
          , pyr_group2
        )
      )
    )
}

# add layercontrol
LIHNMap <- LIHNMap %>%
  addLayersControl(
    baseGroups = c("OSM (default)", "Toner", "Toner Lite"),
    overlayGroups = lsl,
    options = layersControlOptions(
      collapsed = TRUE
      , position = "topright"
    )
  )

LIHNMap <- LIHNMap %>%
  addAwesomeMarkers(
    lng = sv_lng
    , lat = sv_lat
    , icon = hospMarker
    , label = "LI Community Hospital"
    , popup = HospPopup     
  )

# print map
LIHNMap

# SOI Map
# Get unique list of groups needed
s <- unique(origAddress$SOI)

# create SOI color palette
soipal <- colorFactor(
  c('purple', 'blue', 'red','black')
  , domain = origAddress$SOI
)
# create initial leaflet
mtsoi <- leaflet() %>%
  setView(lng = sv_lng, lat = sv_lat, zoom = sv_zoom) %>%
  addTiles(group = "OSM (default)") %>%
  addProviderTiles(providers$Stamen.Toner, group = "Toner") %>%
  addProviderTiles(providers$Stamen.TonerLite, group = "Toner Lite") %>%
  addControl("Severity of Illness Point Map", position = "topright")

# for loop to cycle through adding layers
for(i in 1:length(s)){
  #ss <- s[i]
  mtsoi <- mtsoi %>%
    addCircles(
      data = subset(origAddress, origAddress$SOI == s[i])
      , group = s[i]
      , lat = ~lat
      , lng = ~lon
      , radius = 3
      , fillOpacity = 1
      , color = ~soipal(SOI)
      , label = ~htmlEscape(SOI)
      , popup = ~as.character(
        paste(
          "<strong>Hospitalist/Private: </strong>"
          , hosim
          , "<br><strong>Address: </strong>"
          , FullAddress
          , "<br><strong>Service Line: </strong>"
          , LIHN_Line
          , "<br><strong>LOS: </strong>"
          , LOS
          , "<br><strong>SOI: </strong>"
          , SOI
          , "<br><strong>Encounter: </strong>"
          , pt_id
          , "<br><strong>Payer Group:</strong>"
          , pyr_group2
        )
      )
    )
}

# add layercontrol
mtsoi <- mtsoi %>%
  addLayersControl(
    baseGroups = c("OSM (default)", "Toner", "Toner Lite"),
    overlayGroups = s,
    options = layersControlOptions(
      collapsed = TRUE
      , position = "topright"
    )
  )

mtsoi <- mtsoi %>%
  addAwesomeMarkers(
    lng = sv_lng
    , lat = sv_lat
    , icon = hospMarker
    , label = "LI Community Hospital"
    , popup = HospPopup      
  )

# print map
mtsoi

# clusters ----
# Test map with clusters
LIHNCluster.df <- split(origAddress, origAddress$LIHN_Line)

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
            "<strong>Hospitalist/Private: </strong>"
            , hosim
            , "<br><strong>Address: </strong>"
            , FullAddress
            , "<br><strong>Service Line: </strong>"
            , LIHN_Line
            , "<br><strong>LOS: </strong>"
            , LOS
            , "<br><strong>SOI: </strong>"
            , SOI
            , "<br><strong>Encounter: </strong>"
            , pt_id
            , "<br><strong>Payer Group:</strong>"
            , pyr_group2
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

# save output or just use export from the plot viewer
#htmlwidgets::saveWidget(tmap, file = "LIHN_Service_Line_Clusters.html")

ClusterMapSOI.df <- split(origAddress, origAddress$SOI)

ClusterMapSOI <- leaflet() %>%
  setView(lng = sv_lng, lat = sv_lat, zoom = sv_zoom) %>%
  addTiles(group = "OSM (default)") %>%
  addProviderTiles(providers$Stamen.Toner, group = "Toner") %>%
  addProviderTiles(providers$Stamen.TonerLite, group = "Toner Lite") %>%
  addControl("Severity of Illness Cluster Map", position = "topright")

names(ClusterMapSOI.df) %>%
  purrr::walk(function(df){
    ClusterMapSOI <<- ClusterMapSOI %>%
      addMarkers(
        data = ClusterMapSOI.df[[df]]
        , lng = ~lon
        , lat = ~lat
        , label = ~as.character(SOI)
        , popup = ~as.character(
          paste(
            "<strong>Hospitalist/Private: </strong>"
            , hosim
            , "<br><strong>Address: </strong>"
            , FullAddress
            , "<br><strong>Service Line: </strong>"
            , LIHN_Line
            , "<br><strong>LOS: </strong>"
            , LOS
            , "<br><strong>SOI: </strong>"
            , SOI
            , "<br><strong>Encounter: </strong>"
            , pt_id
            , "<br><strong>Payer Group:</strong>"
            , pyr_group2
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

ClusterMapSOI <- ClusterMapSOI %>%
  addLayersControl(
    baseGroups = c("OSM (default)", "Toner", "Toner Lite")
    , overlayGroups = names(ClusterMapSOI.df)
    , options = layersControlOptions(collapsed = TRUE)
  )

ClusterMapSOI <- ClusterMapSOI %>%
  addAwesomeMarkers(
    lng = sv_lng
    , lat = sv_lat
    , icon = hospMarker
    , label = "BMHMC"
    , popup = HospPopup      
  )

ClusterMapSOI

# Hospitalist / Private
# Get unique list of groups
HospPvtList <- unique(origAddress$hosim)

# Create color palette
HospPvtPal <- colorFactor(
  palette = 'Dark2'
  , domain = origAddress$hosim
)

# Create initial leaflet
HospPvtMap <- leaflet() %>%
  setView(lng = sv_lng, lat = sv_lat, zoom = sv_zoom) %>%
  addTiles() %>%
  addProviderTiles(providers$Stamen.Toner, group = "Toner") %>%
  addProviderTiles(providers$Stamen.TonerLite, group = "Toner Lite") %>%
  addControl("Hospitalist/Private Point Map", position = "topright")

# for loop to add layers
for(i in 1:length(HospPvtList)){
  HospPvtMap <- HospPvtMap %>%
    addCircles(
      data = subset(origAddress, origAddress$hosim == HospPvtList[i])
      , group = HospPvtList[i]
      , radius = 3
      , lng = ~lon
      , lat = ~lat
      , fillOpacity = 1
      , color = ~HospPvtPal(hosim)
      , label = ~htmlEscape(hosim)
      , popup = ~as.character(
        paste(
          "<strong>Hospitalist/Private: </strong>"
          , hosim
          , "<br><strong>Address: </strong>"
          , FullAddress
          , "<br><strong>Service Line: </strong>"
          , LIHN_Line
          , "<br><strong>LOS: </strong>"
          , LOS
          , "<br><strong>SOI: </strong>"
          , SOI
          , "<br><strong>Encounter: </strong>"
          , pt_id
          , "<br><strong>Payer Group:</strong>"
          , pyr_group2
        )
      )
    )
}

# Add Layer Control
HospPvtMap <- HospPvtMap %>%
  addLayersControl(
    baseGroups = c("OSM (default)","Toner","Toner Lite")
    , overlayGroups = HospPvtList
    , options = layersControlOptions(
      collapsed = TRUE
      , position = 'topright'
    )
  )

HospPvtMap <- HospPvtMap %>%
  addAwesomeMarkers(
    lng = sv_lng
    , lat = sv_lat
    , icon = hospMarker
    , label = "LI Community Hospital"
    , popup = HospPopup
  )

HospPvtMap

# Hospitalist / Private Cluster Map ----
ClusterMapHospPvt.df <- split(origAddress, origAddress$hosim)

ClusterMapHospPvt <- leaflet() %>%
  setView(lng = sv_lng, lat = sv_lat, zoom = sv_zoom) %>%
  addTiles() %>%
  addProviderTiles(providers$Stamen.Toner, group = "Toner") %>%
  addProviderTiles(providers$Stamen.TonerLite, group = "Toner Lite") %>%
  addControl("Hospitalist/Private Cluster Map", position = "topright")

names(ClusterMapHospPvt.df) %>%
  purrr::walk(function(df){
    ClusterMapHospPvt <<- ClusterMapHospPvt %>%
      addMarkers(
        data = ClusterMapHospPvt.df[[df]]
        , lng = ~lon
        , lat = ~lat
        , label = ~as.character(hosim)
        , popup = ~as.character(
          paste(
            "<strong>Hospitalist/Private: </strong>"
            , hosim
            , "<br><strong>Address: </strong>"
            , FullAddress
            , "<br><strong>Service Line: </strong>"
            , LIHN_Line
            , "<br><strong>LOS: </strong>"
            , LOS
            , "<br><strong>SOI: </strong>"
            , SOI
            , "<br><strong>Encounter: </strong>"
            , pt_id
            , "<br><strong>Payer Group:</strong>"
            , pyr_group2
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

ClusterMapHospPvt <- ClusterMapHospPvt %>%
  addLayersControl(
    baseGroups = c("OSM (default)", "Toner", "Toner Lite")
    , overlayGroups = names(ClusterMapHospPvt.df)
    , options = layersControlOptions(collapsed = TRUE)
  )

ClusterMapHospPvt <- ClusterMapHospPvt %>%
  addAwesomeMarkers(
    lng = sv_lng
    , lat = sv_lat
    , icon = hospMarker
    , label = "LI Community Hospital"
    , popup = HospPopup      
  )

ClusterMapHospPvt

# Payer Group ----
ClusterMapPayerGroup.df <- split(origAddress, origAddress$pyr_group2)

ClusterMapPayerGroup <- leaflet() %>%
  setView(lng = sv_lng, lat = sv_lat, zoom = sv_zoom) %>%
  addTiles() %>%
  addProviderTiles(providers$Stamen.Toner, group = "Toner") %>%
  addProviderTiles(providers$Stamen.TonerLite, group = "Toner Lite") %>%
  addControl("Payer Group Cluster Map", position = "topright")

names(ClusterMapPayerGroup.df) %>%
  purrr::walk(function(df){
    ClusterMapPayerGroup <<- ClusterMapPayerGroup %>%
      addMarkers(
        data = ClusterMapPayerGroup.df[[df]]
        , lng = ~lon
        , lat = ~lat
        , label = ~as.character(pyr_group2)
        , popup = ~as.character(
          paste(
            "<strong>Hospitalist/Private: </strong>"
            , hosim
            , "<br><strong>Address: </strong>"
            , FullAddress
            , "<br><strong>Service Line: </strong>"
            , LIHN_Line
            , "<br><strong>LOS: </strong>"
            , LOS
            , "<br><strong>SOI: </strong>"
            , SOI
            , "<br><strong>Encounter: </strong>"
            , pt_id
            , "<br><strong>Payer Group:</strong>"
            , pyr_group2
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

ClusterMapPayerGroup <- ClusterMapPayerGroup %>%
  addLayersControl(
    baseGroups = c("OSM (default)", "Toner", "Toner Lite")
    , overlayGroups = names(ClusterMapPayerGroup.df)
    , options = layersControlOptions(collapsed = TRUE)
  )

ClusterMapPayerGroup <- ClusterMapPayerGroup %>%
  addAwesomeMarkers(
    lng = sv_lng
    , lat = sv_lat
    , icon = hospMarker
    , label = "LI Community Hospital"
    , popup = HospPopup      
  )

ClusterMapPayerGroup

# ALOS Variance Map
AVL <- unique(as.factor(origAddress$Var))

AlosVarColor <- colorFactor(
  c("red", "black")
  , domain = origAddress$Var
)

AlosVarMap <- leaflet() %>%
  setView(lng = sv_lng, lat = sv_lat, zoom = sv_zoom) %>%
  addTiles(group = "OSM (default)") %>%
  addProviderTiles(providers$Stamen.Toner, group = "Toner") %>%
  addProviderTiles(providers$Stamen.TonerLite, group = "Toner Lite") %>%
  addControl("ALOS Variance Point Map", position = "topright")

for(i in 1:length(AVL)){
  AlosVarMap <- AlosVarMap %>%
    addCircles(
      data = subset(origAddress, origAddress$Var == AVL[i])
      , group = AVL[i]
      , radius = 3
      , lng = ~lon
      , lat = ~lat
      , fillOpacity = 1
      , color = ~AlosVarColor(Var)
      , label = ~as.character(Var)
      , popup = ~as.character(
        paste(
          "<strong>Hospitalist/Private: </strong>"
          , hosim
          , "<br><strong>Address: </strong>"
          , FullAddress
          , "<br><strong>Service Line: </strong>"
          , LIHN_Line
          , "<br><strong>LOS: </strong>"
          , LOS
          , "<br><strong>SOI: </strong>"
          , SOI
          , "<br><strong>Encounter: </strong>"
          , pt_id
          , "<br><strong>Payer Group:</strong>"
          , pyr_group2
        )
      )
    )
}

AlosVarMap <- AlosVarMap %>%
  addLayersControl(
    baseGroups = c("OSM (default)", "Toner", "Toner Lite")
    , overlayGroups = AVL
    , options = layersControlOptions(
      collapsed = TRUE
      , position = "topright"
    )
  )

AlosVarMap <- AlosVarMap %>%
  addAwesomeMarkers(
    lng = sv_lng
    , lat = sv_lat
    , icon = hospMarker
    , label = "BMHMC"
    , popup = HospPopup
  )

AlosVarMap

# ALOS Variance Cluster Map
AlosVarCluster.df <- split(origAddress, origAddress$Var)

ClusterMapAlosVar <- leaflet() %>%
  setView(lng = sv_lng, lat = sv_lat, zoom = sv_zoom) %>%
  addTiles(group = "OSM (default)") %>%
  addProviderTiles(providers$Stamen.Toner, group = "Toner") %>%
  addProviderTiles(providers$Stamen.TonerLite, group = "Toner Lite") %>%
  addControl("ALOS Variance Cluster Map", position = "topright")

names(AlosVarCluster.df) %>%
  purrr::walk(function(df){
    ClusterMapAlosVar <<- ClusterMapAlosVar %>%
      addMarkers(
        data = AlosVarCluster.df[[df]]
        , lng = ~lon
        , lat = ~lat
        , label = ~as.character(Var)
        , popup = ~as.character(
          paste(
            "<strong>Hospitalist/Private: </strong>"
            , hosim
            , "<br><strong>Address: </strong>"
            , FullAddress
            , "<br><strong>Service Line: </strong>"
            , LIHN_Line
            , "<br><strong>LOS: </strong>"
            , LOS
            , "<br><strong>SOI: </strong>"
            , SOI
            , "<br><strong>Encounter: </strong>"
            , pt_id
            , "<br><strong>Payer Group:</strong>"
            , pyr_group2
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

ClusterMapAlosVar <- ClusterMapAlosVar %>%
  addLayersControl(
    baseGroups = c("OSM (default)", "Toner", "Toner Lite")
    , overlayGroups = names(AlosVarCluster.df)
    , options = layersControlOptions(collapsed = TRUE)
  )

ClusterMapAlosVar <- ClusterMapAlosVar %>%
  addAwesomeMarkers(
    lng = sv_lng
    , lat = sv_lat
    , icon = hospMarker
    , label = "BMHMC"
    , popup = HospPopup
  )

ClusterMapAlosVar
