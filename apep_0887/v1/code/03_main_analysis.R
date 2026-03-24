# 03_main_analysis.R — Main econometric analysis for apep_0887
source("00_packages.R")

cat("=== Main Analysis for apep_0887 ===\n")

panel <- fread("../data/analysis_panel_balanced.csv")
panel[, `:=`(
  fips = as.character(fips),
  state_fips = sprintf("%02d", as.integer(state_fips)),
  county_fips = as.character(county_fips)
)]

rrnc <- fread("../data/rrnc_adoption_dates.csv")

# ============================================================
# 1. Summary Statistics
# ============================================================
cat("\n--- Summary Statistics ---\n")

pre_treated <- panel[treated == 1 & post == 0]
pre_never <- panel[treated == 0]

sumstats <- data.table(
  variable = c("estab_562", "emp_562", "estab_rem", "emp_rem",
               "payroll_rem", "rem_share"),
  label = c("Establishments (NAICS 562)", "Employment (NAICS 562)",
            "Remediation establishments", "Remediation employment",
            "Remediation payroll ($1000)", "Remediation share of employment"),
  treated_mean = sapply(c("estab_562", "emp_562", "estab_rem", "emp_rem",
                           "payroll_rem", "rem_share"),
                         function(v) mean(pre_treated[[v]], na.rm = TRUE)),
  treated_sd = sapply(c("estab_562", "emp_562", "estab_rem", "emp_rem",
                          "payroll_rem", "rem_share"),
                       function(v) sd(pre_treated[[v]], na.rm = TRUE)),
  never_mean = sapply(c("estab_562", "emp_562", "estab_rem", "emp_rem",
                          "payroll_rem", "rem_share"),
                       function(v) mean(pre_never[[v]], na.rm = TRUE)),
  never_sd = sapply(c("estab_562", "emp_562", "estab_rem", "emp_rem",
                        "payroll_rem", "rem_share"),
                     function(v) sd(pre_never[[v]], na.rm = TRUE)),
  n_treated = sapply(c("estab_562", "emp_562", "estab_rem", "emp_rem",
                         "payroll_rem", "rem_share"),
                      function(v) sum(!is.na(pre_treated[[v]])))
)

cat("Pre-treatment summary (treated vs never-treated):\n")
print(sumstats[, .(variable, treated_mean = round(treated_mean, 2),
                    never_mean = round(never_mean, 2))])

fwrite(sumstats, "../data/summary_stats.csv")

# ============================================================
# 2. TWFE Baseline
# ============================================================
cat("\n--- TWFE Baseline ---\n")

# Primary outcome: log remediation employment (NAICS 562910)
m1 <- feols(log_emp_rem ~ post | fips + year,
             data = panel, cluster = ~state_fips)
cat("TWFE — Log Remediation Employment:\n")
summary(m1)

# Secondary: log remediation establishments
m2 <- feols(log_estab_rem ~ post | fips + year,
             data = panel, cluster = ~state_fips)
cat("TWFE — Log Remediation Establishments:\n")
summary(m2)

# Broader sector: log total NAICS 562 employment
m3 <- feols(log_emp_562 ~ post | fips + year,
             data = panel, cluster = ~state_fips)
cat("TWFE — Log Total Waste Mgmt Employment:\n")
summary(m3)

# Remediation payroll
m4 <- feols(log_payroll_rem ~ post | fips + year,
             data = panel, cluster = ~state_fips)
cat("TWFE — Log Remediation Payroll:\n")
summary(m4)

# ============================================================
# 3. Callaway & Sant'Anna (2021)
# ============================================================
cat("\n--- Callaway & Sant'Anna ---\n")

cs_data <- panel[!is.na(log_emp_rem)]
cs_data[, county_id := as.integer(factor(fips))]

# CS-DiD with never-treated control
cs_result <- tryCatch({
  att_gt(
    yname = "log_emp_rem",
    tname = "year",
    idname = "county_id",
    gname = "cohort",
    data = as.data.frame(cs_data),
    control_group = "nevertreated",
    est_method = "reg",
    clustervars = "state_fips",
    base_period = "universal"
  )
}, error = function(e) {
  cat("CS-DiD error:", e$message, "\n")
  NULL
})

cs_agg <- NULL
cs_event <- NULL

if (!is.null(cs_result)) {
  # Simple ATT
  cs_agg <- aggte(cs_result, type = "simple")
  cat("\nCS-DiD Simple ATT:\n")
  summary(cs_agg)

  # Event study
  cs_event <- aggte(cs_result, type = "dynamic", min_e = -5, max_e = 7)
  cat("\nCS-DiD Event Study:\n")
  summary(cs_event)

  # Save event study data
  es_data <- data.table(
    rel_time = cs_event$egt,
    att = cs_event$att.egt,
    se = cs_event$se.egt
  )
  es_data[, `:=`(ci_lo = att - 1.96 * se, ci_hi = att + 1.96 * se)]
  fwrite(es_data, "../data/cs_event_study.csv")
}

# ============================================================
# 4. Sun & Abraham (2021)
# ============================================================
cat("\n--- Sun & Abraham ---\n")

sa_data <- copy(panel)
sa_data[, cohort_sa := ifelse(cohort == 0, 10000L, cohort)]

m_sa <- feols(log_emp_rem ~ sunab(cohort_sa, year) | fips + year,
               data = sa_data, cluster = ~state_fips)
cat("Sun-Abraham:\n")
summary(m_sa)

