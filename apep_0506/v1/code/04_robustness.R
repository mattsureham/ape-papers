## =============================================================================
## 04_robustness.R — Robustness checks for RDD
## Paper: Does Candidate Wealth Buy Development?
## =============================================================================

source("00_packages.R")

data_dir <- "../data"

## =============================================================================
## Load data
## =============================================================================

rdd <- fread(file.path(data_dir, "rdd_analysis.csv"))
cat("Loaded:", nrow(rdd), "constituency-elections\n")

## Create key variables
rdd[, winner_log_assets := ifelse(rich_won == 1, log_rich_assets, log_poor_assets)]
rdd[, reserved := as.integer(ac_type != "GEN" & ac_type != "")]

## =============================================================================
## PART 1: Placebo Cutoff Tests
## =============================================================================

cat("\n=== Placebo Cutoff Tests ===\n")
cat("Testing at false cutoffs where no discontinuity should exist\n")

placebo_cutoffs <- c(-10, -5, -3, -2, 2, 3, 5, 10)
placebo_results <- list()

for (pc in placebo_cutoffs) {
  tryCatch({
    rdd_pc <- rdrobust(rdd$winner_log_assets, rdd$rich_margin, c = pc)
    placebo_results[[as.character(pc)]] <- data.table(
      cutoff = pc,
      estimate = rdd_pc$coef[3],
      se = rdd_pc$se[3],
      p_value = rdd_pc$pv[3],
      n_eff = rdd_pc$N_h[1] + rdd_pc$N_h[2]
    )
    cat(sprintf("  Cutoff %+3d%%: est = %7.4f, p = %.4f, N = %d\n",
                pc, rdd_pc$coef[3], rdd_pc$pv[3], rdd_pc$N_h[1] + rdd_pc$N_h[2]))
  }, error = function(e) {
    cat(sprintf("  Cutoff %+3d%%: FAILED (%s)\n", pc, e$message))
  })
}

placebo_table <- rbindlist(placebo_results)
## Add the true cutoff
true_rdd <- rdrobust(rdd$winner_log_assets, rdd$rich_margin, c = 0)
placebo_table <- rbind(
  placebo_table,
  data.table(cutoff = 0, estimate = true_rdd$coef[3], se = true_rdd$se[3],
             p_value = true_rdd$pv[3], n_eff = true_rdd$N_h[1] + true_rdd$N_h[2])
)
placebo_table <- placebo_table[order(cutoff)]
fwrite(placebo_table, file.path(data_dir, "placebo_cutoffs.csv"))

cat("\nPlacebo test summary:\n")
cat("  True cutoff (0) p-value:", round(placebo_table[cutoff == 0]$p_value, 4), "\n")
cat("  Placebo cutoffs with p < 0.05:",
    sum(placebo_table[cutoff != 0]$p_value < 0.05), "out of",
    nrow(placebo_table[cutoff != 0]), "\n")

## =============================================================================
## PART 2: Polynomial Order Sensitivity
## =============================================================================

cat("\n=== Polynomial Order Sensitivity ===\n")

poly_results <- list()
for (p in 1:3) {
  tryCatch({
    rdd_p <- rdrobust(rdd$winner_log_assets, rdd$rich_margin, c = 0, p = p)
    poly_results[[as.character(p)]] <- data.table(
      poly_order = p,
      estimate = rdd_p$coef[3],
      se = rdd_p$se[3],
      p_value = rdd_p$pv[3],
      bandwidth = rdd_p$bws[1, 1],
      n_eff = rdd_p$N_h[1] + rdd_p$N_h[2]
    )
    cat(sprintf("  Order %d: est = %.4f (se = %.4f), bw = %.2f, N = %d\n",
                p, rdd_p$coef[3], rdd_p$se[3], rdd_p$bws[1, 1],
                rdd_p$N_h[1] + rdd_p$N_h[2]))
  }, error = function(e) {
    cat(sprintf("  Order %d: FAILED (%s)\n", p, e$message))
  })
}

poly_table <- rbindlist(poly_results)
fwrite(poly_table, file.path(data_dir, "polynomial_sensitivity.csv"))

