# Lib Load ####
library(tidyverse)

# Load File ####
filetoload <- file.choose(new = T)
df <- read.csv(filetoload, header = T, sep = ",")
# make df a tibble
df.tibble <- as_tibble(df)
# glimpse() tibble
df.tibble %>% glimpse()
# format Date to lubridate::mdy()
df.tibble$Date <- lubridate::mdy(df.tibble$Date)

# Mk Duration Cols ####
## All in minutes
# Anes LOS
df.tibble$Anes_LOS <- difftime(
  strptime(df.tibble$Anes_End_Time_Formatted, format = "%H:%M")
  , strptime(df.tibble$Anes_Start_Time_Formatted, format = "%H:%M")
  , units = "mins"
)
# Surgery LOS
df.tibble$Sx_LOS <- difftime(
  strptime(df.tibble$Sx_End_Time_Formatted, format = "%H:%M")
  , strptime(df.tibble$Sx_Start_Time_Formatted, format = "%H:%M")
  , units = "mins"
)
# PACU LOS
df.tibble$PACU_LOS <- difftime(
  strptime(df.tibble$PACU_Dsch_Time, format = "%H:%M")
  , strptime(df.tibble$PACU_Arrival_Time, format = "%H:%M")
  , units = "mins"
)
# ASU Los
df.tibble$ASU_LOS <- difftime(
  strptime(df.tibble$ASU_Dsch_Time, format = "%H:%M")
  , strptime(df.tibble$ASU_Arrival_Time, format = "%H:%M")
  , units = "mins"
)
# Total LOS
df.tibble <- mutate(
  .data = df.tibble
  , Total_LOS_Minutes = (
    # kick out NA from values in order to coerce to 0
    ifelse(
      is.na(Sx_LOS)
      , 0
      , Sx_LOS
    ) +
      ifelse(
        is.na(Anes_LOS)
        , 0
        , Anes_LOS
      ) +
      ifelse(
        is.na(PACU_LOS)
        , 0
        , PACU_LOS
      ) +
      ifelse(
        is.na(ASU_LOS)
        , 0
        , ASU_LOS
      )
  )
)

df.tibble <- mutate(
  .data = df.tibble
  , MM_Given = 
    ifelse(
      (
        substring(
          MM_Drugs_Given
          , 1
          , 1
        ) == "Y" |
        substring(
          MM_Drugs_Given
          , 1
          , 1
        ) == 'y'
      )
      , "Yes"
      , "No"
    )
)

# Split Sets ####
# Split sets on age >= 50 and age < 50
# df.fifty.over <- df.tibble %>%
#   filter(Age >= 50)
# 
# df.fifty.over.clean <- df.fifty.over %>%
#   filter(
#     Total_LOS_Minutes > 0
#   )
# 
# df.under.fifty <- df.tibble %>%
#   filter(Age < 50)
# max(df.under.fifty$Age)
# 
# df.under.fifty.clean <- df.under.fifty %>%
#   filter(
#     Total_LOS_Minutes > 0
#   )

# Clean master df
df.tibble.clean <- df.tibble %>%
  filter(Total_LOS_Minutes > 0)

# Visualizations ####
# Age vs Total LOS Scatter Plot
# Data and AES
tl.plt <- ggplot(
  data = df.tibble.clean
  , aes(
    x = Age
    , y = Total_LOS_Minutes
    , color = MM_Given
  )
)
# Geometries
tl.plt <- tl.plt +
  geom_point(
    aes(
      size = Total_LOS_Minutes
    )
    , alpha = 0.618
  ) +
  scale_size_area()
# Facets
# Statistics
tl.plt <- tl.plt + 
  stat_smooth(se = F, method = "lm")
# Coordinates
# Theme
tl.plt <- tl.plt +
  labs(
    title = "Age vs Total LOS in Minutes"
    , subtitle = "Linear Trend"
    , y = "Total LOS in Minutes"
    , x = "Age"
  ) +
  theme(
    legend.background = element_blank()
  ) +
  theme(
    legend.key = element_blank()
  ) +
  labs(color = "MM Given", size = "Total LOS\n(minutes)")
# Print
print(tl.plt)

# MM given Total LOS Box plot
# Date and AES
mm.given.tl.plt <- ggplot(
  data = df.tibble.clean
  , aes(
    x = MM_Given
    , y = Total_LOS_Minutes
    , fill = MM_Given
  )
)
# Geometries
mm.given.tl.plt <- mm.given.tl.plt +
  geom_boxplot(
    alpha = 0.618
  )
