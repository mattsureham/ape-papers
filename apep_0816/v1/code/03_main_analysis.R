# ==============================================================================
# 03_main_analysis.R — DDD estimation for H-1B cap dynamics
# ==============================================================================

source("00_packages.R")

panel <- fread("../data/analysis_panel.csv")
tech_share <- fread("../data/tech_share.csv")

# ==============================================================================
# REVIEWER FIX: Truncate post-period to 2007Q3 (before Great Recession)
# ==============================================================================
panel <- panel[yearqtr <= 2007.5]

cat(sprintf("Sample after truncating to 2007Q3: %s obs, years %d-%d\n",
            format(nrow(panel), big.mark = ","), min(panel$year), max(panel$year)))

# ==============================================================================
# Table 1: Summary Statistics
# ==============================================================================

cat("=== Computing Summary Statistics ===\n")

naics54 <- panel[industry == "54"]
pre <- naics54[yearqtr < 2003.75]

pre_stats <- pre[, .(
  emp = mean(Emp, na.rm = TRUE),
  hires = mean(HirA, na.rm = TRUE),
  seps = mean(Sep, na.rm = TRUE),
  earnings = mean(EarnS, na.rm = TRUE)
), by = .(young)]

cat("Pre-period means by age group (NAICS 54):\n")
print(pre_stats)

summ_list <- list(
  n_counties = uniqueN(panel$fips_county),
  n_quarters = uniqueN(panel$yearqtr),
  tech_share_mean = mean(tech_share$tech_share),
  tech_share_sd = sd(tech_share$tech_share)
)

# ==============================================================================
# Table 2: Main DDD — FY2004 Cap Reduction (pre-crisis sample)
# ==============================================================================

cat("\n=== Main DDD Regressions (2001Q1-2007Q3) ===\n")

# Pre-treatment SD for SDE computation
pre_sd_emp <- naics54[yearqtr < 2003.75, sd(log_emp, na.rm = TRUE)]
pre_sd_hires <- naics54[yearqtr < 2003.75, sd(log_hires, na.rm = TRUE)]
pre_sd_sep <- naics54[yearqtr < 2003.75, sd(log_sep, na.rm = TRUE)]
pre_sd_earn <- naics54[yearqtr < 2003.75, sd(log_earn, na.rm = TRUE)]

cat(sprintf("Pre-treatment SDs: emp=%.3f, hires=%.3f, sep=%.3f, earn=%.3f\n",
            pre_sd_emp, pre_sd_hires, pre_sd_sep, pre_sd_earn))

# Main DDD: continuous tech_share × young × post
m1_emp <- feols(log_emp ~ tech_share:young:post + tech_share:post + young:post |
                  county_ind_age + state_quarter + age_quarter,
                data = naics54, cluster = ~fips_state)

m1_hires <- feols(log_hires ~ tech_share:young:post + tech_share:post + young:post |
                    county_ind_age + state_quarter + age_quarter,
                  data = naics54, cluster = ~fips_state)

m1_sep <- feols(log_sep ~ tech_share:young:post + tech_share:post + young:post |
                  county_ind_age + state_quarter + age_quarter,
                data = naics54, cluster = ~fips_state)

m1_earn <- feols(log_earn ~ tech_share:young:post + tech_share:post + young:post |
                   county_ind_age + state_quarter + age_quarter,
                 data = naics54, cluster = ~fips_state)

cat("\n--- Employment (log) ---\n")
print(summary(m1_emp))
cat("\n--- Hires (log) ---\n")
print(summary(m1_hires))
cat("\n--- Separations (log) ---\n")
print(summary(m1_sep))
cat("\n--- Earnings (log) ---\n")
print(summary(m1_earn))

# ==============================================================================
# Table 3: Event-Study DDD — Quarterly Dynamics (Employment + Earnings)
# ==============================================================================

cat("\n=== Event-Study DDD ===\n")

naics54[, et_bin := pmax(-8, pmin(event_time, 15))]
naics54[, tech_young := tech_share * young]

# Employment event-study
es_emp <- feols(log_emp ~ i(et_bin, I(tech_share * young), ref = -1) +
                  i(et_bin, tech_share, ref = -1) |
                  county_ind_age + state_quarter + age_quarter,
                data = naics54, cluster = ~fips_state)

# Earnings event-study (REVIEWER REQUEST)
es_earn <- feols(log_earn ~ i(et_bin, I(tech_share * young), ref = -1) +
                   i(et_bin, tech_share, ref = -1) |
                   county_ind_age + state_quarter + age_quarter,
                 data = naics54, cluster = ~fips_state)

