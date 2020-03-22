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
origAddress <- origAddress %>%
  filter(LAT != "NULL", LON != "NULL")
origAddress$LAT <- as.numeric(origAddress$LAT)
origAddress$LON <- as.numeric(origAddress$LON)

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
ra.join <- origAddress
ra.join$ZipCode <- as.character(ra.join$ZipCode)
joined.data <- inner_join(ra.join, state_clean, by = c("ZipCode" = "zipcode"))
head(joined.data)
dim(joined.data)

rm(STATE_SHP)
rm(state_join)
rm(all_usa_zip)
rm(state_clean)
rm(specific_state)

discharges <- sum(joined.data$Pt_Count)
readmits <- sum(joined.data$Readmit_Count)

# readmits only data.frame
ra.df <- subset(joined.data, joined.data$Readmit_Count == 1)

# Choropleths ####
# Discharge Count Choropleth
dsch.count.city <- joined.data %>%
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

dsch.count.city <- as.data.frame(dsch.count.city)

dsch.count.city <- dsch.count.city %>%
  mutate(
    dsch_bin = cut(
      dsch_count, breaks = c(0,25,50,75,100,125,150,Inf)
    )
  )

dsch.count.shp <- sp::merge(
  x = usa
  , y = dsch.count.city
  , all.x = F
)

# Central Map Location settings
sv_lng <- -72.97659
sv_lat <- 40.78007
sv_zoom <- 9

pal <- colorBin(
  palette = "Dark2"
  , domain = dsch.count.shp$dsch_count
  , reverse = TRUE
)

popup <- paste(
  "<strong>County: </strong>"
  , dsch.count.shp$County
  , "<br><strong>City: </strong>"
  , dsch.count.shp$City
  , "<br><strong>Discharges: </strong>"
  , dsch.count.shp$dsch_count
)

