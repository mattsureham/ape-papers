# 04_robustness.R — Robustness checks
# apep_0835: Greece POS Terminal Mandates

source("00_packages.R")

panel <- fread("../data/analysis_panel.csv")
panel[, cohort_sa := fifelse(treated == 1, 2017L, 10000L)]

cat("=== Robustness Checks ===\n")

# ===================================================================
# 1. Restricted sample: 2014-2019 (drops 2012-2013 pre-trend issues)
# ===================================================================

cat("\n--- R1: Restricted sample 2014-2019 ---\n")

panel_r1 <- panel[year >= 2014]
panel_r1[, treat_post := treated * as.integer(year >= 2017)]

r1_est <- feols(log_est ~ treat_post | sector_id + year,
                data = panel_r1, cluster = ~nace1)
r1_emp <- feols(log_emp ~ treat_post | sector_id + year,
                data = panel_r1, cluster = ~nace1)
r1_wages <- feols(log_wages ~ treat_post | sector_id + year,
                  data = panel_r1, cluster = ~nace1)

cat("2014-2019 — Est:", round(coef(r1_est)["treat_post"], 4),
    " Emp:", round(coef(r1_emp)["treat_post"], 4),
    " Wages:", round(coef(r1_wages)["treat_post"], 4), "\n")

# ===================================================================
# 2. Include 2020 (COVID year)
# ===================================================================

cat("\n--- R2: Including 2020 ---\n")

panel_full <- fread("../data/analysis_panel_full.csv")
panel_full[, treat_post := treated * as.integer(year >= 2017)]

r2_est <- feols(log_est ~ treat_post | sector_id + year,
                data = panel_full, cluster = ~nace1)
r2_emp <- feols(log_emp ~ treat_post | sector_id + year,
                data = panel_full, cluster = ~nace1)
r2_wages <- feols(log_wages ~ treat_post | sector_id + year,
                  data = panel_full, cluster = ~nace1)

cat("Incl. 2020 — Est:", round(coef(r2_est)["treat_post"], 4),
    " Emp:", round(coef(r2_emp)["treat_post"], 4),
    " Wages:", round(coef(r2_wages)["treat_post"], 4), "\n")

# ===================================================================
# 3. Placebo treatment year (2015, using 2012-2016 only)
# ===================================================================

cat("\n--- R3: Placebo treatment year (2015) ---\n")

placebo_panel <- copy(panel[year <= 2016])
placebo_panel[, placebo_post := as.integer(year >= 2015)]
placebo_panel[, placebo_treat_post := treated * placebo_post]

r3_est <- feols(log_est ~ placebo_treat_post | sector_id + year,
                data = placebo_panel, cluster = ~nace1)
r3_emp <- feols(log_emp ~ placebo_treat_post | sector_id + year,
                data = placebo_panel, cluster = ~nace1)
r3_wages <- feols(log_wages ~ placebo_treat_post | sector_id + year,
                  data = placebo_panel, cluster = ~nace1)

cat("Placebo 2015 — Est:", round(coef(r3_est)["placebo_treat_post"], 4),
    " Emp:", round(coef(r3_emp)["placebo_treat_post"], 4),
    " Wages:", round(coef(r3_wages)["placebo_treat_post"], 4), "\n")

# ===================================================================
# 4. Regional panel (employment, with region × year FEs)
# ===================================================================

cat("\n--- R4: Regional panel ---\n")

if (file.exists("../data/regional_panel.csv")) {
  reg_panel <- fread("../data/regional_panel.csv")

  r4_emp <- feols(log_emp ~ treat_post | sector_id + region_id^year,
                  data = reg_panel, cluster = ~nace1)
  cat("Regional — Emp:", round(coef(r4_emp)["treat_post"], 4), "\n")
} else {
  r4_emp <- NULL
}

# ===================================================================
# 5. Permutation inference (500 permutations)
# ===================================================================

cat("\n--- R5: Permutation Inference (500 draws) ---\n")

set.seed(42)
n_perms <- 500

actual_emp <- coef(feols(log_emp ~ treat_post | sector_id + year,
                         data = panel))["treat_post"]

sectors <- unique(panel$nace1)
n_treated <- sum(sectors %in% c("G", "I", "M", "N", "S"))

perm_coefs <- numeric(n_perms)
for (i in 1:n_perms) {
  perm_treated <- sample(sectors, size = n_treated)
  panel[, perm_treat := as.integer(nace1 %in% perm_treated)]
  panel[, perm_tp := perm_treat * post]

  perm_coefs[i] <- tryCatch(
    coef(feols(log_emp ~ perm_tp | sector_id + year, data = panel))["perm_tp"],
    error = function(e) NA_real_
  )
}

ri_p_emp <- mean(abs(perm_coefs) >= abs(actual_emp), na.rm = TRUE)
cat(sprintf("RI p-value (employment): %.3f\n", ri_p_emp))

panel[, c("perm_treat", "perm_tp") := NULL]

# ===================================================================
# 6. Dropping individual treated sectors (leave-one-out)
# ===================================================================

cat("\n--- R6: Leave-one-out (treated sectors) ---\n")

treated_sectors <- c("G", "I", "M", "N", "S")
loo_results <- list()

for (s in treated_sectors) {
  loo_data <- panel[nace1 != s]
  loo_data[, treat_post := treated * post]
  loo_results[[s]] <- feols(log_emp ~ treat_post | sector_id + year,
                            data = loo_data, cluster = ~nace1)
  cat(sprintf("Drop %s: coef=%.4f, se=%.4f\n", s,
              coef(loo_results[[s]])["treat_post"],
              sqrt(vcov(loo_results[[s]])["treat_post", "treat_post"])))
}

# ===================================================================
# Save robustness results
# ===================================================================

rob_results <- list(
  r1_restricted = list(est = r1_est, emp = r1_emp, wages = r1_wages),
  r2_incl2020 = list(est = r2_est, emp = r2_emp, wages = r2_wages),
  r3_placebo = list(est = r3_est, emp = r3_emp, wages = r3_wages),
  r4_regional = if (!is.null(r4_emp)) list(emp = r4_emp) else NULL,
  r5_ri = list(p_emp = ri_p_emp),
  r6_loo = loo_results
)
saveRDS(rob_results, "../data/robustness_results.rds")

cat("\n=== Robustness checks complete ===\n")
