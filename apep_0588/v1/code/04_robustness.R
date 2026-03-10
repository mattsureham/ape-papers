# ==============================================================================
# 04_robustness.R — Robustness Checks for apep_0588
# ==============================================================================

source("00_packages.R")

data_dir <- "../data/"
dt <- fread(paste0(data_dir, "panel_total.csv"))
dt[, geo := as.factor(geo)]
dt[, yw := as.factor(yw)]

# ==============================================================================
# 1. Wild Cluster Bootstrap (small-N correction)
# ==============================================================================
cat("=== WILD CLUSTER BOOTSTRAP ===\n")

# Main spec with WCB
m_main <- feols(deaths_pc ~ gas_post | geo + yw, data = dt, cluster = "geo")

wcb <- tryCatch({
  boottest(m_main, param = "gas_post", B = 9999,
           clustid = "geo", type = "webb")
}, error = function(e) {
  cat("WCB failed:", e$message, "\n")
  cat("Trying with fewer iterations...\n")
  tryCatch(
    boottest(m_main, param = "gas_post", B = 999,
             clustid = "geo", type = "webb"),
    error = function(e2) {
      cat("WCB failed again:", e2$message, "\n")
      NULL
    }
  )
})

if (!is.null(wcb)) {
  cat("WCB p-value:", wcb$p_val, "\n")
  cat("WCB 95% CI:", wcb$conf_int, "\n")
  wcb_result <- data.table(
    test = "Wild Cluster Bootstrap (Webb)",
    pval = wcb$p_val,
    ci_lo = wcb$conf_int[1],
    ci_hi = wcb$conf_int[2],
    B = attr(wcb, "B")
  )
} else {
  wcb_result <- data.table(
    test = "Wild Cluster Bootstrap",
    pval = NA_real_, ci_lo = NA_real_, ci_hi = NA_real_, B = NA_integer_
  )
}

# ==============================================================================
# 2. Leave-One-Out: Drop Each High-Dependence Country
# ==============================================================================
cat("\n=== LEAVE-ONE-OUT ===\n")

gas_dep <- fread(paste0(data_dir, "gas_dependence.csv"))
high_dep <- gas_dep[gas_dep_2021 >= 0.50, geo]

loo_results <- list()
for (cc in unique(dt$geo)) {
  dt_loo <- dt[geo != cc]
  m_loo <- feols(deaths_pc ~ gas_post | geo + yw, data = dt_loo, cluster = "geo")
  loo_results[[cc]] <- data.table(
    dropped = cc,
    coef = coef(m_loo)["gas_post"],
    se = sqrt(vcov(m_loo)["gas_post", "gas_post"]),
    n = nobs(m_loo),
    gas_dep = gas_dep[geo == cc, gas_dep_2021]
  )
}
dt_loo <- rbindlist(loo_results)
dt_loo[, pval := 2 * pnorm(-abs(coef / se))]
fwrite(dt_loo, paste0(data_dir, "results_loo.csv"))

cat("Leave-one-out range: [", round(min(dt_loo$coef), 3), ", ",
    round(max(dt_loo$coef), 3), "]\n")

# ==============================================================================
# 3. Randomization Inference
# ==============================================================================
cat("\n=== RANDOMIZATION INFERENCE ===\n")

# Permute gas dependence across countries
set.seed(42)
n_perm <- 1000
beta_main <- coef(m_main)["gas_post"]

# Get unique country-level gas dependence
country_gas <- unique(dt[, .(geo, gas_dep_2021)])

perm_betas <- numeric(n_perm)
for (i in 1:n_perm) {
  # Shuffle gas dependence across countries
  perm_dep <- sample(country_gas$gas_dep_2021)
  dt_perm <- copy(dt)
  dt_perm[, gas_dep_perm := perm_dep[match(geo, country_gas$geo)]]
  dt_perm[, gas_post_perm := gas_dep_perm * as.numeric(post_winter)]

  m_perm <- tryCatch(
    feols(deaths_pc ~ gas_post_perm | geo + yw, data = dt_perm, cluster = "geo"),
    error = function(e) NULL
  )
  if (!is.null(m_perm)) {
    perm_betas[i] <- coef(m_perm)["gas_post_perm"]
  }

  if (i %% 100 == 0) cat("  Permutation", i, "/", n_perm, "\n")
}

ri_pval <- mean(abs(perm_betas) >= abs(beta_main), na.rm = TRUE)
cat("RI p-value (two-sided):", ri_pval, "\n")

ri_result <- data.table(
  test = "Randomization Inference",
  pval = ri_pval,
  n_perm = n_perm,
  beta_main = beta_main,
  beta_perm_mean = mean(perm_betas, na.rm = TRUE),
  beta_perm_sd = sd(perm_betas, na.rm = TRUE)
)
fwrite(ri_result, paste0(data_dir, "results_ri.csv"))

# Save permutation distribution for figure
fwrite(data.table(beta_perm = perm_betas), paste0(data_dir, "ri_distribution.csv"))

# ==============================================================================
# 4. Alternative Treatment: Gas Import Volume Drop
# ==============================================================================
cat("\n=== ALTERNATIVE TREATMENT MEASURES ===\n")