# Extract SA event-study coefficients
sa_coefs <- as.data.table(coeftable(m_sa), keep.rownames = TRUE)
setnames(sa_coefs, c("term", "estimate", "se", "t", "p"))
fwrite(sa_coefs, "../data/sa_event_study_coefs.csv")

# ============================================================
# 5. Heterogeneity by Radon Zone (Interaction Approach)
# ============================================================
cat("\n--- Heterogeneity by Radon Zone ---\n")

# Zone interaction: test whether effect varies with radon risk
# Zone 1 (high radon) should show stronger effect if mechanism is information
# Zone 3 (low radon) should show null (placebo)
# Reference: Zone 2 (moderate)
panel[, zone_factor := factor(epa_zone, levels = c(2, 1, 3))]

m_het <- feols(log_emp_rem ~ post + post:zone1 + post:zone3 | fips + year,
                data = panel, cluster = ~state_fips)
cat("Zone Interaction (ref = Zone 2):\n")
summary(m_het)

# Split by zone where sufficient variation exists
# Zone 1 (high risk): multiple treated states
m_zone1 <- feols(log_emp_rem ~ post | fips + year,
                  data = panel[zone1 == 1],
                  cluster = ~state_fips)
cat("Zone 1 (high radon risk):\n")
summary(m_zone1)

# Zone 2 (moderate)
m_zone2 <- tryCatch({
  feols(log_emp_rem ~ post | fips + year,
        data = panel[zone2 == 1],
        cluster = ~state_fips)
}, error = function(e) {
  cat("Zone 2 regression failed:", e$message, "\n")
  NULL
})
if (!is.null(m_zone2)) {
  cat("Zone 2 (moderate radon risk):\n")
  summary(m_zone2)
}

# Zone 3: only Louisiana adopted — insufficient variation for separate regression
# Use the interaction model for the placebo test instead
m_zone3 <- NULL
cat("Zone 3: Only one adopter (LA). Placebo from interaction model above.\n")

# ============================================================
# 7. Save Results and Diagnostics
# ============================================================
cat("\n--- Saving results ---\n")

# Pre-treatment SD for SDE calculation
sd_y_pre <- sd(panel$log_emp_rem[panel$post == 0 | panel$treated == 0],
               na.rm = TRUE)
sd_y_pre_z1 <- sd(panel$log_emp_rem[panel$zone1 == 1 &
                                      (panel$post == 0 | panel$treated == 0)],
                   na.rm = TRUE)
sd_y_pre_z3 <- sd(panel$log_emp_rem[(panel$post == 0 | panel$treated == 0)],
                   na.rm = TRUE)  # Using full pre-treatment SD for Zone 3 SDE

# Diagnostics for validator
n_treated_counties <- uniqueN(panel$fips[panel$treated == 1])
n_pre <- length(unique(panel$year[panel$year < min(rrnc$adoption_year)]))

diagnostics <- list(
  n_treated = n_treated_counties,
  n_pre = n_pre,
  n_obs = nrow(panel),
  n_counties = uniqueN(panel$fips),
  n_treated_states = uniqueN(panel$state_fips[panel$treated == 1]),
  year_range = paste(range(panel$year), collapse = "-"),
  sd_y_pre = sd_y_pre,
  sd_y_pre_z1 = sd_y_pre_z1,
  sd_y_pre_z3 = sd_y_pre_z3,
  twfe_coef = as.numeric(coef(m1)["post"]),
  twfe_se = as.numeric(se(m1)["post"]),
  cs_att = if (!is.null(cs_agg)) cs_agg$overall.att else NA,
  cs_se = if (!is.null(cs_agg)) cs_agg$overall.se else NA,
  zone1_coef = as.numeric(coef(m_zone1)["post"]),
  zone1_se = as.numeric(se(m_zone1)["post"]),
  het_zone1_coef = as.numeric(coef(m_het)["post:zone1"]),
  het_zone3_coef = as.numeric(coef(m_het)["post:zone3"])
)

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

# Save all model objects
results <- list(
  twfe_emp_rem = m1,
  twfe_estab_rem = m2,
  twfe_emp_562 = m3,
  twfe_payroll = m4,
  zone1 = m_zone1,
  zone2 = m_zone2,
  het_zone = m_het,
  sa = m_sa,
  cs_agg = cs_agg,
  cs_event = cs_event,
  sd_y_pre = sd_y_pre,
  sd_y_pre_z1 = sd_y_pre_z1,
  sd_y_pre_z3 = sd_y_pre_z3,
  sumstats = sumstats
)

saveRDS(results, "../data/main_results.rds")

cat("\nKey results:\n")
cat(sprintf("  TWFE (emp_rem):  β=%.4f (%.4f), p=%.4f\n",
            coef(m1)["post"], se(m1)["post"], pvalue(m1)["post"]))
if (!is.null(cs_agg)) {
  cat(sprintf("  CS ATT:          β=%.4f (%.4f)\n",
              cs_agg$overall.att, cs_agg$overall.se))
}
cat(sprintf("  Zone 1 (high):   β=%.4f (%.4f)\n",
            coef(m_zone1)["post"], se(m_zone1)["post"]))
cat(sprintf("  Het zone1 int:   β=%.4f (%.4f)\n",
            coef(m_het)["post:zone1"], se(m_het)["post:zone1"]))
cat(sprintf("  Het zone3 int:   β=%.4f (%.4f)\n",
            coef(m_het)["post:zone3"], se(m_het)["post:zone3"]))

cat("\n=== Main analysis complete ===\n")
