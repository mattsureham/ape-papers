# 04_robustness.R — Robustness checks and placebo tests

library(tidyverse)
library(fixest)
library(did)

data_dir <- file.path(dirname(getwd()), "data")
load(file.path(data_dir, "analysis_panel.RData"))
load(file.path(data_dir, "main_results.RData"))

# ============================================================
# 1. Placebo outcome: Auto repair shops (NAICS 811111)
# ============================================================
cat("=== Placebo: Auto Repair Shops ===\n")
placebo_repair <- feols(log_estab ~ post | state_fips + year,
                        data = auto_repair_panel,
                        cluster = ~state_fips)
cat("Auto repair log estab:", round(coef(placebo_repair)["post"], 4),
    "(SE:", round(se(placebo_repair)["post"], 4), ")\n")

# ============================================================
# 2. Placebo outcome: Auto parts stores (NAICS 441310)
# ============================================================
cat("\n=== Placebo: Auto Parts Stores ===\n")
placebo_parts <- feols(log_estab ~ post | state_fips + year,
                       data = auto_parts_panel,
                       cluster = ~state_fips)
cat("Auto parts log estab:", round(coef(placebo_parts)["post"], 4),
    "(SE:", round(se(placebo_parts)["post"], 4), ")\n")

# ============================================================
# 3. Leave-one-out: Drop Texas (first mover, 2021)
# ============================================================
cat("\n=== Leave-One-Out: Drop Texas ===\n")
panel_no_tx <- panel %>% filter(state_fips != "48")
loo_tx <- feols(log_estab ~ post | state_fips + year,
                data = panel_no_tx,
                cluster = ~state_fips)
cat("Without TX:", round(coef(loo_tx)["post"], 4),
    "(SE:", round(se(loo_tx)["post"], 4), ")\n")

# ============================================================
# 4. Leave-one-out: Drop California (largest state)
# ============================================================
cat("\n=== Leave-One-Out: Drop California ===\n")
# CA treatment is 2024, so it's in the never-treated group for 2017-2023
panel_no_ca <- panel %>% filter(state_fips != "06")
loo_ca <- feols(log_estab ~ post | state_fips + year,
                data = panel_no_ca,
                cluster = ~state_fips)
cat("Without CA:", round(coef(loo_ca)["post"], 4),
    "(SE:", round(se(loo_ca)["post"], 4), ")\n")

# ============================================================
# 5. Employment outcome (robustness)
# ============================================================
cat("\n=== Employment Robustness ===\n")
rob_emp <- feols(log_emp ~ post | state_fips + year,
                 data = panel,
                 cluster = ~state_fips)
cat("Log employment:", round(coef(rob_emp)["post"], 4),
    "(SE:", round(se(rob_emp)["post"], 4), ")\n")

# ============================================================
# 6. Wild cluster bootstrap (for inference with 50 clusters)
# ============================================================
cat("\n=== Wild Cluster Bootstrap ===\n")
# Use fixest's built-in bootstrap
boot_estab <- feols(log_estab ~ post | state_fips + year,
                    data = panel,
                    cluster = ~state_fips)

# Get bootstrapped p-value using fixest
boot_pval <- pvalue(boot_estab, type = "cluster")
cat("Cluster-robust p-value for post:", round(boot_pval["post"], 4), "\n")

# ============================================================
# 7. Levels specification (not logs)
# ============================================================
cat("\n=== Levels Specification ===\n")
levels_estab <- feols(estab ~ post | state_fips + year,
                      data = panel,
                      cluster = ~state_fips)
cat("Establishments (levels):", round(coef(levels_estab)["post"], 2),
    "(SE:", round(se(levels_estab)["post"], 2), ")\n")

# ============================================================
# Save all robustness results
# ============================================================
save(placebo_repair, placebo_parts, loo_tx, loo_ca,
     rob_emp, boot_estab, levels_estab,
     file = file.path(data_dir, "robustness_results.RData"))
cat("\nRobustness results saved.\n")
