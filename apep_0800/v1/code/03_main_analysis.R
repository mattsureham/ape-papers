# =============================================================================
# 03_main_analysis.R — Main DDD estimation
# APEP Working Paper apep_0800
# =============================================================================

source("00_packages.R")

df <- arrow::read_parquet("../data/analysis_panel.parquet")
ban_states <- readRDS("../data/ban_states.rds")

cat("Loaded analysis panel:", format(nrow(df), big.mark = ","), "rows\n")

# ---------------------------------------------------------------------------
# Finance only (NAICS 52) for main results
# ---------------------------------------------------------------------------
df_fin <- df %>% filter(industry == "52")
cat("Finance panel:", format(nrow(df_fin), big.mark = ","), "rows\n")
cat("  Ban state obs:", sum(df_fin$ban_state), "\n")
cat("  Black obs:", sum(df_fin$black), "\n")

# Pre-construct interaction terms as numeric (avoid fixest logical issues)
df_fin <- df_fin %>%
  mutate(
    ban = as.integer(ban_state),
    ddd = black * ban * post,
    bd = black * post,
    bp = ban * post
  )

# ---------------------------------------------------------------------------
# 1. TWFE Triple-Difference: Black × Ban × Post
# ---------------------------------------------------------------------------
cat("\n=== TWFE Triple-Difference ===\n")

# With county×race FE, black and ban are absorbed. Use pre-computed interactions.
m1_hirn <- feols(
  asinh_hirn ~ ddd + bd + bp |
    county_fips^race + cal_quarter,
  data = df_fin,
  cluster = ~state_fips
)
cat("\n--- New Hires (asinh) ---\n")
summary(m1_hirn)

m1_emp <- feols(
  asinh_emp ~ ddd + bd + bp |
    county_fips^race + cal_quarter,
  data = df_fin,
  cluster = ~state_fips
)
cat("\n--- Employment (asinh) ---\n")
summary(m1_emp)

m1_earn <- feols(
  log_earn_hir ~ ddd + bd + bp |
    county_fips^race + cal_quarter,
  data = df_fin,
  cluster = ~state_fips
)
cat("\n--- New Hire Earnings (log) ---\n")
summary(m1_earn)

# ---------------------------------------------------------------------------
# 2. Callaway-Sant'Anna on Black-White hiring gap (annual)
# Use annual data to avoid sparsity issues with quarterly small cells
# ---------------------------------------------------------------------------
cat("\n=== Callaway-Sant'Anna on Black-White Gap (Annual) ===\n")

