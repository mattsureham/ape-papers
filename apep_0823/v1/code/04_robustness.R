## 04_robustness.R — Robustness checks and placebo tests
## apep_0823: The Alice Dividend

library(data.table)
library(fixest)

outdir <- here::here("output", "apep_0823", "v1")
datadir <- file.path(outdir, "data")

cbp <- fread(file.path(datadir, "cbp_panel.csv"))
cbp[, emp := as.numeric(emp)]
cbp[, estab := as.numeric(estab)]
cbp[, payann := as.numeric(payann)]
cbp[, log_emp := log(emp)]
cbp[, log_estab := log(estab)]
cbp[, event_time := year - 2014]

## ========== R1: Restricted sample (2012-2019, drop Great Recession) ==========
cat("=== R1: Restricted sample 2012-2019 ===\n")
cbp_short <- cbp[year >= 2012]
r1 <- feols(log_emp ~ treat_post | fips^naics + year, data = cbp_short,
            cluster = ~state_fips)
cat("  beta =", round(coef(r1)["treat_post"], 4),
    " SE =", round(se(r1)["treat_post"], 4), "\n")

## Event study on restricted sample
r1_es <- feols(log_emp ~ i(event_time, treated, ref = -1) | fips^naics + year,
               data = cbp_short, cluster = ~state_fips)
cat("Event study (2012-2019):\n")
print(round(coeftable(r1_es), 4))

## ========== R2: Industry-specific linear trends ==========
cat("\n=== R2: Industry-specific linear trends ===\n")
cbp[, naics_trend := as.numeric(as.factor(naics)) * year]
r2 <- feols(log_emp ~ treat_post + naics_trend | fips^naics + year, data = cbp,
            cluster = ~state_fips)
cat("  beta =", round(coef(r2)["treat_post"], 4),
    " SE =", round(se(r2)["treat_post"], 4), "\n")

## ========== R3: Placebo industries ==========
cat("\n=== R3: Placebo — 336 (Transport Equip) vs 325 (Chemicals) ===\n")
## Both are control industries: no Alice effect expected
cbp_placebo <- cbp[naics %in% c("325", "336")]
cbp_placebo[, placebo_treat := as.integer(naics == "336")]
cbp_placebo[, placebo_tp := placebo_treat * post]
r3 <- feols(log_emp ~ placebo_tp | fips^naics + year, data = cbp_placebo,
            cluster = ~state_fips)
cat("  Placebo beta =", round(coef(r3)["placebo_tp"], 4),
    " SE =", round(se(r3)["placebo_tp"], 4), "\n")

## ========== R4: Individual treated industries ==========
cat("\n=== R4: Individual treated industries ===\n")

for (ind in c("334", "511", "518")) {
  sub <- cbp[naics %in% c("325", "336", "339", ind)]
  sub[, ind_treat := as.integer(naics == ind)]
  sub[, ind_tp := ind_treat * post]
  r <- feols(log_emp ~ ind_tp | fips^naics + year, data = sub,
             cluster = ~state_fips)
  cat("  NAICS", ind, ": beta =", round(coef(r)["ind_tp"], 4),
      " SE =", round(se(r)["ind_tp"], 4), "\n")
}

## ========== R5: Wild cluster bootstrap (for small-cluster robustness) ==========
cat("\n=== R5: Wild cluster bootstrap inference ===\n")
## Use the main specification and report bootstrap p-value
main <- feols(log_emp ~ treat_post | fips^naics + year, data = cbp,
              cluster = ~state_fips)

## Wild bootstrap using fixest's built-in (or simulate manually)
## fixest supports boottest via feols
boot_result <- tryCatch({
  ## Bootstrap clustered at state level
  b <- boot(main, type = "wild", cluster = ~state_fips, R = 999)
  cat("  Bootstrap p-value:", round(b$p, 4), "\n")
  b
}, error = function(e) {
  cat("  Bootstrap not available:", conditionMessage(e), "\n")
  cat("  Using conventional clustered SEs instead.\n")
  NULL
})

## ========== R6: Dropping top tech states ==========
cat("\n=== R6: Drop CA, WA, TX, MA (tech-heavy states) ===\n")
cbp_notech <- cbp[!state_fips %in% c("06", "53", "48", "25")]
r6 <- feols(log_emp ~ treat_post | fips^naics + year, data = cbp_notech,
            cluster = ~state_fips)
cat("  beta =", round(coef(r6)["treat_post"], 4),
    " SE =", round(se(r6)["treat_post"], 4), "\n")

## ========== R7: Weighted by baseline employment ==========
cat("\n=== R7: Weighted by 2013 employment ===\n")
base_emp <- cbp[year == 2013, .(base_emp = emp), by = .(fips, naics)]
cbp_w <- merge(cbp, base_emp, by = c("fips", "naics"), all.x = TRUE)
cbp_w <- cbp_w[!is.na(base_emp) & base_emp > 0]
r7 <- feols(log_emp ~ treat_post | fips^naics + year, data = cbp_w,
            weights = ~base_emp, cluster = ~state_fips)
cat("  beta =", round(coef(r7)["treat_post"], 4),
    " SE =", round(se(r7)["treat_post"], 4), "\n")

## ========== SAVE ROBUSTNESS RESULTS ==========
rob_results <- list(
  r1_short = r1, r1_es = r1_es,
  r3_placebo = r3,
  r6_notech = r6, r7_weighted = r7
)
saveRDS(rob_results, file.path(datadir, "robustness_results.rds"))
cat("\nRobustness results saved.\n")
