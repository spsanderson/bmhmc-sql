pacman::p_load(
  "leaflet"
  ,"LICHospitalR"
  ,"odbc"
  ,"DBI"
  ,"tidyverse"
)


# DB Conn -----------------------------------------------------------------

db_conn = db_connect()

# Query -------------------------------------------------------------------

df_tbl <- dbGetQuery(
  conn = db_conn
  , statement = paste0(
    "
    SELECT A.PTNO_NUM,
    A.RESULT_CLEAN,
    B.FullAddress,
    B.lat,
    B.lon
    FROM smsdss.c_covid_extract_tbl AS A
    INNER JOIN SMSDSS.c_geocoded_address AS B ON A.PTNO_NUM = B.Encounter
    WHERE DC_DTime is not null
    AND Distinct_Visit_Flag = '1'
    AND RESULT_CLEAN in ('detected','not-detected')
    "
  )
) %>% 
  as_tibble()

# DB Disconnect -----------------------------------------------------------

db_disconnect(.connection = db_conn)


# Mapping -----------------------------------------------------------------

# Set Zoom
sv_lng  <- -72.97659
sv_lat  <- 40.78007
sv_zoom <- 9

# List of Result Clean
result_df <- split(df_tbl, df_tbl$RESULT_CLEAN)

# Inital Leaflet
base_map <- leaflet() %>%
  setView(lng = sv_lng, lat = sv_lat, zoom = sv_zoom) %>%
  addTiles(group = "OSM (default)")

# Map layers
names(result_df) %>%
  walk(function(df){
    base_map <<- base_map %>%
      addMarkers(
        data = result_df[[df]]
        , lng = ~lon
        , lat = ~lat
        , label = ~as.character(RESULT_CLEAN)
        , popup = ~as.character(
          paste(
            "Result: "
            , "<dd>",RESULT_CLEAN,"</dd>"
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
  })

final_map <- base_map %>%
  addLayersControl(
    overlayGroups = names(result_df)
    , options = layersControlOptions(collapsed = FALSE)
  )

final_map
