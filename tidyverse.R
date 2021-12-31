# Package load
library(tidyverse)

mpg

# graph displacement by hwy mpg
ggplot(data = mpg) +
  geom_point(mapping = aes(x = displ, y = hwy))

ggplot(data = mpg) +
  geom_boxplot(mapping = aes(x = as.factor(cyl), y = hwy))

# plot empty graph
ggplot(data = mpg)

# how man rows in mtcars
mpg

# what does the drv variable describe
?mpg

# Make a scatterplot of hwy versus cyl
ggplot(data = mpg) +
  geom_point(mapping = aes(x = cyl, y = hwy))

# what happens if you make a scatterplot of class v drv, why is it not useful
ggplot(data = mpg) +
  geom_point(mapping = aes(x = class, y = drv))

# color hwy v cyl by class
ggplot(data = mpg) +
  geom_point(mapping = aes(x = displ, y = hwy, color = class))

ggplot(data = mpg) +
  geom_point(mapping = aes(x = displ, y = hwy, alpha = class))

ggplot(data = mpg) +
  geom_point(mapping = aes(x = displ, y = hwy, shape = class))

# color needs to be outside of the aes() if not coloring by attribute
ggplot(data = mpg) +
  geom_point(mapping = aes(x = displ, y = hwy, color = "blue"))

?mpg

# factor v continuous color mapping inside aes()
ggplot(data = mpg) +
  geom_point(mapping = aes(x = displ, y = hwy, color = class))

ggplot(data = mpg) +
  geom_point(mapping = aes(x = displ, y = hwy, color = cty))

# map same attribute to multiple aes() mappings
ggplot(data = mpg) +
  geom_point(mapping = aes(x = displ, y = hwy, color = hwy, alpha = hwy))

# use of stroke aes()
ggplot(data = mpg) +
  geom_point(mapping = aes(x = displ, y = hwy, color = hwy, stroke = hwy))

# map an aesthetic to something other than a variable name
ggplot(data = mpg) +
  geom_point(mapping = aes(x = displ, y = hwy, color = displ < 5))

# facet_wrap()
ggplot(data = mpg) +
  geom_point(mapping = aes(x = displ, y = hwy)) +
  facet_wrap(~ class, nrow = 2)

ggplot(data = mpg) +
  geom_point(mapping = aes(x = displ, y = hwy, color = class)) +
  facet_grid(drv ~ cyl)

# trying to facet on a continuous variable will not work
ggplot(data = mpg) +
  geom_point(mapping = aes(x = displ, y = hwy)) +
  facet_wrap(~ city)

# what happens when you facet by ( . )
ggplot(data = mpg) +
  geom_point(mapping = aes(x = displ, y = hwy)) +
  facet_grid(drv ~ .)

ggplot(data = mpg) +
  geom_point(mapping = aes(x = displ, y = hwy)) +
  facet_grid(. ~ cyl)

ggplot(data = mpg) +
  geom_point(mapping = aes(x = displ, y = hwy)) +
  facet_wrap(~ class, nrow = 2)

# using different geoms
ggplot(data = mpg) +
  geom_point(mapping = aes(x = displ, y = hwy))

ggplot(data = mpg) +
  geom_smooth(mapping = aes(x = displ, y = hwy))

ggplot(data = mpg) +
  geom_smooth(mapping = aes(x = displ, y = hwy, linetype = drv))

ggplot(data = mpg) +
  geom_point(mapping = aes(x = displ, y = hwy, color = drv)) +
  geom_smooth(mapping = aes(x = displ, y = hwy, color = drv))

# geom evolution
ggplot(data = mpg) +
  geom_smooth(mapping = aes(x = displ, y = hwy))

ggplot(data = mpg) +
  geom_smooth(mapping = aes(x = displ, y = hwy, group = drv))

ggplot(data = mpg) +
  geom_smooth(mapping = aes(x = displ, y = hwy, color = drv),
              show.legend = FALSE
              )

# multiple geom on same plot
ggplot(data = mpg) +
  geom_point(mapping = aes(x = displ, y = hwy)) +
  geom_smooth(mapping = aes(x = displ, y = hwy))

# much cleaner and efficient to map var in ggplot line
ggplot(data = mpg, mapping = aes(x = displ, y = hwy)) +
  geom_point() +
  geom_smooth()

ggplot(data = mpg, mapping = aes(x = displ, y = hwy)) +
  geom_point(mapping = aes(color = class)) +
  geom_smooth()

# You can use same principal to specify different data per layer
ggplot(data = mpg, mapping = aes(x = displ, y = hwy)) +
  geom_point(mapping = aes(color = class)) +
  geom_smooth(
    data = filter(mpg, class == "subcompact"),
    se = FALSE
  )

# draw line, boxplot, histogram and area chart
ggplot(data = mpg, mapping = aes(x = displ, y = hwy)) +
  geom_line()

