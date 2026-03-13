# 02_clean_data.R — Build analysis panel
# apep_0653: Data Breach Notification Laws and Firm Dynamics

source("00_packages.R")

bds_agg <- readRDS("../data/bds_aggregate.rds")
bds_naics <- readRDS("../data/bds_naics.rds")
bnl_laws <- readRDS("../data/bnl_laws.rds")

# ==============================================================================
# 1. Clean aggregate BDS panel
# ==============================================================================

panel_agg <- bds_agg %>%
  rename(state_fips = state, year = YEAR) %>%
  mutate(
    across(c(FIRM, ESTAB, ESTABS_ENTRY, ESTABS_EXIT, EMP,
             JOB_CREATION, JOB_DESTRUCTION, NET_JOB_CREATION),
           as.numeric),
    across(c(ESTABS_ENTRY_RATE, ESTABS_EXIT_RATE,
             JOB_CREATION_RATE, JOB_DESTRUCTION_RATE, NET_JOB_CREATION_RATE),
           as.numeric),
    year = as.integer(year)
  ) %>%
  filter(!is.na(ESTABS_ENTRY_RATE)) %>%
  # Create numeric state ID for fixest
  mutate(state_id = as.integer(factor(state_fips)))

# Merge treatment
panel_agg <- panel_agg %>%
  left_join(bnl_laws %>% select(state_fips, bnl_year), by = "state_fips") %>%
  mutate(
    # For CS estimator: first_treat = adoption year, 0 = never treated
    # All states eventually treated, so no true never-treated
    # Use adoption year directly
    first_treat = bnl_year,
    treated = as.integer(year >= bnl_year),
    post = treated
  )

cat("Aggregate panel:", nrow(panel_agg), "rows,",
    n_distinct(panel_agg$state_fips), "states,",
    length(unique(panel_agg$year)), "years\n")

# Validate
stopifnot(nrow(panel_agg) > 1000)
stopifnot(all(!is.na(panel_agg$bnl_year)))

# ==============================================================================
# 2. Clean NAICS-level BDS panel
# ==============================================================================

panel_naics <- bds_naics %>%
  rename(state_fips = state, year = YEAR) %>%
  mutate(
    across(c(ESTAB, ESTABS_ENTRY, ESTABS_EXIT, EMP,
             JOB_CREATION, JOB_DESTRUCTION),
           as.numeric),
    across(c(ESTABS_ENTRY_RATE, ESTABS_EXIT_RATE), as.numeric),
    year = as.integer(year)
  ) %>%
  filter(!is.na(ESTABS_ENTRY_RATE)) %>%
  mutate(state_id = as.integer(factor(state_fips)))

# Merge treatment
panel_naics <- panel_naics %>%
  left_join(bnl_laws %>% select(state_fips, bnl_year), by = "state_fips") %>%
  mutate(
    first_treat = bnl_year,
    treated = as.integer(year >= bnl_year),
    post = treated,
    # Data intensity classification
    data_intensive = case_when(
      NAICS %in% c("51", "52") ~ "High",
      NAICS %in% c("54", "53") ~ "Medium",
      NAICS %in% c("23", "11") ~ "Low (Placebo)",
      TRUE ~ "Other"
    )
  )

cat("NAICS panel:", nrow(panel_naics), "rows,",
    n_distinct(panel_naics$state_fips), "states,",
    n_distinct(panel_naics$NAICS), "sectors\n")

# ==============================================================================
# 3. Summary statistics
# ==============================================================================

cat("\n=== Summary Statistics (Aggregate) ===\n")
panel_agg %>%
  summarise(
    mean_entry_rate = mean(ESTABS_ENTRY_RATE, na.rm = TRUE),
    sd_entry_rate = sd(ESTABS_ENTRY_RATE, na.rm = TRUE),
    mean_exit_rate = mean(ESTABS_EXIT_RATE, na.rm = TRUE),
    sd_exit_rate = sd(ESTABS_EXIT_RATE, na.rm = TRUE),
    mean_emp = mean(EMP, na.rm = TRUE),
    mean_firms = mean(FIRM, na.rm = TRUE),
    mean_net_jc_rate = mean(NET_JOB_CREATION_RATE, na.rm = TRUE),
    sd_net_jc_rate = sd(NET_JOB_CREATION_RATE, na.rm = TRUE)
  ) %>%
  print()

cat("\n=== Pre vs Post Treatment Comparison ===\n")
panel_agg %>%
  group_by(treated) %>%
  summarise(
    n = n(),
    mean_entry = mean(ESTABS_ENTRY_RATE, na.rm = TRUE),
    mean_exit = mean(ESTABS_EXIT_RATE, na.rm = TRUE),
    mean_net_jc = mean(NET_JOB_CREATION_RATE, na.rm = TRUE)
  ) %>%
  print()

cat("\n=== Entry Rate by Data Intensity (NAICS) ===\n")
panel_naics %>%
  group_by(data_intensive, treated) %>%
  summarise(
    mean_entry = mean(ESTABS_ENTRY_RATE, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  pivot_wider(names_from = treated, values_from = mean_entry, names_prefix = "post_") %>%
  mutate(diff = post_1 - post_0) %>%
  print()

# ==============================================================================
# 4. Save analysis panels
# ==============================================================================

saveRDS(panel_agg, "../data/panel_aggregate.rds")
saveRDS(panel_naics, "../data/panel_naics.rds")

cat("\n-> data/panel_aggregate.rds (", nrow(panel_agg), " rows)")
cat("\n-> data/panel_naics.rds (", nrow(panel_naics), " rows)\n")
