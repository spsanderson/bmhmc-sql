# Credit To:
# https://jasminedumas.shinyapps.io/Choropleth_Zipcodes/#reproducible-script

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
rm(file3)

specific_state <- all_usa_zip %>%
  filter(state == "NY") %>%
  select(zip, primary_city, county)

colnames(specific_state) <- c("zipcode", "City", "County")
specific_state$zipcode <- as.factor(specific_state$zipcode)
specific_state$County <- gsub("County", "", specific_state$County)

state_join <- full_join(usa@data, specific_state)

state_clean <- na.omit(state_join)

STATE_SHP <- sp::merge(x = usa, y = state_clean, all.x = F)
head(STATE_SHP)
dim(STATE_SHP)

# #####
# # Mapping
# pal <- colorBin(palette = "BuPu", domain = STATE_SHP()$estimated_population, bins = 8)
# 
# # pop values
# state_popup <- paste0("<strong>County: </strong>", 
#                       STATE_SHP$County, 
#                       "<br><strong>City: </strong>", 
#                       STATE_SHP$City, 
#                       "<br><strong>Est. Population: </strong>",
#                       STATE_SHP$estimated_population)
# # plot the map
# leaflet(data = STATE_SHP) %>%
#   addProviderTiles("CartoDB.Positron") %>%
#   addPolygons(fillColor = ~pal(estimated_population), 
#               fillOpacity = 0.7, 
#               color = "#BDBDC3", 
#               weight = 1, 
#               popup = state_popup) %>%
#   addLegend("bottomleft", 
#             pal = pal, 
#             values = ~estimated_population,
#             title = "Est. Population",
#             opacity = 1)
