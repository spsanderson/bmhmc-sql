# Lib Load ####
library(tidyverse)
library(readxl)

# Get File ####
file.vec <- list.files(path = getwd())
file.vec %>% head()

# Is .xlsx or .xls
grepped.files <- grepl(".xls", file.vec)

# File list
f.list <- file.vec[grepped.files]
print(f.list)

# Create df ####
ad.df <- data.frame(
  stringsAsFactors = F
)

cur.doc <- data.frame(
  stringsAsFactors = F
)
# Loop Files ####
for(i in 1:length(f.list)){
  # What is current file
  print(paste("Reading file -", f.list[i]))
  # make current file cur.doc
  cur.doc <- suppressMessages(
    suppressWarnings(
      read_excel(
        f.list[i]
        , sheet = 1
        #, skip = 1
        )
      )
    )
  # how many records in cur.doc
  print(paste("There are", nrow(cur.doc), "records in", f.list[i]))
  df <- cur.doc
  col.names <- c(
    "Patient_Name"
    , "MRN"
    , "Team"
    , "Room_Number"
    , "First_AD_of_Stay"
    , "Total_Avoidable_Days"
    , "Last_Reason"
    , "Last_Category"
  )
  colnames(df) <- col.names
  
  df$Patient_Name <- as.character(df$Patient_Name)
  df$MRN <- as.character(df$MRN)
  df$Team <- as.character(df$Team)
  df$Room_Number <- as.character(df$Room_Number)
  df$First_AD_of_Stay <- as.character(df$First_AD_of_Stay)
  df$Total_Avoidable_Days <- as.character(df$Total_Avoidable_Days)
  df$Last_Reason <- as.character(df$Last_Reason)
  df$Last_Category <- as.character(df$Last_Category)
  
  # suppressWarnings(suppressMessages(if(is.na(df$...3)){df$...3 <- NULL}))
  # suppressWarnings(suppressMessages(if(is.na(df$...9)){df$...9 <- NULL}))
  
  possible.error <- try(bind_rows(ad.df, df))
  if(isTRUE(class(possible.error) == "try-error")){
    print(paste("bind_rows failed for", f.list[i]))
    next
  } else {
    ad.df <- bind_rows(ad.df, df)
    print("bind_rows() success")
    possible.error <- NA
  }
}
ad.df <- ad.df[!is.na(names(ad.df))]
ad.df <- ad.df %>%
  select(
    Patient_Name
    , MRN
    , Team
    , Room_Number
    , First_AD_of_Stay
    , Total_Avoidable_Days
    , Last_Reason
    , Last_Category
  )
# Col Names ####
col.names <- c(
  "Patient_Name"
  , "MRN"
  , "Team"
  , "Room_Number"
  , "First_AD_of_Stay"
  , "Total_Avoidable_Days"
  , "Last_Reason"
  , "Last_Category"
)

colnames(ad.df) <- col.names

# Write csv
write.csv(ad.df, "hospitalist_avoidable_days.csv")
