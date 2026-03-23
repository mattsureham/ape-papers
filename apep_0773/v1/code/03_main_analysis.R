# ============================================================
# 03_main_analysis.R — DiD analysis
# apep_0773: Collateral Damage
# ============================================================

source("00_packages.R")
library(fixest)
library(data.table)

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))

# ----------------------------------------------------------
# 1. Main DiD: SNAP rate ~ integrated × post_unwinding
# ----------------------------------------------------------
cat("=== Main DiD: SNAP Rate ===\n")

did_rate <- feols(snap_rate_pct ~ integrated:post_unwinding + post_ea |
                    state + time_id,
                  data = panel, cluster = ~state)
cat("  SNAP rate:\n")
print(summary(did_rate))

# ----------------------------------------------------------
# 2. DiD: Log SNAP households
# ----------------------------------------------------------
cat("\n=== DiD: Log SNAP HH ===\n")

did_ln <- feols(ln_snap ~ integrated:post_unwinding + post_ea |
                  state + time_id,
                data = panel, cluster = ~state)
cat("  Log SNAP HH:\n")
print(summary(did_ln))

# ----------------------------------------------------------
# 3. Triple-diff: integrated × post_unwinding × high_proc
# ----------------------------------------------------------
cat("\n=== Triple-Diff: High Procedural Burden ===\n")

did_triple <- feols(snap_rate_pct ~ integrated:post_unwinding +
                      integrated:post_unwinding:high_proc + post_ea |
                      state + time_id,
                    data = panel, cluster = ~state)
cat("  Triple-diff:\n")
print(summary(did_triple))

# ----------------------------------------------------------
# 4. Continuous treatment intensity
# ----------------------------------------------------------
cat("\n=== Continuous: Procedural Rate Interaction ===\n")

did_cont <- feols(snap_rate_pct ~ post_unwinding:proc_term_rate + post_ea |
                    state + time_id,
                  data = panel, cluster = ~state)
cat("  Continuous:\n")
print(summary(did_cont))

# ----------------------------------------------------------
# 5. Save results
# ----------------------------------------------------------
saveRDS(did_rate, file.path(data_dir, "did_rate.rds"))
saveRDS(did_ln, file.path(data_dir, "did_ln.rds"))
saveRDS(did_triple, file.path(data_dir, "did_triple.rds"))
saveRDS(did_cont, file.path(data_dir, "did_cont.rds"))

# ----------------------------------------------------------
# 6. Diagnostics
# ----------------------------------------------------------
diagnostics <- list(
  n_treated = sum(panel$integrated == 1 & !duplicated(panel$state)),
  n_pre = sum(panel$post_unwinding == 0 & !duplicated(panel$time_id)),
  n_obs = nrow(panel),
  n_states = length(unique(panel$state)),
  outcome_sd_pre = sd(panel[post_unwinding == 0]$snap_rate_pct, na.rm = TRUE),
  outcome_mean_pre = mean(panel[post_unwinding == 0]$snap_rate_pct, na.rm = TRUE)
)

jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                     auto_unbox = TRUE, pretty = TRUE)

cat("\n  n_treated:", diagnostics$n_treated, "\n")
cat("  n_pre:", diagnostics$n_pre, "\n")
cat("  n_obs:", diagnostics$n_obs, "\n")

cat("\n=== Analysis complete ===\n")
