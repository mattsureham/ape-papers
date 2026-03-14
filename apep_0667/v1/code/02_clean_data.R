## 02_clean_data.R — Build state-year panel
## apep_0667: EBT rollout and drug-market disruption

source("00_packages.R")

cat("=== Loading raw data ===\n")

# --- Load all data files ---
ebt_dates      <- read_csv("../data/ebt_dates.csv", show_col_types = FALSE)
drug_poisoning <- read_csv("../data/drug_poisoning.csv", show_col_types = FALSE)
placebo_raw    <- read_csv("../data/placebo_outcomes.csv", show_col_types = FALSE)
population     <- read_csv("../data/population.csv", show_col_types = FALSE)
state_map      <- read_csv("../data/state_map.csv", show_col_types = FALSE)

cat("  EBT dates:       ", nrow(ebt_dates), "states\n")
cat("  Drug poisoning:  ", nrow(drug_poisoning), "state-years\n")
cat("  Placebo outcomes:", nrow(placebo_raw), "rows\n")
cat("  Population:      ", nrow(population), "state-years\n")
cat("  State map:       ", nrow(state_map), "entries\n")

# ===================================================================
cat("\n=== Merging data ===\n")
# ===================================================================

# Drug poisoning uses full state names; merge with state_map to get abbreviations
drug <- drug_poisoning %>%
  left_join(state_map, by = c("state" = "state_name")) %>%
  rename(drug_deaths = deaths, drug_death_rate = aadr) %>%
  select(state_abbr, state_name = state, year, drug_deaths, drug_death_rate)

# Check merge quality
n_unmatched <- sum(is.na(drug$state_abbr))
if (n_unmatched > 0) {
  cat("  WARNING:", n_unmatched, "drug poisoning rows failed state merge\n")
  cat("  Unmatched states:",
      paste(unique(drug$state_name[is.na(drug$state_abbr)]), collapse = ", "), "\n")
}
drug <- drug %>% filter(!is.na(state_abbr))

# --- Pivot placebo outcomes to wide format ---
placebo_wide <- placebo_raw %>%
  left_join(state_map, by = c("state" = "state_name")) %>%
  filter(!is.na(state_abbr)) %>%
  select(state_abbr, year, cause, aadr) %>%
  pivot_wider(
    names_from = cause,
    values_from = aadr,
    names_prefix = ""
  ) %>%
  rename(
    suicide_rate    = Suicide,
    injury_rate     = `Unintentional injuries`,
    heart_rate      = `Heart disease`
  )

cat("  Placebo wide:    ", nrow(placebo_wide), "state-years\n")

# --- Merge drug + placebo + EBT dates + population ---
panel <- drug %>%
  left_join(ebt_dates %>% select(state_abbr, ebt_year), by = "state_abbr") %>%
  left_join(placebo_wide, by = c("state_abbr", "year")) %>%
  left_join(
    population %>% select(state_abbr, year, population) %>% rename(pop_fred = population),
    by = c("state_abbr", "year")
  )

# Verify EBT merge
n_no_ebt <- sum(is.na(panel$ebt_year))
if (n_no_ebt > 0) {
  cat("  WARNING:", n_no_ebt, "rows missing EBT year\n")
  panel <- panel %>% filter(!is.na(ebt_year))
}

# ===================================================================
cat("\n=== Creating treatment variables ===\n")
# ===================================================================

panel <- panel %>%
  mutate(
    # Treatment indicator: 1 if EBT has been implemented
    treated = as.integer(year >= ebt_year),
    # first_treat for CS-DiD: = ebt_year for all states
    # (all 51 states eventually adopted EBT; no never-treated units)
    first_treat = ebt_year,
    # Relative time to treatment
    rel_time = year - ebt_year
  )

# --- Create numeric state ID ---
panel <- panel %>%
  mutate(state_id = as.integer(factor(state_abbr)))

# --- Filter to analysis window ---
panel <- panel %>%
  filter(year >= 1999, year <= 2010) %>%
  arrange(state_abbr, year)

# ===================================================================
cat("\n=== Panel diagnostics ===\n")
# ===================================================================
cat("  Panel dimensions:", nrow(panel), "rows x", ncol(panel), "cols\n")
cat("  States:          ", n_distinct(panel$state_abbr), "\n")
cat("  Years:           ", min(panel$year), "-", max(panel$year), "\n")
cat("  EBT cohorts:     ", paste(sort(unique(panel$ebt_year)), collapse = ", "), "\n")

# Cohort sizes
cohort_tab <- panel %>%
  distinct(state_abbr, ebt_year) %>%
  count(ebt_year, name = "n_states")
cat("\n  Cohort distribution:\n")
for (i in seq_len(nrow(cohort_tab))) {
  cat(sprintf("    %d: %d states\n", cohort_tab$ebt_year[i], cohort_tab$n_states[i]))
}

# Pre-treatment periods by cohort
cat("\n  Pre-treatment periods by cohort (data starts 1999):\n")
for (yr in sort(unique(panel$ebt_year))) {
  pre_periods <- max(0, yr - 1999)
  cat(sprintf("    Cohort %d: %d pre-periods\n", yr, pre_periods))
}

# Treatment status summary
cat("\n  Treatment status:\n")
cat("    Treated obs:     ", sum(panel$treated == 1), "\n")
cat("    Not-yet-treated: ", sum(panel$treated == 0), "\n")

# Outcome variable summary
cat("\n  Drug death rate (aadr per 100k):\n")
cat("    Mean:  ", round(mean(panel$drug_death_rate, na.rm = TRUE), 2), "\n")
cat("    SD:    ", round(sd(panel$drug_death_rate, na.rm = TRUE), 2), "\n")
cat("    Min:   ", round(min(panel$drug_death_rate, na.rm = TRUE), 2), "\n")
cat("    Max:   ", round(max(panel$drug_death_rate, na.rm = TRUE), 2), "\n")
cat("    NAs:   ", sum(is.na(panel$drug_death_rate)), "\n")

# Check for missing outcome values
for (v in c("drug_death_rate", "suicide_rate", "injury_rate", "heart_rate")) {
  n_miss <- sum(is.na(panel[[v]]))
  cat(sprintf("  Missing %-20s: %d / %d\n", v, n_miss, nrow(panel)))
}

# ===================================================================
cat("\n=== Saving panel ===\n")
# ===================================================================
write_csv(panel, "../data/panel.csv")
cat("  Saved:", nrow(panel), "rows to ../data/panel.csv\n")

# Also save as RDS for faster loading in subsequent scripts
saveRDS(panel, "../data/panel.rds")
cat("  Saved RDS: ../data/panel.rds\n")

cat("\n=== Data cleaning complete ===\n")
