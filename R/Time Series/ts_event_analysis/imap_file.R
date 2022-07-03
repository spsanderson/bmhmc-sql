df_lagged <- df %>%
  dplyr::select(date_col, value, dplyr::everything()) %>%
  # Manipulation
  dplyr::mutate(
    lag_val = dplyr::lag(value, 1),
    adj_diff = (value - lag_val),
    relative_change_raw = adj_diff / lag_val
  ) %>%
  tidyr::drop_na(lag_val) %>%
  dplyr::mutate(
    relative_change = round(relative_change_raw, precision),
    pct_chg_mark = ifelse(relative_change == percent_change, TRUE, FALSE),
    event_base_change = ifelse(pct_chg_mark == TRUE, 0, relative_change_raw),
    group_number = cumsum(pct_chg_mark)
  ) %>%
  dplyr::mutate(numeric_group_number = group_number) %>%
  dplyr::mutate(group_number = as.factor(group_number))

# Drop group 0 if indicated
if (filter_non_event_groups){
  df_lagged <- df_lagged %>%
    dplyr::filter(numeric_group_number != 0)
}

df_event <- df_lagged %>%
  dplyr::group_by(group_number) %>%
  dplyr::mutate(x = dplyr::row_number()) %>%
  dplyr::ungroup() %>%
  dplyr::group_by(x) %>%
  dplyr::mutate(
    mean_event_change = mean(event_base_change, na.rm = TRUE),
    median_event_change = stats::median(event_base_change, na.rm = TRUE),
    event_change_ci_low = unname(stats::quantile(event_base_change, 0.025, na.rm = TRUE)),
    event_change_ci_high = unname(stats::quantile(event_base_change, 0.975, na.rm = TRUE))
  ) %>%
  dplyr::ungroup() %>%
  tibble::rowid_to_column()

max_rows <- nrow(df_lagged)
inds = which(df_lagged$pct_chg_mark == TRUE)
rows <- lapply(inds, function(x) (x-horizon):(x+horizon))
l <- map(
  .x = rows, 
  .f = ~ .x %>% 
    subset(. > 0) %>% 
    df_event[.,]
) %>%
  imap(
    .f = ~ bind_cols(.x, group_event_number = .y)
  ) %>%
  map_df(as_tibble)

ll <- l %>%
  group_by(group_event_number) %>%
  mutate(x = row_number()) %>%
  ungroup() %>%
  group_by(x) %>%
  mutate(mean_event_change = mean(event_base_change, na.rm = TRUE),
         event_change_ci_low = unname(stats::quantile(event_base_change, 0.025, na.rm = TRUE)),
         event_change_ci_high = unname(stats::quantile(event_base_change, 0.975, na.rm = TRUE))
  ) %>%
  ungroup()

ll %>%
  ggplot(aes(x = x, y = mean_event_change, group = group_event_number)) +
  geom_line() +
  geom_line(aes(y = event_change_ci_high), color = "blue", linetype = "dashed") +
  geom_line(aes(y = event_change_ci_low), color = "blue", linetype = "dashed") +
  geom_vline(xintercept = horizon + 1, color = "red", linetype = "dashed") +
  theme_minimal() +
  labs(
    title = "AirPassengers Event Analysis at 5% Increase",
    subtitle = "Verticle Redline is normalized event epoch",
    x = "",
    y = "Mean Event Change"
  )


df_final %>% 
  filter(group_number != 1) %>%
  ggplot(aes(x = date_col, y = mean_event_change, group = group_event_number)) + 
  geom_line() + 
  geom_line(aes(y = event_change_ci_high), color = "red", linetype = "dashed") +
  geom_line(aes(y = event_change_ci_low), color = "red", linetype = "dashed") +
  geom_vline(xintercept = c(vl), color = "red", linetype = "dashed") + 
  theme_minimal()
