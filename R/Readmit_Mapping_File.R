# Readmit Mapping File

# Lib Load ####
# load libraries
library(ggmap)
library(leaflet)
library(readxl)
library(rgdal)
library(htmltools)
library(dplyr)
library(readr)

# RA File ####
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
MaxRpt <- max(origAddress$Rpt_Month)
MinRpt <- min(origAddress$Rpt_Month)
MaxRptYr <- substr(MaxRpt, 1, 4)
MaxRptMonth <- substr(MaxRpt, 5, 6)
MinRptYr <- substr(MinRpt, 1, 4)
MinRptMonth <- substr(MinRpt, 5, 6)

# Make USA SHP File ####
# At this point run the file get_usa_zipcode_level_2015.R Script
# create a new df/tibble to work with data and leave origAddress alone
ra_join <- origAddress
ra_join$ZipCode <- as.character(ra_join$ZipCode)
joined_data <- inner_join(ra_join, state_clean, by = c("ZipCode" = "zipcode"))
head(joined_data)
dim(joined_data)

rm(STATE_SHP)
rm(state_join)
rm(all_usa_zip)
rm(state_clean)
rm(specific_state)

discharges <- sum(joined_data$Pt_Count)
readmits <- sum(joined_data$Readmit_Count)

# readmits only data.frame
ra.df <- subset(joined_data, joined_data$Readmit_Count == 1)

# Choropleths ####
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

pal <- colorBin(
  palette = "Dark2"
  , domain = dsch_count_shp$dsch_count
  , reverse = TRUE
)

popup <- paste(
  "<strong>County: </strong>"
  , dsch_count_shp$County
  , "<br><strong>City: </strong>"
  , dsch_count_shp$City
  , "<br><strong>Discharges: </strong>"
  , dsch_count_shp$dsch_count
)

l <- leaflet(data = dsch_count_shp) %>%
  setView(lng = sv_lng, lat = sv_lat, zoom = sv_zoom) %>%
  addTiles(group = "OSM (default)") %>%
  addProviderTiles("CartoDB.Positron") %>%
  addPolygons(
    data = dsch_count_shp
    , fillColor = ~pal(dsch_count)
    , fillOpacity = 0.7
    , weight = 0.7
    , popup = popup
  ) %>%
  
  addControl(
    paste0("Discharges from: "
          , MinRptMonth
          , "-"
          , MinRptYr
          , " to "
          , MaxRptMonth
          , "-"
          , MaxRptYr
        )
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
    , values = ~dsch_count
    , title = "Discharge Bin"
    , opacity = 1
  )

l
rm(l)

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
    dsch_count = n()
    , RA_Rate = round(mean(Readmit_Count), 2)
  ) %>%
  # We want at least 10 discharges for the 6 months
  filter(
    dsch_count >= 10
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
  #, bins = 8
  , reverse = TRUE
)

popupRA <- paste(
  "<strong>County: </strong>"
  , dsch_ra_shp$County
  , "<br><strong>City: </strong>"
  , dsch_ra_shp$City
  , "<br><strong>Discharges: </strong>"
  , dsch_ra_shp$dsch_count
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
    paste0("Readmit Rate for: "
          , MinRptMonth
          , "-"
          , MinRptYr
          , " to "
          , MaxRptMonth
          , "-"
          , MaxRptYr
          , "<br>Min Discharge Count = 10"
        )
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
rm(ral)

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
    dsch_count = n()
    , avgSOI = round(mean(as.numeric(SOI)), 2)
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
  , dsch_soi_shp$County
  , "<br><strong>City: </strong>"
  , dsch_soi_shp$City
  , "<br><strong>Discharges: </strong>"
  , dsch_soi_shp$dsch_count
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
    paste0("SOI Map for: "
          , MinRptMonth
          , "-"
          , MinRptYr
          , " to "
          , MaxRptMonth
          , "-"
          , MaxRptYr
       )
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
rm(soil)
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
    dsch_count = n()
    , avgVar = round(mean(Readmit_Count - Readmit_Rate_Bench), 2)
  ) %>%
  filter(
    dsch_count >= 10
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
  #, bins = 5
  , reverse = FALSE
)

