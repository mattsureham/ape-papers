## ── 04_robustness.R ────────────────────────────────────────────
## Robustness checks and placebo tests
## ────────────────────────────────────────────────────────────────

source("00_packages.R")

out_dir <- "../data"
panel <- readRDS(file.path(out_dir, "panel.rds"))

## ── 1. Placebo test: fake treatment in 2013 ───────────────────
pre_panel <- panel[year <= 2014]
pre_panel[, fake_post := as.integer(year >= 2013)]
pre_panel[, fake_treat := log(mining_emp + 1) * fake_post]

placebo <- feols(log_light ~ fake_treat | dist_id + year, data = pre_panel, cluster = ~state_id)
cat("=== Placebo (2013 fake treatment) ===\n")
print(summary(placebo))

## ── 2. Drop top 10% mining districts (extreme values) ─────────
q90 <- quantile(panel[is_mining == 1, unique(mining_emp), by = dist_id]$V1, 0.90)
panel_trimmed <- panel[mining_emp <= q90 | is_mining == 0]
trim <- feols(log_light ~ treat_log | dist_id + year, data = panel_trimmed, cluster = ~state_id)
cat("\n=== Trimmed (drop top 10% mining) ===\n")
print(summary(trim))

## ── 3. Alternative outcome: total light (sum, not mean) ───────
panel[, log_total_light := log(viirs_annual_sum + 1)]
alt_outcome <- feols(log_total_light ~ treat_log | dist_id + year, data = panel, cluster = ~state_id)
cat("\n=== Alternative outcome: total light ===\n")
print(summary(alt_outcome))

## ── 4. Top 6 mining states only (Odisha, Chhattisgarh, etc.) ──
# State IDs for major mining states:
# Odisha=21, Jharkhand=20, Chhattisgarh=22, Rajasthan=08, MP=23, Telangana=36
top_mining_states <- c(21, 20, 22, 8, 23, 36)
panel_top <- panel[state_id %in% top_mining_states]
top_states <- feols(log_light ~ treat_log | dist_id + year, data = panel_top, cluster = ~state_id)
cat("\n=== Top 6 mining states only ===\n")
print(summary(top_states))

## ── 5. Bordering districts placebo ─────────────────────────────
# Districts with zero mining employment but in states that have mining
mining_states <- unique(panel[is_mining == 1]$state_id)
spillover_panel <- panel[state_id %in% mining_states]
spillover_panel[, border_treat := as.integer(is_mining == 0 & state_id %in% mining_states) * post]
spillover <- feols(log_light ~ border_treat | dist_id + year, data = spillover_panel, cluster = ~state_id)
cat("\n=== Spillover to non-mining districts in mining states ===\n")
print(summary(spillover))

## ── Save robustness results ────────────────────────────────────
saveRDS(list(placebo = placebo, trim = trim, alt_outcome = alt_outcome,
             top_states = top_states, spillover = spillover),
        file.path(out_dir, "robustness_results.rds"))

cat("\nRobustness checks complete.\n")
