## ============================================================
## 04_robustness.R — Robustness checks
## apep_0531: PCSO Cuts and Crime in England
## ============================================================

source("00_packages.R")

panel <- fread(file.path(dat_dir, "analysis_panel.csv"))
panel <- panel[!is.na(total_crime) & !is.na(pcso_fte) & year <= 2024]

## ---- 1. Wild Cluster Bootstrap --------------------------------

cat("=== WILD CLUSTER BOOTSTRAP ===\n")

m_base <- feols(log_crime_rate ~ pcso_per100k + officer_per100k | force_id + year,
                data = panel, cluster = ~force_id)

set.seed(12345)
boot_result <- tryCatch({
  boottest(m_base, param = "pcso_per100k", clustid = ~force_id,
           B = 9999, type = "webb", impose_null = TRUE)
}, error = function(e) {
  cat("Wild bootstrap failed:", e$message, "\n")
  NULL
})

if (!is.null(boot_result)) {
  cat("Wild cluster bootstrap p-value:", boot_result$p_val, "\n")
  cat("Bootstrap CI:", boot_result$conf_int, "\n")
  boot_dt <- data.table(
    method = "Wild cluster bootstrap (Webb)",
    pval = boot_result$p_val,
    ci_low = boot_result$conf_int[1],
    ci_high = boot_result$conf_int[2]
  )
  fwrite(boot_dt, file.path(dat_dir, "wild_bootstrap.csv"))
}


## ---- 2. Randomization Inference --------------------------------

cat("\n=== RANDOMIZATION INFERENCE ===\n")

# Permute treatment (PCSO changes) across forces within year
set.seed(42)
n_perm <- 999
true_coef <- coef(m_base)["pcso_per100k"]

perm_coefs <- numeric(n_perm)
for (i in 1:n_perm) {
  perm_data <- copy(panel)
  # Shuffle force_std within each year (permute treatment assignment)
  for (yr in unique(perm_data$year)) {
    idx <- which(perm_data$year == yr)
    perm_data[idx, pcso_per100k := sample(pcso_per100k)]
    perm_data[idx, officer_per100k := sample(officer_per100k)]
  }
  perm_m <- tryCatch({
    feols(log_crime_rate ~ pcso_per100k + officer_per100k | force_id + year,
          data = perm_data, notes = FALSE)
  }, error = function(e) NULL)
  if (!is.null(perm_m) && "pcso_per100k" %in% names(coef(perm_m))) {
    perm_coefs[i] <- coef(perm_m)["pcso_per100k"]
  } else {
    perm_coefs[i] <- NA
  }
}
perm_coefs <- perm_coefs[!is.na(perm_coefs)]

ri_pval <- mean(abs(perm_coefs) >= abs(true_coef))
cat("RI p-value (two-sided):", ri_pval, "\n")
cat("True coef:", true_coef, "\n")
cat("Permutation distribution: mean=", mean(perm_coefs), "sd=", sd(perm_coefs), "\n")

ri_dt <- data.table(
  true_coef = true_coef,
  ri_pval = ri_pval,
  perm_mean = mean(perm_coefs),
  perm_sd = sd(perm_coefs),
  n_perms = length(perm_coefs)
)
fwrite(ri_dt, file.path(dat_dir, "randomization_inference.csv"))

# Save permutation distribution for figure
fwrite(data.table(perm_coef = perm_coefs), file.path(dat_dir, "ri_distribution.csv"))


## ---- 3. Leave-One-Out Jackknife --------------------------------

cat("\n=== LEAVE-ONE-OUT JACKKNIFE ===\n")

forces <- unique(panel$force_std)
jack_results <- list()
for (f in forces) {
  jack_data <- panel[force_std != f]
  jack_m <- tryCatch({
    feols(log_crime_rate ~ pcso_per100k + officer_per100k | force_id + year,
          data = jack_data, notes = FALSE)
  }, error = function(e) NULL)
  if (!is.null(jack_m) && "pcso_per100k" %in% names(coef(jack_m))) {
    jack_results[[f]] <- data.table(
      dropped_force = f,
      coef = coef(jack_m)["pcso_per100k"],
      se = se(jack_m)["pcso_per100k"]
    )
  }
}
jack_dt <- rbindlist(jack_results)
cat("Jackknife coefficient range:",
    round(min(jack_dt$coef), 5), "to", round(max(jack_dt$coef), 5), "\n")
cat("Full sample coefficient:", round(true_coef, 5), "\n")
fwrite(jack_dt, file.path(dat_dir, "jackknife_results.csv"))


## ---- 4. Drop Metropolitan Police ------------------------------

cat("\n=== DROP METROPOLITAN POLICE ===\n")

m_no_met <- feols(log_crime_rate ~ pcso_per100k + officer_per100k | force_id + year,
                  data = panel[force_std != "metropolitan police"],
                  cluster = ~force_id)
cat("Without Met Police:\n")
print(summary(m_no_met))

# Drop all London forces
m_no_london <- feols(log_crime_rate ~ pcso_per100k + officer_per100k | force_id + year,
                     data = panel[!grepl("metropolitan|city of london", force_std)],
                     cluster = ~force_id)
cat("\nWithout London forces:\n")
print(summary(m_no_london))


## ---- 5. Pre-Trend Test ----------------------------------------