# Create Black-White gap at county-year level
df_gap <- df_fin %>%
  filter(!is.na(HirN)) %>%
  group_by(county_fips, state_fips, year, race, ban_state, first_treat_yr) %>%
  summarise(
    HirN = sum(HirN, na.rm = TRUE),
    EarnHirNS = {
      idx <- !is.na(EarnHirNS) & !is.na(HirN)
      if (sum(idx) > 0) weighted.mean(EarnHirNS[idx], w = pmax(HirN[idx], 1)) else NA_real_
    },
    Emp = mean(Emp, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  pivot_wider(
    id_cols = c(county_fips, state_fips, year, ban_state, first_treat_yr),
    names_from = race,
    values_from = c(HirN, EarnHirNS, Emp),
    values_fn = list(HirN = sum, EarnHirNS = mean, Emp = mean)
  ) %>%
  filter(!is.na(HirN_A2) & !is.na(HirN_A1)) %>%
  mutate(
    gap_hirn = asinh(HirN_A2) - asinh(HirN_A1),
    gap_emp = asinh(Emp_A2) - asinh(Emp_A1),
    gap_earn = log(pmax(EarnHirNS_A2, 1)) - log(pmax(EarnHirNS_A1, 1)),
    county_id = as.integer(factor(county_fips)),
    # For CS: first_treat_yr (0 = never treated)
    g = as.integer(first_treat_yr)
  )

cat("Gap panel:", nrow(df_gap), "county-years\n")
cat("  Treated counties:", n_distinct(df_gap$county_fips[df_gap$g > 0]), "\n")
cat("  Never-treated counties:", n_distinct(df_gap$county_fips[df_gap$g == 0]), "\n")
cat("  Treatment groups:", paste(sort(unique(df_gap$g[df_gap$g > 0])), collapse = ", "), "\n")

# Balance the panel by keeping only counties observed in all years
county_year_counts <- df_gap %>%
  group_by(county_id) %>%
  summarise(n_years = n_distinct(year), .groups = "drop")

balanced_ids <- county_year_counts %>%
  filter(n_years == max(n_years)) %>%
  pull(county_id)

df_gap_bal <- df_gap %>% filter(county_id %in% balanced_ids)
cat("Balanced panel:", nrow(df_gap_bal), "obs,", n_distinct(df_gap_bal$county_id), "counties\n")

# CS estimation on hiring gap
cs_hirn <- att_gt(
  yname = "gap_hirn",
  tname = "year",
  idname = "county_id",
  gname = "g",
  data = df_gap_bal,
  control_group = "nevertreated",
  base_period = "universal",
  clustervars = "state_fips"
)

# Aggregate: simple ATT
cs_agg_hirn <- aggte(cs_hirn, type = "simple")
cat("\n--- CS Simple ATT: Black-White Hiring Gap ---\n")
summary(cs_agg_hirn)

# Event study
cs_es_hirn <- aggte(cs_hirn, type = "dynamic", min_e = -5, max_e = 8)
cat("\n--- CS Event Study: Black-White Hiring Gap ---\n")
summary(cs_es_hirn)

# Save event study for plotting
es_df <- data.frame(
  event_time = cs_es_hirn$egt,
  att = cs_es_hirn$att.egt,
  se = cs_es_hirn$se.egt
) %>%
  mutate(
    ci_lo = att - 1.96 * se,
    ci_hi = att + 1.96 * se
  )
saveRDS(es_df, "../data/cs_event_study.rds")

# CS on employment gap
cs_emp <- att_gt(
  yname = "gap_emp",
  tname = "year",
  idname = "county_id",
  gname = "g",
  data = df_gap_bal,
  control_group = "nevertreated",
  base_period = "universal",
  clustervars = "state_fips"
)
cs_agg_emp <- aggte(cs_emp, type = "simple")
cat("\n--- CS Simple ATT: Black-White Employment Gap ---\n")
summary(cs_agg_emp)

# CS on earnings gap (use panel = FALSE due to missing earnings data)
df_gap_earn <- df_gap_bal %>%
  filter(!is.na(gap_earn) & is.finite(gap_earn))

cs_earn <- tryCatch({
  att_gt(
    yname = "gap_earn",
    tname = "year",
    idname = "county_id",
    gname = "g",
    data = df_gap_earn,
    control_group = "nevertreated",
    base_period = "universal",
    clustervars = "state_fips",
    panel = FALSE
  )
}, error = function(e) {
  cat("CS earnings estimation failed:", e$message, "\n")
  NULL
})

if (!is.null(cs_earn)) {
  cs_agg_earn <- aggte(cs_earn, type = "simple")
  cat("\n--- CS Simple ATT: Black-White Earnings Gap ---\n")
  summary(cs_agg_earn)
} else {
  cs_agg_earn <- NULL
  cat("\nCS earnings gap: estimation failed, using TWFE only.\n")
}

# ---------------------------------------------------------------------------
# 3. Save all results
# ---------------------------------------------------------------------------
results <- list(
  twfe_hirn = m1_hirn,
  twfe_emp = m1_emp,
  twfe_earn = m1_earn,
  cs_hirn = cs_hirn,
  cs_emp = cs_emp,
  cs_earn = cs_earn,
  cs_agg_hirn = cs_agg_hirn,
  cs_agg_emp = cs_agg_emp,
  cs_agg_earn = cs_agg_earn,
  cs_es_hirn = cs_es_hirn,
  gap_panel = df_gap_bal
)
saveRDS(results, "../data/main_results.rds")

# ---------------------------------------------------------------------------
# 4. Write diagnostics.json
# ---------------------------------------------------------------------------
diag <- list(
  n_treated = n_distinct(df_fin$county_fips[df_fin$ban_state]),
  n_pre = length(unique(df_fin$year[df_fin$year < 2007])),
  n_obs = nrow(df_fin),
  n_states_treated = n_distinct(df_fin$state_fips[df_fin$ban_state]),
  n_states_control = n_distinct(df_fin$state_fips[!df_fin$ban_state]),
  year_range = paste(range(df_fin$year), collapse = "-"),
  industries = "52,11"
)
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)
cat("\nDiagnostics written to data/diagnostics.json\n")

cat("\n=== Main analysis complete ===\n")
