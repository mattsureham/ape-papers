# 02_clean_data.R — Prepare panel for DiD analysis
# apep_0720: Sports Betting Revenue Cannibalization

source("00_packages.R")

data_dir <- "../data"
stc <- readRDS(file.path(data_dir, "stc_panel.rds"))

cat(sprintf("Panel: %d state-years (%d states x %d years)\n",
            nrow(stc), length(unique(stc$state_fips)), length(unique(stc$year))))

# Convert amounts to millions for readability
stc <- stc %>%
  mutate(
    across(starts_with("T"), ~ . / 1000),  # amounts already in thousands; divide by 1000 -> millions
    # Log transform for percentage interpretation
    log_T11 = ifelse(T11 > 0, log(T11), NA_real_),
    log_T20 = ifelse(T20 > 0, log(T20), NA_real_),
    log_T09 = ifelse(T09 > 0, log(T09), NA_real_),
    log_T10 = ifelse(T10 > 0, log(T10), NA_real_)
  )

# Define treatment groups clearly
stc <- stc %>%
  mutate(
    treatment_group = case_when(
      g > 0 ~ paste0("Treat_", g),
      g == 0 ~ "Never",
      TRUE ~ "Unknown"
    )
  )

cat("\n--- Treatment group counts ---\n")
stc %>%
  filter(!is.na(g)) %>%
  group_by(treatment_group) %>%
  summarise(
    n_states = n_distinct(state_fips),
    n_obs = n(),
    .groups = "drop"
  ) %>%
  arrange(treatment_group) %>%
  print()

# Summary by treatment status
cat("\n--- Mean tax revenue (millions) by treatment status ---\n")
stc %>%
  filter(!is.na(g)) %>%
  mutate(treated_period = ifelse(g > 0 & year >= g, "Post", "Pre/Never")) %>%
  group_by(treated_period) %>%
  summarise(
    mean_T11_amusement = mean(T11, na.rm = TRUE),
    mean_T20_parimutuel = mean(T20, na.rm = TRUE),
    mean_T09_sales = mean(T09, na.rm = TRUE),
    mean_T10_alcohol = mean(T10, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  ) %>%
  print()

saveRDS(stc, file.path(data_dir, "stc_analysis.rds"))
cat("\nCleaned data saved.\n")
