# 04_robustness.R — Robustness checks for Alice Corp study

library(data.table)
library(fixest)
library(dplyr)

args <- commandArgs(trailingOnly = FALSE)
script_dir <- dirname(sub("--file=", "", args[grep("--file=", args)]))
if (length(script_dir) == 0) script_dir <- "code"
setwd(file.path(script_dir, ".."))

panel <- readRDS("data/analysis_panel.rds")
results <- readRDS("data/results.rds")

tc36 <- panel %>% filter(tc == "TC3600", total_actions > 0) %>%
  mutate(log_total = log(total_actions + 1))

# ============================================================
# R1: Binary treatment (high shock >20pp vs low shock <5pp)
# ============================================================
tc36_binary <- tc36 %>% filter(alice_shock > 0.20 | alice_shock < 0.05) %>%
  mutate(treated = ifelse(alice_shock > 0.20, 1L, 0L),
         treat_x_post = treated * post_alice)

r1 <- feols(s101_rate ~ treat_x_post | art_unit + quarter, data = tc36_binary,
            cluster = ~art_unit)

cat("=== R1: Binary treatment (>20pp vs <5pp) ===\n")
etable(r1, se.below = TRUE)

# ============================================================
# R2: Drop 2014Q3 transition quarter
# ============================================================
tc36_notrans <- tc36 %>% filter(quarter != "2014Q3")
r2 <- feols(s101_rate ~ shock_x_post | art_unit + quarter, data = tc36_notrans,
            cluster = ~art_unit)

cat("\n=== R2: Drop transition quarter ===\n")
etable(r2, se.below = TRUE)

# ============================================================
# R3: Leave-one-out (drop each art unit)
# ============================================================
aus <- unique(tc36$art_unit)
loo_coefs <- numeric(length(aus))
for (i in seq_along(aus)) {
  d_loo <- tc36 %>% filter(art_unit != aus[i])
  fit_loo <- feols(s101_rate ~ shock_x_post | art_unit + quarter, data = d_loo,
                   cluster = ~art_unit)
  loo_coefs[i] <- coef(fit_loo)["shock_x_post"]
}
cat("\n=== R3: Leave-one-out ===\n")
cat("  Main coef:", round(coef(results$m1)["shock_x_post"], 4), "\n")
cat("  LOO range:", round(min(loo_coefs), 4), "to", round(max(loo_coefs), 4), "\n")
cat("  LOO mean: ", round(mean(loo_coefs), 4), "\n")

# ============================================================
# R4: Alternative clustering (quarterly)
# ============================================================
r4 <- feols(s101_rate ~ shock_x_post | art_unit + quarter, data = tc36,
            cluster = ~quarter)

cat("\n=== R4: Cluster by quarter ===\n")
etable(r4, se.below = TRUE)

# ============================================================
# R5: Weighted by pre-period action volume
# ============================================================
# Use pre-period total actions as weight
tc36_w <- tc36 %>%
  mutate(weight = as.numeric(pre_total)) %>%
  filter(!is.na(weight) & weight > 0)
r5 <- feols(s101_rate ~ shock_x_post | art_unit + quarter, data = tc36_w,
            weights = ~weight, cluster = ~art_unit)

cat("\n=== R5: Weighted by pre-period volume ===\n")
etable(r5, se.below = TRUE)

# ============================================================
# R6: §103 placebo (full analysis)
# ============================================================
r6_shock <- feols(s103_rate ~ shock_x_post | art_unit + quarter, data = tc36,
                  cluster = ~art_unit)
# Also: §103 rate regressed on §103 shock × post (positive control)
tc36$s103_x_post <- tc36$s103_shock * tc36$post_alice
r6_own <- feols(s103_rate ~ s103_x_post | art_unit + quarter, data = tc36,
                cluster = ~art_unit)

cat("\n=== R6: §103 placebo ===\n")
cat("Alice shock → §103 rate (should be null):\n")
etable(r6_shock, se.below = TRUE)
cat("§103 shock → §103 rate (positive control):\n")
etable(r6_own, se.below = TRUE)

# ============================================================
# Save robustness results
# ============================================================
rob <- list(
  r1_binary = r1,
  r2_notrans = r2,
  r3_loo_coefs = loo_coefs,
  r3_loo_mean = mean(loo_coefs),
  r3_loo_range = range(loo_coefs),
  r4_cluster_q = r4,
  r5_weighted = r5,
  r6_placebo = r6_shock,
  r6_positive = r6_own,
  n_binary_treated = sum(tc36_binary$treated == 1) / 20,
  n_binary_control = sum(tc36_binary$treated == 0) / 20
)
saveRDS(rob, "data/robustness.rds")
cat("\nSaved robustness results to data/robustness.rds\n")
