## 02_clean_data.R — Additional cleaning and variable construction
## APEP-0636: Constitutional Carry and Firearm Violence

source("00_packages.R")

panel <- read_csv("data/analysis_panel.csv", show_col_types = FALSE)

cat("Loaded panel:", nrow(panel), "rows,", n_distinct(panel$state_fips), "states\n")

# ============================================================
# 1. CREATE NUMERIC STATE ID FOR CS-DiD
# ============================================================
# The `did` package requires a numeric panel ID

state_ids <- panel |>
  distinct(state_name, state_fips) |>
  arrange(state_fips) |>
  mutate(state_id = row_number())

panel <- panel |> left_join(state_ids, by = c("state_name", "state_fips"))

# ============================================================
# 2. LOG OUTCOMES (for semi-elasticity interpretation)
# ============================================================

panel <- panel |>
  mutate(
    log_fa_homicide_rate = log(fa_homicide_rate + 0.1),  # +0.1 to handle zeros
    log_fa_suicide_rate = log(fa_suicide_rate + 0.1),
    log_total_fa_rate = log(total_fa_rate + 0.1)
  )

# ============================================================
# 3. PRE-TREATMENT COVARIATES (state-level baseline)
# ============================================================
# Use 2019 values as pre-treatment baselines

baselines <- panel |>
  filter(year == 2019) |>
  select(state_fips,
         baseline_fa_homicide = fa_homicide_rate,
         baseline_fa_suicide = fa_suicide_rate,
         baseline_pop = population)

panel <- panel |>
  left_join(baselines, by = "state_fips")

# ============================================================
# 4. TREATMENT INTENSITY MEASURES
# ============================================================

# Time since treatment (event time)
panel <- panel |>
  mutate(
    event_time = ifelse(gname > 0, year - gname, NA_integer_),
    post = as.integer(gname > 0 & year >= gname)
  )

# ============================================================
# 5. SUMMARY STATISTICS BY GROUP
# ============================================================

cat("\n=== Summary Statistics ===\n")

summ <- panel |>
  group_by(cc_wave) |>
  summarise(
    n_states = n_distinct(state_fips),
    mean_fa_hom = mean(fa_homicide_rate),
    sd_fa_hom = sd(fa_homicide_rate),
    mean_fa_sui = mean(fa_suicide_rate),
    sd_fa_sui = sd(fa_suicide_rate),
    mean_pop = mean(population) / 1e6,
    .groups = "drop"
  )

print(summ)

# ============================================================
# 6. VALIDATE BALANCED PANEL
# ============================================================

panel_balance <- panel |>
  count(state_fips) |>
  pull(n) |>
  unique()

if (length(panel_balance) == 1) {
  cat("\nPanel is balanced:", panel_balance, "years per state\n")
} else {
  cat("\nWARNING: Unbalanced panel. Years per state:", paste(panel_balance, collapse = ", "), "\n")
  # Fill missing years
  full_grid <- expand_grid(
    state_fips = unique(panel$state_fips),
    year = 2019:2024
  )
  panel <- full_grid |>
    left_join(panel, by = c("state_fips", "year"))
  cat("Filled to balanced panel:", nrow(panel), "rows\n")
}

write_csv(panel, "data/analysis_panel_clean.csv")
cat("\nCleaned panel saved to data/analysis_panel_clean.csv\n")
