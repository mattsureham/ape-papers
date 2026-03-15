## 02_clean_data.R — Clean BFS data and construct treatment variables
## apep_0693: The Price of Privacy

source("00_packages.R")

# ------------------------------------------------------------------
# 1. Load raw BFS state data
# ------------------------------------------------------------------
bfs <- fread("../data/bfs_state_weekly.csv")

cat("Raw BFS columns:", paste(names(bfs), collapse = ", "), "\n")
cat(sprintf("Raw BFS: %d rows\n", nrow(bfs)))

# Standardize column names to lowercase
setnames(bfs, names(bfs), tolower(names(bfs)))

# Create date variable from year + week
bfs[, date := as.Date(paste0(year, "-01-01")) + (week - 1) * 7]

# ------------------------------------------------------------------
# 2. Privacy law treatment dates
# ------------------------------------------------------------------
# Source: IAPP Comprehensive State Privacy Law Tracker
# Each entry is (state FIPS abbreviation, effective date)
privacy_laws <- tribble(
  ~state, ~effective_date,
  "CA", "2020-01-01",  # CCPA (CPRA effective 2023-01-01, but CCPA from 2020)
  "VA", "2023-01-01",  # VCDPA
  "CO", "2023-07-01",  # CPA
  "CT", "2023-07-01",  # CTDPA
  "UT", "2023-12-31",  # UCPA
  "TX", "2024-07-01",  # TDPSA
  "FL", "2024-07-01",  # FDBR
  "OR", "2024-07-01",  # OCPA
  "MT", "2024-10-01",  # MCDPA
  "IA", "2025-01-01",  # Iowa
  "DE", "2025-01-01",  # Delaware
  "NE", "2025-01-01",  # Nebraska
  "NH", "2025-01-01",  # New Hampshire
  "NJ", "2025-01-01",  # New Jersey
  "TN", "2025-07-01",  # Tennessee
  "MN", "2025-07-01",  # Minnesota
  "MD", "2025-10-01",  # Maryland
  "IN", "2026-01-01",  # Indiana
  "KY", "2026-01-01",  # Kentucky
  "RI", "2026-01-01"   # Rhode Island
) %>%
  mutate(effective_date = as.Date(effective_date))

cat(sprintf("Privacy laws coded: %d states\n", nrow(privacy_laws)))

# ------------------------------------------------------------------
# 3. Merge treatment into BFS panel
# ------------------------------------------------------------------
# Match state abbreviations
bfs <- bfs %>%
  as_tibble() %>%
  left_join(privacy_laws, by = "state") %>%
  mutate(
    # Treatment indicator: 1 if state has privacy law effective by this week
    treated = ifelse(!is.na(effective_date) & date >= effective_date, 1L, 0L),
    # First treatment year-week for CS-DiD (year * 52 + week)
    time_period = year * 52L + week,
    # Cohort group for CS-DiD: first treatment period (0 = never treated)
    first_treat_period = ifelse(
      !is.na(effective_date),
      as.integer(format(effective_date, "%Y")) * 52L +
        as.integer(format(effective_date, "%W")),
      0L
    )
  )

# ------------------------------------------------------------------
# 4. Create numeric state ID for panel
# ------------------------------------------------------------------
state_ids <- bfs %>%
  distinct(state) %>%
  arrange(state) %>%
  mutate(state_id = row_number())

bfs <- bfs %>%
  left_join(state_ids, by = "state")

# ------------------------------------------------------------------
# 5. Create quarterly aggregation for CS-DiD (weekly is too granular)
# ------------------------------------------------------------------
bfs <- bfs %>%
  mutate(
    quarter = ceiling(as.numeric(format(date, "%m")) / 3),
    year_quarter = paste0(year, "Q", quarter),
    yq = year * 4L + quarter  # numeric quarter index
  )

bfs_quarterly <- bfs %>%
  group_by(state, state_id, year, quarter, yq, first_treat_period) %>%
  summarise(
    ba = sum(ba_nsa, na.rm = TRUE),
    hba = sum(hba_nsa, na.rm = TRUE),
    wba = sum(wba_nsa, na.rm = TRUE),
    cba = sum(cba_nsa, na.rm = TRUE),
    effective_date = first(effective_date),
    .groups = "drop"
  ) %>%
  mutate(
    # First treat quarter for CS-DiD
    first_treat_q = ifelse(
      !is.na(effective_date),
      as.integer(format(effective_date, "%Y")) * 4L +
        ceiling(as.numeric(format(effective_date, "%m")) / 3),
      0L
    ),
    treated = ifelse(!is.na(effective_date) & yq >= first_treat_q, 1L, 0L),
    log_ba = log(ba + 1),
    log_hba = log(hba + 1),
    log_wba = log(wba + 1),
    log_cba = log(cba + 1)
  )

# ------------------------------------------------------------------
# 6. Summary statistics
# ------------------------------------------------------------------
cat("\n=== Panel Summary ===\n")
cat(sprintf("States: %d\n", n_distinct(bfs_quarterly$state)))
cat(sprintf("Quarters: %d\n", n_distinct(bfs_quarterly$yq)))
cat(sprintf("Treated states: %d\n", n_distinct(bfs_quarterly$state[bfs_quarterly$first_treat_q > 0])))
cat(sprintf("Never-treated states: %d\n", n_distinct(bfs_quarterly$state[bfs_quarterly$first_treat_q == 0])))
cat(sprintf("Total obs: %d\n", nrow(bfs_quarterly)))
cat(sprintf("Mean weekly BA (all): %.1f\n", mean(bfs$ba_nsa, na.rm = TRUE)))
cat(sprintf("Mean quarterly BA (all): %.1f\n", mean(bfs_quarterly$ba, na.rm = TRUE)))

# Cohort sizes
cohort_sizes <- bfs_quarterly %>%
  filter(first_treat_q > 0) %>%
  distinct(state, first_treat_q) %>%
  count(first_treat_q, name = "n_states") %>%
  arrange(first_treat_q)

cat("\n=== Treatment Cohorts ===\n")
print(cohort_sizes)

# ------------------------------------------------------------------
# 7. Save cleaned data
# ------------------------------------------------------------------
saveRDS(bfs, "../data/bfs_weekly_clean.rds")
saveRDS(bfs_quarterly, "../data/bfs_quarterly_clean.rds")

cat("\nCleaned data saved.\n")
