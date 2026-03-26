## 02_clean_data.R — Merge and construct analysis panel
## Paper: The Deterrence Dividend (apep_0984)

source("00_packages.R")

cat("=== CONSTRUCTING ANALYSIS PANEL ===\n\n")

# Load raw data
palladium_q  <- readRDS("../data/palladium_quarterly.rds")
law_dates    <- readRDS("../data/law_dates.rds")
all_states   <- readRDS("../data/all_states.rds")
gtrends_q    <- readRDS("../data/gtrends_quarterly.rds")

# Load unemployment if available
unemp <- tryCatch(readRDS("../data/state_unemployment.rds"), error = function(e) NULL)

# -----------------------------------------------------------------------
# 1. Create state panel skeleton (all states × all quarters)
# -----------------------------------------------------------------------
quarters <- palladium_q %>%
  select(year, quarter, yq) %>%
  distinct() %>%
  arrange(year, quarter) %>%
  mutate(time_num = row_number())

panel <- expand_grid(
  state_abbr = all_states$state_abbr,
  yq = quarters$yq
) %>%
  left_join(quarters, by = "yq") %>%
  left_join(all_states, by = "state_abbr")

cat(sprintf("Panel skeleton: %d state-quarters (%d states × %d quarters)\n",
            nrow(panel), n_distinct(panel$state_abbr), n_distinct(panel$yq)))

# -----------------------------------------------------------------------
# 2. Add treatment variable
# -----------------------------------------------------------------------
panel <- panel %>%
  left_join(
    law_dates %>% select(state_abbr, effective_date, first_treat_num, law_type),
    by = "state_abbr"
  ) %>%
  mutate(
    # first_treat for C-S: quarter number when law took effect; 0 for never-treated
    first_treat = ifelse(is.na(first_treat_num), 0, first_treat_num),
    # Binary treatment indicator
    treated = ifelse(first_treat > 0 & time_num >= first_treat, 1, 0),
    # Treatment cohort label
    cohort = case_when(
      first_treat == 0 ~ "Never treated",
      !is.na(effective_date) & year(effective_date) == 2021 ~ "2021 cohort",
      !is.na(effective_date) & year(effective_date) == 2022 ~ "2022 cohort",
      !is.na(effective_date) & year(effective_date) == 2023 ~ "2023 cohort",
      !is.na(effective_date) & year(effective_date) == 2024 ~ "2024 cohort",
      TRUE ~ "Never treated"
    )
  )

n_treated_states <- sum(panel$first_treat > 0) / n_distinct(panel$yq)
n_control_states <- sum(panel$first_treat == 0) / n_distinct(panel$yq)
cat(sprintf("Treatment: %d treated states, %d never-treated states\n",
            n_treated_states, n_control_states))

# -----------------------------------------------------------------------
# 3. Merge outcomes
# -----------------------------------------------------------------------
# Google Trends search index
panel <- panel %>%
  left_join(gtrends_q %>% select(state_abbr, yq, search_index),
            by = c("state_abbr", "yq"))

# Fill missing search_index with 0 (low search volume = no theft concern)
panel <- panel %>%
  mutate(search_index = ifelse(is.na(search_index), 0, search_index))

# Palladium prices
panel <- panel %>%
  left_join(palladium_q %>% select(yq, palladium_price, log_palladium),
            by = "yq")

# Unemployment
if (!is.null(unemp)) {
  panel <- panel %>%
    left_join(unemp %>%
                mutate(yq = paste0(year, "Q", quarter)) %>%
                select(state_abbr, yq, unemp_rate),
              by = c("state_abbr", "yq"))
} else {
  panel$unemp_rate <- NA_real_
}

# -----------------------------------------------------------------------
# 4. Construct derived variables
# -----------------------------------------------------------------------
panel <- panel %>%
  mutate(
    # Inverse hyperbolic sine transformation (handles zeros)
    ihs_search = log(search_index + sqrt(search_index^2 + 1)),
    # Log(1 + search_index)
    log1p_search = log1p(search_index),
    # State numeric ID for fixest
    state_id = as.numeric(factor(state_abbr)),
    # Relative time to treatment
    rel_time = ifelse(first_treat > 0, time_num - first_treat, NA_integer_),
    # Palladium price interaction
    treated_x_price = treated * log_palladium
  )

# -----------------------------------------------------------------------
# 5. Sample restrictions
# -----------------------------------------------------------------------
# Drop quarters with missing palladium data
panel <- panel %>% filter(!is.na(palladium_price))

# Analysis sample: 2017Q1 - 2025Q2 (ensuring pre-period for all cohorts)
panel <- panel %>%
  filter(year >= 2017, !(year == 2025 & quarter > 2))

cat(sprintf("\nFinal panel: %d state-quarter observations\n", nrow(panel)))
cat(sprintf("  States: %d\n", n_distinct(panel$state_abbr)))
cat(sprintf("  Quarters: %d (%s to %s)\n",
            n_distinct(panel$yq),
            min(panel$yq), max(panel$yq)))
cat(sprintf("  Mean search index: %.1f (SD: %.1f)\n",
            mean(panel$search_index), sd(panel$search_index)))
cat(sprintf("  Treated obs: %d (%.1f%%)\n",
            sum(panel$treated), 100 * mean(panel$treated)))

# Cohort distribution
cat("\nCohort distribution:\n")
panel %>%
  distinct(state_abbr, cohort) %>%
  count(cohort) %>%
  print()

# -----------------------------------------------------------------------
# 6. Save analysis panel
# -----------------------------------------------------------------------
saveRDS(panel, "../data/analysis_panel.rds")
cat("\nSaved analysis_panel.rds\n")

cat("\n=== PANEL CONSTRUCTION COMPLETE ===\n")
