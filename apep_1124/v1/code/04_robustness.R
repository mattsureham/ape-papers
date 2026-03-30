## ============================================================
## 04_robustness.R — Robustness checks and heterogeneity
## apep_1124: Sanctions at Sea
## ============================================================

source("00_packages.R")

cat("=== Loading data and results ===\n")

panel <- read_csv("../data/panel_annual.csv", show_col_types = FALSE) %>%
  mutate(
    first_treat = ifelse(first_treat == 2012, 2013, first_treat),
    treated = as.integer(first_treat > 0 & year >= first_treat),
    cohort = ifelse(first_treat == 0, 10000, first_treat)
  )

results <- readRDS("../data/main_results.rds")
iuu_cards <- read_csv("../data/iuu_cards.csv", show_col_types = FALSE)

panel_balanced <- panel %>%
  group_by(flag_id) %>%
  filter(n() >= 8) %>%
  ungroup() %>%
  mutate(flag_id = as.integer(flag_id))

# ---------------------------------------------------------------
# 1. Placebo: Small fleets (< 50 vessels avg)
# ---------------------------------------------------------------

cat("=== Placebo: Small fleets ===\n")

fleet_size <- panel_balanced %>%
  group_by(flag_iso3, flag_id) %>%
  summarise(avg_vessels = mean(n_vessels, na.rm = TRUE), .groups = "drop")

small_ids <- fleet_size %>% filter(avg_vessels < 50) %>% pull(flag_id)
large_ids <- fleet_size %>% filter(avg_vessels >= 50) %>% pull(flag_id)

cat(sprintf("Small fleets (<50 vessels): %d countries\n", length(small_ids)))
cat(sprintf("Large fleets (>=50 vessels): %d countries\n", length(large_ids)))

twfe_placebo_small <- feols(
  ln_fishing_hours ~ treated | flag_id + year,
  data = panel_balanced %>% filter(flag_id %in% small_ids),
  cluster = ~flag_id
)
cat("Placebo (small fleets):\n")
cat(sprintf("  coef = %.4f (SE = %.4f)\n",
            coef(twfe_placebo_small)["treated"],
            se(twfe_placebo_small)["treated"]))

twfe_large <- feols(
  ln_fishing_hours ~ treated | flag_id + year,
  data = panel_balanced %>% filter(flag_id %in% large_ids),
  cluster = ~flag_id
)
cat("Large fleets only:\n")
cat(sprintf("  coef = %.4f (SE = %.4f)\n",
            coef(twfe_large)["treated"],
            se(twfe_large)["treated"]))

# ---------------------------------------------------------------
# 2. Drop Early Cohorts (2013 — limited pre-periods)
# ---------------------------------------------------------------

cat("\n=== Drop 2013 cohort ===\n")

panel_no13 <- panel_balanced %>% filter(first_treat != 2013)
twfe_no13 <- feols(
  ln_fishing_hours ~ treated | flag_id + year,
  data = panel_no13,
  cluster = ~flag_id
)
cat(sprintf("  coef = %.4f (SE = %.4f), N = %d\n",
            coef(twfe_no13)["treated"], se(twfe_no13)["treated"],
            nobs(twfe_no13)))

# ---------------------------------------------------------------
# 3. Later Cohorts Only (2015+, better pre-trends)
# ---------------------------------------------------------------

cat("\n=== Later cohorts only (2015+) ===\n")

panel_late <- panel_balanced %>%
  filter(first_treat == 0 | first_treat >= 2015)

sa_late <- feols(
  ln_fishing_hours ~ sunab(cohort, year) | flag_id + year,
  data = panel_late,
  cluster = ~flag_id
)

sa_late_att <- summary(sa_late, agg = "ATT")
cat(sprintf("SA ATT (2015+ cohorts): %.4f (SE = %.4f)\n",
            coef(sa_late_att), se(sa_late_att)))

# ---------------------------------------------------------------
# 4. Heterogeneity: Card Resolution (Green vs Red vs Ongoing)
# ---------------------------------------------------------------

cat("\n=== Heterogeneity: Card resolution ===\n")

