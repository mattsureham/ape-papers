## 03_main_analysis.R — Main regressions for apep_0700
## UK LHA Freeze and Homelessness

source("00_packages.R")
setwd("../data")

panel <- fread("analysis_panel.csv")
cat("=== Main Analysis: LHA Freeze and Homelessness ===\n")
cat("Panel:", nrow(panel), "obs,", uniqueN(panel$la_code), "LAs,",
    uniqueN(panel$yq), "quarters\n")

## -----------------------------------------------------------------------
## Analysis sample: LAs with proper BRMA mapping (non-median gap)
## -----------------------------------------------------------------------
# Exclude LAs assigned median gap (unmapped)
mapped <- panel[brma_name != "UNMAPPED"]
cat("\nMapped sample:", nrow(mapped), "obs,", uniqueN(mapped$la_code), "LAs\n")
cat("Gap range in mapped sample: [", round(min(mapped$gap_pct), 1), ",",
    round(max(mapped$gap_pct), 1), "]\n")

# Standardize gap for interpretation (10pp increase)
mapped[, gap_10pp := gap_pct / 10]

# Create event study indicators
mapped[, relative_q_factor := factor(relative_q)]
# Omit q=-1 as reference period (quarter before freeze)
mapped[, relative_q_factor := relevel(relative_q_factor, ref = "-1")]

## -----------------------------------------------------------------------
## Table 1: Summary Statistics
## -----------------------------------------------------------------------
cat("\n=== Summary Statistics ===\n")

# Split by high/low treatment
mapped[, high_gap := as.integer(gap_pct > median(gap_pct))]

sumstats <- mapped[, .(
  accept_rate = mean(accept_rate_per1000, na.rm = TRUE),
  acceptances = mean(acceptances, na.rm = TRUE),
  ta_rate = mean(ta_rate_per1000, na.rm = TRUE),
  total_ta = mean(total_ta, na.rm = TRUE),
  claimant_rate = mean(claimant_count / (households_000 * 1000) * 100, na.rm = TRUE),
  gap_pct = mean(gap_pct),
  n_la = uniqueN(la_code)
), by = .(Period = ifelse(post == 1, "Post-freeze", "Pre-freeze"),
          Treatment = ifelse(high_gap == 1, "High gap", "Low gap"))]

print(sumstats)

## -----------------------------------------------------------------------
## Main Specification: Continuous DiD
## Y_{it} = alpha_i + gamma_t + beta * (Gap_i * Post_t) + epsilon
## -----------------------------------------------------------------------
cat("\n=== Main Specification: Continuous DiD ===\n")

# Model 1: Acceptance rate ~ gap × post, LA + quarter FE
m1 <- feols(accept_rate_per1000 ~ gap_10pp:post | la_code + yq,
            data = mapped, cluster = ~la_code)
cat("Model 1 (acceptance rate):\n")
print(summary(m1))

# Model 2: Log(acceptances + 1) ~ gap × post
mapped[, log_accept := log(acceptances + 1)]
m2 <- feols(log_accept ~ gap_10pp:post | la_code + yq,
            data = mapped, cluster = ~la_code)
cat("\nModel 2 (log acceptances):\n")
print(summary(m2))

# Model 3: Total decisions
mapped[, log_decisions := log(total_decisions + 1)]
m3 <- feols(log_decisions ~ gap_10pp:post | la_code + yq,
            data = mapped, cluster = ~la_code)
cat("\nModel 3 (log decisions):\n")
print(summary(m3))

# Model 4: Temporary accommodation rate
m4 <- feols(ta_rate_per1000 ~ gap_10pp:post | la_code + yq,
            data = mapped, cluster = ~la_code)
cat("\nModel 4 (TA rate per 1000):\n")
print(summary(m4))

## -----------------------------------------------------------------------
## Event Study
## -----------------------------------------------------------------------
cat("\n=== Event Study ===\n")
es <- feols(accept_rate_per1000 ~ i(relative_q, gap_10pp, ref = -1) | la_code + yq,
            data = mapped, cluster = ~la_code)
cat("Event study coefficients:\n")
print(coeftable(es))

## -----------------------------------------------------------------------
## Model 5: With controls (claimant count)
## -----------------------------------------------------------------------
cat("\n=== With Controls ===\n")
mapped[, claimant_rate := claimant_count / (households_000 * 1000) * 100]
m5 <- feols(accept_rate_per1000 ~ gap_10pp:post + claimant_rate | la_code + yq,
            data = mapped, cluster = ~la_code)
cat("Model 5 (with claimant rate control):\n")
print(summary(m5))

## -----------------------------------------------------------------------
## Save regression objects
## -----------------------------------------------------------------------
saveRDS(list(m1 = m1, m2 = m2, m3 = m3, m4 = m4, m5 = m5, es = es),
        file = "regression_results.rds")

# Update diagnostics
diagnostics <- list(
  n_treated = uniqueN(mapped[gap_pct > median(gap_pct)]$la_code),
  n_pre = uniqueN(mapped[post == 0]$yq),
  n_obs = nrow(mapped),
  n_la = uniqueN(mapped$la_code),
  mean_gap = round(mean(mapped$gap_pct), 1),
  sd_gap = round(sd(mapped$gap_pct), 1)
)
jsonlite::write_json(diagnostics, "diagnostics.json", auto_unbox = TRUE)

cat("\n=== Main analysis complete ===\n")
cat("Results saved to regression_results.rds\n")
cat("Diagnostics:", diagnostics$n_treated, "high-gap LAs,",
    diagnostics$n_pre, "pre-periods,", diagnostics$n_obs, "obs,",
    diagnostics$n_la, "LAs\n")

setwd("../code")