# Facetes
# Statistics
# Coordinates
# Theme
mm.given.tl.plt <- mm.given.tl.plt +
  labs(
    title = "Total Length of Stay in Minutes"
    , subtitle = "Grouped by Multi-Modal Drugs Given: Yes/No"
    , y = "Total Los in Minutes"
    , x = "Multi-Modal Drugs"
  ) +
  theme(
    legend.background = element_blank()
  ) +
  theme(
    legend.key = element_blank()
  ) +
  labs(fill = "MM Given")
# Print Graph
print(mm.given.tl.plt)

# Surgical Duration Scatter Plot
# Data and AES
sxlos.plt <- ggplot(
  data = df.tibble.clean
  , aes(
    x = Age
    , y = Sx_LOS
    , color = MM_Given
  )
)
# Geometries
sxlos.plt <- sxlos.plt +
  geom_point(
    aes(
      size = Sx_LOS
    )
    , alpha = 0.618
  ) +
  scale_size_area()
# Facets
# Statistics
sxlos.plt <- sxlos.plt + 
  stat_smooth(se = F, method = "lm")
# Coordinates
# Theme
sxlos.plt <- sxlos.plt + 
  labs(
    title = "Age vs Surgical LOS in Minutes"
    , subtitle = "Linear Trend"
    , y = "Total Surgical LOS in Minutes"
    , x = "Age"
  ) +
  theme(
    legend.background = element_blank()
  ) +
  theme(
    legend.key = element_blank()
  ) +
  labs(color = "MM Given", size = "Surgical LOS\n(minutes)")
# Print
print(sxlos.plt)

# MM given Surgical LOS Box plot
# Date and AES
mm.given.sxlos.plt <- ggplot(
  data = df.tibble.clean
  , aes(
    x = MM_Given
    , y = Sx_LOS
    , fill = MM_Given
  )
)
# Geometries
mm.given.sxlos.plt <- mm.given.sxlos.plt +
  geom_boxplot(
    alpha = 0.618
  )
# Facetes
# Statistics
# Coordinates
# Theme
mm.given.sxlos.plt <- mm.given.sxlos.plt +
  labs(
    title = "Surgical Length of Stay in Minutes"
    , subtitle = "Grouped by Multi-Modal Drugs Given: Yes/No"
    , y = "Surgical Los in Minutes"
    , x = "Multi-Modal Drugs"
  ) +
  theme(
    legend.background = element_blank()
  ) +
  theme(
    legend.key = element_blank()
  ) +
  labs(fill = "MM Given")
# Print Graph
print(mm.given.sxlos.plt)

# Age v PACU Pain Scatter Plot
# Data and AES
age.pacupain.plt <- df.tibble.clean %>%
  filter(PACU_Pain_Score > 0) %>%
  ggplot(
    aes(
      x = Age
      , y = PACU_Pain_Score
      , color = MM_Given
      )
  )
# Geomoetries
age.pacupain.plt <-age.pacupain.plt +
  geom_point(
    aes(
      size = PACU_Pain_Score
    )
    , alpha = 0.618
  ) +
  scale_size_area()
# Facets
# Statistics
age.pacupain.plt <- age.pacupain.plt + 
  stat_smooth(
    se = F
    , method = "lm"
  )
# Coordinates
# Theme
age.pacupain.plt <- age.pacupain.plt + 
  labs(
    title = "PACU Pain Score"
    , subtitle = "Linear Trend - Pain Score > 0"
    , y = "Pain Score"
    , x = "Age"
  ) +
  theme(
    legend.background = element_blank()
  ) +
  theme(
    legend.key = element_blank()
  ) +
  labs(color = "MM Given", size = "Pain Score")
# Print
print(age.pacupain.plt)

# PACU Pain Score Box Plot
# Data and AES
mm.given.pacupain.plt <- df.tibble.clean %>%
  filter(PACU_Pain_Score > 0) %>%
  ggplot(
    aes(
      x = MM_Given
      , y = PACU_Pain_Score
      , fill = MM_Given
      )
    )
# Geomoetries
mm.given.pacupain.plt <- mm.given.pacupain.plt +
  geom_boxplot(
    alpha = 0.618
  )
# Facets
# Statistics
# Coordinates
# Theme
mm.given.pacupain.plt <- mm.given.pacupain.plt +
  labs(
    title = "PACU Pain Score"
    , subtitle = "Grouped by Multi-Modal Drugs Given: Yes/No - Pain Score > 0"
    , y = "Pain Score"
    , x = "Multi-Modal Drugs"
  ) +
  theme(
    legend.background = element_blank()
  ) +
  theme(
    legend.key = element_blank()
  ) +
  labs(
    fill = "MM Given"
  )
# Print Graph
print(mm.given.pacupain.plt)

