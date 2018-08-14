# Readmit Mapping File

# load libraries
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

# Read in the csv/xlsx data dn staroe it in a variable
origAddress <- read_xlsx(fileToLoad, col_names = TRUE)
rm(fileToLoad)

# Add some structure to the data
origAddress$LIHN_Line <- as.factor(origAddress$LIHN_Svc_Line)
origAddress$SOI <- as.factor(origAddress$SEVERITY_OF_ILLNESS)
origAddress$ZipCode <- as.factor(origAddress$ZipCode)

# Number of Discharges
discharges <- nrow(origAddress)
MaxRpt <- max(origAddress$Rpt_Month)
MaxRptYr <- substr(MaxRpt, 1, 4)
MaxRptMonth <- substr(MaxRpt, 5, 6)

# At this point run the file get_usa_zipcode_level_2015.R Script
# create a new df/tibble to work with data and leave origAddress alone
ra_join <- origAddress
ra_join$ZipCode <- as.character(ra_join$ZipCode)
joined_data <- inner_join(ra_join, state_clean, by = c("ZipCode" = "zipcode"))
head(joined_data)
dim(joined_data)

# Discharge Count Choropleth
dsch_count_city <- joined_data %>%
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

dsch_count_city <- as.data.frame(dsch_count_city)

dsch_count_city <- dsch_count_city %>%
  mutate(
    dsch_bin = cut(
      dsch_count, breaks = c(0,25,50,75,100,125,150,Inf)
    )
  )

dsch_count_shp <- sp::merge(
  x = usa
  , y = dsch_count_city
  , all.x = F
)

# Central Map Location settings
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

# Avg Readmit Rate by City Map
dsch_ra_city <- joined_data %>%
  group_by(
    ZipCode
    , AFFGEOID10
    , GEOID10
    , ALAND10
    , AWATER10
    , City
    , County
  ) %>%
  summarise(
    RA_Rate = round(mean(Readmit_Count), 2)
  )
dsch_ra_city <- as.data.frame(dsch_ra_city)

dsch_ra_shp <- sp::merge(
  x = usa
  , y = dsch_ra_city
  , all.x = F
)

palRA <- colorBin(
  palette = "Dark2"
  , domain = dsch_ra_shp$RA_Rate
  , bins = 8
  , reverse = TRUE
)

popupRA <- paste(
  "<strong>County: </strong>"
  , dsch_ra_shp$County
  , "<br><strong>City: </strong>"
  , dsch_ra_shp$City
  , "<br><strong>Discharges: </strong>"
  , dsch_count_shp$dsch_count
  , "<br><strong>Readmit Rate: </strong>"
  , 100 * dsch_ra_shp$RA_Rate
  , "Pct."
)

ral <- leaflet(data = dsch_ra_shp) %>%
  setView(lng = sv_lng, lat = sv_lat, zoom = sv_zoom) %>%
  addTiles(group = "OSM (defaul)") %>%
  addProviderTiles("CartoDB.Positron") %>%
  addPolygons(
    data = dsch_ra_shp
    , fillColor = ~palRA(RA_Rate)
    , fillOpacity = 0.7
    , weight = 0.7
    , popup = popupRA
  ) %>%
  
  addControl(
    paste("Readmit Rate for:", MaxRptMonth, MaxRptYr)
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
    , pal = palRA
    , values = ~RA_Rate
    , title = "Readmit Rate"
    , opacity = 1
  )

ral
#

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

