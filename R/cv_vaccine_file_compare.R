
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


# Data Manipulation -------------------------------------------------------

unioned_files <- union_all(x = file_1, y = file_2)

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
