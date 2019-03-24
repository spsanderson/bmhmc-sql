# Lib Load ####
library(tidyverse)
library(tabulizer)
library(data.table)

# Doc List ####
file.vector <- list.files(path = getwd())
file.vector %>% head()

# Is PDF? ####
grepl(".pdf", file.vector)

# Get PDF List ####
pdf.list <- file.vector[grepl(".pdf", file.vector)]
print(pdf.list)

# Create DF ####
documents <- data.frame()
error.page.df <- data.frame()

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
      error.page.df <- rbind(error.page.df, error.msg)
      next 
    } else {
      documents <-rbind(documents, df)
      possible.error <- NA
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
    MRN != "" | Room_Number != "" | Physician != "" | Team != "" 
  )

documents <- as_tibble(documents)

# Write file ####
write.csv(documents, "Sound_Connect_Communication.csv")
