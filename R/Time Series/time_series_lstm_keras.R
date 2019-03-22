# Lib Load ####
# Core Tidyverse
library(tidyverse)
library(glue)
library(forcats)

# Time Series
library(timetk)
library(tidyquant)
library(tibbletime)

# Visualization
library(cowplot)

# Preprocessing
library(recipes)

# Sampling / Accuracy
library(rsample)
library(yardstick) 

# Modeling
library(keras)

# Get file ####
file.to.choose <- file.choose(new = T)
df <- read.csv(file.to.choose)
df <- df %>%
  mutate(index = mdy(Time)) %>%
  as_tbl_time(index = index)
head(df)

# make a monthly object
df.monthly <- df %>%
  collapse_by("monthly") %>%
  group_by(index, add = TRUE) %>%
  summarize(
    excess.rate = round(mean(EXCESS), 4)
  )
head(df.monthly)
# Get start and end dates
min.date <- min(df.monthly$index)
max.date <- max(df.monthly$index)

p1 <- df.monthly %>%
  ggplot(
    aes(
      index
      , excess.rate
    )
  ) +
  geom_point(
    color = palette_light()[[1]]
    , alpha = 0.5
  ) +
  theme_tq() +
  labs(
    title = paste0(
      "From "
      , min.date
      , " to "
      , max.date
    )
  )
print(p1)

p2 <- df.monthly %>%
  filter_time(
    "2018" ~ "end"
  ) %>%
  ggplot(
    aes(
      index
      , excess.rate
    )
  ) +
  geom_line(
    color = palette_light()[[1]]
    , alpha = 0.5
  ) +
  geom_point(
    color = palette_light()[[1]]
  ) +
  geom_smooth(
    method = "loess"
    , span = 0.2
    , se = F
  ) +
  theme_tq() +
  labs(
    title = paste0(
      "From 2018-01-01 to "
      , max.date
    )
    , caption = "Excess Readmits Data"
  )

print(p2)

p.title <- ggdraw() +
  draw_label(
    "Excess Readmits"
    , size = 18
    , fontface = "bold"
    , colour = palette_light()[[1]]
    )
plot_grid(p.title, p1, p2, ncol = 1, rel_heights = c(0.1,1,1))

# is lstm good?
tidy.acf <- function(data, excess.rate, lags = 0:20){
  value.expr <- enquo(excess.rate)
  
  acf.values <- data %>%
    pull(excess.rate) %>%
    acf(lag.max = tail(lags, 1), plot = F) %>%
    .$acf %>%
    .[,,1]
  
  ret <- tibble(acf = acf.values) %>%
    rowid_to_column(var = "lag") %>%
    mutate(lag = lag - 1) %>%
    filter(lag %in% lags)
  
  return(ret)
}

max.lag <- 12 * 2

df.monthly %>%
  tidy.acf(
    excess.rate
    , lags = 0:max.lag
  )

df.monthly %>%
  tidy.acf(excess.rate, lags = 0:max.lag) %>%
  ggplot(aes(lag, acf)) +
  geom_segment(aes(xend = lag, yend = 0), color = palette_light()[[1]]) +
  geom_vline(xintercept = 12, size = 3, color = palette_light()[[2]])

df.monthly %>%
  tidy.acf(excess.rate, lags = 6:24) %>%
  ggplot(aes(lag, acf)) +
  geom_vline(xintercept = 12, size = 3, color = palette_light()[[2]]) +
  geom_segment(aes(xend = lag, yend = 0), color = palette_light()[[1]]) +
  geom_point(color = palette_light()[[1]], size = 2) +
  geom_label(aes(label = acf %>% round(2)), vjust = -1, color = palette_light()[[1]])

optimal.lag.setting <- df.monthly %>%
  tidy.acf(excess.rate, lags = 10:24) %>%
  filter(acf == max(acf)) %>%
  pull(lag)

print(optimal.lag.setting)

periods.train <- 12 * 2
periods.test <- 12 * 1
skip.span <- 6 

rolling_origin_resamples <- rolling_origin(
  df.monthly
  , initial = periods.train
  , assess = periods.test
  , cumulative = F
  , skip = skip.span
)
rolling_origin_resamples
