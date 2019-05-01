# Lib Load ####
library(tidyverse)
library(tabulizer)
library(data.table)
library(shiny)

# Doc List ####
file.vector <- list.files(path = getwd())
file.vector %>% head()

# Is PDF? ####
grepl(".pdf", file.vector)

# Get PDF List ####
pdf.list <- file.vector[grepl(".pdf", file.vector)]
print(pdf.list)

# Create DF ####
documents <- data.frame(stringsAsFactors = FALSE)
error.page.df <- data.frame(
  Error_Message = character()
  ,stringsAsFactors = FALSE
  )

# For Loop ####
for(i in 1:length(pdf.list)){
  print(paste("Reading file -", pdf.list[i]))
  cur.doc <- extract_tables(pdf.list[i])
  print(paste("There are", length(cur.doc), "pages in the current file."))
  for(j in 1:length(cur.doc)){
    cur.doc.page <- cur.doc[j]
    print(
      paste(
        "Reading page -"
        , j
        , "There are"
        , ncol(as.data.frame(cur.doc.page))
        , "columns."
        )
      )
    df <- as.data.frame(cur.doc.page)
    df <- df[-1, ]
    df <- df[, colSums(df != "") != 0]
    df$FileName <- pdf.list[i]
    tmp.col.names <- c(
      "V1","V2","V3","V4","V6","FileName"
    )
    try(colnames(df) <- tmp.col.names, silent = T)
    possible.error <- try(rbind(documents, df))
    if(isTRUE(class(possible.error)=="try-error")) { 
      print(
        paste(
          "Could not insert page"
          , j
          , "for file -"
          , pdf.list[i]
        )
      )
      error.msg <- paste(
        "Could not insert page"
        , j
        , "for file -"
        , pdf.list[i]
      )
      error.msg <- as.data.frame(as.character(error.msg))
      error.page.df <- rbind(error.page.df, error.msg)
      next 
    } else {
      documents <-rbind(documents, df)
      possible.error <- NA
      error.msg <- NA
    }
  }
}

# Clean DF ####
column.names <- c(
  "Patient"
  , "MRN"
  , "Room_Number"
  , "Physician"
  , "Team"
  , "FileName"
)

colnames(documents) <- column.names

documents <- filter(
    documents
    , Room_Number != "Room #"
  ) %>%
  filter(
    !(Patient %like% "Confidentiality Notice")
  ) %>%
  filter(
    MRN != ""#, Room_Number != "", Physician != "", Team != "" 
  )

# Get Error Pages ####
all.documents <- data.frame(stringsAsFactors = FALSE)
all.documents <- documents

f <- tryCatch(file.choose(new = T), error = function(e) "")
f.data <- extract_areas(f, 2)
f.data.df <- as.data.frame(f.data, stringsAsFactors = FALSE)
f.data.df$X5 <- NA
f.data.df$FileName = 'SoundConnectCommunication_2019_04_04_04_30.pdf'
#View(f.data.df)
# is mrn column blank
f.data.df$MRN <- str_sub(f.data.df$X1, -6, -1)
f.data.df <- f.data.df %>%
  select(
    X1
    #, MRN
    , X2
    , X3
    , X4
    , X5
    , FileName
  )

colnames(f.data.df) <- column.names

f.data.df <- f.data.df %>%
  filter(
    Room_Number != "Room #"
  ) %>%
  filter(
    !(Patient %like% "Confidentiality Notice")
  ) %>%
  filter(
    MRN != ""
    , Room_Number != ""
    , Physician != ""
    # , Team != "" 
  )

# rbind errors to doc ####
all.documents <- bind_rows(all.documents, f.data.df)

# Write file ####
write.csv(documents, "Sound_Connect_Communication.csv")
write.csv(all.documents, "Sound_Connect_Communication.csv")
