## 03_main_analysis.R — Triple-difference estimation
source("00_packages.R")

dt <- readRDS("../data/analysis_panel.rds")

# ---- Exclude always-treated from main estimation (CA, OK, ND) ----
# They serve as long-run benchmark; main DiD uses ban vs never-ban states
est <- dt[state_group != "Always-Treated"]

cat("=== Main Estimation Sample ===\n")
cat("Observations:", nrow(est), "\n")
cat("Ban states:", uniqueN(est[ban_state == TRUE, state_abbr]), "\n")
cat("Control states:", uniqueN(est[ban_state == FALSE, state_abbr]), "\n")

# ---- Model 1: Simple DiD (ban × post) on separation rate ----
# All industries, all races
m1 <- feols(sep_rate ~ post | state_abbr + yq + industry,
            data = est, cluster = ~state_abbr)
cat("\n--- Model 1: Simple DiD ---\n")
summary(m1)

# ---- Model 2: DD with race interaction ----
m2 <- feols(sep_rate ~ post + post:black | state_abbr + yq + industry + race,
            data = est, cluster = ~state_abbr)
cat("\n--- Model 2: DD with race interaction ---\n")
summary(m2)

# ---- Model 3: DDD (ban × post × knowledge sector) ----
# Knowledge = NAICS 51/54 (high NCA prevalence)
# Placebo = NAICS 72 (low NCA prevalence)
m3 <- feols(sep_rate ~ post:knowledge | state_abbr^industry + yq^industry + state_abbr^yq,
            data = est, cluster = ~state_abbr)
cat("\n--- Model 3: DDD ---\n")
summary(m3)

# ---- Model 4: Full DDDD (ban × post × knowledge × black) ----
# This is the key specification: differential effect for Black workers
# in knowledge sectors in ban states after ban
m4 <- feols(sep_rate ~ post:knowledge + post:knowledge:black + post:black +
              knowledge:black |
              state_abbr^industry^race + yq^industry^race + state_abbr^yq^race,
            data = est, cluster = ~state_abbr)
cat("\n--- Model 4: DDDD (key specification) ---\n")
summary(m4)

# ---- Model 5: Earnings (log) ----
m5_earn <- feols(log_earn ~ post:knowledge + post:knowledge:black + post:black +
                   knowledge:black |
                   state_abbr^industry^race + yq^industry^race + state_abbr^yq^race,
                 data = est, cluster = ~state_abbr)
cat("\n--- Model 5: Log earnings DDDD ---\n")
summary(m5_earn)

# ---- Model 6: Hire rate ----
m6_hire <- feols(hire_rate ~ post:knowledge + post:knowledge:black + post:black +
                   knowledge:black |
                   state_abbr^industry^race + yq^industry^race + state_abbr^yq^race,
                 data = est, cluster = ~state_abbr)
cat("\n--- Model 6: Hire rate DDDD ---\n")
summary(m6_hire)

# ---- Wild cluster bootstrap (5 treatment states) ----
cat("\n=== Wild Cluster Bootstrap for key coefficient ===\n")
# WCB needs simpler FE specification (no ^ notation)
# Use explicit interaction dummies
est_wcb <- copy(est)
est_wcb[, st_ind_race := paste(state_abbr, industry, race, sep = "_")]
est_wcb[, yq_ind_race := paste(yq, industry, race, sep = "_")]
est_wcb[, st_yq_race := paste(state_abbr, yq, race, sep = "_")]
m5_wcb <- feols(log_earn ~ post:knowledge + post:knowledge:black + post:black +
                  knowledge:black |
                  st_ind_race + yq_ind_race + st_yq_race,
                data = est_wcb, cluster = ~state_abbr)
tryCatch({
  boot_res <- boottest(m5_wcb, param = "postTRUE:knowledgeTRUE:black",
                       clustid = "state_abbr",
                       B = 9999, type = "webb")
  cat("WCB p-value (earnings, Black×Knowledge):", boot_res$p_val, "\n")
  cat("WCB 95% CI:", boot_res$conf_int, "\n")
  saveRDS(boot_res, "../data/wcb_results.rds")
}, error = function(e) {
  cat("WCB failed:", conditionMessage(e), "\n")
  cat("Falling back to cluster-robust SEs (reported above)\n")
})

# ---- Event study: descriptive means by period ----
cat("\n=== Descriptive Event Study ===\n")
# With staggered treatment, compute mean separation rates by period and group
es_means <- est[knowledge == TRUE, .(
  sep_black_ban = mean(sep_rate[black == 1 & ban_state == TRUE], na.rm = TRUE),
  sep_white_ban = mean(sep_rate[black == 0 & ban_state == TRUE], na.rm = TRUE),
  sep_black_ctrl = mean(sep_rate[black == 1 & ban_state == FALSE], na.rm = TRUE),
  sep_white_ctrl = mean(sep_rate[black == 0 & ban_state == FALSE], na.rm = TRUE)
), by = yq]
es_means[, gap_ban := sep_black_ban - sep_white_ban]
es_means[, gap_ctrl := sep_black_ctrl - sep_white_ctrl]
es_means[, ddd := gap_ban - gap_ctrl]
setorder(es_means, yq)
cat("Racial sep-rate gap in knowledge sectors (ban vs control):\n")
print(es_means[, .(yq, gap_ban = round(gap_ban, 4), gap_ctrl = round(gap_ctrl, 4),
                    ddd = round(ddd, 4))])
saveRDS(es_means, "../data/event_study_means.rds")

# ---- Save results ----
results <- list(
  m1_did = coeftable(m1),
  m2_race = coeftable(m2),
  m3_ddd = coeftable(m3),
  m4_dddd = coeftable(m4),
  m5_earn = coeftable(m5_earn),
  m6_hire = coeftable(m6_hire)
)
saveRDS(results, "../data/main_results.rds")
saveRDS(list(m1 = m1, m2 = m2, m3 = m3, m4 = m4, m5 = m5_earn, m6 = m6_hire),
        "../data/model_objects.rds")

# ---- Diagnostics for validator ----
# Count treated state-industry-race cells (the unit of variation in DDDD)
n_treated <- uniqueN(est[ban_state == TRUE & post == TRUE,
                         paste(state_abbr, industry, race)])
n_pre <- uniqueN(est[year < 2020, yq])
n_obs <- nrow(est)
write_json(list(n_treated = n_treated, n_pre = n_pre, n_obs = n_obs),
           "../data/diagnostics.json", auto_unbox = TRUE)
cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            n_treated, n_pre, n_obs))
cat("Main analysis complete.\n")