# Use actual gas import data if available
if (file.exists(paste0(data_dir, "gas_imports_russia.csv"))) {
  dt_gas <- fread(paste0(data_dir, "gas_imports_russia.csv"))

  # Compute 2021 baseline gas imports by country
  gas_baseline <- dt_gas[year == 2021, .(gas_2021 = sum(gas_imports_ru, na.rm = TRUE)), by = geo]

  # Compute 2022 gas imports
  gas_2022 <- dt_gas[year == 2022, .(gas_2022 = sum(gas_imports_ru, na.rm = TRUE)), by = geo]

  gas_change <- merge(gas_baseline, gas_2022, by = "geo", all = TRUE)
  gas_change[is.na(gas_2022), gas_2022 := 0]
  gas_change[, gas_drop_pct := (gas_2021 - gas_2022) / gas_2021]
  gas_change[is.nan(gas_drop_pct) | is.infinite(gas_drop_pct), gas_drop_pct := 0]

  # Merge with panel
  dt_alt <- merge(dt, gas_change[, .(geo, gas_drop_pct)], by = "geo", all.x = TRUE)
  dt_alt <- dt_alt[!is.na(gas_drop_pct)]
  dt_alt[, gas_drop_post := gas_drop_pct * as.numeric(post_winter)]

  m_alt <- feols(deaths_pc ~ gas_drop_post | geo + yw, data = dt_alt, cluster = "geo")
  cat("\nAlternative treatment (actual gas import drop %):\n")
  summary(m_alt)

  alt_result <- data.table(
    test = "Actual Gas Import Drop",
    coef = coef(m_alt)["gas_drop_post"],
    se = sqrt(vcov(m_alt)["gas_drop_post", "gas_drop_post"]),
    n = nobs(m_alt)
  )
} else {
  alt_result <- data.table(test = "Actual Gas Import Drop", coef = NA, se = NA, n = 0)
}

# ==============================================================================
# 5. Excluding COVID Period (2020-2021)
# ==============================================================================
cat("\n=== EXCLUDING COVID PERIOD ===\n")

dt_nocovid <- dt[!(year %in% c(2020, 2021))]
m_nocovid <- feols(deaths_pc ~ gas_post | geo + yw, data = dt_nocovid, cluster = "geo")
cat("\nExcluding 2020-2021:\n")
summary(m_nocovid)

# ==============================================================================
# 6. Winter-Only Analysis (Drop Summer Entirely)
# ==============================================================================
cat("\n=== WINTER-ONLY ANALYSIS ===\n")

dt_winter <- dt[heating_season == TRUE]
m_winter <- feols(deaths_pc ~ gas_post | geo + yw, data = dt_winter, cluster = "geo")
cat("\nWinter weeks only:\n")
summary(m_winter)

# ==============================================================================
# 7. Dose-Response: Binned Gas Dependence
# ==============================================================================
cat("\n=== DOSE-RESPONSE (BINNED) ===\n")

dt[, gas_q := fcase(
  gas_dep_2021 < 0.15, "Q1 (<15%)",
  gas_dep_2021 < 0.40, "Q2 (15-40%)",
  gas_dep_2021 < 0.60, "Q3 (40-60%)",
  default = "Q4 (>60%)"
)]

for (q in unique(dt$gas_q)) {
  dt[, (paste0("post_", gsub("[^A-Za-z0-9]", "", q))) :=
       as.numeric(gas_q == q) * as.numeric(post_winter)]
}

dose_vars <- grep("^post_Q", names(dt), value = TRUE)
dose_form <- paste0("deaths_pc ~ ", paste(dose_vars, collapse = " + "), " | geo + yw")
m_dose <- feols(as.formula(dose_form), data = dt, cluster = "geo")
cat("\nDose-response results:\n")
summary(m_dose)

dose_results <- data.table(
  quartile = dose_vars,
  coef = coef(m_dose)[dose_vars],
  se = sqrt(diag(vcov(m_dose)))[dose_vars]
)
fwrite(dose_results, paste0(data_dir, "results_dose_response.csv"))

# ==============================================================================
# 8. Compile All Robustness Results
# ==============================================================================
cat("\n=== COMPILING ROBUSTNESS SUMMARY ===\n")

rob_summary <- data.table(
  test = c("Main specification", "Wild cluster bootstrap p-val",
           "Leave-one-out min coef", "Leave-one-out max coef",
           "Randomization inference p-val",
           "Excluding 2020-2021", "Winter-only",
           if (!is.na(alt_result$coef)) "Alt treatment (gas drop)" else NULL),
  value = c(
    round(coef(m_main)["gas_post"], 4),
    if (!is.null(wcb)) round(wcb$p_val, 4) else NA,
    round(min(dt_loo$coef), 4),
    round(max(dt_loo$coef), 4),
    round(ri_pval, 4),
    round(coef(m_nocovid)["gas_post"], 4),
    round(coef(m_winter)["gas_post"], 4),
    if (!is.na(alt_result$coef)) round(alt_result$coef, 4) else NULL
  )
)
fwrite(rob_summary, paste0(data_dir, "results_robustness_summary.csv"))

cat("\nRobustness checks complete.\n")
print(rob_summary)
