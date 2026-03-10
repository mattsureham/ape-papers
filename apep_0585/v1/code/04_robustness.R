## 04_robustness.R — Robustness checks and placebo tests
## APEP-0585: EU Medical Device Regulation (MDR) and Innovation

source("00_packages.R")

data_dir <- "../data/"

panel <- fread(paste0(data_dir, "panel_production_with_intensity.csv"))

eu_panel <- panel[is_eu == TRUE & balanced == TRUE]
eu_panel[, treat := as.integer(is_meddev & post_mdr)]

full_panel <- panel[balanced == TRUE]
full_panel[, treat_ddd := as.integer(is_eu & is_meddev & post_mdr)]

# ============================================================================
# 1) COVID DELAY PLACEBO (May 2020 as False Treatment Date)
# ============================================================================

cat("=== Placebo: COVID Delay (May 2020 treatment) ===\n")

# Use pre-period data only (2015-2020), with 2020 as false post-treatment
pre_panel <- eu_panel[year <= 2020]
pre_panel[, placebo_post := year >= 2020]
pre_panel[, placebo_treat := as.integer(is_meddev & placebo_post)]

m_placebo <- feols(prod_index ~ placebo_treat |
                     country_sector + geo^year,
                   data = pre_panel,
                   cluster = "geo")

cat("  COVID placebo coefficient:", round(coef(m_placebo)["placebo_treat"], 3),
    " (p =", round(fixest::pvalue(m_placebo)["placebo_treat"], 3), ")\n")


# ============================================================================
# 2) TURKEY PLACEBO (Non-EU Country Should Show No Effect)
# ============================================================================

cat("\n=== Placebo: Turkey (non-EU) ===\n")

tr_panel <- panel[geo == "TR" & balanced == TRUE]
tr_panel[, treat_tr := as.integer(is_meddev & post_mdr)]

if (nrow(tr_panel) > 0 && n_distinct(tr_panel$nace) > 1) {
  m_turkey <- feols(prod_index ~ treat_tr |
                      nace + year,
                    data = tr_panel)
  cat("  Turkey placebo coefficient:", round(coef(m_turkey)["treat_tr"], 3),
      " (p =", round(fixest::pvalue(m_turkey)["treat_tr"], 3), ")\n")
} else {
  cat("  Turkey data insufficient for placebo test\n")
  m_turkey <- NULL
}


# ============================================================================
# 3) LEAVE-ONE-COUNTRY-OUT
# ============================================================================

cat("\n=== Leave-One-Country-Out ===\n")

eu_countries <- unique(eu_panel$geo[eu_panel$is_meddev])
loo_results <- data.frame()

for (drop_country in eu_countries) {
  m_loo <- feols(prod_index ~ treat |
                   country_sector + geo^year,
                 data = eu_panel[geo != drop_country],
                 cluster = "geo")

  loo_results <- rbind(loo_results, data.frame(
    dropped = drop_country,
    coef = coef(m_loo)["treat"],
    se = se(m_loo)["treat"],
    pval = fixest::pvalue(m_loo)["treat"],
    n = nobs(m_loo)
  ))
}

cat("  Leave-one-out results:\n")
print(loo_results)
fwrite(loo_results, paste0(data_dir, "robustness_loo.csv"))


# ============================================================================
# 4) ALTERNATIVE CONTROL SECTORS
# ============================================================================

cat("\n=== Alternative Control Sectors ===\n")

alt_results <- data.frame()

# Each control sector individually vs C325
for (ctrl in c("C21", "C265", "C26")) {
  pair_panel <- eu_panel[nace %in% c("C325", ctrl)]

  if (nrow(pair_panel) > 0 && n_distinct(pair_panel$nace) == 2) {
    pair_panel[, treat_pair := as.integer(nace == "C325" & post_mdr)]

    m_alt <- feols(prod_index ~ treat_pair |
                     country_sector + geo^year,
                   data = pair_panel,
                   cluster = "geo")

    alt_results <- rbind(alt_results, data.frame(
      control_sector = ctrl,
      coef = coef(m_alt)["treat_pair"],
      se = se(m_alt)["treat_pair"],
      pval = fixest::pvalue(m_alt)["treat_pair"],
      n = nobs(m_alt)
    ))
  }
}

cat("  Alternative control sectors:\n")
print(alt_results)
fwrite(alt_results, paste0(data_dir, "robustness_alt_controls.csv"))


# ============================================================================
# 5) WILD CLUSTER BOOTSTRAP (Few Clusters)
# ============================================================================

cat("\n=== Wild Cluster Bootstrap ===\n")

# Main specification with wild cluster bootstrap
# Using fixest's built-in bootstrap
m_main <- feols(prod_index ~ treat |
                  country_sector + geo^year,
                data = eu_panel,
                cluster = "geo")