## =============================================================================
## PART 3: Donut RDD (Exclude Closest Observations)
## =============================================================================

cat("\n=== Donut RDD ===\n")

donut_sizes <- c(0.5, 1, 2, 3)
donut_results <- list()

for (d in donut_sizes) {
  rdd_donut <- rdd[abs(rich_margin) >= d]
  tryCatch({
    rdd_d <- rdrobust(rdd_donut$winner_log_assets, rdd_donut$rich_margin, c = 0)
    donut_results[[as.character(d)]] <- data.table(
      donut = d,
      estimate = rdd_d$coef[3],
      se = rdd_d$se[3],
      p_value = rdd_d$pv[3],
      n_eff = rdd_d$N_h[1] + rdd_d$N_h[2],
      n_excluded = nrow(rdd) - nrow(rdd_donut)
    )
    cat(sprintf("  Donut ±%.1f%%: est = %.4f (se = %.4f), excluded = %d obs\n",
                d, rdd_d$coef[3], rdd_d$se[3], nrow(rdd) - nrow(rdd_donut)))
  }, error = function(e) {
    cat(sprintf("  Donut ±%.1f%%: FAILED (%s)\n", d, e$message))
  })
}

donut_table <- rbindlist(donut_results)
fwrite(donut_table, file.path(data_dir, "donut_rdd.csv"))

## =============================================================================
## PART 4: Alternative Wealth Measures
## =============================================================================

cat("\n=== Alternative Wealth Measures ===\n")

## Outcome: Wealth ratio (instead of log difference)
cat("--- Using log wealth ratio ---\n")
rdd[, winner_wealth_ratio := ifelse(rich_won == 1, wealth_ratio, 1 / wealth_ratio)]
rdd_ratio <- rdrobust(log(rdd$winner_wealth_ratio + 1), rdd$rich_margin, c = 0)
cat("  Robust estimate:", round(rdd_ratio$coef[3], 4),
    "  p-value:", round(rdd_ratio$pv[3], 4), "\n")

## Outcome: Net worth instead of total assets
cat("--- Using net worth ---\n")
rdd[, rich_net := ifelse(c1_wealthier, net_worth_c1, net_worth_c2)]
rdd[, poor_net := ifelse(c1_wealthier, net_worth_c2, net_worth_c1)]
rdd[, winner_net_worth := ifelse(rich_won == 1, rich_net, poor_net)]
## Handle negative net worth with asinh transformation
rdd_net <- rdrobust(asinh(rdd$winner_net_worth), rdd$rich_margin, c = 0)
cat("  Robust estimate:", round(rdd_net$coef[3], 4),
    "  p-value:", round(rdd_net$pv[3], 4), "\n")

## Outcome: Movable assets only
cat("--- Using movable assets only ---\n")
rdd[, rich_movable := ifelse(c1_wealthier, movable_self_c1, movable_self_c2)]
rdd[, poor_movable := ifelse(c1_wealthier, movable_self_c2, movable_self_c1)]
rdd[, winner_movable := ifelse(rich_won == 1, rich_movable, poor_movable)]
rdd_mov <- rdrobust(log(pmax(rdd$winner_movable, 1)), rdd$rich_margin, c = 0)
cat("  Robust estimate:", round(rdd_mov$coef[3], 4),
    "  p-value:", round(rdd_mov$pv[3], 4), "\n")

## Outcome: Immovable assets only
cat("--- Using immovable assets only ---\n")
rdd[, rich_immovable := ifelse(c1_wealthier, immovable_self_c1, immovable_self_c2)]
rdd[, poor_immovable := ifelse(c1_wealthier, immovable_self_c2, immovable_self_c1)]
rdd[, winner_immovable := ifelse(rich_won == 1, rich_immovable, poor_immovable)]
rdd_imm <- rdrobust(log(pmax(rdd$winner_immovable, 1)), rdd$rich_margin, c = 0)
cat("  Robust estimate:", round(rdd_imm$coef[3], 4),
    "  p-value:", round(rdd_imm$pv[3], 4), "\n")

