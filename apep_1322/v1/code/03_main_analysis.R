## 03_main_analysis.R — Main DiD estimation
## State zoning preemption → missing middle housing construction

source("00_packages.R")

panel <- readRDS("../data/analysis_panel.rds")
cat("=== Main Analysis ===\n")
cat(sprintf("Panel: %d county-years, %d counties, %d years\n",
            nrow(panel), n_distinct(panel$fips), n_distinct(panel$year)))

# ============================================================
# TABLE 1: Summary Statistics
# ============================================================
cat("\n=== Summary Statistics ===\n")

sumstats <- panel %>%
  filter(year >= 2015) %>%
  group_by(treated) %>%
  summarise(
    N = n(),
    counties = n_distinct(fips),
    mean_total = mean(total_units, na.rm = TRUE),
    sd_total = sd(total_units, na.rm = TRUE),
    mean_mm = mean(mm_units, na.rm = TRUE),
    sd_mm = sd(mm_units, na.rm = TRUE),
    mean_mm_share = mean(mm_share, na.rm = TRUE) * 100,
    sd_mm_share = sd(mm_share, na.rm = TRUE) * 100,
    mean_1unit = mean(units1_units, na.rm = TRUE),
    mean_5plus = mean(units5p_units, na.rm = TRUE),
    pct_any_mm = mean(has_mm, na.rm = TRUE) * 100,
    .groups = "drop"
  )

print(as.data.frame(sumstats))

# ============================================================
# TABLE 2: TWFE DiD (main specification)
# ============================================================
cat("\n=== TWFE DiD Estimation ===\n")

# Restrict to 2015-2024 for balanced pre/post
est_df <- panel %>% filter(year >= 2015)

# (1) Missing middle share (pp)
m1 <- feols(mm_share ~ post | fips + year, data = est_df,
            cluster = ~state_fips)

# (2) Log missing middle units
m2 <- feols(log_mm ~ post | fips + year, data = est_df,
            cluster = ~state_fips)

# (3) Log total permits (expansion vs substitution)
m3 <- feols(log_total ~ post | fips + year, data = est_df,
            cluster = ~state_fips)

# (4) Log 5+ unit permits (PLACEBO — should be null)
m4 <- feols(log_5plus ~ post | fips + year, data = est_df,
            cluster = ~state_fips)

# (5) Has any missing middle (extensive margin)
m5 <- feols(has_mm ~ post | fips + year, data = est_df,
            cluster = ~state_fips)

# (6) Log single-family permits
m6 <- feols(log_1unit ~ post | fips + year, data = est_df,
            cluster = ~state_fips)

cat("\n--- Main results ---\n")
etable(m1, m2, m3, m4, m5, m6,
       headers = c("MM Share", "Log MM", "Log Total",
                    "Log 5+ (Placebo)", "Has MM", "Log 1-Unit"),
       se.below = TRUE)

# ============================================================
# TABLE 3: Event Study (leads and lags)
# ============================================================
cat("\n=== Event Study ===\n")

# Create relative time variable
est_df <- est_df %>%
  mutate(
    rel_time = ifelse(treat_year > 0, year - treat_year, NA),
    # Bin extreme values
    rel_time_bin = case_when(
      is.na(rel_time) ~ NA_real_,
      rel_time <= -5 ~ -5,
      rel_time >= 3 ~ 3,
      TRUE ~ rel_time
    )
  )

# Event study using fixest's i() syntax
# Reference period: rel_time = -1
es1 <- feols(mm_share ~ i(rel_time_bin, treated, ref = -1) | fips + year,
             data = est_df, cluster = ~state_fips)

cat("\n--- Event study coefficients (MM Share) ---\n")
coeftable(es1)

# Event study for log MM units
es2 <- feols(log_mm ~ i(rel_time_bin, treated, ref = -1) | fips + year,
             data = est_df, cluster = ~state_fips)

# Event study for placebo (log 5+)
es3 <- feols(log_5plus ~ i(rel_time_bin, treated, ref = -1) | fips + year,
             data = est_df, cluster = ~state_fips)

cat("\n--- Event study: log 5+ units (Placebo) ---\n")
coeftable(es3)

# ============================================================
# Callaway-Sant'Anna
# ============================================================
cat("\n=== Callaway-Sant'Anna ===\n")

# Prepare data for did package
cs_df <- panel %>%
  filter(year >= 2015) %>%
  mutate(
    county_id = as.integer(factor(fips)),
    g = treat_year  # 0 = never treated
  )

# CS estimation
cs_out <- tryCatch({
  att_gt(
    yname = "mm_share",
    tname = "year",
    idname = "county_id",
    gname = "g",
    data = cs_df,
    control_group = "nevertreated",
    base_period = "universal"
  )
}, error = function(e) {
  cat("CS estimation error:", e$message, "\n")
  NULL
})

if (!is.null(cs_out)) {
  cat("\nGroup-time ATT estimates:\n")
  print(summary(cs_out))

  # Aggregate to simple ATT
  cs_simple <- aggte(cs_out, type = "simple")
  cat(sprintf("\nCS Simple ATT: %.5f (SE: %.5f)\n",
              cs_simple$overall.att, cs_simple$overall.se))

  # Dynamic aggregation
  cs_dyn <- aggte(cs_out, type = "dynamic")
  cat("\nDynamic effects:\n")
  print(summary(cs_dyn))
}

# ============================================================
# Diagnostics
# ============================================================
cat("\n=== Writing diagnostics ===\n")

diagnostics <- list(
  n_treated = n_distinct(est_df$fips[est_df$treated == 1]),
  n_control = n_distinct(est_df$fips[est_df$treated == 0]),
  n_pre = length(unique(est_df$year[est_df$year < 2022])),
  n_obs = nrow(est_df),
  n_treated_states = 4,
  treat_years = c(2022, 2022, 2022, 2023),
  sd_mm_share = sd(est_df$mm_share[est_df$year < 2022], na.rm = TRUE)
)

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat("Diagnostics written to data/diagnostics.json\n")

# Save regression objects
saveRDS(list(m1=m1, m2=m2, m3=m3, m4=m4, m5=m5, m6=m6,
             es1=es1, es2=es2, es3=es3,
             cs_out=cs_out), "../data/regression_results.rds")

cat("\nMain analysis complete.\n")