# Age v PACU Pain Score at PACU Discharge
# Data and AES
age.dsch.pacupain.plt <- df.tibble.clean %>%
  filter(Discharge_PACU_Pain_Score > 0) %>%
  ggplot(
   aes(
    x = Age
    , y = Discharge_PACU_Pain_Score
    , color = MM_Given
  )
)
# Geomoetries
age.dsch.pacupain.plt <- age.dsch.pacupain.plt +
  geom_point(
    aes(
      size = Discharge_PACU_Pain_Score
    )
    , alpha = 0.618
  )
# Facets
# Statistics
age.dsch.pacupain.plt <- age.dsch.pacupain.plt +
  stat_smooth(
    se = F
    , method = "lm"
  )
# Coordinates
# Theme
age.dsch.pacupain.plt <- age.dsch.pacupain.plt +
  labs(
    title = "Age vs PACU Pain Score at PACU Discharge"
    , subtitle = "Linear Trend - Pain Score > 0"
    , y = "Pain Score"
    , x = "Age"
  ) +
  theme(
    legend.background = element_blank()
  ) +
  theme(
    legend.key = element_blank()
  ) +
  labs(color = "MM Given", size = "Dsch PACU\nPain Score")
# Print Graph
print(age.dsch.pacupain.plt)

# PACU Pain Score at discharge boxplot
# Data and AES
dsch.pacupain.boxplot <- df.tibble.clean %>%
  filter(Discharge_PACU_Pain_Score > 0) %>%
  ggplot(
    aes(
      x = MM_Given
      , y = Discharge_PACU_Pain_Score
      , fill = MM_Given
    )
  
  )
# Geomoetries
dsch.pacupain.boxplot <- dsch.pacupain.boxplot +
  geom_boxplot(
    alpha = 0.618
  )
# Facets
# Statistics
# Coordinates
# 
dsch.pacupain.boxplot <- dsch.pacupain.boxplot +
  labs(
    title = "Discharge PACU Pain Score Boxplot"
    , subtitle = "Grouped by Multi-Modal Drugs Give: Yes/No - Discharge PACU Pain Score > 0"
    , y = "Discharge PACU Pain Score"
    , x = "Multi-Modal Drugs"
  ) +
  theme(
    legend.background = element_blank()
  ) +
  theme(
    legend.key = element_blank()
  ) +
  labs(fill = "MM Given")
# Print Graph
print(dsch.pacupain.boxplot)

# Age v Propofol mg given Scatterplot
# Data and AES
age.propofol.plt <- df.tibble.clean %>%
  filter(Propofol_mg <= 500) %>%
  filter(Propofol_Flag == 1) %>%
  ggplot(
    aes(
      x = Age
      , y = Propofol_mg
      , color = MM_Given
    )
  )
# Geomoetries
age.propofol.plt <- age.propofol.plt +
  geom_point(
    aes(
      size = Propofol_mg
    )
    , alpha = 0.618
  ) +
  scale_size_area()
# Facets
# Statistics
age.propofol.plt <- age.propofol.plt +
  stat_smooth(
    se = F
    , method = "lm"
  )
# Coordinates
# Theme
age.propofol.plt <- age.propofol.plt +
  labs(
    title = "Age vs Propofol mg"
    , subtitle = "Grouped by Multi-Modal Drugs Given: Yes/No with Linear Trend"
    , caption = "For patients who recieved Propofol and mg <= 500(mg) - 5 Cases had mg > 500"
    , y = "Propofol (mg)"
    , x = "Age"
  ) +
  theme(
    legend.background = element_blank()
  ) +
  theme(
    legend.key = element_blank()
  ) +
  labs(color = "MM given", size = "Propofol(mg)")
# Print Graph
print(age.propofol.plt)

# Age v Propofol mg given boxplot
# Data and AES
age.propofol.boxplot <- df.tibble.clean %>%
  filter(Propofol_mg <= 500) %>%
  filter(Propofol_Flag == 1) %>%
  ggplot(
    aes(
      x = Age
      , y = Propofol_mg
      , fill = MM_Given
    )
  )
# Geomoetries
age.propofol.boxplot <- age.propofol.boxplot +
  geom_boxplot(
    alpha = 0.618
  )
# Facets
# Statistics
# Coordinates
# Theme
age.propofol.boxplot <- age.propofol.boxplot +
  labs(
    title = "Propofol(mg) Given Boxplot"
    , subtitle = "Grouped by Multi-Modal Drugs Given: Yes/No"
    , caption = "For patients who recieved Propofol and mg <= 500(mg) - 5 Cases had mg > 500"
    , y = "Propofol (mg)"
    , x = "Multi-Modal Drugs"
  ) +
  theme(
    legend.background = element_blank()
  ) +
  theme(
    legend.key = element_blank()
  ) +
  labs(fill = "MM Given")
# Print Graph
print(age.propofol.boxplot)

