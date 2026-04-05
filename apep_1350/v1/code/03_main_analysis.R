## 03_main_analysis.R — Main DiD analysis
## apep_1350: The Segregation Dividend

source("00_packages.R")

# ── 1. Load analysis panels ──
bw <- arrow::read_parquet("../data/analysis_panel_624.parquet") |> as_tibble()
state_panel <- arrow::read_parquet("../data/state_panel_624.parquet") |> as_tibble()

cat(sprintf("Analysis panel: %d obs, %d states, years %d-%d\n",
            nrow(bw), n_distinct(bw$state_fips),
            min(bw$year), max(bw$year)))

# Also restrict state_panel for later use
state_panel <- state_panel |> filter(year >= 2005, year <= 2023)

# ── 2. Document the phenomenon: National B/W earnings ratio trend ──
national_trend <- bw |>
  group_by(year, quarter, yq) |>
  summarise(
    mean_bw_ratio = weighted.mean(bw_earn_ratio, w = total_emp, na.rm = TRUE),
    mean_black_share = weighted.mean(black_emp_share, w = total_emp, na.rm = TRUE),
    mean_earn_black = weighted.mean(EarnS_A2, w = Emp_A2, na.rm = TRUE),
    mean_earn_white = weighted.mean(EarnS_A1, w = Emp_A1, na.rm = TRUE),
    total_black = sum(Emp_A2, na.rm = TRUE),
    total_white = sum(Emp_A1, na.rm = TRUE),
    n_states = n(),
    .groups = "drop"
  )

cat("\n── National trend: B/W earnings ratio in NAICS 624 ──\n")
national_trend |>
  filter(quarter == 1) |>
  select(year, mean_bw_ratio, mean_black_share, total_black, total_white) |>
  print(n = 30)

# ── 3. TWFE as baseline (for comparison, not primary) ──
cat("\n── TWFE baseline (state-level) ──\n")

# Outcome 1: B/W earnings ratio
twfe_ratio <- feols(
  bw_earn_ratio ~ post | state_fips + yq,
  data = bw,
  cluster = ~state_fips
)
cat("TWFE: B/W earnings ratio\n")
print(summary(twfe_ratio))

# Outcome 2: ln(Black earnings)
twfe_lnearn <- feols(
  ln_earn_black ~ post | state_fips + yq,
  data = bw,
  cluster = ~state_fips
)
cat("\nTWFE: ln(Black earnings)\n")
print(summary(twfe_lnearn))

# Outcome 3: Black employment share
twfe_share <- feols(
  black_emp_share ~ post | state_fips + yq,
  data = bw,
  cluster = ~state_fips
)
cat("\nTWFE: Black employment share\n")
print(summary(twfe_share))

# ── 4. Callaway-Sant'Anna (primary estimator) ──
cat("\n── Callaway-Sant'Anna (staggered DiD) ──\n")

# Need integer time periods for CS
# Convert yq to integer: 2001.0 → 1, 2001.25 → 2, etc.
all_yq <- sort(unique(bw$yq))
yq_to_int <- setNames(seq_along(all_yq), as.character(all_yq))

# Restrict to 2005-2023 for consistent coverage and balance
bw <- bw |> filter(year >= 2005, year <= 2023)
all_yq <- sort(unique(bw$yq))
yq_to_int <- setNames(seq_along(all_yq), as.character(all_yq))

# Balance the panel: keep states present in all quarters of this window
state_counts <- bw |> count(state_fips)
all_quarters <- n_distinct(bw$yq)
balanced_states <- state_counts$state_fips[state_counts$n == all_quarters]

cat(sprintf("Balanced panel (2005-2023): %d of %d states have all %d quarters\n",
            length(balanced_states), n_distinct(bw$state_fips), all_quarters))

# If still too few, relax to >= 90% of quarters
if (length(balanced_states) < 30) {
  threshold <- floor(0.90 * all_quarters)
  balanced_states <- state_counts$state_fips[state_counts$n >= threshold]
  cat(sprintf("  Relaxed to 90%%: %d states with >= %d quarters\n", length(balanced_states), threshold))
}

bw_balanced <- bw |> filter(state_fips %in% balanced_states)

bw_cs <- bw_balanced |>
  filter(!is.na(bw_earn_ratio)) |>
  mutate(
    time_id = as.integer(yq_to_int[as.character(yq)]),
    first_treat_id = if_else(
      first_treat_yq > 0,
      as.integer(yq_to_int[as.character(first_treat_yq)]),
      0L
    )
  ) |>
  filter(!is.na(time_id), !is.na(first_treat_id))

# CS: B/W earnings ratio
cs_ratio <- att_gt(
  yname = "bw_earn_ratio",
  tname = "time_id",
  idname = "state_fips",
  gname = "first_treat_id",
  data = bw_cs,
  control_group = "nevertreated",
  base_period = "universal"
)

cat("CS overall ATT: B/W earnings ratio\n")
cs_ratio_agg <- aggte(cs_ratio, type = "simple")
print(summary(cs_ratio_agg))

# Event study
cs_ratio_es <- aggte(cs_ratio, type = "dynamic", min_e = -12, max_e = 20)
cat("\nCS event study (B/W ratio):\n")
print(summary(cs_ratio_es))

# CS: Black employment share
cs_share <- att_gt(
  yname = "black_emp_share",
  tname = "time_id",
  idname = "state_fips",
  gname = "first_treat_id",
  data = bw_cs,
  control_group = "nevertreated",
  base_period = "universal"
)

