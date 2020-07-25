# Lib Load ####
library(funModeling)
library(dplyr)
library(Hmisc)
library(minerva) # contains MIC stat
library(ggplot2)
library(reshape2)
library(gridExtra) # allow to plot two plots in a row
options(scipen = 999) # disable scientific notation

# Load File ####
file.to.choose <- file.choose(new = TRUE)
df <- read.csv(file.to.choose)
rm(file.to.choose)

# Profile Data ####
# Check missing values, zeros, data type, and unique values
# Profiling the data input
my.data.status <- df_status(df)

# Remove data with 25% or more zero values
vars.to.remove <- filter(my.data.status, p_zeros >= 25) %>% .$variable
vars.to.remove

# Keep all columns except those in vars.to.remove
df2 <- select(df, -one_of(vars.to.remove))

# Order by percentage of zeros
arrange(my.data.status, -p_zeros) %>%
  select(variable, q_zeros, p_zeros)

# Total Rows
nrow(df2)
# Total Columns
ncol(df2)
# Column Names
colnames(df2)
# Describe the data
describe(df2)
# Profile the data
profiling_num(df2)
# Plot data
plot_num(df2)

# Correlation and Relationship ####
correlation_table(data = df2, target = "DSCH_COUNT")

# If Skewness and Kurtosis are high consider a transform
df2 <- df2 %>%
  filter(Avg_Pmts > 0) %>% 
  mutate(avg.pmts.trans = sqrt(Avg_Pmts)) %>%
  mutate(avg.chgs.trans = sqrt(Avg_Chgs))