ggplot(data = mpg, mapping = aes(x = cyl, y = hwy, group = cyl)) +
  geom_boxplot()

ggplot(data = mpg, mapping = aes(x = hwy)) +
  geom_histogram()

ggplot(data = mpg, mapping = aes(x = displ, y = hwy)) +
  geom_area()

ggplot(data = mpg, mapping = aes(x = displ, y = hwy, color = drv)) +
  geom_point() +
  geom_smooth(se = FALSE)

ggplot(data = mpg, mapping = aes(x = displ, y = hwy)) +
  geom_point() +
  geom_smooth(se = FALSE, show.legend = FALSE)

ggplot(data = mpg, mapping = aes(x = displ, y = hwy, group = drv)) +
  geom_point() +
  geom_smooth(se = FALSE, show.legend = FALSE)

ggplot(data = mpg, mapping = aes(x = displ, y = hwy, group = drv, color = drv)) +
  geom_point() +
  geom_smooth(se = FALSE)

ggplot(data = mpg) +
  geom_point(mapping = aes(x = displ, y = hwy, color = drv)) + 
  geom_smooth(mapping = aes(x = displ, y = hwy), se = FALSE)

ggplot(data = mpg) +
  geom_point(mapping = aes(x = displ, y = hwy, color = drv)) +
  geom_smooth(mapping = aes(x = displ, y = hwy, linetype = drv), se = FALSE)

ggplot(data = mpg, mapping = aes(x = displ, y = hwy, color = drv)) +
  geom_point() +
  geom_smooth(se = FALSE, mapping = aes(linetype = drv))

ggplot(data = mpg, mapping = aes(x = displ, y = hwy, color = drv)) + 
  geom_point()

# Statistical Transformations
ggplot(data = diamonds) +
  geom_bar(mapping = aes(x = cut))

ggplot(data = diamonds) +
  stat_count(mapping = aes(x = cut))

ggplot(data = mpg) +
  geom_bar(mapping = aes(x = class))

# get a barchart of proportion rather than count
ggplot(data = diamonds) +
  geom_bar(
    mapping = aes(x = cut, y = ..prop.., group = 1)
  )

# draw greater attention to statistical transformation
ggplot(data = diamonds) +
  stat_summary(
    mapping = aes(x = cut, y = depth),
    fun.ymin = min,
    fun.ymax = max,
    fun.y =  median
  )

ggplot(data = diamonds) +
  geom_bar(mapping = aes(x = cut, y = ..prop..))

ggplot(data = diamonds) +
  geom_bar(
    mapping = aes(x = cut, fill = color, y = ..prop..)
  )

# Position adjustments
ggplot(data = diamonds) +
  geom_bar(mapping = aes(x = cut, color = cut))

ggplot(data = diamonds) +
  geom_bar(mapping = aes(x = cut, fill = cut))

ggplot(data = diamonds) +
  geom_bar(mapping = aes(x = cut, fill = clarity))

ggplot( data = diamonds, mapping = aes(x = cut, fill = clarity)) +
  geom_bar(alpha = 1/5, position = "identity")

ggplot(data = diamonds, mapping = aes(x = cut, color = clarity)) +
  geom_bar(fill = NA, position = "identity")

ggplot(data = diamonds) +
  geom_bar(mapping = aes(x = cut, fill = clarity),
           position = "fill")

ggplot(data = diamonds) +
  geom_bar(
    mapping = aes(x = cut, fill = clarity),
    position = "dodge"
  )

ggplot(data = mpg) +
  geom_point(
    mapping = aes(x = displ, y = hwy),
    position = "jitter"
  )

plot(mpg$hwy ~ mpg$displ)

ggplot(data = mpg, mapping = aes(x = cty, y = hwy)) +
  geom_point(position = "jitter")

ggplot(data = mpg, mapping = aes(x = cyl, y = hwy, group = cyl)) +
  geom_boxplot()

ggplot(data = mpg, mapping = aes(x = class, y = hwy)) +
  geom_boxplot()

ggplot(data = mpg, mapping = aes(x = class, y = hwy))+
  geom_boxplot()+
  coord_flip()

nz <- map_data("nz")
ggplot(data = nz, mapping = aes(x = long, y = lat, group = group)) +
  geom_polygon(fill = "white", color = "black") +
  coord_quickmap()

# polar coordinates
bar <- ggplot(data = diamonds) +
  geom_bar(
    mapping = aes(x = cut, fill = cut),
    show.legend = FALSE,
    width = 1
  ) +
  theme(aspect.ratio = 1) +
  labs(x = NULL, y = NULL)

bar + coord_flip()
bar + coord_polar()

ggplot(data = mpg, mapping = aes(x = cty, y = hwy)) +
  geom_point() +
  coord_fixed() + 
  geom_abline()

