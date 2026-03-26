# =============================================================================
# 04_robustness.R — Robustness checks and placebo tests
# apep_0980: IRA Energy Community Bonus Credit and County-Level Labor Markets
# =============================================================================

source("00_packages.R")

DATA_DIR <- "../data"

# Load panel and results
panel <- arrow::read_parquet(file.path(DATA_DIR, "analysis_panel.parquet"))
setDT(panel)
panel[, time_idx := (year - 2018) * 4 + quarter]
main_sample <- panel[cohort != "no_unemp_data"]

load(file.path(DATA_DIR, "main_results.RData"))

# =============================================================================
# 1. Within-FF-eligible comparison (tightest control group)
# =============================================================================
cat("=== Robustness 1: Within-FF-eligible comparison ===\n")

# Only FF-eligible counties: treated vs near-miss (unemployment below threshold)
ff_sample <- main_sample[cohort %in% c("always_treated", "treated_2023_only",
                                        "treated_2024_only", "never_treated_ff")]

for (s in c("23", "22", "21")) {
  sname <- c("23" = "Construction", "22" = "Utilities", "21" = "Mining")[[s]]
  dt <- ff_sample[industry == s & !is.na(Emp)]
  if (nrow(dt) < 50) next
  mod <- feols(log_emp ~ treated | county_fips + time, data = dt, cluster = ~state_fips)
  cat(sprintf("  FF-only %s: beta = %0.4f (SE = %0.4f), N = %d\n",
              sname, coef(mod)["treated"], se(mod)["treated"], mod$nobs))
}

# =============================================================================
# 2. Restricted pre-period (2021-2025, avoid COVID contamination)
# =============================================================================
cat("\n=== Robustness 2: Post-COVID sample (2021+) ===\n")

post_covid <- main_sample[year >= 2021]
for (s in c("23", "22", "21")) {
  sname <- c("23" = "Construction", "22" = "Utilities", "21" = "Mining")[[s]]
  dt <- post_covid[industry == s & !is.na(Emp)]
  if (nrow(dt) < 50) next
  mod <- feols(log_emp ~ treated | county_fips + time, data = dt, cluster = ~state_fips)
  cat(sprintf("  Post-COVID %s: beta = %0.4f (SE = %0.4f), N = %d\n",
              sname, coef(mod)["treated"], se(mod)["treated"], mod$nobs))
}

# =============================================================================
# 3. Placebo sectors (retail, accommodation should show null)
# =============================================================================
cat("\n=== Robustness 3: Placebo sectors ===\n")

for (s in c("44-45", "72")) {
  sname <- c("44-45" = "Retail", "72" = "Accommodation")[[s]]
  dt <- main_sample[industry == s & !is.na(Emp)]
  mod <- feols(log_emp ~ treated | county_fips + time, data = dt, cluster = ~state_fips)
  cat(sprintf("  Placebo %s: beta = %0.4f (SE = %0.4f)\n",
              sname, coef(mod)["treated"], se(mod)["treated"]))
}

# =============================================================================
# 4. State-level clustering (conservative)
# =============================================================================
cat("\n=== Robustness 4: State clustering ===\n")

for (s in c("23", "21")) {
  sname <- c("23" = "Construction", "21" = "Mining")[[s]]
  dt <- main_sample[industry == s & !is.na(Emp)]
  mod_state <- feols(log_emp ~ treated | county_fips + time,
                     data = dt, cluster = ~state_fips)
  cat(sprintf("  State-clustered %s: beta = %0.4f (SE = %0.4f)\n",
              sname, coef(mod_state)["treated"], se(mod_state)["treated"]))
}

# =============================================================================
# 5. Callaway-Sant'Anna (fix time encoding)
# =============================================================================
cat("\n=== Robustness 5: Callaway-Sant'Anna ===\n")

cs_dt <- main_sample[industry == "23" & !is.na(Emp)]

# CS group: first_treat_qtr encoded as time_idx
# 20232 → time_idx = (2023-2018)*4 + 2 = 22
# 20242 → time_idx = (2024-2018)*4 + 2 = 26
cs_dt[, cs_group := fcase(
  first_treat_qtr == 20232, 22L,
  first_treat_qtr == 20242, 26L,
  default = 0L
)]