# Extract triple interaction coefs for employment
es_emp_coefs <- coeftable(es_emp)
emp_rows <- grep("tech_share.*young", rownames(es_emp_coefs))
es_emp_dt <- as.data.table(es_emp_coefs[emp_rows, ], keep.rownames = TRUE)
n_cols <- ncol(es_emp_dt)
if (n_cols == 5) {
  setnames(es_emp_dt, c("term", "estimate", "se", "tstat", "pval"))
} else if (n_cols == 4) {
  setnames(es_emp_dt, c("term", "estimate", "se", "tstat"))
  es_emp_dt[, pval := 2 * pt(-abs(tstat), df = 45)]
}
es_emp_dt[, outcome := "employment"]

# Extract triple interaction coefs for earnings
es_earn_coefs <- coeftable(es_earn)
earn_rows <- grep("tech_share.*young", rownames(es_earn_coefs))
es_earn_dt <- as.data.table(es_earn_coefs[earn_rows, ], keep.rownames = TRUE)
n_cols2 <- ncol(es_earn_dt)
if (n_cols2 == 5) {
  setnames(es_earn_dt, c("term", "estimate", "se", "tstat", "pval"))
} else if (n_cols2 == 4) {
  setnames(es_earn_dt, c("term", "estimate", "se", "tstat"))
  es_earn_dt[, pval := 2 * pt(-abs(tstat), df = 45)]
}
es_earn_dt[, outcome := "earnings"]

# Combine and save
es_all <- rbindlist(list(es_emp_dt, es_earn_dt))
fwrite(es_all, "../data/event_study_coefs.csv")

cat("Employment event-study (DDD):\n")
print(es_emp_dt[, .(term, estimate, se)])
cat("\nEarnings event-study (DDD):\n")
print(es_earn_dt[, .(term, estimate, se)])

# ==============================================================================
# Table 4: Industry Heterogeneity DDD
# ==============================================================================

cat("\n=== Industry Heterogeneity ===\n")

industries <- c("54", "42", "44-45", "56", "62", "72")
ind_names <- c("Professional/Technical", "Wholesale", "Retail",
               "Admin/Support", "Healthcare", "Accommodation")

ind_results <- list()
for (i in seq_along(industries)) {
  ind_data <- panel[industry == industries[i]]
  if (nrow(ind_data) < 1000) {
    cat(sprintf("Skipping %s: too few observations\n", industries[i]))
    next
  }
  m <- feols(log_emp ~ tech_share:young:post + tech_share:post + young:post |
               county_ind_age + state_quarter + age_quarter,
             data = ind_data, cluster = ~fips_state)
  ct <- coeftable(m)
  triple_row <- grep("tech_share:young:post", rownames(ct))
  if (length(triple_row) > 0) {
    ind_results[[i]] <- data.table(
      industry = industries[i],
      name = ind_names[i],
      beta = ct[triple_row, 1],
      se = ct[triple_row, 2],
      pval = ct[triple_row, 4],
      n_obs = nobs(m)
    )
    cat(sprintf("  %s: beta=%.4f (se=%.4f), n=%s\n",
                ind_names[i], ct[triple_row, 1], ct[triple_row, 2],
                format(nobs(m), big.mark = ",")))
  }
}
ind_dt <- rbindlist(ind_results)
fwrite(ind_dt, "../data/industry_heterogeneity.csv")

# ==============================================================================
# Save diagnostics for validation
# ==============================================================================

n_treated_counties <- uniqueN(naics54[high_tech == 1, fips_county])
n_pre_quarters <- uniqueN(naics54[yearqtr < 2003.75, yearqtr])

diag <- list(
  n_treated = n_treated_counties,
  n_pre = n_pre_quarters,
  n_obs = nrow(naics54),
  n_counties = uniqueN(naics54$fips_county),
  n_clusters = uniqueN(naics54$fips_state),
  pre_sd_emp = pre_sd_emp,
  pre_sd_hires = pre_sd_hires,
  pre_sd_sep = pre_sd_sep,
  pre_sd_earn = pre_sd_earn
)

write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)
cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%s\n",
            n_treated_counties, n_pre_quarters, format(nrow(naics54), big.mark = ",")))

# Save main models for tables
save(m1_emp, m1_hires, m1_sep, m1_earn, es_emp, es_earn,
     summ_list, pre_sd_emp, pre_sd_hires, pre_sd_sep, pre_sd_earn,
     file = "../data/main_models.RData")

cat("\nMain analysis complete.\n")