seq(1, 10)
(y <- seq(1, 10))

ggplot(data = mpg) +
  geom_point(mapping = aes(x = displ, y = hwy))

filter(mpg, cyl == 8)
filter(diamonds, carat > 3)

# Chapter 3 - Data Transformation with dplyr
library(nycflights13)
flights
filter(flights, month == 1, day == 1)
(jan1 <- filter(flights, month == 1, day == 1))
(dec25 <- filter(flights, month == 12, day == 25))

near(sqrt(2) ^ 2, 2)

# find all the flights that departed in either November or December
filter(flights, month == 11 | month == 12)
# or
nov_dec <- filter(flights, month %in% c(11, 12))

# flight that do not have an arrival or departure delay of more than 120
# equivalent statements
filter(flights, !(arr_delay > 120 | dep_delay > 120))
filter(flights, arr_delay <= 120, dep_delay <= 120)

# Determine if value is missing
x <- NA
is.na(x)

# filter will only bring back rows where the condition is TRUE, it excludes
# both FALSE and NA, if you want the NA rows be explicit
df <- tibble(x = c(1, NA, 3))
filter(df, x > 1)
filter(df, is.na(x) | x > 1)


# Fin all flights that:
# Had an arrival delay of two or more hours
filter(flights, arr_delay > 120)
# destination Houston (IAH, HOU)
filter(flights, dest %in% c("IAH", "HOU"))
# Operated by UA, American or Delta
filter(flights, carrier %in% c("UA", "AA", "DL"))
# departed in summer, July, August, September
filter(flights, month %in% c(7,8,9))
# arrived more than two hours late but did not leave late
filter(flights, arr_delay > 120, dep_delay < 1)
# dep_delay >= 60 && but made up over 30 minutes in flight
yyy <- filter(flights, dep_delay >= 60, (dep_delay - arr_delay) >= 30)
# departed between mightnight and 6am inclusive
zzz <- filter(flights, dep_time <= 0600, dep_time <= 2400)

filter(flights, between(dep_time, 0, 0600))
filter(flights, between(month, 7, 9))

filter(flights, is.na(dep_time))

# Arrange Rows with arrange() like order by in SQL
arrange(flights, year, month, day)
arrange(flights, desc(arr_delay))

# missing values are sorted at the end
df <- tibble(x = c(5, 2, NA))
arrange(df, x)
arrange(df, desc(x))
# get all missing values at top
arrange(df, desc(is.na(x)))
# most delayed flights
arrange(flights, desc(dep_delay))
arrange(flights, arr_delay)
y <- arrange(flights, desc(distance))
y <- arrange(flights, distance)

# use select() just like select in SQL
# select columns by name
select(flights, year, month, day)
# select columns between year and day (inclusive)
select(flights, year:day)
# select all columns except those from year to day (inclusive)
select(flights, -(year:day))
rename(flights, tail_num = tailnum)
# everthing() like select, x, y, z, *
select(flights,time_hour, air_time, everything())
select(flights,dep_time, dep_delay, arr_time, arr_delay)
select(flights, c(dep_time, dep_delay, arr_time, arr_delay))
vars <- c("dep_time", "dep_delay", "arr_time", "arr_delay")
select(flights, vars)
select(flights, vars, vars) # will only display once
select(flights, dep_time, dep_time) # will only display once
select(flights, one_of(vars))
vars <- c("year", "month", "day", "dep_delay", "arr_delay")
select(flights, one_of(vars))
select(flights, contains("TIME"))

# add variable swith mutate()
flights_sml <- select(
  flights
  , year:day
  , ends_with("delay")
  , distance
  , air_time
)
mutate(
  flights_sml
  , gain = arr_delay - dep_delay
  , speed = distance / air_time * 60
)
# You can refer to columns you just created
mutate(
  flights_sml
  , gain = arr_delay - dep_delay
  , hours = air_time / 60
  , gain_per_hour = gain / hours
)
transmute(
  flights
  , gain = arr_delay - dep_delay
  , hours = air_time / 60
  , gain_per_hour = gain / hours
)
transmute(
  flights
  , dep_time
  , hour = dep_time %/% 100
  , minute = dep_time %% 100
)
transmute(
  flights
  , dep_time
  , hour = dep_time %/% 100
  , minutes = dep_time %% 100
  , hour_to_min = (dep_time %/% 100) * 60
  , tot_minutes = minutes + hour_to_min
)
transmute(
  flights
  , air_time
  , arr_time
  , dep_time
  , air_time_test = arr_time - dep_time
  , air_time_minutes = (air_time %/% 100)*60 + (air_time %% 100)
)

