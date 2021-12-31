# Lib Load ####
library(gganimate)
library(gifski)
library(tidyverse)

# Load File ####
file.to.choose <- "G:\\R Studio Projects\\ED_Avg_Hourly_Census\\data.csv"
df <- read.csv(file.to.choose)
df.tibble <- as_tibble(df)
head(df.tibble, 5)

# Tidy ####
df.arrivals <- df.tibble %>%
  filter(Data_Label == "Average Arrivals/Hr")
head(df.arrivals)

df.census <- df.tibble %>%
  filter(Data_Label == "Average Census/Hr")
head(df.census)

df.census.gathered <- gather(
  df.census,
  `Hr0`,
  `Hr1`,
  `Hr2`,
  `Hr3`,
  `Hr4`,
  `Hr5`,
  `Hr6`,
  `Hr7`,
  `Hr8`,
  `Hr9`,
  `Hr10`,
  `Hr11`,
  `Hr12`,
  `Hr13`,
  `Hr14`,
  `Hr15`,
  `Hr16`,
  `Hr17`,
  `Hr18`,
  `Hr19`,
  `Hr20`,
  `Hr21`,
  `Hr22`,
  `Hr23`,
  key = "Census_Hour",
  value = "Census"
)
df.census.gathered$Census_Hour <- factor(
  df.census.gathered$Census_Hour,
  levels = c(
    "Hr0",
    "Hr1",
    "Hr2",
    "Hr3",
    "Hr4",
    "Hr5",
    "Hr6",
    "Hr7",
    "Hr8",
    "Hr9",
    "Hr10",
    "Hr11",
    "Hr12",
    "Hr13",
    "Hr14",
    "Hr15",
    "Hr16",
    "Hr17",
    "Hr18",
    "Hr19",
    "Hr20",
    "Hr21",
    "Hr22",
    "Hr23"
  ),
  ordered = T
)

df.arrivals.gathered <- gather(
  df.arrivals,
  `Hr0`,
  `Hr1`,
  `Hr2`,
  `Hr3`,
  `Hr4`,
  `Hr5`,
  `Hr6`,
  `Hr7`,
  `Hr8`,
  `Hr9`,
  `Hr10`,
  `Hr11`,
  `Hr12`,
  `Hr13`,
  `Hr14`,
  `Hr15`,
  `Hr16`,
  `Hr17`,
  `Hr18`,
  `Hr19`,
  `Hr20`,
  `Hr21`,
  `Hr22`,
  `Hr23`,
  key = "Arrival_Hour",
  value = "Arrivals"
)
df.arrivals.gathered$Arrival_Hour <- factor(
  df.arrivals.gathered$Arrival_Hour,
  levels = c(
    "Hr0",
    "Hr1",
    "Hr2",
    "Hr3",
    "Hr4",
    "Hr5",
    "Hr6",
    "Hr7",
    "Hr8",
    "Hr9",
    "Hr10",
    "Hr11",
    "Hr12",
    "Hr13",
    "Hr14",
    "Hr15",
    "Hr16",
    "Hr17",
    "Hr18",
    "Hr19",
    "Hr20",
    "Hr21",
    "Hr22",
    "Hr23"
  ),
  ordered = T
)

# Visualize ####

caption <- paste("From 12-30-2020 to 12-25-2021")

arrivals.boxplt <- df.arrivals.gathered %>% 
  ggplot(
  aes(
    x = Arrival_Hour,
    y = Arrivals
  )
) +
  geom_boxplot(
    fill = "lightblue",
    alpha = 0.618,
    outlier.colour = "red"
  ) +
  labs(
    title = "Average Arrivals by Hour to the ED",
    subtitle = "Source: DSS",
    x = "",
    y = "",
    caption = caption
  )
print(arrivals.boxplt)

census.boxplt <- df.census.gathered %>% ggplot(
  aes(
    x = Census_Hour,
    y = Census
  )
) +
  geom_boxplot(
    fill = "lightblue",
    alpha = 0.618,
    outlier.colour = "red"
  ) +
  labs(
    title = "Average Census by Hour in the ED",
    subtitle = "Source: DSS",
    x = "",
    y = "",
    caption = caption
  )
print(census.boxplt)

gridExtra::grid.arrange(
  arrivals.boxplt,
  census.boxplt,
  nrow = 2,
  ncol = 1
)

# Animate ####
arrivals.anim.plt <- df.arrivals.gathered %>% ggplot(
  aes(
    x = Arrival_Hour,
    y = Arrivals,
    fill = Arrivals
  )
) +
  geom_bar(
    stat = "identity",
    alpha = 0.618
  ) +
  transition_states(
    Week_Num,
    transition_length = 2,
    state_length = 1
  ) +
  labs(
    title = "Average Arrivals by Hour to the ED",
    subtitle = paste(
      "Week : {frame_time} of ",
      max(df.census.gathered$Week_Num),
      "Source: DSS"
    ),
    x = "Arrival Hour",
    y = "Average Arrivals by Hour"
  ) +
  scale_fill_gradient(low = "blue", high = "red") +
  transition_time(Week_Num) +
  enter_fade() +
  exit_shrink() +
  ease_aes("sine-in-out")
anim_save(
  "avg_arrivals_by_hour.gif",
  arrivals.anim.plt
)

census.anim.plt <- df.census.gathered %>% ggplot(
  aes(
    x = Census_Hour,
    y = Census,
    fill = Census
  )
) +
  geom_bar(
    stat = "identity",
    alpha = 0.618
  ) +
  transition_states(
    Week_Num,
    transition_length = 2,
    state_length = 1
  ) +
  labs(
    title = "Average Census by Hour in the ED",
    subtitle = paste(
      "Week : {frame_time} of ",
      max(df.census.gathered$Week_Num),
      "Source: DSS"
    ),
    x = "Census Hour",
    y = "Average Census by Hour"
  ) +
  scale_fill_gradient(low = "blue", high = "red") +
  transition_time(Week_Num) +
  enter_fade() +
  exit_shrink() +
  ease_aes("sine-in-out")
anim_save(
  "avg_census_by_hour.gif",
  census.anim.plt
)
