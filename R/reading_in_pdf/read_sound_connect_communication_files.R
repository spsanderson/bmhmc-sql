# Lib Load ####
library(tidyverse)
library(tabulizer)
library(data.table)

# Doc List ####
file.vector <- list.files(path = getwd())
file.vector %>% head()

# is file a pdf
grepl(".pdf", file.vector)

# get list of pdfs
pdf.list <- file.vector[grepl(".pdf", file.vector)]
print(pdf.list)

cur.doc <- extract_tables(pdf.list[1])[[1]]
print(cur.doc)

documents <- data.frame()

for(i in 1:length(pdf.list)){
  print(paste("Reading - ", pdf.list[i]))
  cur.doc <- extract_tables(pdf.list[i])
  for(j in 1:length(cur.doc[i])){
    cur.doc.page <- cur.doc[[j]]
    df <- as.data.frame(cur.doc.page)
    df$FileName <- pdf.list[i]
    documents <- rbind(documents, df)
  }
}

column.names <- c(
  "Patient"
  , "MRN"
  , "Room_Number"
  , "Physician"
  , "Pysician_Pager"
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
)

documents <- as_tibble(documents)

write.csv(documents, "Sound_Connect_Communication.csv")
