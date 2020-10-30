# Import GeoAdd from Census -----------------------------------------------

library(readxl)
library(odbc)
library(DBI)
library(tidyverse)

GeocodeResults <- read_excel("C:/Users/bha485/Desktop/GeocodeResults.xlsx", 
                             col_types = c("text", "text", "text", 
                                           "text"))

comma_cnt <- max(str_count(GeocodeResults$FullAddress, fixed(","))) + 1
geocoded <- GeocodeResults %>%
  separate(
    col = lon_lat
    , into = c("lon","lat")
    , sep = ","
    , remove = FALSE
    , fill = "right"
  ) %>%
  separate(
    col = FullAddress
    #, into = str_c("FullAddress_", 1:10)
    , into = str_c("FullAddress_", 1:comma_cnt)
    , sep = ","
    , remove = FALSE
    , fill = "right"
  ) %>%
  mutate_if(is.character, str_squish) %>%
  select_if(function(x) any(!is.na(x))) %>%
  mutate(ZipCode = FullAddress_4) %>%
  select(Encounter, FullAddress, ZipCode, lon, lat)

# Connection Obj ----
con <- DBI::dbConnect(
  odbc::odbc(),
  Driver = "SQL Server",
  Server = "BMH-HIDB",
  Database = "SMSPHDSSS0X0",
  Trusted_Connection = "TRUE"
)

# Insert into tbl ----
dbWriteTable(
  con
  , Id(
    schema = "smsdss"
    , table = "c_geocoded_address"
  )
  , geocoded
  , append = T
)

# Delete Dupes ----
dbGetQuery(
  conn = con
  , paste0(
    "
    DELETE X
    FROM (
    	SELECT Encounter
    	, FullAddress
    	, ZipCode
    	, lon
    	, lat
    	, RN = ROW_NUMBER() OVER(
    		PARTITION BY Encounter
    	, FullAddress
    	, ZipCode
    	, lon
    	, lat
    	ORDER BY Encounter
    	, FullAddress
    	, ZipCode
    	, lon
    	, lat
    	)
    	FROM SMSDSS.c_geocoded_address
    ) X
    WHERE X.RN > 1
    "
  )
)

# DB Disconnect ----
dbDisconnect(conn = con)