alt_wealth <- data.table(
  measure = c("Log total assets (baseline)", "Log wealth ratio",
              "Asinh net worth", "Log movable assets", "Log immovable assets"),
  estimate = c(true_rdd$coef[3], rdd_ratio$coef[3], rdd_net$coef[3],
               rdd_mov$coef[3], rdd_imm$coef[3]),
  se = c(true_rdd$se[3], rdd_ratio$se[3], rdd_net$se[3],
         rdd_mov$se[3], rdd_imm$se[3]),
  p_value = c(true_rdd$pv[3], rdd_ratio$pv[3], rdd_net$pv[3],
              rdd_mov$pv[3], rdd_imm$pv[3])
)
fwrite(alt_wealth, file.path(data_dir, "alt_wealth_measures.csv"))

## =============================================================================
## PART 5: Subsample Stability
## =============================================================================

cat("\n=== Subsample Stability ===\n")

## By major states
big_states <- rdd[, .N, by = state][N >= 100]$state
cat("States with 100+ observations:", length(big_states), "\n")

state_results <- list()
for (st in sort(big_states)) {
  rdd_st <- rdd[state == st]
  tryCatch({
    rdd_s <- rdrobust(rdd_st$winner_log_assets, rdd_st$rich_margin, c = 0)
    state_results[[st]] <- data.table(
      state = st, estimate = rdd_s$coef[3], se = rdd_s$se[3],
      p_value = rdd_s$pv[3], n = nrow(rdd_st)
    )
    cat(sprintf("  %-20s: est = %7.4f, p = %.4f, N = %d\n",
                st, rdd_s$coef[3], rdd_s$pv[3], nrow(rdd_st)))
  }, error = function(e) {
    cat(sprintf("  %-20s: FAILED (%s)\n", st, e$message))
  })
}

state_table <- rbindlist(state_results)
fwrite(state_table, file.path(data_dir, "state_subsample.csv"))

## By early vs late period
cat("\n--- By Period ---\n")
rdd_early <- rdd[year <= 2008]
rdd_late  <- rdd[year > 2008]

tryCatch({
  m_early <- rdrobust(rdd_early$winner_log_assets, rdd_early$rich_margin, c = 0)
  cat(sprintf("  2004-2008: est = %.4f, p = %.4f, N = %d\n",
              m_early$coef[3], m_early$pv[3], m_early$N_h[1] + m_early$N_h[2]))
}, error = function(e) cat("  2004-2008: FAILED\n"))

tryCatch({
  m_late <- rdrobust(rdd_late$winner_log_assets, rdd_late$rich_margin, c = 0)
  cat(sprintf("  2009-2013: est = %.4f, p = %.4f, N = %d\n",
              m_late$coef[3], m_late$pv[3], m_late$N_h[1] + m_late$N_h[2]))
}, error = function(e) cat("  2009-2013: FAILED\n"))

## =============================================================================
## PART 6: Controlling for Confounders
## =============================================================================

cat("\n=== Controlling for Confounders ===\n")

opt_bw <- true_rdd$bws[1, 1]
rdd_bw <- rdd[abs(rich_margin) <= opt_bw]

## Baseline
m_base <- feols(winner_log_assets ~ rich_won + rich_margin + rich_won:rich_margin | state + year,
                data = rdd_bw, vcov = "HC1")

## Control for criminal cases
rdd_bw[, winner_criminal := ifelse(rich_won == 1, rich_criminal, poor_criminal)]
m_crim <- feols(winner_log_assets ~ rich_won + rich_margin + rich_won:rich_margin +
                  rich_criminal + poor_criminal | state + year,
                data = rdd_bw, vcov = "HC1")

## Control for age
m_age <- feols(winner_log_assets ~ rich_won + rich_margin + rich_won:rich_margin +
                 rich_age + poor_age | state + year,
               data = rdd_bw, vcov = "HC1")

## Control for reservation status
m_res <- feols(winner_log_assets ~ rich_won + rich_margin + rich_won:rich_margin +
                 reserved | state + year,
               data = rdd_bw, vcov = "HC1")

## All controls
rdd_bw[, reserved := as.integer(ac_type != "GEN" & ac_type != "")]
m_all <- feols(winner_log_assets ~ rich_won + rich_margin + rich_won:rich_margin +
                 rich_criminal + poor_criminal + rich_age + poor_age + reserved | state + year,
               data = rdd_bw, vcov = "HC1")

