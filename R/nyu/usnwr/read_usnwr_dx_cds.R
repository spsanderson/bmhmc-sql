library(tidyverse)

file_path <- "C://Users//bha485//Desktop/usnwr_cardiology_procedure_codes.txt"
text_file <- vroom::vroom(file_path, col_names = FALSE)
text_file 

text_file %>%
  mutate(across(.fns = as.character)) %>%
  pivot_longer(everything()) %>%
  filter(!is.na(value)) %>%
  select(value) %>%
  write.table(
    file = "C://Users//bha485//Desktop/usnwr_cardiology_procedure_codes_clean.txt",
    sep = ",",
    row.names = FALSE
  )
