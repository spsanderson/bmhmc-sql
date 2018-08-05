# Mapping a geocoded csv column of "addresses" in R

#load ggmap
library(ggmap)
library(rworldmap)
library(rworldxtra)
library(leaflet)
library(readxl)
library(rgdal)
library(htmltools)

# Select the file from the file chooser
fileToLoad <- file.choose(new = TRUE)

# Read in the CSV/xlsx data and store it in a variable 
origAddress <- read_xlsx(fileToLoad, col_names = TRUE)

# Add some structure to the data
origAddress$LIHN_Line <- as.factor(origAddress$LIHN_Svc_Line)
origAddress$ROM <- as.factor(origAddress$RISK_OF_MORTALITY)
origAddress$SOI <- as.factor(origAddress$SEVERITY_OF_ILLNESS)

# make a simple map
newmap <- getMap(resolution = "high")
plot(newmap, xlim = c(-74,-72), ylim = c(40, 41.5), asp = 1)
points(origAddress$lon, origAddress$lat, col = "red", cex = 0.6)

# nicer map ggplot2 style
map <- get_map(location = 'Patchogue', zoom = 9, maptype = "roadmap")
mapPoints <- ggmap(map) +
  geom_point(
    aes(
      x = lon
      , y = lat
      , color = "red"
      , alpha = 0.3
      )
    , data = origAddress
    ) +
  xlab("Longitude") +
  ylab("Lattitude") +
  ggtitle("Discharges") +
  theme(legend.position = "none")
mapPoints

mapbin2d <- ggmap(map) +
  geom_bin2d(
    aes(
      x = lon
      , y = lat
      )
    , data = origAddress
    )
mapbin2d

mapdensity2d <- ggmap(map) +
  geom_density2d(
    aes(
      x = lon
      , y = lat
      , group = origAddress$SOI
      , color = origAddress$SOI
      )
    , data = origAddress
    )
mapdensity2d

mapdensity2db <- ggmap(map) + 
  geom_density2d(
    aes(
      x = lon
      , y = lat
        )
    , data = origAddress
  )
mapdensity2db

## ggplot qqplot style
# qmplot(lon, lat, data = origAddress
#        , maptype = "toner-lite"
#        , zoom = 9
#        , color = I("red")
#        )
# 
# qmplot(lon, lat, data = origAddress
#        , maptype = "toner-lite"
#        , zoom = 9
#        , geom = "density2d"
#        , color = I("red"))

######################################
# leaflet maps
# Cluster Map
sv_lng <- -72.97659
sv_lat <- 40.78007
sv_zoom <- 9

mcluster <- leaflet() %>%
  setView(lng = sv_lng, lat = sv_lat, zoom = sv_zoom) %>%
  addTiles() %>% 
  addMarkers(
  lng = origAddress$lon
  , lat = origAddress$lat
  , clusterOptions = markerClusterOptions())

mcluster

#####################################
# Service Line map
# Get unique list of groups needed
lsl <- unique(origAddress$LIHN_Line)

# Create color palette
lihnpal <- colorFactor(
  palette = 'Dark2'
  , domain = origAddress$LIHN_Line
)
# create initial leaflet
mt <- leaflet() %>%
  setView(lng = sv_lng, lat = sv_lat, zoom = sv_zoom) %>%
  addTiles(group = "OSM (default)") %>%
  addProviderTiles(providers$Stamen.Toner, group = "Toner") %>%
  addProviderTiles(providers$Stamen.TonerLite, group = "Toner Lite")

# for loop to cycle through adding layers
for(i in 1:length(lsl)){
  #l <- lsl[i]
  mt <- mt %>%
    addCircles(
      data = subset(origAddress, origAddress$LIHN_Line == lsl[i])
      , group = lsl[i]
      , radius = 3
      , fillOpacity = 1
      , color = ~lihnpal(LIHN_Line)
      , label = ~htmlEscape(LIHN_Line)
      , popup = ~as.character(
        paste(
          "Address: "
          , "<dd>",FullAddress,"</dd>"
          , "Service Line: "
          , "<dd>",LIHN_Line,"</dd>"
          , "LOS: "
          , "<dd>",DAYSSTAY,"</dd>"
          , "SOI: "
          , "<dd>",SOI,"</dd>"
          , "Encounter: "
          , "<dd>",Encounter,"</dd>"
        )
      )
    )
}

# add layercontrol
mt <- mt %>%
  addLayersControl(
    baseGroups = c("OSM (default)", "Toner", "Toner Lite"),
    overlayGroups = lsl,
    options = layersControlOptions(collapsed = TRUE
      , position = "bottomright")
  )