cat("\n=== PRE-TREND TEST ===\n")

# Test if 2010 PCSO baseline predicts pre-trend crime changes (2008-2010)
pre_panel <- panel[year <= 2010]
pre_panel[, year_fac := factor(year)]

m_pre <- feols(log_crime_rate ~ i(year, pcso_baseline, ref = 2010) | force_id + year,
               data = pre_panel[!is.na(pcso_baseline)], cluster = ~force_id)
cat("Pre-trend test:\n")
print(summary(m_pre))


## ---- 6. Minimum Detectable Effect -----------------------------

cat("\n=== MINIMUM DETECTABLE EFFECT ===\n")

# With PCSO coefficient SE ≈ 0.002 and average PCSO decline ≈ 15 per 100k:
se_pcso <- se(m_base)["pcso_per100k"]
avg_decline <- 15.3  # approximate average PCSO decline per 100k

# MDE at 5% significance, 80% power: 2.8 × SE
mde_coef <- 2.8 * se_pcso
mde_pct <- mde_coef * avg_decline * 100

cat("SE of PCSO coefficient:", round(se_pcso, 5), "\n")
cat("Average PCSO decline:", avg_decline, "per 100k\n")
cat("MDE coefficient (2.8×SE):", round(mde_coef, 5), "\n")
cat("MDE in crime percentage:", round(mde_pct, 1), "%\n")
cat("Interpretation: we can rule out crime effects larger than",
    round(mde_pct, 1), "% from the average PCSO decline\n")

mde_dt <- data.table(
  se = se_pcso,
  avg_decline = avg_decline,
  mde_coef = mde_coef,
  mde_pct = mde_pct,
  baseline_crime_rate = mean(panel$crime_rate, na.rm = TRUE)
)
fwrite(mde_dt, file.path(dat_dir, "mde_results.csv"))


## ---- 7. Alternative Specifications ----------------------------

cat("\n=== ALTERNATIVE SPECIFICATIONS ===\n")

# Region × year FE
panel[, region := substr(force_std, 1, 5)]  # crude region proxy
# Use actual region from workforce data if available
wf_raw <- fread(file.path(dat_dir, "workforce_raw.csv"))
wf_raw[, force_std_r := tolower(gsub("[^a-z0-9 ]", "", force_name))]
wf_raw[, force_std_r := gsub("\\s+", " ", trimws(force_std_r))]
wf_raw[, force_std_r := gsub("london city of", "city of london", force_std_r)]
wf_raw[, force_std_r := gsub("hampshire and isle of wight", "hampshire", force_std_r)]
regions <- unique(wf_raw[, .(force_std = force_std_r, region_name = region)])
regions <- regions[!duplicated(force_std)]
panel <- merge(panel, regions[, .(force_std, region_name)],
               by = "force_std", all.x = TRUE)

m_region <- tryCatch({
  feols(log_crime_rate ~ pcso_per100k + officer_per100k |
          force_id + year + region_name^year,
        data = panel[!is.na(region_name)], cluster = ~force_id)
}, error = function(e) {
  cat("Region×year FE failed:", e$message, "\n")
  NULL
})

if (!is.null(m_region)) {
  cat("With region×year FE:\n")
  print(summary(m_region))
}

# First-differenced specification
panel <- panel[order(force_std, year)]
panel[, d_log_crime := log_crime_rate - shift(log_crime_rate), by = force_std]
panel[, d_pcso := pcso_per100k - shift(pcso_per100k), by = force_std]
panel[, d_officer := officer_per100k - shift(officer_per100k), by = force_std]

m_fd <- feols(d_log_crime ~ d_pcso + d_officer | year,
              data = panel[!is.na(d_log_crime)], cluster = ~force_id)
cat("\nFirst-differenced:\n")
print(summary(m_fd))


## ---- 8. Save Robustness Summary --------------------------------

cat("\n=== ROBUSTNESS SUMMARY ===\n")

rob_summary <- data.table(
  specification = c("Baseline TWFE",
                     "Drop Met Police",
                     "Drop London forces",
                     "First-differenced",
                     if (!is.null(m_region)) "Region×year FE" else character(0)),
  coef = c(coef(m_base)["pcso_per100k"],
           coef(m_no_met)["pcso_per100k"],
           coef(m_no_london)["pcso_per100k"],
           coef(m_fd)["d_pcso"],
           if (!is.null(m_region)) coef(m_region)["pcso_per100k"] else numeric(0)),
  se = c(se(m_base)["pcso_per100k"],
         se(m_no_met)["pcso_per100k"],
         se(m_no_london)["pcso_per100k"],
         se(m_fd)["d_pcso"],
         if (!is.null(m_region)) se(m_region)["pcso_per100k"] else numeric(0)),
  n = c(nobs(m_base),
        nobs(m_no_met),
        nobs(m_no_london),
        nobs(m_fd),
        if (!is.null(m_region)) nobs(m_region) else integer(0))
)
rob_summary[, ci_low := coef - 1.96 * se]
rob_summary[, ci_high := coef + 1.96 * se]

cat("Robustness:\n")
print(rob_summary)
fwrite(rob_summary, file.path(dat_dir, "robustness_summary.csv"))

cat("\n=== ALL ROBUSTNESS CHECKS COMPLETE ===\n")