popupcvar <- paste(
  "<strong>County: </strong>"
  , dsch_cvar_shp$County
  , "<br><strong>City: </strong>"
  , dsch_cvar_shp$City
  , "<br><strong>Discharges: </strong>"
  , dsch_cvar_shp$dsch_count
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
    paste0("Avg Variance Map for: "
          , MinRptMonth
          , "-"
          , MinRptYr
          , " to "
          , MaxRptMonth
          , "-"
          , MaxRptYr
          , "<br>Min Discharge Count = 10"
    )
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
rm(cvarl)

# Multi Layer Heatmap ####
# Multi layer choropleth map
mlmap <- leaflet(data = dsch_cvar_shp) %>%
  setView(lng = sv_lng, lat = sv_lat, zoom = sv_zoom) %>%
  addTiles(group = "OSM (default)") %>%
  addProviderTiles("CartoDB.Positron") %>%
  
  addPolygons(
    data = dsch_count_shp
    , fillColor = ~pal(dsch_count)
    , fillOpacity = 0.7
    , weight = 0.7
    , popup = popup
    , group = "Discharges"
  ) %>%
  
  addPolygons(
    data = dsch_ra_shp
    , fillColor = ~palRA(RA_Rate)
    , fillOpacity = 0.7
    , weight = 0.7
    , popup = popupRA
    , group = "Readmit Rate"
  ) %>%
  
  addPolygons(
    data = dsch_soi_shp
    , fillColor = ~palSOI(avgSOI)
    , fillOpacity = 0.7
    , weight = 0.7
    , popup = popupSOI
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
    paste0("Readmit Map for: "
           , MinRptMonth
           , "-"
           , MinRptYr
           , " to "
           , MaxRptMonth
           , "-"
           , MaxRptYr
           )
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
    , values = dsch_count_shp$dsch_count
    , title = "Dsch Bin"
    , opacity = 1
  ) %>%
  
  addLegend(
    "bottomright"
    , pal = palRA
    , values = dsch_ra_shp$RA_Rate
    , title = "Readmit Rate"
    , opacity = 1
  ) %>%
  
  addLegend(
    "bottomleft"
    , pal = palSOI
    , values = dsch_soi_shp$avgSOI
    , title = "SOI Bin"
    , opacity = 1
  ) %>%
  
  addLegend(
    "topleft"
    , pal = palcvar
    , values = dsch_cvar_shp$avgVar
    , title = "Variance"
    , opacity = 1
  )

mlmap
rm(mlmap)

# Comparison Heatmaps ####
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
  ) %>%
  filter(
    dsch_count >= 10
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
  #, bins = 8
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
    paste0(
      "Hospitalist Readmit Rate for: "
      , MinRptMonth
      , "-"
      , MinRptYr
      , " to "
      , MaxRptMonth
      , "-"
      , MaxRptYr
      , "<br> Min Discharge Count = 10"
      )
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
rm(hral)

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
  ) %>%
  filter(
    dsch_count >= 10
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
  #, bins = 8
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
    paste0(
      "Private Provider Readmit Rates for: "
      , MinRptMonth
      , "-"
      , MinRptYr
      , " to "
      , MaxRptMonth
      , "-"
      , MaxRptYr
      , "<br>Min Discharge Count = 10"
      )
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
rm(pral)

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
rm(hpral)

# Facility Marker ####
hospMarker <- makeAwesomeIcon(
  icon = 'glyphicon-plus'
  , markerColor = 'lightblue'
  , iconColor = 'black'
  , library = "glyphicon"
)

HospPopup <- paste(
  "<b><a href='http://www.licommunityhospital.org/'>LI Community Hospital</a></b>"
  , "<br><strong>Data as of: </strong>"
  , MaxRptMonth,"/",MaxRptYr
  , "<br><strong>Discharges: </strong>"
  , discharges
  , "<br><strong>Readmits: </strong>"
  , readmits
)

HospLabel <- "LI Community Hospital"

# Point Maps ####
# Service Line Point Map
# Create list of LIHN Service Line
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
  addProviderTiles("CartoDB.Positron") %>%
  addControl(
    "LIHN Service Line Point Map - Last Six Months"
    , position = "topright"
    )

# for loop to cycle through adding layers
for(i in 1:length(lsl)){
  LIHNMap <- LIHNMap %>%
    addCircles(
      data = subset(joined_data, joined_data$LIHN_Line == lsl[i])
      , group = lsl[i]
      , radius = 3
      , fillOpacity = 1
      , lat = ~LAT
      , lng = ~LON
      , color = ~lihnpal(LIHN_Line)
      , label = ~htmlEscape(LIHN_Line)
      , popup = ~as.character(
        paste(
          "<strong>City :</strong>"
          , City
          , "<br><strong>Hospitalist/Private: </strong>"
          , Hospitalist_Private
          , "<br><strong>Service Line: </strong>"
          , LIHN_Line
          , "<br><strong>Readmit: </strong>"
          , Readmit_Count
          , "<br><strong>SOI: </strong>"
          , SOI
          , "<br><strong>Encounter: </strong>"
          , PtNo_Num
          , "<br><strong>Payer Group:</strong>"
          , Payor_Category
        )
      )
    )
}

# add layercontrol
LIHNMap <- LIHNMap %>%
  addLayersControl(
    baseGroups = c("OSM (default)", "CartoDB.Positron"),
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
    , label = HospLabel
    , popup = HospPopup     
  )

# print map
LIHNMap
rm(LIHNMap)

# MDC Point Map
# Get unique list of MDC Categories
mdcl <- unique(joined_data$MDCDescText)

# Create Color Palette
mdc.palette <- colorFactor(
  palette = "Dark2"
  , domain = joined_data$MDCDescText
)

# Create Initial Leaflet
mdc.map <- leaflet() %>%
  setView(lng = sv_lng, lat = sv_lat, zoom = sv_zoom) %>%
  addTiles(group = "OSM (default)") %>%
  addProviderTiles("CartoDB.Positron") %>%
  addControl("MDC Category Point Map - Last Six Months", position = "topright")

# for loop to cycle through adding layers
for(i in 1:length(mdcl)){
  mdc.map <- mdc.map %>%
    addCircles(
      data = subset(joined_data, joined_data$MDCDescText == mdcl[i])
      , group = mdcl[i]
      , radius = 3
      , fillOpacity = 1
      , lat = ~LAT
      , lng = ~LON
      , color = ~mdc.palette(MDCDescText)
      , label = ~htmlEscape(MDCDescText)
      , popup = ~as.character(
        paste(
          "<strong>City :</strong>"
          , City
          , "<br><strong>Hospitalist/Private: </strong>"
          , Hospitalist_Private
          , "<br><strong>Service Line: </strong>"
          , LIHN_Line
          , "<br><strong>Readmit: </strong>"
          , Readmit_Count
          , "<br><strong>SOI: </strong>"
          , SOI
          , "<br><strong>Encounter: </strong>"
          , PtNo_Num
          , "<br><strong>Payer Group:</strong>"
          , Payor_Category
        )
      )
    )
}

# Add layercontrol
mdc.map <- mdc.map %>%
  addLayersControl(
    baseGroups = c("OSM (default)", "CartoDB.Positron"),
    overlayGroups = mdcl,
    options = layersControlOptions(
      collapsed = TRUE
      , position = "topright"
    )
  )

mdc.map <- mdc.map %>%
  addAwesomeMarkers(
    lng = sv_lng
    , lat = sv_lat
    , icon = hospMarker
    , label = HospLabel
    , popup = HospPopup
  )

# print map
mdc.map
rm(mdc.map)

# Discharge Cluster Maps ####
# Discharge Cluster Map
mcluster <- leaflet() %>%
  setView(lng = sv_lng, lat = sv_lat, zoom = sv_zoom) %>%
  addTiles() %>% 
  addMarkers(
    lng = joined_data$LON
    , lat = joined_data$LAT
    , clusterOptions = markerClusterOptions()
  ) %>%
  addControl(
    paste0(
      "Discharges for:"
      , MinRptMonth
      , "-"
      , MinRptYr
      , " to "
      , MaxRptMonth
      , "-"
      , MaxRptYr
      )
    , position = "topright"
  )

mcluster <- mcluster %>%
  addAwesomeMarkers(
    lng = sv_lng
    , lat = sv_lat
    , icon = hospMarker
    , label = HospLabel
    , popup = HospPopup      
  )

mcluster

# Service Line Cluster Map All Discharges
LIHNCluster.df <- split(joined_data, joined_data$LIHN_Line)

ClusterMapLIHN <- leaflet() %>%
  setView(lng = sv_lng, lat = sv_lat, zoom = sv_zoom) %>%
  addTiles() %>%
  addTiles(group = "OSM (default)") %>%
  addProviderTiles("CartoDB.Positron") %>%
  addControl(
    paste0(
      "LIHN Service Line Cluster Map for: "
      , MinRptMonth
      , "-"
      , MinRptYr
      , " to "
      , MaxRptMonth
      , "-"
      , MaxRptYr
      )
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
            "<strong>City :</strong>"
            , City
            , "<br><strong>Hospitalist/Private: </strong>"
            , Hospitalist_Private
            , "<br><strong>Service Line: </strong>"
            , LIHN_Line
            , "<br><strong>Readmit: </strong>"
            , Readmit_Count
            , "<br><strong>SOI: </strong>"
            , SOI
            , "<br><strong>Encounter: </strong>"
            , PtNo_Num
            , "<br><strong>Payer Group:</strong>"
            , Payor_Category
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
    , label = HospLabel
    , popup = HospPopup      
  )

ClusterMapLIHN

rm(LIHNCluster.df)
rm(ClusterMapLIHN)

# MDC Cluster Map All Discharges
mdc.cl <- sort(unique(joined_data$MDCDescText))

ClusterMapMDC <- leaflet() %>%
  setView(lng = sv_lng, lat = sv_lat, zoom = sv_zoom) %>%
  addTiles(group = "OSM (default)") %>%
  addProviderTiles("CartoDB.Positron") %>%
  addControl(
    paste0(
      "MDC Cluster Map for: "
      , MinRptMonth
      , "-"
      , MinRptYr
      , " to "
      , MaxRptMonth
      , "-"
      , MaxRptYr
    )
    , position = "topright"
  )

# for loop to cycle through adding layers
for(i in 1:length(mdc.cl)){
  ClusterMapMDC <- ClusterMapMDC %>%
    addMarkers(
      data = subset(joined_data, joined_data$MDCDescText == mdc.cl[i])
      , group = mdc.cl[i]
      , lng = ~LON
      , lat = ~LAT
      , label = ~MDCDescText
      , popup = ~as.character(
        paste(
          "<strong>City :</strong>"
          , City
          , "<br><strong>Hospitalist/Private: </strong>"
          , Hospitalist_Private
          , "<br><strong>MDC Category: </strong>"
          , MDCDescText
          , "<br><strong>Readmit: </strong>"
          , Readmit_Count
          , "<br><strong>SOI: </strong>"
          , SOI
          , "<br><strong>Encounter: </strong>"
          , PtNo_Num
          , "<br><strong>Payer Group:</strong>"
          , Payor_Category
        )
      )
      , clusterOptions = markerClusterOptions(
        removeOutsideVisibleBounds = F
        , labelOptions = labelOptions(
          noHide = F
          , direction = 'auto'
        )
      )
    )
}

ClusterMapMDC <- ClusterMapMDC %>%
  addLayersControl(
    baseGroups = c("OSM (default)", "CartoDB.Positron")
    , overlayGroups = mdc.cl
    , options = layersControlOptions(
      collapsed = T
    )
  )

ClusterMapMDC <- ClusterMapMDC %>%
  addAwesomeMarkers(
    lng = sv_lng
    , lat = sv_lat
    , icon = hospMarker
    , label = HospLabel
    , popup = HospPopup
  )

ClusterMapMDC

rm(ClusterMapMDC)

# RA Cluster Maps ####
# LIHN Readmit Cluster Map
lsl.ra <- sort(unique(ra.df$LIHN_Line))

ClusterMapReadmitLIHN <- leaflet() %>%
  setView(lng = sv_lng, lat = sv_lat, zoom = sv_zoom) %>%
  addTiles(group = "OSM (defualt)") %>%
  addProviderTiles("CartoDB.Positron") %>%
  addControl(
    paste0(
      "LIHN Service Line Readmits Map for: "
      , MinRptMonth
      , "-"
      , MinRptYr
      , " to "
      , MaxRptMonth
      , "-"
      , MaxRptYr
    )
    , position = "topright"
  )

# for loop to cycle through adding layers
for(i in 1:length(lsl.ra)){
  ClusterMapReadmitLIHN <- ClusterMapReadmitLIHN %>%
    addMarkers(
      data = subset(ra.df, ra.df$LIHN_Line == lsl.ra[i])
      , group = lsl.ra[i]
      , lng = ~LON
      , lat = ~LAT
      , label = ~LIHN_Line
      , popup = ~as.character(
        paste(
          "<strong>City :</strong>"
          , City
          , "<br><strong>Hospitalist/Private: </strong>"
          , Hospitalist_Private
          , "<br><strong>Service Line: </strong>"
          , LIHN_Line
          , "<br><strong>Readmit: </strong>"
          , Readmit_Count
          , "<br><strong>SOI: </strong>"
          , SOI
          , "<br><strong>Encounter: </strong>"
          , PtNo_Num
          , "<br><strong>Payer Group:</strong>"
          , Payor_Category
        )
      )
      , clusterOptions = markerClusterOptions(
        removeOutsideVisibleBounds = F
        , labelOptions = labelOptions(
          noHide = F
          , direction = 'auto'
        )
      )
    )
}

ClusterMapReadmitLIHN <- ClusterMapReadmitLIHN %>%
  addLayersControl(
    baseGroups = c("OSM (default)", "CartoDB.Positron")
    , overlayGroups = lsl.ra
    , options = layersControlOptions(
      collapsed = T
    )
  )

ClusterMapReadmitLIHN <- ClusterMapReadmitLIHN %>%
  addAwesomeMarkers(
    lng = sv_lng
    , lat = sv_lat
    , icon = hospMarker
    , label = HospLabel
    , popup = HospPopup
  )

ClusterMapReadmitLIHN
rm(ClusterMapReadmitLIHN)

# MDC Readmit Cluster Map
mdc.ra <- sort(unique(ra.df$MDCDescText))

ClusterMapReadmitMDC <- leaflet() %>%
  setView(lng = sv_lng, lat = sv_lat, zoom = sv_zoom) %>%
  addTiles(group = "OSM (defualt)") %>%
  addProviderTiles("CartoDB.Positron") %>%
  addControl(
    paste0(
      "Readmits Map by MDC for: "
      , MinRptMonth
      , "-"
      , MinRptYr
      , " to "
      , MaxRptMonth
      , "-"
      , MaxRptYr
    )
    , position = "topright"
  )

# for loop to cycle through adding layers
for(i in 1:length(mdc.ra)){
  ClusterMapReadmitMDC <- ClusterMapReadmitMDC %>%
    addMarkers(
      data = subset(ra.df, ra.df$MDCDescText == mdc.ra[i])
      , group = mdc.ra[i]
      , lng = ~LON
      , lat = ~LAT
      , label = ~MDCDescText
      , popup = ~as.character(
        paste(
          "<strong>City :</strong>"
          , City
          , "<br><strong>Hospitalist/Private: </strong>"
          , Hospitalist_Private
          , "<br><strong>MDC Category: </strong>"
          , MDCDescText
          , "<br><strong>Readmit: </strong>"
          , Readmit_Count
          , "<br><strong>SOI: </strong>"
          , SOI
          , "<br><strong>Encounter: </strong>"
          , PtNo_Num
          , "<br><strong>Payer Group:</strong>"
          , Payor_Category
        )
      )
      , clusterOptions = markerClusterOptions(
        removeOutsideVisibleBounds = F
        , labelOptions = labelOptions(
          noHide = F
          , direction = 'auto'
        )
      )
    )
}

ClusterMapReadmitMDC <- ClusterMapReadmitMDC %>%
  addLayersControl(
    baseGroups = c("OSM (default)", "CartoDB.Positron")
    , overlayGroups = mdc.ra
    , options = layersControlOptions(
      collapsed = T
    )
  )

ClusterMapReadmitMDC <- ClusterMapReadmitMDC %>%
  addAwesomeMarkers(
    lng = sv_lng
    , lat = sv_lat
    , icon = hospMarker
    , label = HospLabel
    , popup = HospPopup
  )

ClusterMapReadmitMDC
rm(ClusterMapReadmitMDC)