# print map
mt

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
  addProviderTiles(providers$Stamen.TonerLite, group = "Toner Lite")

# for loop to cycle through adding layers
for(i in 1:length(s)){
  #ss <- s[i]
  mtsoi <- mtsoi %>%
    addCircles(
      data = subset(origAddress, origAddress$SOI == s[i])
      , group = s[i]
      , radius = 3
      , fillOpacity = 1
      , color = ~soipal(SOI)
      , label = ~htmlEscape(SOI)
      , popup = ~as.character(
        paste(
          "Address: "
          , "<dd>",FullAddress,"</dd>"
          , "Service Line: "
          , "<dd>",LIHN_Line,"</dd>"
          , "LOS: "
          , "<dd>",DAYSSTAY,"</dd>"
          , "SOI: "
          , "<dd>",SOI,"</dd>"
          , "Encounter: "
          , "<dd>",Encounter,"</dd>"
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
      collapsed = FALSE
      , position = "bottomright"
    )
  )

# print map
mtsoi

# ROM Map
# Get unique list of groups needed
r <- unique(origAddress$ROM)

# create rom color palette
rompal <- colorFactor(
  c('purple', 'blue', 'red', 'black')
  , domain = origAddress$ROM
  )

# Create intial leaflet
mtrom <- leaflet() %>%
  setView(lng = sv_lng, lat = sv_lat, zoom = sv_zoom) %>%
  addTiles(group = "OSM (default)") %>%
  addProviderTiles(providers$Stamen.Toner, group = "Toner") %>%
  addProviderTiles(providers$Stamen.TonerLite, group = "Toner Lite")

# for loop to cycle through adding layers
for(i in 1:length(r)){
  mtrom <- mtrom %>%
    addCircles(
      data = subset(origAddress, origAddress$ROM == r[i])
      , group = r[i]
      , radius = 3
      , fillOpacity = 1
      , color = ~rompal(ROM)
      , label = ~htmlEscape(ROM)
      , popup = ~as.character(
        paste(
          "Address: "
          , "<dd>",FullAddress,"</dd>"
          , "Service Line: "
          , "<dd>",LIHN_Line,"</dd>"
          , "LOS: "
          , "<dd>",DAYSSTAY,"</dd>"
          , "SOI: "
          , "<dd>",ROM,"</dd>"
          , "Encounter: "
          , "<dd>",Encounter,"</dd>"
        )
      )
    )
  }

# add layercontrol
mtrom <- mtrom %>%
  addLayersControl(
    baseGroups = c("OSM (default)", "Toner", "Toner Lite"),
    overlayGroups = r,
    options = layersControlOptions(
      collapsed = FALSE
      , position = "bottomright"
    )
  )

# print map
mtrom

# Test map with clusters
LIHNCluster.df <- split(origAddress, origAddress$LIHN_Line)

ClusterMapLIHN <- leaflet() %>%
  setView(lng = sv_lng, lat = sv_lat, zoom = sv_zoom) %>%
  addTiles()

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
            "Address: "
            , "<dd>",FullAddress,"</dd>"
            , "Service Line: "
            , "<dd>",LIHN_Line,"</dd>"
            , "LOS: "
            , "<dd>",DAYSSTAY,"</dd>"
            , "Encounter: "
            , "<dd>",Encounter,"</dd>"
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
    overlayGroups = names(LIHNCluster.df)
    , options = layersControlOptions(collapsed = TRUE)
  )

ClusterMapLIHN

# save output or just use export from the plot viewer
#htmlwidgets::saveWidget(tmap, file = "LIHN_Service_Line_Clusters.html")
ClusterMapSOI.df <- split(origAddress, origAddress$SOI)

ClusterMapSOI <- leaflet() %>%
  setView(lng = sv_lng, lat = sv_lat, zoom = sv_zoom) %>%
  addTiles()

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
            "Address: "
            , "<dd>",FullAddress,"</dd>"
            , "Service Line: "
            , "<dd>",LIHN_Line,"</dd>"
            , "LOS: "
            , "<dd>",DAYSSTAY,"</dd>"
            , "SOI: "
            , "<dd>",SOI,"</dd>"
            , "Encounter: "
            , "<dd>",Encounter,"</dd>"
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
    overlayGroups = names(ClusterMapSOI.df)
    , options = layersControlOptions(collapsed = FALSE)
  )

ClusterMapSOI