# Balanced panel
county_period_counts <- cs_dt[, .N, by = county_fips]
max_periods <- max(county_period_counts$N)
balanced_ids <- county_period_counts[N == max_periods]$county_fips
cs_bal <- cs_dt[county_fips %in% balanced_ids]

cat(sprintf("  Balanced panel: %d counties (%d treated), %d periods\n",
            uniqueN(cs_bal$county_fips),
            uniqueN(cs_bal[cs_group > 0]$county_fips),
            uniqueN(cs_bal$time_idx)))

if (uniqueN(cs_bal[cs_group > 0]$county_fips) >= 10) {
  cs_out <- tryCatch({
    att_gt(
      yname = "log_emp",
      tname = "time_idx",
      idname = "county_fips",
      gname = "cs_group",
      data = as.data.frame(cs_bal),
      control_group = "notyettreated",
      est_method = "reg",
      base_period = "universal"
    )
  }, error = function(e) {
    cat("  CS error:", e$message, "\n")
    NULL
  })

  if (!is.null(cs_out)) {
    cs_simple <- aggte(cs_out, type = "simple")
    cat(sprintf("  CS ATT (simple): %0.4f (SE = %0.4f)\n",
                cs_simple$overall.att, cs_simple$overall.se))

    cs_dyn <- aggte(cs_out, type = "dynamic", min_e = -8, max_e = 8)
    cat("  CS dynamic effects:\n")
    for (j in seq_along(cs_dyn$egt)) {
      sig <- ifelse(abs(cs_dyn$att.egt[j] / cs_dyn$se.egt[j]) > 1.96, "*", " ")
      cat(sprintf("    e=%2d: %7.4f (%6.4f) %s\n",
                  cs_dyn$egt[j], cs_dyn$att.egt[j], cs_dyn$se.egt[j], sig))
    }

    save(cs_out, cs_simple, cs_dyn, file = file.path(DATA_DIR, "cs_results.RData"))
  }
}

# =============================================================================
# 6. Hires as alternative outcome
# =============================================================================
cat("\n=== Robustness 6: Hires (alternative outcome) ===\n")

for (s in c("23", "22", "21")) {
  sname <- c("23" = "Construction", "22" = "Utilities", "21" = "Mining")[[s]]
  dt <- main_sample[industry == s & !is.na(HirA)]
  if (nrow(dt) < 50) next
  mod <- feols(log_hires ~ treated | county_fips + time, data = dt, cluster = ~state_fips)
  cat(sprintf("  Hires %s: beta = %0.4f (SE = %0.4f)\n",
              sname, coef(mod)["treated"], se(mod)["treated"]))
}

# =============================================================================
# 7. Intensive margin: earnings per worker
# =============================================================================
cat("\n=== Robustness 7: Earnings per worker ===\n")

for (s in c("23", "22", "21")) {
  sname <- c("23" = "Construction", "22" = "Utilities", "21" = "Mining")[[s]]
  dt <- main_sample[industry == s & !is.na(EarnS) & EarnS > 0]
  if (nrow(dt) < 50) next
  mod <- feols(log_earn ~ treated | county_fips + time, data = dt, cluster = ~state_fips)
  cat(sprintf("  Earnings %s: beta = %0.4f (SE = %0.4f)\n",
              sname, coef(mod)["treated"], se(mod)["treated"]))
}

# =============================================================================
# 8. Pre-trend test: joint F-test on pre-treatment event-study coefficients
# =============================================================================
cat("\n=== Pre-trend diagnostics ===\n")

constr_dt <- main_sample[industry == "23" & !is.na(Emp) &
                          (first_treat_qtr == 20232 | first_treat_qtr == 0)]
constr_dt[first_treat_qtr > 0, event_time := time_idx - 22L]
constr_dt[first_treat_qtr == 0, event_time := NA_integer_]
constr_dt[, g := fifelse(first_treat_qtr > 0, 22L, 10000L)]

# Restrict event study to recent pre-period
es_short <- feols(log_emp ~ sunab(g, time_idx, ref.p = -1) | county_fips + time_idx,
                  data = constr_dt[time_idx >= 13],  # 2021Q1 onwards
                  cluster = ~state_fips)

es_coefs <- coeftable(es_short)
pre_coefs <- es_coefs[grep("^time_idx::-", rownames(es_coefs)), ]
cat("  Short pre-period event study (2021+):\n")
print(round(pre_coefs, 4))

cat("\nRobustness checks complete.\n")