cs_share_agg <- aggte(cs_share, type = "simple")
cat("\nCS overall ATT: Black employment share\n")
print(summary(cs_share_agg))

cs_share_es <- aggte(cs_share, type = "dynamic", min_e = -12, max_e = 20)

# CS: ln(Black earnings)
cs_lnearn <- att_gt(
  yname = "ln_earn_black",
  tname = "time_id",
  idname = "state_fips",
  gname = "first_treat_id",
  data = bw_cs,
  control_group = "nevertreated",
  base_period = "universal"
)

cs_lnearn_agg <- aggte(cs_lnearn, type = "simple")
cat("\nCS overall ATT: ln(Black earnings)\n")
print(summary(cs_lnearn_agg))

# ── 5. Race-level panel DiD (stacked by race) ──
# This is the individual-race-level specification
cat("\n── Race-level panel: state × quarter × race ──\n")

race_panel <- state_panel |>
  filter(state_fips %in% balanced_states) |>
  left_join(
    bw_balanced |> select(state_fips, yq, expansion_yq, expanded, post, first_treat_yq) |> distinct(),
    by = c("state_fips", "yq")
  ) |>
  mutate(
    black = as.integer(race == "A2"),
    ln_earn = log(EarnS),
    ln_emp = log(Emp)
  ) |>
  filter(!is.na(expanded))

# ── 5b. Decomposition: separate CS by race ──
# Instead of triple-diff (collinear with staggered FEs),
# run CS separately for Black and White earnings to decompose the ratio effect
cat("\n── Decomposition: CS by race ──\n")

# Prepare race-specific panels
black_panel <- race_panel |>
  filter(race == "A2") |>
  mutate(
    time_id = as.integer(yq_to_int[as.character(yq)]),
    first_treat_id = if_else(first_treat_yq > 0,
      as.integer(yq_to_int[as.character(first_treat_yq)]), 0L)
  ) |>
  filter(!is.na(time_id), !is.na(first_treat_id), !is.na(ln_earn))

white_panel <- race_panel |>
  filter(race == "A1") |>
  mutate(
    time_id = as.integer(yq_to_int[as.character(yq)]),
    first_treat_id = if_else(first_treat_yq > 0,
      as.integer(yq_to_int[as.character(first_treat_yq)]), 0L)
  ) |>
  filter(!is.na(time_id), !is.na(first_treat_id), !is.na(ln_earn))

cs_black_earn <- att_gt(
  yname = "ln_earn", tname = "time_id", idname = "state_fips",
  gname = "first_treat_id", data = black_panel,
  control_group = "nevertreated", base_period = "universal"
)
cs_black_earn_agg <- aggte(cs_black_earn, type = "simple")
cat("CS ATT: ln(Black earnings)\n")
print(summary(cs_black_earn_agg))

cs_white_earn <- att_gt(
  yname = "ln_earn", tname = "time_id", idname = "state_fips",
  gname = "first_treat_id", data = white_panel,
  control_group = "nevertreated", base_period = "universal"
)
cs_white_earn_agg <- aggte(cs_white_earn, type = "simple")
cat("CS ATT: ln(White earnings)\n")
print(summary(cs_white_earn_agg))

# Employment by race
cs_black_emp <- att_gt(
  yname = "ln_emp", tname = "time_id", idname = "state_fips",
  gname = "first_treat_id", data = black_panel,
  control_group = "nevertreated", base_period = "universal"
)
cs_black_emp_agg <- aggte(cs_black_emp, type = "simple")
cat("CS ATT: ln(Black employment)\n")
print(summary(cs_black_emp_agg))

cs_white_emp <- att_gt(
  yname = "ln_emp", tname = "time_id", idname = "state_fips",
  gname = "first_treat_id", data = white_panel,
  control_group = "nevertreated", base_period = "universal"
)
cs_white_emp_agg <- aggte(cs_white_emp, type = "simple")
cat("CS ATT: ln(White employment)\n")
print(summary(cs_white_emp_agg))
# ── 6. Save results for tables ──
results <- list(
  national_trend = national_trend,
  twfe_ratio = twfe_ratio,
  twfe_lnearn = twfe_lnearn,
  twfe_share = twfe_share,
  cs_ratio = cs_ratio,
  cs_ratio_agg = cs_ratio_agg,
  cs_ratio_es = cs_ratio_es,
  cs_share = cs_share,
  cs_share_agg = cs_share_agg,
  cs_share_es = cs_share_es,
  cs_lnearn = cs_lnearn,
  cs_lnearn_agg = cs_lnearn_agg,
  cs_black_earn_agg = cs_black_earn_agg,
  cs_white_earn_agg = cs_white_earn_agg,
  cs_black_emp_agg = cs_black_emp_agg,
  cs_white_emp_agg = cs_white_emp_agg,
  bw_cs = bw_cs,
  bw = bw,
  race_panel = race_panel,
  yq_to_int = yq_to_int
)
saveRDS(results, "../data/main_results.rds")

# ── 7. Write diagnostics.json ──
diag <- list(
  n_treated = sum(bw$expanded & bw$yq == min(bw$yq)),
  n_pre = length(unique(bw$yq[bw$yq < 2014])),
  n_obs = nrow(bw),
  n_states = n_distinct(bw$state_fips),
  n_quarters = n_distinct(bw$yq),
  year_range = paste(min(bw$year), max(bw$year), sep = "-"),
  expansion_states = n_distinct(bw$state_fips[bw$expanded]),
  never_treated = n_distinct(bw$state_fips[!bw$expanded])
)
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)
cat("\nDiagnostics saved.\n")

cat("03_main_analysis.R complete.\n")