flights %>% 
  mutate(dep_time = (dep_time %/% 100) * 60 + (dep_time %% 100),
         sched_dep_time = (sched_dep_time %/% 100) * 60 + (sched_dep_time %% 100),
         arr_time = (arr_time %/% 100) * 60 + (arr_time %% 100),
         sched_arr_time = (sched_arr_time %/% 100) * 60 + (sched_arr_time %% 100)) %>%
  transmute((arr_time - dep_time) %% (60*24) - air_time)

select(flights, dep_time, sched_dep_time, dep_delay)

filter(flights, min_rank(desc(dep_delay))<=10)
flights %>% top_n(n = 10, wt = dep_delay)

select(1:3+1:10)

??trig

# summarize()
summarize(flights, delay = mean(dep_delay, na.rm = TRUE))
by_day <- group_by(flights, year, month, day)
delay_by_day <- summarize(by_day, delay = mean(dep_delay, na.rm = TRUE))

# the pipe
by_dest <- group_by(flights, dest)
delay <- summarize(by_dest,
  count = n()
  , dist = mean(distance, na.rm = TRUE)
  , delay = mean(arr_delay, na.rm = TRUE)
)

# lets ggplot the delay data by destination excluding Honolulu
delay <- filter(delay, count > 20, dest != "HNL")
ggplot(data = delay, mapping = aes(x = dist, y = delay)) +
  geom_point(aes(size = count), alpha = 1/3) +
  geom_smooth(method = loess)#, se = FALSE)

# now lets pipe it
delays <- flights %>%
  group_by(dest) %>%
  summarize(
    count = n()
    , dist = mean(distance, na.rm = TRUE)
    , delay = mean(arr_delay, na.rm = TRUE)
  ) %>%
  filter(count > 20, dest != "HNL")

ggplot(data = delays, mapping = aes(x = dist, y = delay)) +
  geom_point(aes(size = count), alpha = 1/3) +
  geom_smooth(method = loess, se = FALSE)

# Start Page 61
# If there are missing values this will keep them
flights %>%
  group_by(year, month, day) %>%
  summarize(mean = mean(dep_delay))

# this will get rid of the missing values
flights %>%
  group_by(year, month, day) %>%
  summarize(mean = mean(dep_delay, na.rm = TRUE))

# get rid of non cancelled flights
not_cancelled <- flights %>%
  filter(!is.na(dep_delay), !is.na(arr_delay))

not_cancelled %>%
  group_by(year, month, day) %>%
  summarise(mean = mean(dep_delay))

# lets look at the planes (identified by their tail number) that have the
# highest average delays
delays <- not_cancelled %>%
  group_by(tailnum) %>%
  summarise(delay = mean(arr_delay))

ggplot(data = delays, mapping = aes(x = delay)) +
  geom_freqpoly(binwidth = 10)

delays <- not_cancelled %>%
  group_by(tailnum) %>%
  summarise(
    delay = mean(arr_delay, na.rm = TRUE),
    n = n()
  )
ggplot(data = delays, mapping = aes(x = n, y = delay)) +
  geom_point(alpha = 1/10)

# lets filter out low n planes
delays %>%
  filter(n > 25) %>%
  ggplot(mapping = aes(x = n, y = delay)) +
  geom_point(alpha = 1/10)

library(Lahman)
batting <- as_tibble(Lahman::Batting)
batters <- batting %>%
  group_by(playerID) %>%
  summarize(
    ba = sum(H, na.rm = TRUE) / sum(AB, na.rm = TRUE),
    ab = sum(AB, na.rm = TRUE)
  )

batters %>%
  filter(ab > 100) %>%
  ggplot(mapping = aes(x = ab, y = ba)) +
  geom_point()+
  geom_smooth(se = FALSE)

batters %>%
  arrange(desc(ba))

# Start at page 66
not_cancelled %>%
  group_by(year, month, day) %>%
  summarize(
    # average delay
    avg_delay1 = mean(arr_delay),
    # average positive delay
    avg_delay2 = mean(arr_delay[arr_delay > 0])
  )

not_cancelled %>%
  group_by(dest) %>%
  summarize(distance_sd = sd(distance)) %>%
  arrange(desc(distance_sd))

not_cancelled %>%
  group_by(year, month, day) %>%
  summarize(
    first = min(dep_time),
    last = max(dep_time)
  )

not_cancelled %>%
  group_by(year, month, day) %>%
  summarize(
    first_dep = first(dep_time),
    last_dep = last(dep_time)
  )

# filtering on rank
not_cancelled %>%
  group_by(year, month, day) %>%
  mutate(r = min_rank(desc(dep_time))) %>%
  filter(r %in% range(r))

# which destinations have the most unique carriers?
not_cancelled %>%
  group_by(dest) %>%
  summarize(carriers = n_distinct(carrier)) %>%
  arrange(desc(carriers))

not_cancelled %>%
  count(dest)

not_cancelled %>%
  count(tailnum, wt = distance)

