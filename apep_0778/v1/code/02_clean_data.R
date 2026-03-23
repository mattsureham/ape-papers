## =============================================================================
## 02_clean_data.R — Build analysis panel
## apep_0778
## =============================================================================

source("00_packages.R")

cat("=== Loading data ===\n")
panel <- readRDS("../data/analysis_panel.rds")
treatment <- readRDS("../data/treatment_states.rds")

## ---- Handle pre-ACS adopters ----
cat("\n=== Step 1: Handle pre-2005 adopters ===\n")

## ACS 1-year starts in 2005. States adopting before 2005 have no pre-period.
## For CS-DiD, we have two options:
## 1. Exclude them (lose 12 treated states)
## 2. Keep them as "already-treated" (CS-DiD ignores groups with no pre-period)
##
## Strategy: Keep all states. CS-DiD will only estimate ATTs for groups that
## have at least one pre-treatment period (i.e., adoption_year >= 2006 since
## first ACS year is 2005). States with adoption_year <= 2005 contribute as
## "already treated" context but don't have estimated group-time ATTs.

## For the TWFE specification, all states contribute to the comparison.

cat("  Treatment cohort distribution:\n")
cohort_tab <- panel %>%
  filter(treated == 1) %>%
  distinct(state_abbr, first_treat) %>%
  count(first_treat) %>%
  arrange(first_treat)
print(cohort_tab)

## Cohorts with pre-treatment data in ACS (first_treat >= 2006):
usable_cohorts <- cohort_tab %>% filter(first_treat >= 2006)
cat(sprintf("\n  Cohorts with pre-ACS data: %d (%d states)\n",
            nrow(usable_cohorts), sum(usable_cohorts$n)))

## ---- Summary statistics ----
cat("\n=== Step 2: Summary statistics ===\n")

sumstats <- panel %>%
  group_by(treated) %>%
  summarize(
    n_states = n_distinct(state_abbr),
    n_obs = n(),
    mean_snap_rate = mean(snap_rate, na.rm = TRUE),
    sd_snap_rate = sd(snap_rate, na.rm = TRUE),
    mean_snap_hh = mean(snap_hh, na.rm = TRUE),
    sd_snap_hh = sd(snap_hh, na.rm = TRUE),
    mean_total_hh = mean(total_hh, na.rm = TRUE),
    .groups = "drop"
  )
print(sumstats)

## ---- Save overall stats ----
overall_stats <- panel %>%
  summarize(
    n_obs = n(),
    n_states = n_distinct(state_abbr),
    n_treated = n_distinct(state_abbr[treated == 1]),
    n_control = n_distinct(state_abbr[treated == 0]),
    n_cohorts = n_distinct(first_treat[first_treat >= 2006]),
    mean_snap_rate = mean(snap_rate, na.rm = TRUE),
    sd_snap_rate = sd(snap_rate, na.rm = TRUE),
    mean_log_snap_hh = mean(log_snap_hh, na.rm = TRUE),
    sd_log_snap_hh = sd(log_snap_hh, na.rm = TRUE),
    min_year = min(year),
    max_year = max(year)
  )

saveRDS(overall_stats, "../data/overall_stats.rds")
cat("  Saved: overall_stats.rds\n")
cat("  DONE.\n")
