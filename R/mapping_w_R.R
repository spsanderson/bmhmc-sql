# Mapping a geocoded csv column of "addresses" in R

#load ggmap
library(ggmap)
library(rworldmap)
library(rworldxtra)
library(leaflet)
library(readxl)
library(rgdal)

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
plot(newmap, xlim = c(-74,-72), ylim = c(40, 41), asp = 1)
points(origAddress$lon, origAddress$lat, col = "red", cex = 0.6)

# nicer map ggplot2 style
# map <- get_map(location = 'Patchogue', zoom = 9, maptype = "roadmap")
# mapPoints <- ggmap(map) +
#   geom_point(aes(x = lon, y = lat, color = "red"), data = origAddress) +
#   xlab("Longitude") +
#   ylab("Lattitude") +
#   ggtitle("Discharges") +
#   theme(legend.position = "none")
# mapPoints
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
sv_lng <- -72.9772425
sv_lat <- 40.7799931
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

# create initial leaflet
mt <- leaflet() %>%
  setView(lng = sv_lng, lat = sv_lat, zoom = sv_zoom) %>%
  addTiles(group = "OSM (default)") %>%
  addProviderTiles(providers$Stamen.Toner, group = "Toner") %>%
  addProviderTiles(providers$Stamen.TonerLite, group = "Toner Lite")

# for loop to cycle through adding layers
for(i in 1:length(lsl)){
  l <- lsl[i]
  mt <- mt %>%
    addCircles(
      data = subset(origAddress, origAddress$LIHN_Line == lsl[i])
      , group = lsl[i]
      , radius = 3
      , fillOpacity = 0.6)
}

# add layercontrol
mt <- mt %>%
  addLayersControl(
    baseGroups = c("OSM (default)", "Toner", "Toner Lite"),
    overlayGroups = lsl,
    options = layersControlOptions(collapsed = FALSE
      , position = "bottomright")
  )

# print map
mt

# SOI Map
# Get unique list of groups needed
s <- unique(origAddress$SOI)

# create initial leaflet
mtsoi <- leaflet() %>%
  setView(lng = sv_lng, lat = sv_lat, zoom = sv_zoom) %>%
  addTiles(group = "OSM (default)") %>%
  addProviderTiles(providers$Stamen.Toner, group = "Toner") %>%
  addProviderTiles(providers$Stamen.TonerLite, group = "Toner Lite")

# for loop to cycle through adding layers
for(i in 1:length(s)){
  ss <- s[i]
  mtsoi <- mtsoi %>%
    addCircles(
      data = subset(origAddress, origAddress$SOI == s[i])
      , group = s[i]
      , radius = 3
      , fillOpacity = 0.6)
}

# add layercontrol
mtsoi <- mtsoi %>%
  addLayersControl(
    baseGroups = c("OSM (default)", "Toner", "Toner Lite"),
    overlayGroups = s,
    options = layersControlOptions(collapsed = FALSE
                                   , position = "bottomright")
  )

# print map
mtsoi
