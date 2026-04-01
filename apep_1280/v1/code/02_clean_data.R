# ==============================================================================
# 02_clean_data.R — Build analysis panel (state × quarter × industry × race)
# ==============================================================================

source("00_packages.R")

qwi <- readRDS("../data/qwi_classified.rds")
mw  <- readRDS("../data/mw_quarterly.rds")

cat("QWI rows:", nrow(qwi), "\n")

# --- Aggregate to state × quarter × industry_group × race ---
# Filter out missing earnings first to avoid weighted.mean length mismatch
state_panel <- qwi |>
  filter(!is.na(earns), !is.na(emp), emp > 0) |>
  group_by(state_fips, year, quarter, period, industry_group, race) |>
  summarize(
    total_wage_bill = sum(earns * emp, na.rm = TRUE),
    emp = sum(emp, na.rm = TRUE),
    hires = sum(hires, na.rm = TRUE),
    seps = sum(seps, na.rm = TRUE),
    n_counties = n_distinct(county_fips),
    .groups = "drop"
  ) |>
  mutate(earns = total_wage_bill / emp) |>
  filter(emp > 0)

cat("State panel rows:", nrow(state_panel), "\n")

# --- Merge MW data ---
mw_slim <- mw |>
  distinct(state_fips, year, quarter, period, effective_mw, log_mw,
           mw_ratio, first_treat_period, treated)

panel <- state_panel |>
  inner_join(mw_slim, by = c("state_fips", "year", "quarter", "period"))

cat("Merged panel rows:", nrow(panel), "\n")
cat("States in merged:", n_distinct(panel$state_fips), "\n")

# --- Reshape to wide: one row per state × quarter × industry_group ---
wide <- panel |>
  select(state_fips, year, quarter, period, industry_group,
         race, emp, earns, effective_mw, log_mw, mw_ratio,
         first_treat_period) |>
  pivot_wider(
    id_cols = c(state_fips, year, quarter, period, industry_group,
                effective_mw, log_mw, mw_ratio, first_treat_period),
    names_from = race,
    values_from = c(emp, earns),
    names_sep = "_"
  )

# Compute racial gap outcomes (all in logs)
analysis <- wide |>
  filter(!is.na(emp_A1), !is.na(emp_A2), emp_A1 > 0, emp_A2 > 0) |>
  mutate(
    # Wage bill = earnings × employment
    wage_bill_white = earns_A1 * emp_A1,
    wage_bill_black = earns_A2 * emp_A2,

    # Log ratios (Black / White) — positive = gap narrows
    log_emp_ratio = log(emp_A2) - log(emp_A1),
    log_earns_ratio = log(earns_A2) - log(earns_A1),
    log_wage_bill_ratio = log(wage_bill_black) - log(wage_bill_white),

    # Industry breakdown
    naics2_label = industry_group,

    # IDs for fixed effects
    state_id = as.integer(factor(state_fips)),
    yq_id = as.integer(factor(period)),
    state_ind_id = as.integer(factor(paste(state_fips, industry_group)))
  )

cat("\nAnalysis panel: ", nrow(analysis), " rows\n")
cat("States: ", n_distinct(analysis$state_fips), "\n")
cat("Periods: ", n_distinct(analysis$period), "\n")
cat("Industry groups: ", paste(unique(analysis$industry_group), collapse = ", "), "\n")

# --- Summary statistics ---
cat("\n=== Summary Statistics ===\n")
analysis |>
  group_by(industry_group) |>
  summarize(
    n_obs = n(),
    n_states = n_distinct(state_fips),
    mean_bw_earns_ratio = mean(earns_A2 / earns_A1, na.rm = TRUE),
    sd_bw_earns_ratio = sd(earns_A2 / earns_A1, na.rm = TRUE),
    mean_bw_emp_share = mean(emp_A2 / (emp_A1 + emp_A2), na.rm = TRUE),
    mean_mw = mean(effective_mw, na.rm = TRUE),
    .groups = "drop"
  ) |>
  print()

# --- Diagnostics ---
n_treated <- analysis |>
  filter(first_treat_period > 0) |>
  pull(state_fips) |>
  n_distinct()

min_pre <- analysis |>
  filter(first_treat_period > 0) |>
  group_by(state_fips, industry_group) |>
  summarize(n_pre = sum(period < first_treat_period), .groups = "drop") |>
  pull(n_pre) |>
  min()

cat("\nDiagnostics:\n")
cat("  Treated states:", n_treated, "\n")
cat("  Min pre-periods:", min_pre, "\n")
cat("  Total obs:", nrow(analysis), "\n")

write_json(list(
  n_treated = n_treated,
  n_pre = min_pre,
  n_obs = nrow(analysis)
), "../data/diagnostics.json", auto_unbox = TRUE)

saveRDS(analysis, "../data/analysis_panel.rds")
cat("\nSaved analysis_panel.rds\n")