# Age v Fent(mcg) Given Scatterplot
# Data and AES
age.fent.plt <- df.tibble.clean %>%
  filter(Fentanyl_OR_Flag == 1) %>%
  ggplot(
    aes(
      x = Age
      , y = Fentanyl_mcg_in_OR
      , color = MM_Given
    )
  )
# Geomoetries
age.fent.plt <- age.fent.plt +
  geom_point(
    aes(
      size = Fentanyl_mcg_in_OR
    )
    , alpha = 0.618
  ) +
  scale_size_area()
# Facets
# Statistics
age.fent.plt <- age.fent.plt +
  stat_smooth(
    se = F
    , method = "lm"
  )
# Coordinates
# Theme
age.fent.plt <- age.fent.plt +
  labs(
    title = "Age vs Fentanyl(mcg) given in OR"
    , subtitle = "Grouped by Multi-MOdal Drugs Given: Yes/No with Linear Trend"
    , y = "Fentenyl(mcg)"
    , x = "Age"
  ) +
  theme(
    legend.background = element_blank()
  ) +
  theme(
    legend.key = element_blank()
  ) +
  labs(color = "MM Given", size = "Fentenyl(mcg)")
# Print Graph
print(age.fent.plt)

# Age v Fent(mcg) boxplot
# Data and AES
age.fent.boxplot <- df.tibble.clean %>%
  filter(Fentanyl_OR_Flag == 1) %>%
  ggplot(
    aes(
      x = Age
      , y = Fentanyl_mcg_in_OR
      , fill = MM_Given
    )
  )
# Geomoetries
age.fent.boxplot <- age.fent.boxplot +
  geom_boxplot(
    alpha = 0.618
  )
# Facets
# Statistics
# Coordinates
# Theme
age.fent.boxplot <- age.fent.boxplot +
  labs(
    title = "Fentenyl(mcg) Given in OR Boxplot"
    , subtitle = "Grouped by Multi-Modal Drugs Give: Yes/No"
    , y = "Fentenyl(mcg)"
    , x = "Multi-Modal Drugs"
  ) +
  theme(
    legend.background = element_blank()
  ) +
  theme(
    legend.key = element_blank()
  ) +
  labs(
    color = "MM Given"
  )
# Print Graph
print(age.fent.boxplot)

# Dilaudid Fent Equiv scatterplot
# Data and AES
age.dilaud.fent.equiv.plt <- df.tibble.clean %>%
  filter(Fent_Equiv_Flag == 1) %>%
  ggplot(
    aes(
      x = Age
      , y = Total_Fent_equiv_In_PACU
      , color = MM_Given
    )
  )
# Geomoetries
age.dilaud.fent.equiv.plt <- age.dilaud.fent.equiv.plt +
  geom_point(
    aes(
      size = Total_Fent_equiv_In_PACU
    )
    , alpha = 0.618
  )
# Facets
# Statistics
age.dilaud.fent.equiv.plt <- age.dilaud.fent.equiv.plt +
  stat_smooth(
    se = F
    , method = "lm"
  )
# Coordinates
# Theme
age.dilaud.fent.equiv.plt <- age.dilaud.fent.equiv.plt +
  labs(
    title = "Age vs Fent/Dialudid Fent Equivalent"
    , subtitle = "Grouped by Multi-Modal Drugs Given: Yes/No with Linear Trend"
    , y = "Fent/Dialudid Fent Equivalent"
    , x = "Age"
  ) +
  theme(
    legend.background = element_blank()
  ) +
  theme(
    legend.key = element_blank()
  ) +
  labs(color = "MM Given", size = "Fent Equiv")
# Print Graph
print(age.dilaud.fent.equiv.plt)

# Dilaudid Fent Equiv boxplot
# Data and AES
age.dilaud.fent.equiv.boxplot <- df.tibble.clean %>%
  filter(Fent_Equiv_Flag == 1) %>%
  ggplot(
    aes(
      x = Age
      , y = Total_Fent_equiv_In_PACU
      , fill = MM_Given
    )
  )
# Geomoetries
age.dilaud.fent.equiv.boxplot <- age.dilaud.fent.equiv.boxplot +
  geom_boxplot(
    alpha = 0.618
  )
# Facets
# Statistics
# Coordinates
# Theme
age.dilaud.fent.equiv.boxplot <- age.dilaud.fent.equiv.boxplot +
  labs(
    title = "Fen/Dialudid Fent Equivalent Boxplot"
    , subtitle = "Grouped by Multi-Modal Drugs Given: Yes/No"
    , y = "Fent/Dialudid Fent Equivalent"
    , x = "Multi-Modal Given"
  ) +
  theme(
    legend.background = element_blank()
  ) +
  theme(
    legend.key = element_blank()
  ) +
  labs(fill = "MM Given")
# Print Graph
print(age.dilaud.fent.equiv.boxplot)