cat("\nConfounders comparison:\n")
etable(m_base, m_crim, m_age, m_res, m_all,
       headers = c("Baseline", "+ Criminal", "+ Age", "+ Reserved", "All"),
       keep = "rich_won",
       fitstat = c("n", "r2"))

## =============================================================================
## PART 7: Alternative Kernel and Bandwidth Selection
## =============================================================================

cat("\n=== Alternative Kernel/Bandwidth ===\n")

## Triangular kernel (default)
m_tri <- rdrobust(rdd$winner_log_assets, rdd$rich_margin, c = 0, kernel = "tri")
cat("Triangular kernel:", round(m_tri$coef[3], 4), "  p =", round(m_tri$pv[3], 4), "\n")

## Uniform kernel
m_uni <- rdrobust(rdd$winner_log_assets, rdd$rich_margin, c = 0, kernel = "uni")
cat("Uniform kernel:", round(m_uni$coef[3], 4), "  p =", round(m_uni$pv[3], 4), "\n")

## Epanechnikov kernel
m_epa <- rdrobust(rdd$winner_log_assets, rdd$rich_margin, c = 0, kernel = "epa")
cat("Epanechnikov kernel:", round(m_epa$coef[3], 4), "  p =", round(m_epa$pv[3], 4), "\n")

## Half bandwidth
m_half <- rdrobust(rdd$winner_log_assets, rdd$rich_margin, c = 0,
                   h = opt_bw / 2, b = opt_bw)
cat("Half bandwidth:", round(m_half$coef[3], 4), "  p =", round(m_half$pv[3], 4), "\n")

## Double bandwidth
m_dbl <- rdrobust(rdd$winner_log_assets, rdd$rich_margin, c = 0,
                  h = opt_bw * 2, b = opt_bw * 2)
cat("Double bandwidth:", round(m_dbl$coef[3], 4), "  p =", round(m_dbl$pv[3], 4), "\n")

kernel_bw <- data.table(
  specification = c("Triangular (baseline)", "Uniform", "Epanechnikov",
                     "Half bandwidth", "Double bandwidth"),
  estimate = c(m_tri$coef[3], m_uni$coef[3], m_epa$coef[3],
               m_half$coef[3], m_dbl$coef[3]),
  se = c(m_tri$se[3], m_uni$se[3], m_epa$se[3],
         m_half$se[3], m_dbl$se[3]),
  p_value = c(m_tri$pv[3], m_uni$pv[3], m_epa$pv[3],
              m_half$pv[3], m_dbl$pv[3])
)
fwrite(kernel_bw, file.path(data_dir, "kernel_bandwidth.csv"))

## =============================================================================
## PART 8: Wealth Premium Analysis (Is Being Wealthier an Advantage?)
## =============================================================================

cat("\n=== Wealth Premium Analysis ===\n")

## Does the wealthier candidate win more often than 50%?
cat("Overall wealth premium:", round(mean(rdd$rich_won) * 100, 2), "%\n")

## Test against 50%
binom_test <- binom.test(sum(rdd$rich_won), nrow(rdd), p = 0.5)
cat("Binomial test against 50%: p =", formatC(binom_test$p.value, format = "e", digits = 3), "\n")
cat("95% CI:", round(binom_test$conf.int[1] * 100, 2), "to",
    round(binom_test$conf.int[2] * 100, 2), "%\n")

## Wealth premium by margin bin
cat("\nWealth premium by margin proximity:\n")
bins <- c(1, 2, 3, 5, 10, 20, 50)
for (b in bins) {
  sub <- rdd[abs(rich_margin) <= b]
  if (nrow(sub) < 10) next
  wp <- mean(sub$rich_won) * 100
  ci <- binom.test(sum(sub$rich_won), nrow(sub), p = 0.5)
  cat(sprintf("  |margin| <= %2d%%: %.1f%% (N = %d, p = %.4f)\n",
              b, wp, nrow(sub), ci$p.value))
}

cat("\n=== Robustness checks complete ===\n")