card_outcome <- iuu_cards %>%
  mutate(
    yellow_year = year(yellow_date),
    outcome = case_when(
      !is.na(red_date) ~ "escalated",
      !is.na(green_date) ~ "resolved",
      TRUE ~ "ongoing"
    )
  ) %>%
  select(flag_iso3, outcome)

panel_het <- panel_balanced %>%
  left_join(card_outcome, by = "flag_iso3") %>%
  mutate(outcome = replace_na(outcome, "never_carded"))

# Resolved countries
resolved_panel <- panel_het %>%
  filter(outcome %in% c("resolved", "never_carded"))

n_resolved <- n_distinct(resolved_panel$flag_id[resolved_panel$first_treat > 0])
cat(sprintf("Resolved (green card): %d treated countries\n", n_resolved))

if (n_resolved >= 3) {
  twfe_resolved <- feols(
    ln_fishing_hours ~ treated | flag_id + year,
    data = resolved_panel,
    cluster = ~flag_id
  )
  cat(sprintf("  coef = %.4f (SE = %.4f)\n",
              coef(twfe_resolved)["treated"], se(twfe_resolved)["treated"]))
} else {
  twfe_resolved <- NULL
}

# Escalated countries (red card)
escalated_panel <- panel_het %>%
  filter(outcome %in% c("escalated", "never_carded"))

n_escalated <- n_distinct(escalated_panel$flag_id[escalated_panel$first_treat > 0])
cat(sprintf("Escalated (red card): %d treated countries\n", n_escalated))

if (n_escalated >= 3) {
  twfe_escalated <- feols(
    ln_fishing_hours ~ treated | flag_id + year,
    data = escalated_panel,
    cluster = ~flag_id
  )
  cat(sprintf("  coef = %.4f (SE = %.4f)\n",
              coef(twfe_escalated)["treated"], se(twfe_escalated)["treated"]))
} else {
  twfe_escalated <- NULL
}

# Ongoing countries (still under yellow card)
ongoing_panel <- panel_het %>%
  filter(outcome %in% c("ongoing", "never_carded"))

n_ongoing <- n_distinct(ongoing_panel$flag_id[ongoing_panel$first_treat > 0])
cat(sprintf("Ongoing (yellow card persists): %d treated countries\n", n_ongoing))

if (n_ongoing >= 3) {
  twfe_ongoing <- feols(
    ln_fishing_hours ~ treated | flag_id + year,
    data = ongoing_panel,
    cluster = ~flag_id
  )
  cat(sprintf("  coef = %.4f (SE = %.4f)\n",
              coef(twfe_ongoing)["treated"], se(twfe_ongoing)["treated"]))
} else {
  twfe_ongoing <- NULL
}

# ---------------------------------------------------------------
# 5. Heterogeneity: Major fishing nations vs small islands
# ---------------------------------------------------------------

cat("\n=== Heterogeneity: Major vs small fishing nations ===\n")

# Top fishing nations by pre-treatment average
major_fish <- fleet_size %>%
  filter(avg_vessels >= 200) %>%
  pull(flag_id)

major_panel <- panel_balanced %>%
  filter(flag_id %in% major_fish | first_treat == 0)

n_major_treated <- n_distinct(major_panel$flag_id[major_panel$first_treat > 0])
cat(sprintf("Major fishing nations (>=200 vessels): %d treated\n", n_major_treated))

if (n_major_treated >= 3) {
  twfe_major <- feols(
    ln_fishing_hours ~ treated | flag_id + year,
    data = major_panel,
    cluster = ~flag_id
  )
  cat(sprintf("  coef = %.4f (SE = %.4f)\n",
              coef(twfe_major)["treated"], se(twfe_major)["treated"]))
} else {
  twfe_major <- NULL
}

# ---------------------------------------------------------------
# 6. Save Robustness Results
# ---------------------------------------------------------------

cat("\n=== Saving robustness results ===\n")

robustness <- list(
  twfe_placebo_small = twfe_placebo_small,
  twfe_large = twfe_large,
  twfe_no13 = twfe_no13,
  sa_late_att = sa_late_att,
  twfe_resolved = twfe_resolved,
  twfe_escalated = twfe_escalated,
  twfe_ongoing = twfe_ongoing,
  twfe_major = twfe_major
)

saveRDS(robustness, "../data/robustness_results.rds")

cat("Robustness results saved.\n")
