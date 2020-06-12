# Lib Load ####
pacman::p_load(
  "tidyverse"
  , "tabulizer"
  , "data.table"
  , "shiny"
)
pdf_list <- file.choose(new = TRUE)
pdf <- extract_tables(pdf_list)
df <- map_df(pdf, as.data.frame)
df %>%
  select(V2) %>%
  distinct() %>%
  as_tibble() %>%
  write_csv(path = "My_Path.csv")