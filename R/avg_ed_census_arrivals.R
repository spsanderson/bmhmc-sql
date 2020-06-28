# Lib Load ####
pacman::p_load(
  "gganimate"
  , "gifski"
  , "tidyverse"
)

# Load File ####
file.to.choose <- file.choose(new = T)
df <- read.csv(file.to.choose)
df.tibble <- as_tibble(df)
head(df.tibble, 5)

# Tidy ####
df.arrivals <- df.tibble %>%
  filter(Data_Label == "Avg_Arrivals")
head(df.arrivals)

df.census <- df.tibble %>%
  filter(Data_Label == "Avg_Census")
head(df.census)

df.census.gathered <- gather(
  df.census
  , `Hr0`
  , `Hr1`
  , `Hr2`
  , `Hr3`
  , `Hr4`
  , `Hr5`
  , `Hr6`
  , `Hr7`
  , `Hr8`
  , `Hr9`
  , `Hr10`
  , `Hr11`
  , `Hr12`
  , `Hr13`
  , `Hr14`
  , `Hr15`
  , `Hr16`
  , `Hr17`
  , `Hr18`
  , `Hr19`
  , `Hr20`
  , `Hr21`
  , `Hr22`
  , `Hr23`
  , key = "Census_Hour"
  , value = "Census"
)
df.census.gathered$Census_Hour <- factor(
  df.census.gathered$Census_Hour
  , levels = c(
    'Hr0'
    , 'Hr1'
    , 'Hr2'
    , 'Hr3'
    , 'Hr4'
    , 'Hr5'
    , 'Hr6'
    , 'Hr7'
    , 'Hr8'
    , 'Hr9'
    , 'Hr10'
    , 'Hr11'
    , 'Hr12'
    , 'Hr13'
    , 'Hr14'
    , 'Hr15'
    , 'Hr16'
    , 'Hr17'
    , 'Hr18'
    , 'Hr19'
    , 'Hr20'
    , 'Hr21'
    , 'Hr22'
    , 'Hr23'
  )
  , ordered = T
)

df.arrivals.gathered <- gather(
  df.arrivals
  , `Hr0`
  , `Hr1`
  , `Hr2`
  , `Hr3`
  , `Hr4`
  , `Hr5`
  , `Hr6`
  , `Hr7`
  , `Hr8`
  , `Hr9`
  , `Hr10`
  , `Hr11`
  , `Hr12`
  , `Hr13`
  , `Hr14`
  , `Hr15`
  , `Hr16`
  , `Hr17`
  , `Hr18`
  , `Hr19`
  , `Hr20`
  , `Hr21`
  , `Hr22`
  , `Hr23`
  , key = "Arrival_Hour"
  , value = "Arrivals"
  )
df.arrivals.gathered$Arrival_Hour <- factor(
  df.arrivals.gathered$Arrival_Hour
  , levels = c(
    'Hr0'
    , 'Hr1'
    , 'Hr2'
    , 'Hr3'
    , 'Hr4'
    , 'Hr5'
    , 'Hr6'
    , 'Hr7'
    , 'Hr8'
    , 'Hr9'
    , 'Hr10'
    , 'Hr11'
    , 'Hr12'
    , 'Hr13'
    , 'Hr14'
    , 'Hr15'
    , 'Hr16'
    , 'Hr17'
    , 'Hr18'
    , 'Hr19'
    , 'Hr20'
    , 'Hr21'
    , 'Hr22'
    , 'Hr23'
    )
  , ordered = T
  )

# 5 Hour buckets
df_arr_bucket <- df.arrivals.gathered %>%
  mutate(Arrival_Hour = Arrival_Hour %>% as.character()) %>%
  mutate(
    hour_bucket = case_when(
      Arrival_Hour %in% c('Hr0','Hr1','Hr2','Hr3','Hr4') ~ 1
      , Arrival_Hour %in% c('Hr5','Hr6','Hr7','Hr8','Hr9') ~ 2
      , Arrival_Hour %in% c('Hr10','Hr11','Hr12','Hr13','Hr14') ~ 3
      , Arrival_Hour %in% c('Hr15','Hr16','Hr17','Hr18','Hr19') ~ 4
      , TRUE ~ 5
    )
  ) %>%
  mutate(hour_bucket = hour_bucket %>% as_factor())

df_cen_bucket <- df.census.gathered %>%
  mutate(Census_Hour = Census_Hour %>% as.character()) %>%
  mutate(
    hour_bucket = case_when(
      Census_Hour %in% c('Hr0','Hr1','Hr2','Hr3','Hr4') ~ 1
      , Census_Hour %in% c('Hr5','Hr6','Hr7','Hr8','Hr9') ~ 2
      , Census_Hour %in% c('Hr10','Hr11','Hr12','Hr13','Hr14') ~ 3
      , Census_Hour %in% c('Hr15','Hr16','Hr17','Hr18','Hr19') ~ 4
      , TRUE ~ 5
    )
  ) %>%
  mutate(hour_bucket = hour_bucket %>% as_factor())