popupSOI <- paste(
  "<strong>County: </strong>"
  , dsch_ra_shp$County
  , "<br><strong>City: </strong>"
  , dsch_ra_shp$City
  , "<br><strong>Discharges: </strong>"
  , dsch_count_shp$dsch_count
  , "<br><strong>Readmit Rate: </strong>"
  , 100 * dsch_ra_shp$RA_Rate
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
    , popup = popupSOI
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

# Readmit Variance Map
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
    avgVar = round(mean(Readmit_Count - Readmit_Rate_Bench), 2)
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

popupcvar <- paste(
  "<strong>County: </strong>"
  , dsch_ra_shp$County
  , "<br><strong>City: </strong>"
  , dsch_ra_shp$City
  , "<br><strong>Discharges: </strong>"
  , dsch_count_shp$dsch_count
  , "<br><strong>Readmit Rate: </strong>"
  , 100 * dsch_ra_shp$RA_Rate
  , "<br><strong>Avg SOI: </strong>"
  , dsch_soi_shp$avgSOI
  ,"<br><strong>Avg Variance: </strong>"
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
    , popup = popupcvar
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
    , title = "Variance"
    , opacity = 1
  )
cvarl

# Multi layer choropleth map
mlmap <- leaflet(data = dsch_cvar_shp) %>%
  setView(lng = sv_lng, lat = sv_lat, zoom = sv_zoom) %>%
  addTiles(group = "OSM (default)") %>%
  addProviderTiles("CartoDB.Positron") %>%
  
  addPolygons(
    data = dsch_count_shp
    , fillColor = ~pal(dsch_bin)
    , fillOpacity = 0.7
    , weight = 0.7
    , popup = popupcvar
    , group = "Discharges"
  ) %>%
  
  addPolygons(
    data = dsch_ra_shp
    , fillColor = ~palRA(RA_Rate)
    , fillOpacity = 0.7
    , weight = 0.7
    , popup = popupcvar
    , group = "Readmit Rate"
  ) %>%
  
  addPolygons(
    data = dsch_soi_shp
    , fillColor = ~palSOI(avgSOI)
    , fillOpacity = 0.7
    , weight = 0.7
    , popup = popupcvar
    , group = "SOI"
  ) %>%
  
  addPolygons(
    data = dsch_cvar_shp
    , fillColor = ~palcvar(avgVar)
    , fillOpacity = 0.7
    , weight = 0.7
    , popup = popupcvar
    , group = "Readmit Variance"
  ) %>%
  
  addControl(
    paste("Readmit Map for:", MaxRptMonth, MaxRptYr)
    , position = "topright"
  ) %>%
  
  addLayersControl(
    baseGroups = c("OSM (default)", "CartoDB.Positron")
    , overlayGroups = c("Discharges", "Readmit Rate", "SOI", "Readmit Variance")
    , options =
      layersControlOptions(
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
    , pal = palRA
    , values = dsch_ra_shp$RA_Rate
    , title = "Readmit Rate"
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
    , title = "Variance"
    , opacity = 1
  )

mlmap

#####
# Comparison choropleth maps
# Hospitalist v Private
hosp_ra <- joined_data %>%
  filter(
    Hospitaslit_Private_Flag == 1
  ) %>%
  group_by(
    ZipCode
    , AFFGEOID10
    , ALAND10
    , AWATER10
    , City
    , County
  ) %>%
  summarize(
    dsch_count = n()
    , ra_rate = round(mean(Readmit_Count), 2)
    , avgSOI = round(mean(SEVERITY_OF_ILLNESS), 2)
    , avgCMI = round(mean(drg_cost_weight), 4)
    , alos = round(mean(LOS), 2)
  )

hosp_ra <- as.data.frame(hosp_ra)

hosp_ra_shp <- sp::merge(
  x = usa
  , y = hosp_ra
  , all.x = F
)

palHRA <- colorBin(
  palette = "Dark2"
  , domain = hosp_ra_shp$ra_rate
  , bins = 8
  , reverse = TRUE
)

popupHRA <- paste(
  "<strong>County: </strong>"
  , hosp_ra_shp$County
  , "<br><strong>City: </strong>"
  , hosp_ra_shp$City
  , "<br><strong>Discharges: </strong>"
  , hosp_ra_shp$dsch_count
  , "<br><strong>Readmit Rate: </strong>"
  , 100 * hosp_ra_shp$ra_rate
  , "Pct."
  , "<br><strong>Avg SOI: </strong>"
  , hosp_ra_shp$avgSOI
  , "<br><strong>Avg CMI: </strong>"
  , hosp_ra_shp$avgCMI
  , "<br><strong>ALOS: </strong>"
  , hosp_ra_shp$alos
)

hral <- leaflet(data = hosp_ra_shp) %>%
  setView(lng = sv_lng, lat = sv_lat, zoom = sv_zoom) %>%
  addTiles(group = "OSM (default)") %>%
  addProviderTiles("CartoDB.Positron") %>%
  addPolygons(
    data = hosp_ra_shp
    , fillColor = ~palHRA(ra_rate)
    , fillOpacity = 0.7
    , weight = 0.7
    , popup = popupHRA
  ) %>%
  
  addControl(
    paste("Hospitalist Readmit Rate for: ", MaxRptMonth, MaxRptYr)
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
    , pal = palHRA
    , values = ~ra_rate
    , title = "Hospitalist Readmit Rate"
    , opacity = 1
  )

hral

pvt_ra <- joined_data %>%
  filter(
    Hospitaslit_Private_Flag == 0
  ) %>%
  group_by(
    ZipCode
    , AFFGEOID10
    , ALAND10
    , AWATER10
    , City
    , County
  ) %>%
  summarize(
    dsch_count = n()
    , ra_rate = round(mean(Readmit_Count), 2)
    , avgSOI = round(mean(SEVERITY_OF_ILLNESS), 2)
    , avgCMI = round(mean(drg_cost_weight), 4)
    , alos = round(mean(LOS), 2)
  )

pvt_ra <- as.data.frame(pvt_ra)

pvt_ra_shp <- sp::merge(
  x = usa
  , y = pvt_ra
  , all.x = F
)

palPvtRA <- colorBin(
  palette = "Dark2"
  , domain = pvt_ra_shp$ra_rate
  , bins = 8
  , reverse = TRUE
)

popupPvtRA <- paste(
  "<strong>County: </strong>"
  , pvt_ra_shp$County
  , "<br><strong>City: </strong>"
  , pvt_ra_shp$City
  , "<br><strong>Discharges: </strong>"
  , pvt_ra_shp$dsch_count
  , "<br><strong>Readmit Rate: </strong>"
  , 100 * pvt_ra_shp$ra_rate
  , "Pct."
  , "<br><strong>Avg SOI: </strong>"
  , pvt_ra_shp$avgSOI
  , "<br><strong>Avg CMI: </strong>"
  , pvt_ra_shp$avgCMI
  , "<br><strong>ALOS: </strong>"
  , pvt_ra_shp$alos
)

pral <- leaflet(data = pvt_ra_shp) %>%
  setView(lng = sv_lng, lat = sv_lat, zoom = sv_zoom) %>%
  addTiles(group = "OSM (default)") %>%
  addProviderTiles("CartoDB.Positron") %>%
  addPolygons(
    data = pvt_ra_shp
    , fillColor = ~palPvtRA(ra_rate)
    , fillOpacity = 0.7
    , weight = 0.7
    , popup = popupPvtRA
  ) %>%
  
  addControl(
    paste("Private Provider Readmit Rates for:", MaxRptMonth, MaxRptYr)
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
    , pal = palPvtRA
    , values = ~ra_rate
    , title = "Private Readmit Rate"
    , opacity = 1
  )

pral

# combined Hosp / Pvt readmit maps
hpral <- leaflet() %>%
  setView(lng = sv_lng, lat = sv_lat, zoom = sv_zoom) %>%
  addTiles(group = "OSM (default)") %>%
  addProviderTiles("CartoDB.Positron") %>%
  
  addPolygons(
    data = hosp_ra_shp
    , fillColor = ~palHRA(ra_rate)
    , fillOpacity = 0.7
    , weight = 0.7
    , popup = popupHRA
    , group = "Hospitalist"
  ) %>%
  
  addPolygons(
    data = pvt_ra_shp
    , fillColor = ~palPvtRA(ra_rate)
    , fillOpacity = 0.7
    , weight = 0.7
    , popup = popupPvtRA
    , group = "Private"
  ) %>%
  
  addControl(
    paste("Readmit Map for:", MaxRptMonth, MaxRptYr)
    , position = "topright"
  ) %>%
  
  addLayersControl(
    baseGroups = c("OSM (default)", "CartoDB.Positron")
    , overlayGroups = c("Hospitalist", "Private")
    , position = "topright"
    , options = layersControlOptions(
      collapsed = FALSE
      , position = "topright"
    )
  ) %>%
  
  addLegend(
    "topright"
    , pal = palHRA
    , values = hosp_ra_shp$ra_rate
    , title = "Hospitalist Readmit Rate"
    , opacity = 1
  ) %>%
  
  addLegend(
    "topright"
    , pal = palPvtRA
    , values = pvt_ra_shp$ra_rate
    , title = "Private Readmit Rate"
    , opacity = 1
  )

hpral


#####################################
# Service Line Point Map
# Get unique list of groups needed
HospPopup <- paste(
  "<b><a href='http://www.brookhavenhospital.org/'>BMHMC</a></b>"
  , "<br><strong>Discharges for: </strong>"
  , MaxRptMonth,"/",MaxRptYr
  , "<br><strong>Discharges: </strong>"
  , discharges
)

Popup <- paste(
    "<strong>Hospitalist/Private: </strong>"
    , joined_data$Hospitalist_Private
    , "<br><strong>Service Line: </strong>"
    , joined_data$LIHN_Line
    , "<br><strong>Readmit: </strong>"
    , joined_data$Readmit_Count
    , "<br><strong>SOI: </strong>"
    , joined_data$SOI
    , "<br><strong>Encounter: </strong>"
    , joined_data$PtNo_Num
    , "<br><strong>Payer Group:</strong>"
    , joined_data$Payor_Category
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
      data = subset(joined_data, joined_data$LIHN_Line == lsl[i])
      , group = lsl[i]
      , radius = 3
      , fillOpacity = 1
      , color = ~lihnpal(LIHN_Line)
      , label = ~htmlEscape(LIHN_Line)
      , popup = Popup
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
    , label = "BMHMC"
    , popup = HospPopup     
  )

# print map
LIHNMap

#############################
# Cluster Maps
#
# Discharge Cluster Map
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
    lng = origAddress$LON
    , lat = origAddress$LAT
    , clusterOptions = markerClusterOptions()
  ) %>%
  addControl(
    paste("Discharges for:", MaxRptMonth, MaxRptYr)
    , position = "topright"
  )

mcluster <- mcluster %>%
  addAwesomeMarkers(
    lng = sv_lng
    , lat = sv_lat
    , icon = hospMarker
    , label = "BMHMC"
    , popup = paste(
      "<b><a href='http://www.brookhavenhospital.org/'>BMHMC</a></b>"
      , "<br><strong>Discharges for: </strong>"
      , MaxRptMonth,"/",MaxRptYr
      , "<br><strong>Discharges: </strong>"
      , discharges
    )      
  )

mcluster

# Service Line Cluster Map
LIHNCluster.df <- split(joined_data, joined_data$LIHN_Line)

ClusterMapLIHN <- leaflet() %>%
  setView(lng = sv_lng, lat = sv_lat, zoom = sv_zoom) %>%
  addTiles() %>%
  addTiles(group = "OSM (default)") %>%
  addProviderTiles("CartoDB.Positron") %>%
  addControl(
    paste("LIHN Service Line Cluster Map for:", MaxRptMonth, MaxRptYr)
    , position = "topright"
    )

names(LIHNCluster.df) %>%
  purrr::walk( function(df) {
    ClusterMapLIHN <<- ClusterMapLIHN %>%
      addMarkers(
        data = LIHNCluster.df[[df]]
        , lng = ~LON
        , lat = ~LAT
        , label = ~as.character(LIHN_Line)
        , popup = ~as.character(
          paste(
            sep = "<br/>"
            , "<strong>Encounter: </strong>"
            , PtNo_Num
            , "<strong>Service Line: </strong>"
            , LIHN_Line
            , "<strong>Hospitalist/Private: </strong>"
            , Hospitalist_Private
            , "<strong>Payor Category </strong>"
            , Payor_Category
            , "<strong>SOI: </strong>"
            , SOI
            , "<strong>Readmit: </strong>"
            , Readmit_Count
            # , "<strong>Address: </strong>"
            # , FullAddress
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
    baseGroups = c("OSM (default)", "CartoDB.Positron")
    , overlayGroups = names(LIHNCluster.df)
    , options = layersControlOptions(
      collapsed = TRUE
      )
  )

ClusterMapLIHN <- ClusterMapLIHN %>%
  addAwesomeMarkers(
    lng = sv_lng
    , lat = sv_lat
    , icon = hospMarker
    , label = "BMHMC"
    , popup = HospPopup      
  )

ClusterMapLIHN
