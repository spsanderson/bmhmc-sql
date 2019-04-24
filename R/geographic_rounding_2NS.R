# Lib Load ####
library(tidyverse)
library(readxl)
library(funModeling)

# File Load ####
file.to.load <- file.choose(new = T)
df <- read_xlsx(path = file.to.load, sheet = "data")
df %>% glimpse()

# Add excess days
df$excess.days <- df$DAYS_STAY - df$Index_ELOS

# Frequencies ####
freq(
  data = df
  , input = c(
    "HOSPITALIST_Pvt_CD_FLAG"
    , "Tele_Adm_Dx_Ind"
    , "TELE_FLAG"
    , "RA_FLAG"
    , "ward_cd"
  )
)

# Viz ####
# Data and AES
readmit.plt <- df %>%
  group_by(DSCH_YYYYqN, ward_cd, HOSPITALIST_Pvt_CD_FLAG) %>%
  summarise(
    Ra_Rate = round(sum(RA_FLAG) / sum(Enc_Flag), 4) * 100
    ) %>%
  ggplot(
    aes(
      x = as.factor(DSCH_YYYYqN)
      , y = Ra_Rate
      , fill = HOSPITALIST_Pvt_CD_FLAG
      )
    ) +
  # Geometries
  geom_bar(
    stat = "identity"
    , color = "black"
    , position = "dodge"
    , alpha = 0.5
    ) +
# Facets
  facet_grid(. ~ ward_cd) +
# Statistics
# Coordinates
  geom_text(
    aes(
      label = Ra_Rate
    )
    , vjust = 1.5
    , color = "black"
    , position = position_dodge(0.9)
    , size = 3
  ) +
# Theme
  labs(
    title = "Readmit Rate by Hospitalist / Pvt"
    , subtitle = "Patients discharged from 2SOU & 2NOR"
    , x = ""
    , y = ""
    , fill = "Hosp / Pvt"
  ) +
  theme(
    legend.background = element_blank()
  ) +
  theme(
    legend.key = element_blank()
  ) +
  tidyquant::theme_tq()
# Print Graph
print(readmit.plt)

# Data and AES
# Patient had to have telemetr
appropriate.tele.plt <- df %>%
  filter(TELE_FLAG == 1) %>%
  group_by(DSCH_YYYYqN, ward_cd, HOSPITALIST_Pvt_CD_FLAG) %>%
  summarise(
    App.Tele.Rate = round(sum(Tele_Adm_Dx_Ind) / sum(TELE_FLAG), 4) * 100
    ) %>%
  ggplot(
    aes(
      x = as.factor(DSCH_YYYYqN)
      , y = App.Tele.Rate
      , fill = HOSPITALIST_Pvt_CD_FLAG
    )
  ) +
  # Geometries
  geom_bar(
    stat = "identity"
    , color = "black"
    , position = "dodge"
    , alpha = 0.5
  ) +
  # Facets
  facet_grid(. ~ ward_cd) +
  # Statistics
  # Coordinates
  geom_text(
    aes(
      label = App.Tele.Rate
    )
    , vjust = 1.5
    , color = "black"
    , position = position_dodge(0.9)
    , size = 3
  ) +
  # Theme
  labs(
    title = "Telemetry Indication Rate by Hospitalist / Pvt"
    , subtitle = "Patients discharged from 2SOU & 2NOR"
    , x = ""
    , y = ""
    , fill = "Hosp / Pvt"
    , caption = "Percentage of patients who had an admitting dx for telemetry"
  ) +
  theme(
    legend.background = element_blank()
  ) +
  theme(
    legend.key = element_blank()
  ) +
  tidyquant::theme_tq()
# Print Graph
print(appropriate.tele.plt)

# Data and AES
excess.days.plt <- df %>%
  group_by(DSCH_YYYYqN, ward_cd, HOSPITALIST_Pvt_CD_FLAG) %>%
  summarise(
    excess.days.stay = round(sum(excess.days, na.rm = T), 0)
  ) %>%
  ggplot(
    aes(
      x = as.factor(DSCH_YYYYqN)
      , y = excess.days.stay
      , fill = HOSPITALIST_Pvt_CD_FLAG
    )
  ) +
# Geometries
  geom_bar(
    stat = "identity"
    , color = "black"
    , position = "dodge"
    , alpha = 0.5
  ) +
# Facets
  facet_grid(. ~ ward_cd) +
# Statistics
# Coordinates
  geom_text(
    aes(
      label = excess.days.stay
    )
    , vjust = 1.5
    , color = "black"
    , position = position_dodge(0.9)
    , size = 3
  ) +
# Theme
  labs(
    title = "Total Excess Days by Hospitalist / Pvt"
    , subtitle = "Patients discharged from 2SOU & 2NOR"
    , x = ""
    , y = ""
    , fill = "Hosp / Pvt"
    , caption = "Excess Days: Actual LOS - Exp LOS (Smaller Number is Better)"
  ) +
  theme(
    legend.background = element_blank()
  ) +
  theme(
    legend.key = element_blank()
  ) +
  tidyquant::theme_tq()
# Print Graph
print(excess.days.plt)

# Data and AES
avg.soi.plt <- df %>%
  group_by(DSCH_YYYYqN, ward_cd, HOSPITALIST_Pvt_CD_FLAG) %>%
  summarise(
    avg.soi = round(mean(Index_SOI, na.rm = T), 2)
  ) %>%
  ggplot(
    aes(
      x = as.factor(DSCH_YYYYqN)
      , y = avg.soi
      , fill = HOSPITALIST_Pvt_CD_FLAG
    )
  ) +
# Geometries
  geom_bar(
    stat = "identity"
    , color = "black"
    , position = "dodge"
    , alpha = 0.5
  ) +
# Facets
  facet_grid(. ~ ward_cd) +
# Statistics
# Coordinates
  geom_text(
    aes(
      label = avg.soi
    )
    , vjust = 1.5
    , color = "black"
    , position = position_dodge(0.9)
    , size = 3
  ) +
# Theme
  labs(
    title = "Mean SOI (Severity Of Illness) by Hospitalist / Pvt"
    , subtitle = "Patients discharged from 2SOU & 2NOR"
    , x = ""
    , y = ""
    , fill = "Hosp / Pvt"
  ) +
  theme(
    legend.background = element_blank()
  ) +
  theme(
    legend.key = element_blank()
  ) +
  tidyquant::theme_tq()
# Print Graph
print(avg.soi.plt)