# Wild bootstrap p-value (Rademacher weights, 9999 iterations)
tryCatch({
  boot_pval <- fixest::pvalue(m_main, type = "wildboot", nboot = 999)
  cat("  Wild bootstrap p-value:", round(boot_pval["treat"], 4), "\n")
}, error = function(e) {
  cat("  Wild bootstrap: using fwildclusterboot\n")

  # Try fwildclusterboot package
  if (requireNamespace("fwildclusterboot", quietly = TRUE)) {
    library(fwildclusterboot)

    # Need to run OLS version for fwildclusterboot
    m_ols <- feols(prod_index ~ treat + factor(country_sector) + factor(paste0(geo, year)) +
                     factor(paste0(nace, year)),
                   data = eu_panel)

    boot_result <- boottest(m_ols, param = "treat",
                            clustid = "geo",
                            B = 999,
                            type = "rademacher")
    cat("  Wild bootstrap p-value:", round(boot_result$p_val, 4), "\n")
    cat("  Wild bootstrap CI:", round(boot_result$conf_int, 3), "\n")
  } else {
    cat("  fwildclusterboot not available; skipping wild bootstrap\n")
  }
})


# ============================================================================
# 5b) ROBUSTNESS: 2022 AS POST (TREATING 2021 AS TRANSITION)
# ============================================================================

cat("\n=== Robustness: 2022+ as Post ===\n")

eu_panel[, post_2022 := year >= 2022]
eu_panel[, treat_2022 := as.integer(is_meddev & post_2022)]

m_2022 <- feols(prod_index ~ treat_2022 |
                  country_sector + geo^year,
                data = eu_panel,
                cluster = "geo")

cat("  2022+ post coefficient:", round(coef(m_2022)["treat_2022"], 3),
    " (SE =", round(se(m_2022)["treat_2022"], 3),
    ", p =", round(fixest::pvalue(m_2022)["treat_2022"], 3), ")\n")


# ============================================================================
# 6) RANDOMIZATION INFERENCE
# ============================================================================

cat("\n=== Randomization Inference ===\n")

# Permute which sector is "treated" within each country-year
set.seed(42)
n_perms <- 999
actual_coef <- coef(m_main)["treat"]

ri_coefs <- numeric(n_perms)

sectors_in_panel <- unique(eu_panel$nace)

for (i in 1:n_perms) {
  # Randomly assign which sector is "treated" (shuffle sector labels within country)
  perm_panel <- copy(eu_panel)

  perm_panel[, nace_perm := sample(nace), by = .(geo, year)]
  perm_panel[, treat_perm := as.integer(nace_perm == "C325" & post_mdr)]

  m_perm <- tryCatch(
    feols(prod_index ~ treat_perm |
            country_sector + geo^year,
          data = perm_panel,
          cluster = "geo"),
    error = function(e) NULL
  )

  if (!is.null(m_perm)) {
    ri_coefs[i] <- coef(m_perm)["treat_perm"]
  } else {
    ri_coefs[i] <- NA
  }
}

ri_coefs <- ri_coefs[!is.na(ri_coefs)]
ri_pval <- mean(abs(ri_coefs) >= abs(actual_coef))

cat("  RI p-value (two-sided):", round(ri_pval, 4), "\n")
cat("  RI distribution: mean =", round(mean(ri_coefs), 3),
    ", sd =", round(sd(ri_coefs), 3), "\n")

fwrite(data.frame(ri_coef = ri_coefs), paste0(data_dir, "ri_distribution.csv"))


# ============================================================================
# 7) PRE-TREND TEST
# ============================================================================

cat("\n=== Pre-Trend Test ===\n")

# Formal F-test on pre-treatment coefficients from event study
models <- readRDS(paste0(data_dir, "regression_models.rds"))
m_es <- models$m_es

# Extract pre-treatment coefficients
es_coefs <- coeftable(m_es)
pre_coefs <- es_coefs[grepl("event_time::-[2-6]", rownames(es_coefs)), ]

if (nrow(pre_coefs) > 0) {
  # Joint test of pre-treatment coefficients = 0
  pre_terms <- rownames(pre_coefs)
  f_test <- tryCatch({
    wald(m_es, keep = pre_terms)
  }, error = function(e) {
    cat("  Wald test error:", e$message, "\n")
    NULL
  })

  if (!is.null(f_test)) {
    cat("  Pre-trend F-test:\n")
    print(f_test)
  }

  cat("\n  Pre-treatment coefficients:\n")
  print(pre_coefs)
}


# ============================================================================
# SAVE ALL ROBUSTNESS RESULTS
# ============================================================================

cat("\n=== Saving robustness results ===\n")

robustness_summary <- data.frame(
  test = c("Main DiD (Country-Year FE)",
           "COVID delay placebo (2020)",
           "Turkey placebo",
           "RI p-value"),
  coef = c(coef(m_main)["treat"],
           coef(m_placebo)["placebo_treat"],
           ifelse(!is.null(m_turkey), coef(m_turkey)["treat_tr"], NA),
           actual_coef),
  pval = c(fixest::pvalue(m_main)["treat"],
           fixest::pvalue(m_placebo)["placebo_treat"],
           ifelse(!is.null(m_turkey), fixest::pvalue(m_turkey)["treat_tr"], NA),
           ri_pval)
)

cat("  Robustness summary:\n")
print(robustness_summary)

fwrite(robustness_summary, paste0(data_dir, "robustness_summary.csv"))

# Save models
saveRDS(list(m_placebo = m_placebo, m_turkey = m_turkey,
             m_2022 = m_2022,
             ri_coefs = ri_coefs, ri_pval = ri_pval,
             loo_results = loo_results, alt_results = alt_results),
        paste0(data_dir, "robustness_models.rds"))

cat("\nRobustness checks complete.\n")