# Visualize ####
capt <- "From 12-29-2019 to 06-20-2020"

arrivals.boxplt <- df.arrivals.gathered %>% ggplot(
  aes(
    x = Arrival_Hour
    , y = Arrivals
  )
) +
  geom_boxplot(
    fill = "lightblue"
    , alpha = 0.618
    , outlier.colour = "red"
  ) +
  labs(
    title = "Average Arrivals by Hour to the ED"
    , subtitle = "Source: DSS"
    , x = ""
    , y = ""
    , caption = capt
  ) 
print(arrivals.boxplt)

census.boxplt <- df.census.gathered %>% ggplot(
  aes(
    x = Census_Hour
    , y = Census
  )
) +
  geom_boxplot(
    fill = "lightblue"
    , alpha = 0.618
    , outlier.colour = "red"
  ) +
  labs(
    title = "Average Census by Hour in the ED"
    , subtitle = "Source: DSS"
    , x = ""
    , y = ""
    , caption = capt
  )
print(census.boxplt)

gridExtra::grid.arrange(
  arrivals.boxplt
  , census.boxplt
  , nrow = 2
  , ncol = 1
)

df_arr_bucket_boxplot <- df_arr_bucket %>%
  ggplot(
    mapping = aes(
      x = hour_bucket
      , y = Arrivals
    )
  ) +
  geom_boxplot(
    fill = "lightblue"
    , alpha = 0.618
    , outlier.color = "red"
  ) +
  labs(
    title = "Average Arrivals by Hour Bucket in the ED"
    , subtitle = "Source: DSS - By Hour of Arrival Bucket"
    , caption = capt
    , x = ""
    , y = ""
  )
print(df_arr_bucket_boxplot)

df_cen_bucket_boxplot <- df_cen_bucket %>%
  ggplot(
    mapping = aes(
      x = hour_bucket
      , y = Census
    )
  ) +
  geom_boxplot(
    fill = "lightblue"
    , alpha = 0.618
    , outlier.color = "red"
  ) +
  labs(
    title = "Average Census by Hour Bucket in the ED"
    , subtitle = "Source: DSS - By Hour of Arrival Bucket"
    , caption = capt
    , x = ""
    , y = ""
  )
print(df_cen_bucket_boxplot)

gridExtra::grid.arrange(
  df_arr_bucket_boxplot
  , df_cen_bucket_boxplot
  , nrow = 2
  , ncol = 1
)

# Animate ####
arrivals.anim.plt <- df.arrivals.gathered %>% ggplot(
  aes(
    x = Arrival_Hour
    , y = Arrivals
    , fill = Arrivals
  )
) +
  geom_bar(
    stat = "identity"
    , alpha = 0.618
    ) +
  transition_states(
    Week_Num
    , transition_length = 2
    , state_length = 1
  ) +
  labs(
    title = "Average Arrivals by Hour to the ED"
    , subtitle = paste(
      'Week : {frame_time} of '
      , max(df.census.gathered$Week_Num)
      , 'Source: DSS'
      )
    , x = 'Arrival Hour'
    , y = 'Average Arrivals by Hour'
  ) +
  scale_fill_gradient(low = "blue", high = "red") +
  transition_time(Week_Num) +
  enter_fade() +
  exit_shrink() +
  ease_aes('sine-in-out')
anim_save(
  "avg_arrivals_by_hour.gif"
  , arrivals.anim.plt
  , renderer = gifski_renderer()
  )

census.anim.plt <- df.census.gathered %>% ggplot(
  aes(
    x = Census_Hour
    , y = Census
    , fill = Census
  )
) +
  geom_bar(
    stat = "identity"
    , alpha = 0.618
  ) +
  transition_states(
    Week_Num
    , transition_length = 2
    , state_length = 1
  ) +
  labs(
    title = "Average Census by Hour in the ED"
    , subtitle = paste(
      'Week : {frame_time} of '
      , max(df.census.gathered$Week_Num)
      , 'Source: DSS'
      )
    , x = 'Census Hour'
    , y = 'Average Census by Hour'
    ) +
  scale_fill_gradient(low = "blue", high = "red") +
  transition_time(Week_Num) +
  enter_fade() +
  exit_shrink() +
  ease_aes('sine-in-out')

anim_save(
  "avg_census_by_hour.gif"
  , census.anim.plt
  , renderer = gifski_renderer()
  )

