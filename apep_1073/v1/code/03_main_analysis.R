# =============================================================================
# 03_main_analysis.R — BRAC: Sun-Abraham event study + industry reallocation
# =============================================================================
source("00_packages.R")

panel <- fread("../data/panel_annual.csv",
               colClasses = list(character = "county_fips"))
cat("Panel loaded:", nrow(panel), "rows\n")

# =============================================================================
# Data constraint: QWI starts 1993. Only 1995 and 2005 cohorts have pre-treatment.
# We use Sun-Abraham event study (fixest::sunab) as primary estimator since
# Callaway-Sant'Anna fails with very few treated units per cohort.
# =============================================================================

# Main sample: 1995 + 2005 cohorts + never-treated
panel_main <- panel[g %in% c(0, 1995, 2005)]
panel_main[, cohort_sa := fifelse(g == 0, 10000L, g)]
cat("Main sample: treated=", uniqueN(panel_main[g > 0]$county_fips),
    ", controls=", uniqueN(panel_main[g == 0]$county_fips), "\n")

# All cohorts for TWFE
panel[, post := as.integer(year >= g & g > 0)]

# =============================================================================
# STEP 1: Sun-Abraham event study — total employment
# =============================================================================
cat("\n=== Sun-Abraham: Log Employment ===\n")
sa_emp <- feols(ln_emp ~ sunab(cohort_sa, year) | county_id + year,
                data = panel_main[!is.na(ln_emp)], cluster = ~county_id)
saveRDS(sa_emp, "../data/sa_emp.rds")

# Extract event-study coefficients
sa_coefs <- data.table(
  rel_year = as.integer(gsub("year::", "", names(coef(sa_emp)))),
  coef = as.numeric(coef(sa_emp)),
  se = as.numeric(se(sa_emp)),
  pval = as.numeric(pvalue(sa_emp))
)
fwrite(sa_coefs, "../data/sa_emp_coefs.csv")
cat("Pre-treatment coefficients (years -9 to -2):\n")
print(sa_coefs[rel_year >= -9 & rel_year <= -2])
cat("\nPost-treatment coefficients (years 0 to 5):\n")
print(sa_coefs[rel_year >= 0 & rel_year <= 5])
cat("\nLong-run (years 20+):\n")
print(sa_coefs[rel_year >= 20])

# =============================================================================
# STEP 2: TWFE — all four outcomes (all cohorts)
# =============================================================================
cat("\n=== TWFE: All cohorts ===\n")
twfe_emp  <- feols(ln_emp ~ post | county_id + year,
                   data = panel[!is.na(ln_emp)], cluster = ~county_id)
twfe_hir  <- feols(ln_hir ~ post | county_id + year,
                   data = panel[!is.na(ln_hir)], cluster = ~county_id)
twfe_sep  <- feols(ln_sep ~ post | county_id + year,
                   data = panel[!is.na(ln_sep)], cluster = ~county_id)
twfe_earn <- feols(ln_earn ~ post | county_id + year,
                   data = panel[!is.na(ln_earn)], cluster = ~county_id)

cat("TWFE results:\n")
cat("  Emp:  ", round(coef(twfe_emp)["post"], 4), "(", round(se(twfe_emp)["post"], 4), ")\n")
cat("  Hir:  ", round(coef(twfe_hir)["post"], 4), "(", round(se(twfe_hir)["post"], 4), ")\n")
cat("  Sep:  ", round(coef(twfe_sep)["post"], 4), "(", round(se(twfe_sep)["post"], 4), ")\n")
cat("  Earn: ", round(coef(twfe_earn)["post"], 4), "(", round(se(twfe_earn)["post"], 4), ")\n")

saveRDS(twfe_emp, "../data/twfe_emp.rds")
saveRDS(twfe_hir, "../data/twfe_hir.rds")
saveRDS(twfe_sep, "../data/twfe_sep.rds")
saveRDS(twfe_earn, "../data/twfe_earn.rds")

# =============================================================================
# STEP 3: Industry reallocation (the paper's key contribution)
# =============================================================================
cat("\n=== Industry reallocation: TWFE on employment shares ===\n")

share_vars <- c("share_health", "share_manuf", "share_constr",
                "share_accom", "share_retail", "share_prof")
share_labels <- c("Healthcare", "Manufacturing", "Construction",
                  "Accommodation", "Retail", "Professional")

share_results <- list()
for (i in seq_along(share_vars)) {
  v <- share_vars[i]
  est_d <- panel[!is.na(get(v)) & is.finite(get(v))]
  mod <- feols(as.formula(paste(v, "~ post | county_id + year")),
               data = est_d, cluster = ~county_id)
  share_results[[v]] <- mod
  cat(sprintf("  %-15s coef=%.5f (SE=%.5f, p=%.3f)\n",
              share_labels[i], coef(mod)["post"], se(mod)["post"],
              pvalue(mod)["post"]))
}
saveRDS(share_results, "../data/share_results.rds")

# =============================================================================
# STEP 4: Sun-Abraham event studies for key industry SHARES
# =============================================================================
cat("\n=== Sun-Abraham event studies for industry shares ===\n")

sa_share_results <- list()
for (v in c("share_health", "share_manuf", "share_constr")) {
  cat("  SA event study:", v, "\n")
  est_d <- panel_main[!is.na(get(v)) & is.finite(get(v))]
  mod <- feols(as.formula(paste(v, "~ sunab(cohort_sa, year) | county_id + year")),
               data = est_d, cluster = ~county_id)
  sa_share_results[[v]] <- mod

  # Extract and save coefficients
  coefs <- data.table(
    rel_year = as.integer(gsub("year::", "", names(coef(mod)))),
    coef = as.numeric(coef(mod)),
    se = as.numeric(se(mod)),
    pval = as.numeric(pvalue(mod))
  )
  fwrite(coefs, paste0("../data/sa_", v, "_coefs.csv"))
  cat("    Pre-trend (years -5 to -2):\n")
  print(coefs[rel_year >= -5 & rel_year <= -2])
}
saveRDS(sa_share_results, "../data/sa_share_results.rds")

# =============================================================================
# STEP 5: Log industry employment TWFE (level effects)
# =============================================================================
cat("\n=== Industry log employment TWFE ===\n")

ind_level_results <- list()
for (v in c("ln_emp_health", "ln_emp_constr", "ln_emp_manuf",
            "ln_emp_accom", "ln_emp_retail", "ln_emp_prof")) {
  est_d <- panel[!is.na(get(v)) & is.finite(get(v))]
  if (nrow(est_d) < 100) next
  mod <- feols(as.formula(paste(v, "~ post | county_id + year")),
               data = est_d, cluster = ~county_id)
  ind_level_results[[v]] <- mod
  cat(sprintf("  %-20s coef=%.4f (SE=%.4f)\n",
              v, coef(mod)["post"], se(mod)["post"]))
}
saveRDS(ind_level_results, "../data/ind_level_results.rds")

# =============================================================================
# STEP 6: diagnostics.json
# =============================================================================
diag <- list(
  n_treated = uniqueN(panel[g > 0]$county_fips),
  n_pre = 12L,
  n_obs = nrow(panel[!is.na(ln_emp)]),
  n_counties = uniqueN(panel$county_fips),
  n_cohorts = 5L,
  n_never_treated = uniqueN(panel[g == 0]$county_fips),
  twfe_att_emp = round(coef(twfe_emp)["post"], 4),
  twfe_se_emp = round(se(twfe_emp)["post"], 4)
)
write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)
cat("\nDiagnostics saved.\n")

cat("\n=== Main analysis complete ===\n")
