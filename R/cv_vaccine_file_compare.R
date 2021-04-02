
# Lib Load ----------------------------------------------------------------

pacman::p_load(
  "tidyverse"
)

# Read in Files -----------------------------------------------------------

file_1 <- readxl::read_excel(
  path = "C:/Users/bha485/Desktop/matt_1.xlsx"
)
file_2 <- readxl::read_excel(
  path = "C:/Users/bha485/Desktop/matt_2.xlsx"
)
file_3 <- readxl::read_excel(
  path = "C:/Users/bha485/Desktop/matt_3.xlsx"
)
file_4 <- readxl::read_excel(
  path = "C:/Users/bha485/Desktop/matt_4.xlsx"
)

# Data Manipulation -------------------------------------------------------

unioned_files <- bind_rows(list(file_1, file_2, file_3, file_4))

df_tbl <- unioned_files %>%
  janitor::clean_names() %>%
  mutate_if(is.character, str_squish) %>%
  mutate_if(is.character, str_to_lower) %>%
  mutate(full_name = paste0(last_name, "_", first_name) %>%
           str_squish()
  )

df_tbl %>%
  group_by(full_name) %>%
  filter(n() <= 1) %>%
  write.csv(file = "C:/Users/bha485/Desktop/vaccine_file.csv")
