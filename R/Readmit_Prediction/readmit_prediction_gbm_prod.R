# Start ####
install.load::install_load(
  "tidyverse"
  , "mlr"
  , "rJava"
  , "FSelector"
  , "gbm"
)

options(scipen = 999) # prevent printing in scientific notation

# Prod testing ####
gbm_readmit_model <- readRDS("gbm_pred.rds")
print(gbm_readmit_model)
new.file <- file.choose(new = T)
df <- readxl::read_xlsx(new.file, sheet = "data")
print(df)

# Functions ####
# Bin Size functions
source("S:\\Global Finance\\1 REVENUE CYCLE\\Steve Sanderson II\\Code\\R\\Functions\\optimal_bin_size.R")
source("S:\\Global Finance\\1 REVENUE CYCLE\\Steve Sanderson II\\Code\\R\\Functions\\optimal_hist_bin_size.R")
source("S:\\Global Finance\\1 REVENUE CYCLE\\Steve Sanderson II\\Code\\R\\Functions\\readmit_pred_functions.R")

# Not in Function
'%ni%' <- Negate('%in%')

# Pre-Processing ####
# column reductions
df$reduced_dispo <- sapply(df$Init_Disp, reduce_dispo_func)
df$reduced_hsvc <- sapply(df$Init_Hosp_Svc, reduce_hsvc_func)
df$reduced_abucket <- sapply(df$Age_Bucket, reduce_agebucket_func)
df$reduced_spclty <- sapply(df$Init_Attn_Specialty, reduce_spclty_func)
df$reduced_lihn <- sapply(df$Init_LIHN_Svc, reduce_lihn_func)
df$discharge_month <- lubridate::month(df$Init_dsch_date)

# We don't need all columns, drop those not needed
base.mod.df <- df %>%
  dplyr::select(
    -med_rec_no
    , -Init_adm_date
    , -Init_dsch_date
    , -Init_Attn_ID
    , -Init_Attn_Name
    , -Init_Attn_Specialty
    , -Init_Disp
    , -Init_Hosp_Svc
    , -Init_LIHN_Svc
    , -READMIT_FLAG
    , -Readmit_Date
    , -Days_To_Readmit
  )
str(base.mod.df)
base.mod.df$reduced_dispo <- factor(base.mod.df$reduced_dispo)
base.mod.df$reduced_hsvc <- factor(base.mod.df$reduced_hsvc)
base.mod.df$reduced_abucket <- factor(base.mod.df$reduced_abucket)
base.mod.df$reduced_spclty <- factor(base.mod.df$reduced_spclty)
base.mod.df$reduced_lihn <- factor(base.mod.df$reduced_lihn)
base.mod.df$discharge_month <- factor(base.mod.df$discharge_month)

base.mod.df <- as.data.frame(base.mod.df)

# Run Model ####
prod_predictions <- predict(
  gbm_readmit_model
  , newdata = base.mod.df
  )

# Join Pred to data ####
# first add sequential number column called id to base.mod.df
prod_predictions_data <- prod_predictions$data %>%
  mutate(id = 1:n())

base.mod.df <- base.mod.df %>%
  mutate(id = 1:n()) %>%
  dplyr::select(Init_Acct, id) %>%
  dplyr::inner_join(prod_predictions_data, by = c("id"="id")) %>%
  dplyr::select(-id)

table(base.mod.df$response)

write_csv(base.mod.df, "readmit_predictions.csv")
