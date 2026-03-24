## 04_robustness.R — Robustness checks and validity tests
## apep_0863: The Forecaster Lottery

library(data.table)
library(fixest)

args <- commandArgs(trailingOnly = FALSE)
script_dir <- dirname(sub("--file=", "", args[grep("--file=", args)]))
if (length(script_dir) > 0) setwd(file.path(script_dir, ".."))

analysis <- fread("data/analysis_tornado_pairs.csv")
analysis <- analysis[!is.na(avg_lt_overall) & !is.na(pair_id)]
analysis[, ef_sq := ef_scale^2]
analysis[, log_pop := log(population + 1)]
analysis[, log_damage := log(damage_property + 1)]

cat("=== ROBUSTNESS CHECKS ===\n\n")

## ============================================================
## 1. Covariate balance at WFO boundaries
## ============================================================
cat("--- Covariate balance ---\n\n")

# Population should be smooth at WFO boundaries
m_pop_bal <- feols(log_pop ~ avg_lt_overall | pair_id, data = analysis, cluster = ~wfo + year)
cat("Population balance:\n")
print(summary(m_pop_bal))

# Mobile home share
if ("mobile_share" %in% names(analysis)) {
  m_mob_bal <- feols(mobile_share ~ avg_lt_overall | pair_id, data = analysis, cluster = ~wfo + year)
  cat("\nMobile home share balance:\n")
  print(summary(m_mob_bal))
}

## ============================================================
## 2. Leave-one-WFO-out sensitivity
## ============================================================
cat("\n--- Leave-one-WFO-out ---\n\n")

wfos <- unique(analysis$wfo)
loo_coefs <- numeric(length(wfos))
names(loo_coefs) <- wfos

for (i in seq_along(wfos)) {
  d_sub <- analysis[wfo != wfos[i]]
  m_loo <- feols(casualties ~ avg_lt_overall + ef_scale + ef_sq + path_length + path_width | pair_id + year,
                 data = d_sub, cluster = ~wfo + year)
  loo_coefs[i] <- coef(m_loo)["avg_lt_overall"]
}

cat("Leave-one-WFO-out coefficients:\n")
cat("  Mean:", round(mean(loo_coefs, na.rm = TRUE), 5), "\n")
cat("  SD:", round(sd(loo_coefs, na.rm = TRUE), 5), "\n")
cat("  Range:", round(range(loo_coefs, na.rm = TRUE), 5), "\n")
cat("  Full-sample coef for comparison:",
    round(coef(feols(casualties ~ avg_lt_overall + ef_scale + ef_sq + path_length + path_width | pair_id + year,
                     data = analysis, cluster = ~wfo + year))["avg_lt_overall"], 5), "\n")


## ============================================================
## 3. Alternative bandwidth (restrict to counties closer to border)
## ============================================================
cat("\n--- Alternative specifications ---\n\n")

# Use only pairs where both counties have at least N tornado events
pair_counts <- analysis[, .N, by = pair_id]
active_pairs <- pair_counts[N >= 5]$pair_id
cat("Pairs with 5+ events:", length(active_pairs), "of", uniqueN(analysis$pair_id), "\n")

m_active <- feols(casualties ~ avg_lt_overall + ef_scale + ef_sq + path_length + path_width | pair_id + year,
                  data = analysis[pair_id %in% active_pairs], cluster = ~wfo + year)
cat("Active pairs only:\n")
print(summary(m_active))

# EF1+ only (exclude EF0 which rarely cause casualties)
m_ef1plus <- feols(casualties ~ avg_lt_overall + ef_scale + ef_sq + path_length + path_width | pair_id + year,
                   data = analysis[ef_scale >= 1], cluster = ~wfo + year)
cat("\nEF1+ tornadoes only:\n")
print(summary(m_ef1plus))

# Time-varying WFO performance (year-specific instead of long-run average)
if ("avg_leadtime" %in% names(analysis)) {
  analysis_tv <- analysis[!is.na(avg_leadtime)]
  if (nrow(analysis_tv) > 100) {
    m_tv <- feols(casualties ~ avg_leadtime + ef_scale + ef_sq + path_length + path_width | pair_id + year,
                  data = analysis_tv, cluster = ~wfo + year)
    cat("\nTime-varying lead time:\n")
    print(summary(m_tv))
  }
}

## ============================================================
## 4. Poisson model (count outcome)
## ============================================================
cat("\n--- Poisson specification ---\n\n")

m_pois <- fepois(casualties ~ avg_lt_overall + ef_scale + ef_sq + path_length + path_width | pair_id + year,
                 data = analysis[casualties >= 0], cluster = ~wfo + year)
cat("Poisson (casualties):\n")
print(summary(m_pois))


## ============================================================
## 5. Wild cluster bootstrap (small number of clusters concern)
## ============================================================
cat("\n--- Inference robustness ---\n\n")

# State-level clustering (coarser)
m_state <- feols(casualties ~ avg_lt_overall + ef_scale + ef_sq + path_length + path_width | pair_id + year,
                 data = analysis, cluster = ~state_fips + year)
cat("State-clustered SE:\n")
print(summary(m_state))

# WFO-only clustering
m_wfo_only <- feols(casualties ~ avg_lt_overall + ef_scale + ef_sq + path_length + path_width | pair_id + year,
                    data = analysis, cluster = ~wfo)
cat("\nWFO-only clustered SE:\n")
print(summary(m_wfo_only))


## ============================================================
## 6. Save robustness results
## ============================================================

rob_results <- list(
  loo_coefs = loo_coefs,
  m_active = m_active,
  m_ef1plus = m_ef1plus,
  m_pois = m_pois,
  m_state = m_state,
  m_wfo_only = m_wfo_only,
  m_pop_bal = m_pop_bal
)
if (exists("m_tv")) rob_results$m_tv <- m_tv
if (exists("m_mob_bal")) rob_results$m_mob_bal <- m_mob_bal

saveRDS(rob_results, "data/robustness_results.rds")
cat("\n=== ROBUSTNESS COMPLETE ===\n")