l <- leaflet(data = dsch.count.shp) %>%
  setView(lng = sv_lng, lat = sv_lat, zoom = sv_zoom) %>%
  addTiles(group = "OSM (default)") %>%
  addProviderTiles("CartoDB.Positron") %>%
  addPolygons(
    data = dsch.count.shp
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

# Avg RRA ----
dsch.ra.city <- joined.data %>%
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
dsch.ra.city <- as.data.frame(dsch.ra.city)

dsch.ra.shp <- sp::merge(
  x = usa
  , y = dsch.ra.city
  , all.x = F
)

palRA <- colorBin(
  palette = "Dark2"
  , domain = dsch.ra.shp$RA_Rate
  #, bins = 8
  , reverse = TRUE
)

popupRA <- paste(
  "<strong>County: </strong>"
  , dsch.ra.shp$County
  , "<br><strong>City: </strong>"
  , dsch.ra.shp$City
  , "<br><strong>Discharges: </strong>"
  , dsch.ra.shp$dsch_count
  , "<br><strong>Readmit Rate: </strong>"
  , 100 * dsch.ra.shp$RA_Rate
  , "Pct."
)

ral <- leaflet(data = dsch.ra.shp) %>%
  setView(lng = sv_lng, lat = sv_lat, zoom = sv_zoom) %>%
  addTiles(group = "OSM (defaul)") %>%
  addProviderTiles("CartoDB.Positron") %>%
  addPolygons(
    data = dsch.ra.shp
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
dsch.soi.city <- joined.data %>%
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
dsch.soi.city <- as.data.frame(dsch.soi.city)

dsch.soi.shp <- sp::merge(
  x = usa
  , y = dsch.soi.city
  , all.x = F
)

palSOI <- colorBin(
  palette = "Dark2"
  , domain = dsch.soi.shp$avgSOI
  , bins = 8
  , reverse = TRUE
)

popupSOI <- paste(
  "<strong>County: </strong>"
  , dsch.soi.shp$County
  , "<br><strong>City: </strong>"
  , dsch.soi.shp$City
  , "<br><strong>Discharges: </strong>"
  , dsch.soi.shp$dsch_count
  , "<br><strong>Avg SOI: </strong>"
  , dsch.soi.shp$avgSOI
)

soil <- leaflet(data = dsch.soi.shp) %>%
  setView(lng = sv_lng, lat = sv_lat, zoom = sv_zoom) %>%
  addTiles(group = "OSM (default)") %>%
  addProviderTiles("CartoDB.Positron") %>%
  addPolygons(
    data = dsch.soi.shp
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

# Readmit Variance Map ----
dsch.cvar.city <- joined.data %>%
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
dsch.cvar.city <- as.data.frame(dsch.cvar.city)

dsch.cvar.shp <- sp::merge(
  x = usa
  , y = dsch.cvar.city
  , all.x = F
)

palcvar <- colorBin(
  palette = "Paired"
  , domain = dsch.cvar.shp$avgVar
  #, bins = 5
  , reverse = FALSE
)

popupcvar <- paste(
  "<strong>County: </strong>"
  , dsch.cvar.shp$County
  , "<br><strong>City: </strong>"
  , dsch.cvar.shp$City
  , "<br><strong>Discharges: </strong>"
  , dsch.cvar.shp$dsch_count
  ,"<br><strong>Avg Variance: </strong>"
  , dsch.cvar.shp$avgVar
)

cvarl <- leaflet(data = dsch.cvar.shp) %>%
  setView(lng = sv_lng, lat = sv_lat, zoom = sv_zoom) %>%
  addTiles(group = "OSM (default)") %>%
  addProviderTiles("CartoDB.Positron") %>%
  addPolygons(
    data = dsch.cvar.shp
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
mlmap <- leaflet(data = dsch.cvar.shp) %>%
  setView(lng = sv_lng, lat = sv_lat, zoom = sv_zoom) %>%
  addTiles(group = "OSM (default)") %>%
  addProviderTiles("CartoDB.Positron") %>%
  
  addPolygons(
    data = dsch.count.shp
    , fillColor = ~pal(dsch_count)
    , fillOpacity = 0.7
    , weight = 0.7
    , popup = popup
    , group = "Discharges"
  ) %>%
  
  addPolygons(
    data = dsch.ra.shp
    , fillColor = ~palRA(RA_Rate)
    , fillOpacity = 0.7
    , weight = 0.7
    , popup = popupRA
    , group = "Readmit Rate"
  ) %>%
  
  addPolygons(
    data = dsch.soi.shp
    , fillColor = ~palSOI(avgSOI)
    , fillOpacity = 0.7
    , weight = 0.7
    , popup = popupSOI
    , group = "SOI"
  ) %>%
  
  addPolygons(
    data = dsch.cvar.shp
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
    , values = dsch.count.shp$dsch_count
    , title = "Dsch Bin"
    , opacity = 1
  ) %>%
  
  addLegend(
    "bottomright"
    , pal = palRA
    , values = dsch.ra.shp$RA_Rate
    , title = "Readmit Rate"
    , opacity = 1
  ) %>%
  
  addLegend(
    "bottomleft"
    , pal = palSOI
    , values = dsch.soi.shp$avgSOI
    , title = "SOI Bin"
    , opacity = 1
  ) %>%
  
  addLegend(
    "topleft"
    , pal = palcvar
    , values = dsch.cvar.shp$avgVar
    , title = "Variance"
    , opacity = 1
  )

mlmap
rm(mlmap)

# Comparison Heatmaps ####
# Comparison choropleth maps
# Hospitalist v Private
hosp.ra <- joined.data %>%
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

hosp.ra <- as.data.frame(hosp.ra)

hosp.ra.shp <- sp::merge(
  x = usa
  , y = hosp.ra
  , all.x = F
)

palHRA <- colorBin(
  palette = "Dark2"
  , domain = hosp.ra.shp$ra_rate
  #, bins = 8
  , reverse = TRUE
)

popupHRA <- paste0(
  "<strong>County: </strong>"
  , hosp.ra.shp$County
  , "<br><strong>City: </strong>"
  , hosp.ra.shp$City
  , "<br><strong>Discharges: </strong>"
  , hosp.ra.shp$dsch_count
  , "<br><strong>Readmit Rate: </strong>"
  , 100 * hosp.ra.shp$ra_rate
  , "%"
  , "<br><strong>Avg SOI: </strong>"
  , hosp.ra.shp$avgSOI
  , "<br><strong>Avg CMI: </strong>"
  , hosp.ra.shp$avgCMI
  , "<br><strong>ALOS: </strong>"
  , hosp.ra.shp$alos
)

hral <- leaflet(data = hosp.ra.shp) %>%
  setView(lng = sv_lng, lat = sv_lat, zoom = sv_zoom) %>%
  addTiles(group = "OSM (default)") %>%
  addProviderTiles("CartoDB.Positron") %>%
  addPolygons(
    data = hosp.ra.shp
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

pvt.ra <- joined.data %>%
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

pvt.ra <- as.data.frame(pvt.ra)

pvt.ra.shp <- sp::merge(
  x = usa
  , y = pvt.ra
  , all.x = F
)

palPvtRA <- colorBin(
  palette = "Dark2"
  , domain = pvt.ra.shp$ra_rate
  #, bins = 8
  , reverse = TRUE
)

popupPvtRA <- paste0(
  "<strong>County: </strong>"
  , pvt.ra.shp$County
  , "<br><strong>City: </strong>"
  , pvt.ra.shp$City
  , "<br><strong>Discharges: </strong>"
  , pvt.ra.shp$dsch_count
  , "<br><strong>Readmit Rate: </strong>"
  , 100 * pvt.ra.shp$ra_rate
  , "%"
  , "<br><strong>Avg SOI: </strong>"
  , pvt.ra.shp$avgSOI
  , "<br><strong>Avg CMI: </strong>"
  , pvt.ra.shp$avgCMI
  , "<br><strong>ALOS: </strong>"
  , pvt.ra.shp$alos
)

pral <- leaflet(data = pvt.ra.shp) %>%
  setView(lng = sv_lng, lat = sv_lat, zoom = sv_zoom) %>%
  addTiles(group = "OSM (default)") %>%
  addProviderTiles("CartoDB.Positron") %>%
  addPolygons(
    data = pvt.ra.shp
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
    data = hosp.ra.shp
    , fillColor = ~palHRA(ra_rate)
    , fillOpacity = 0.7
    , weight = 0.7
    , popup = popupHRA
    , group = "Hospitalist"
  ) %>%
  
  addPolygons(
    data = pvt.ra.shp
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
    , values = hosp.ra.shp$ra_rate
    , title = "Hospitalist Readmit Rate"
    , opacity = 1
  ) %>%
  
  addLegend(
    "topright"
    , pal = palPvtRA
    , values = pvt.ra.shp$ra_rate
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
lsl <- sort(unique(origAddress$LIHN_Line))

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
      data = subset(joined.data, joined.data$LIHN_Line == lsl[i])
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
mdcl <- sort(unique(joined.data$MDCDescText))

# Create Color Palette
mdc.palette <- colorFactor(
  palette = "Dark2"
  , domain = joined.data$MDCDescText
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
      data = subset(joined.data, joined.data$MDCDescText == mdcl[i])
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
    lng = joined.data$LON
    , lat = joined.data$LAT
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
lcl <- sort(unique(joined.data$LIHN_Line))

ClusterMapLIHN <- leaflet() %>%
  setView(lng = sv_lng, lat = sv_lat, zoom = sv_zoom) %>%
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

# for loop to cycle through adding layers
for(i in 1:length(lcl)){
  ClusterMapLIHN <- ClusterMapLIHN %>%
    addMarkers(
      data = subset(joined.data, joined.data$LIHN_Line == lcl[i])
      , group = lcl[i]
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

ClusterMapLIHN <- ClusterMapLIHN %>%
  addLayersControl(
    baseGroups = c("OSM (default)", "CartoDB.Positron")
    , overlayGroups = lcl
    , options = layersControlOptions(
      collapsed = T
    )
  )

ClusterMapLIHN <- ClusterMapLIHN %>%
  addAwesomeMarkers(
    lng = sv_lng
    , lat = sv_lat
    , icon = hospMarker
    , popup = HospPopup
  )

ClusterMapLIHN
rm(ClusterMapLIHN)

# MDC Cluster Map All Discharges
mdc.cl <- sort(unique(joined.data$MDCDescText))

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
      data = subset(joined.data, joined.data$MDCDescText == mdc.cl[i])
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
