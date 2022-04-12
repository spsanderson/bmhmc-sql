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

pdf_text <- extract_text(pdf_list, encoding = "UTF-8")
pdf_text %>%
  as_tibble() %>%
  separate_rows(value, sep = "\r\n") %>%
  mutate(value = str_squish(value)) %>%
  slice(4:n()) %>% 
  filter(!str_detect(value, "11/30/2020")) %>%
  separate(
    value
    , into = str_c("value_", 1:100)
    , sep = " "
    , fill = "right"
    , remove = FALSE
    ) %>%
  select_if(function(x) any(!is.na(x))) %>%
  select(value_1) %>%
  write_csv(path = "C:/Users/bha485/Desktop/oncology_op_codes.csv")
