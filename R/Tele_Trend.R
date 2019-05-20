# Lib Load ####
install.load::install_load(
  "tidyverse"
  , "readxl"
)

# Get file ####
df <- read_excel(file.choose(new = T), sheet = "DATA")
glimpse(df)

# Processing ####
# get a count of unique encounts and ord_no per Ent_YYYYqN
distinct_visits_by_qtr <- df %>%
  group_by(Ent_YYYYqN) %>%
  distinct_at(.vars = c("Encounter")) %>%
  summarise(Visit_Count = n())
head(distinct_visits_by_qtr, 2)

distinct_orders_by_qtr <- df %>%
  group_by(Ent_YYYYqN) %>%
  distinct_at(.vars = c("ord_no")) %>%
  summarise(Order_Count = n())
head(distinct_orders_by_qtr, 2)

base_tbl <- left_join(
  distinct_visits_by_qtr
  , distinct_orders_by_qtr
  , by = "Ent_YYYYqN"
)

base_tbl <- base_tbl %>%
  mutate(Ord_Per_Visit = round((Order_Count / Visit_Count), 4))

cpoe_visits <- df %>%
  group_by(Ent_YYYYqN, ord_src_modf) %>%
  distinct_at(.vars = c("Encounter")) %>%
  summarise(Visit_Count = n())

cpoe_orders <- df %>%
  group_by(Ent_YYYYqN, ord_src_modf) %>%
  distinct_at(.vars = c("ord_no")) %>%
  summarise(Order_Count = n())

cpoe_tbl <- left_join(
  cpoe_visits
  , cpoe_orders
  , by = c("Ent_YYYYqN", "ord_src_modf")
)

cpoe_tbl <- cpoe_tbl %>%
  mutate(Ord_Per_Visit = round((Order_Count / Visit_Count), 4))

# Get yes/no for outlier from anomalize package
df$anomaly <- anomalize::iqr(df$Hours_On_Telemtry)

# Viz ####
# Data and AES
ggplot(
  data = base_tbl
  , aes(
    x = as.factor(Ent_YYYYqN)
    , weight = Ord_Per_Visit
  )
) +
  # Geometries
  geom_bar(
    fill = "#4292c6"
  ) +
  # Facets
  # Statistics
  # Coordinates
  # Theme
  labs(
    title = "Tele Orders per Visit by Quarter"
    , subtitle = "Source: DSS"
    , y = "Count"
    , x = "Order Entry Quarter"
  ) +
  theme_minimal()

# Data and Aes
cpoe_tbl %>%
  ggplot(
    aes(
      x = Ent_YYYYqN
      , weight = Ord_Per_Visit
    )
  ) +
  # Geometries
  geom_bar(
    fill = "#4292c6"
  ) +
  # Facets
  facet_grid(vars(ord_src_modf)) +
  # Statistics
  # Coordinates
  # Theme
  labs(
    title = "Tele Orders per Visit by Quarter"
    , subtitle = "Facet by CPOE Type"
    , x = "Order Entry Quarter"
    , y = "Count"
  ) +
  theme_minimal()

df %>%
  filter(Hours_On_Telemtry > 0) %>%
  filter(anomaly == "No") %>%
  # Data and AES
  ggplot(
    aes(
      x = Ent_YYYYqN
      , y = Hours_On_Telemtry
    )
  ) +
  # Geometries
  geom_boxplot(
    fill = "#4292c6"
    , outlier.color = "red"
  ) +
  # Facets
  # Statistics
  # Coordinates
  # Theme
  labs(
    title = "Hours on Telemetry by Quarter"
    , x = "Order Entry Quarter"
    , y = ""
  ) +
  theme_minimal()
  # Print Graph
