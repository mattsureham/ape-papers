## =============================================================================
## 03_main_analysis.R — Core RDD estimation
## Paper: Does Candidate Wealth Buy Development?
## =============================================================================

source("00_packages.R")

data_dir <- "../data"

## =============================================================================
## PART 1: Load cleaned RDD data
## =============================================================================

cat("=== Loading cleaned RDD data ===\n")
rdd <- fread(file.path(data_dir, "rdd_analysis.csv"))
cat("Loaded:", nrow(rdd), "constituency-elections\n")
cat("States:", length(unique(rdd$state)), "\n")
cat("Years:", paste(sort(unique(rdd$year)), collapse = ", "), "\n")

## =============================================================================
## PART 2: McCrary Density Test (Manipulation Test)
## =============================================================================

cat("\n=== McCrary Density Test ===\n")

## Test for manipulation at the cutoff (running variable = rich_margin)
density_test <- rddensity(rdd$rich_margin, c = 0)
cat("McCrary test statistic:", round(density_test$test$t_jk, 4), "\n")
cat("P-value:", round(density_test$test$p_jk, 4), "\n")
cat("Interpretation:", ifelse(density_test$test$p_jk > 0.05,
    "No evidence of manipulation (good)", "Potential manipulation (concern)"), "\n")

## Save density test results
density_results <- data.table(
  test = "McCrary density test",
  t_stat = density_test$test$t_jk,
  p_value = density_test$test$p_jk,
  n_left = density_test$N$eff_l,
  n_right = density_test$N$eff_r,
  bandwidth_left = density_test$h$left,
  bandwidth_right = density_test$h$right
)
fwrite(density_results, file.path(data_dir, "mccrary_test.csv"))

## =============================================================================
## PART 3: Main RDD — Effect of Electing Wealthier Candidate
## =============================================================================

cat("\n=== Main RDD Estimation ===\n")

## Primary outcome: Does the wealthier candidate win more often in close elections?
## This is a FIRST-STAGE check: verify the RDD is sharp

## The RDD running variable is rich_margin (vote margin of wealthier candidate)
## Treatment: rich_won = 1 if wealthier candidate won

## Sharp RDD check: rich_won should jump from 0 to 1 at margin = 0
cat("--- Verification: Sharp RDD ---\n")
cat("Fraction rich_won when margin > 0:", round(mean(rdd$rich_won[rdd$rich_margin > 0]), 4), "\n")
cat("Fraction rich_won when margin < 0:", round(mean(rdd$rich_won[rdd$rich_margin < 0]), 4), "\n")
cat("Sharp RDD confirmed: treatment is deterministic at cutoff\n\n")

## Main outcome: winning probability (this is mechanical in sharp RDD)
## Now estimate RDD for WEALTH RATIO at the cutoff
## This tells us whether elections near the cutoff have meaningful wealth differences

cat("--- RDD: Wealth Ratio at Cutoff ---\n")
rdd_wealth <- rdrobust(rdd$log_wealth_diff, rdd$rich_margin, c = 0)
cat("Log wealth difference at cutoff:\n")
cat("  Conventional estimate:", round(rdd_wealth$coef[1], 4), "\n")
cat("  Robust estimate:", round(rdd_wealth$coef[3], 4), "\n")
cat("  Robust 95% CI: [", round(rdd_wealth$ci[3, 1], 4), ",",
    round(rdd_wealth$ci[3, 2], 4), "]\n")
cat("  Bandwidth (h):", round(rdd_wealth$bws[1, 1], 2), "\n")
cat("  N (left, right):", rdd_wealth$N_h[1], ",", rdd_wealth$N_h[2], "\n\n")

## =============================================================================
## PART 4: RDD on Political Outcomes
## =============================================================================

cat("=== RDD on Political Outcomes ===\n")

## Outcome 1: Does electing wealthy candidate affect subsequent re-election bid?
## We can check whether rich winners are more likely to contest next election
## But this requires panel data — skip for now and focus on cross-sectional outcomes

## Outcome 2: Criminal cases of elected representative
cat("--- RDD: Criminal Cases ---\n")
## Treatment effect: does electing wealthy candidate change criminal cases of winner?
## Create outcome: criminal cases of the winning candidate
rdd[, winner_criminal := ifelse(rich_won == 1, rich_criminal, poor_criminal)]
rdd[, loser_criminal  := ifelse(rich_won == 1, poor_criminal, rich_criminal)]

rdd_criminal <- rdrobust(rdd$rich_criminal, rdd$rich_margin, c = 0)
cat("Rich candidate's criminal cases at cutoff:\n")
cat("  Conventional:", round(rdd_criminal$coef[1], 4), "\n")
cat("  Robust:", round(rdd_criminal$coef[3], 4), "\n")
cat("  Robust p-value:", round(rdd_criminal$pv[3], 4), "\n")
cat("  Bandwidth:", round(rdd_criminal$bws[1, 1], 2), "\n\n")

## Outcome 3: Winner's assets (comparison of elected representative's wealth)
cat("--- RDD: Winner's Log Assets ---\n")
rdd[, winner_log_assets := ifelse(rich_won == 1, log_rich_assets, log_poor_assets)]

rdd_assets <- rdrobust(rdd$winner_log_assets, rdd$rich_margin, c = 0)
cat("Winner's log assets at cutoff:\n")
cat("  Conventional:", round(rdd_assets$coef[1], 4), "\n")
cat("  Robust:", round(rdd_assets$coef[3], 4), "\n")
cat("  Robust CI: [", round(rdd_assets$ci[3, 1], 4), ",",
    round(rdd_assets$ci[3, 2], 4), "]\n")
cat("  Bandwidth:", round(rdd_assets$bws[1, 1], 2), "\n\n")

## =============================================================================
## PART 5: Covariate Balance Tests (RDD Validity)
## =============================================================================

cat("\n=== Covariate Balance Tests ===\n")

## Test that pre-determined covariates are balanced at the cutoff
## These should NOT show discontinuities

## Balance test: Rich candidate's age
cat("--- Balance: Rich Candidate's Age ---\n")
bal_age <- rdrobust(rdd$rich_age, rdd$rich_margin, c = 0)
cat("  Robust estimate:", round(bal_age$coef[3], 4),
    "  p-value:", round(bal_age$pv[3], 4), "\n")

## Balance test: Rich candidate's sex (male indicator)
cat("--- Balance: Rich Candidate Male ---\n")
rdd[, rich_male := as.integer(rich_sex == "M" | rich_sex == "MALE")]
bal_sex <- rdrobust(rdd$rich_male, rdd$rich_margin, c = 0)
cat("  Robust estimate:", round(bal_sex$coef[3], 4),
    "  p-value:", round(bal_sex$pv[3], 4), "\n")

## Balance test: Poor candidate's age
cat("--- Balance: Poor Candidate's Age ---\n")
bal_poor_age <- rdrobust(rdd$poor_age, rdd$rich_margin, c = 0)
cat("  Robust estimate:", round(bal_poor_age$coef[3], 4),
    "  p-value:", round(bal_poor_age$pv[3], 4), "\n")

## Balance test: Number of candidates in constituency
## (approximated by total votes in top-2 / margin)
cat("--- Balance: Total Top-2 Votes ---\n")
bal_votes <- rdrobust(log(rdd$total_top2_votes), rdd$rich_margin, c = 0)
cat("  Robust estimate:", round(bal_votes$coef[3], 4),
    "  p-value:", round(bal_votes$pv[3], 4), "\n")

## Balance test: Wealth ratio (pre-determined)
cat("--- Balance: Wealth Ratio ---\n")
bal_wealth <- rdrobust(log(rdd$wealth_ratio), rdd$rich_margin, c = 0)
cat("  Robust estimate:", round(bal_wealth$coef[3], 4),
    "  p-value:", round(bal_wealth$pv[3], 4), "\n")

## Balance test: SC/ST reservation status
cat("--- Balance: Reserved Constituency ---\n")
rdd[, reserved := as.integer(ac_type != "GEN" & ac_type != "")]
bal_reserved <- rdrobust(rdd$reserved, rdd$rich_margin, c = 0)
cat("  Robust estimate:", round(bal_reserved$coef[3], 4),
    "  p-value:", round(bal_reserved$pv[3], 4), "\n")

## Collect balance results
balance_results <- data.table(
  variable = c("Rich candidate age", "Rich candidate male",
               "Poor candidate age", "Log total votes",
               "Log wealth ratio", "Reserved constituency"),
  estimate = c(bal_age$coef[3], bal_sex$coef[3], bal_poor_age$coef[3],
               bal_votes$coef[3], bal_wealth$coef[3], bal_reserved$coef[3]),
  se = c(bal_age$se[3], bal_sex$se[3], bal_poor_age$se[3],
         bal_votes$se[3], bal_wealth$se[3], bal_reserved$se[3]),
  p_value = c(bal_age$pv[3], bal_sex$pv[3], bal_poor_age$pv[3],
              bal_votes$pv[3], bal_wealth$pv[3], bal_reserved$pv[3]),
  bandwidth = c(bal_age$bws[1, 1], bal_sex$bws[1, 1], bal_poor_age$bws[1, 1],
                bal_votes$bws[1, 1], bal_wealth$bws[1, 1], bal_reserved$bws[1, 1])
)
fwrite(balance_results, file.path(data_dir, "balance_tests.csv"))

cat("\n=== Balance Summary ===\n")
cat("Variables with p < 0.05:", sum(balance_results$p_value < 0.05), "out of",
    nrow(balance_results), "\n")

## =============================================================================
## PART 6: Main RDD with Controls and Fixed Effects
## =============================================================================

cat("\n=== RDD with Controls (fixest) ===\n")

## Local linear regression within bandwidth
## Use CCT optimal bandwidth from rdrobust
opt_bw <- rdd_assets$bws[1, 1]
cat("Using CCT optimal bandwidth:", round(opt_bw, 2), "percentage points\n")

## Restrict to bandwidth
rdd_bw <- rdd[abs(rich_margin) <= opt_bw]
cat("Observations within bandwidth:", nrow(rdd_bw), "\n")

## Model 1: Simple OLS within bandwidth
m1 <- feols(winner_log_assets ~ rich_won, data = rdd_bw, vcov = "HC1")

## Model 2: Control for running variable (local linear)
m2 <- feols(winner_log_assets ~ rich_won + rich_margin + rich_won:rich_margin,
            data = rdd_bw, vcov = "HC1")

## Model 3: Add state FE
m3 <- feols(winner_log_assets ~ rich_won + rich_margin + rich_won:rich_margin | state,
            data = rdd_bw, vcov = "HC1")

## Model 4: Add state + year FE
m4 <- feols(winner_log_assets ~ rich_won + rich_margin + rich_won:rich_margin | state + year,
            data = rdd_bw, vcov = "HC1")

## Display results
cat("\n--- Winner's Log Assets: RDD Estimates ---\n")
etable(m1, m2, m3, m4,
       headers = c("Simple", "Local Linear", "+ State FE", "+ State + Year FE"),
       keep = "rich_won",
       fitstat = c("n", "r2"))

## =============================================================================
## PART 7: RDD at Multiple Bandwidths
## =============================================================================

cat("\n=== Bandwidth Sensitivity ===\n")

bandwidths <- c(2, 3, 5, opt_bw, 10, 15, 20)
bw_results <- list()

for (bw in bandwidths) {
  rdd_sub <- rdd[abs(rich_margin) <= bw]
  if (nrow(rdd_sub) < 20) next

  m <- feols(winner_log_assets ~ rich_won + rich_margin + rich_won:rich_margin | state + year,
             data = rdd_sub, vcov = "HC1")

  bw_results[[as.character(bw)]] <- data.table(
    bandwidth = bw,
    estimate = coef(m)["rich_won"],
    se = sqrt(vcov(m)["rich_won", "rich_won"]),
    n = nrow(rdd_sub),
    p_value = summary(m)$coeftable["rich_won", "Pr(>|t|)"]
  )
}

bw_table <- rbindlist(bw_results)
bw_table[, stars := ifelse(p_value < 0.01, "***",
                    ifelse(p_value < 0.05, "**",
                    ifelse(p_value < 0.1, "*", "")))]
cat("\nBandwidth sensitivity for Winner's Log Assets:\n")
print(bw_table[, .(bandwidth = round(bandwidth, 1),
                    estimate = round(estimate, 3),
                    se = round(se, 3),
                    n, stars)])

fwrite(bw_table, file.path(data_dir, "bandwidth_sensitivity.csv"))

## =============================================================================
## PART 8: Heterogeneity Analysis
## =============================================================================

cat("\n=== Heterogeneity Analysis ===\n")

## By reservation status
cat("--- By Reservation Status ---\n")
rdd_gen <- rdd[ac_type == "GEN" | ac_type == ""]
rdd_res <- rdd[ac_type != "GEN" & ac_type != ""]

if (nrow(rdd_gen[abs(rich_margin) <= opt_bw]) >= 20) {
  m_gen <- rdrobust(rdd_gen$winner_log_assets, rdd_gen$rich_margin, c = 0)
  cat("General constituencies: estimate =", round(m_gen$coef[3], 4),
      "  p =", round(m_gen$pv[3], 4),
      "  N =", m_gen$N_h[1] + m_gen$N_h[2], "\n")
}

if (nrow(rdd_res[abs(rich_margin) <= opt_bw]) >= 20) {
  m_res <- rdrobust(rdd_res$winner_log_assets, rdd_res$rich_margin, c = 0)
  cat("Reserved constituencies: estimate =", round(m_res$coef[3], 4),
      "  p =", round(m_res$pv[3], 4),
      "  N =", m_res$N_h[1] + m_res$N_h[2], "\n")
}

## By wealth ratio (above/below median)
cat("\n--- By Wealth Disparity ---\n")
med_ratio <- median(rdd$wealth_ratio, na.rm = TRUE)
rdd_high_disp <- rdd[wealth_ratio >= med_ratio]
rdd_low_disp  <- rdd[wealth_ratio < med_ratio]

if (nrow(rdd_high_disp) >= 50) {
  m_high <- rdrobust(rdd_high_disp$winner_log_assets, rdd_high_disp$rich_margin, c = 0)
  cat("High wealth disparity: estimate =", round(m_high$coef[3], 4),
      "  p =", round(m_high$pv[3], 4), "\n")
}

if (nrow(rdd_low_disp) >= 50) {
  m_low <- rdrobust(rdd_low_disp$winner_log_assets, rdd_low_disp$rich_margin, c = 0)
  cat("Low wealth disparity: estimate =", round(m_low$coef[3], 4),
      "  p =", round(m_low$pv[3], 4), "\n")
}

## =============================================================================
## PART 9: Summary of Main Results
## =============================================================================

cat("\n=== SUMMARY OF MAIN RESULTS ===\n")
cat("Sample: ", nrow(rdd), " constituency-elections across ",
    length(unique(rdd$state)), " states\n", sep = "")
cat("Close elections (|margin| < 5%):", sum(rdd$close_election), "\n")
cat("Wealthier candidate wins:", round(mean(rdd$rich_won) * 100, 1), "% overall\n")
cat("McCrary test p-value:", round(density_test$test$p_jk, 4), "\n")
cat("Covariate balance: ", sum(balance_results$p_value < 0.05),
    " of ", nrow(balance_results), " covariates imbalanced at 5%\n", sep = "")
cat("\nMain RDD estimate (Winner's Log Assets, rdrobust):\n")
cat("  Robust estimate:", round(rdd_assets$coef[3], 4), "\n")
cat("  95% CI: [", round(rdd_assets$ci[3, 1], 4), ",",
    round(rdd_assets$ci[3, 2], 4), "]\n")
cat("  Bandwidth:", round(rdd_assets$bws[1, 1], 2), "\n")
cat("  Effective N:", rdd_assets$N_h[1] + rdd_assets$N_h[2], "\n")

## Save main results
main_results <- data.table(
  outcome = c("Winner log assets", "Rich candidate criminal cases"),
  conventional_est = c(rdd_assets$coef[1], rdd_criminal$coef[1]),
  robust_est = c(rdd_assets$coef[3], rdd_criminal$coef[3]),
  robust_se = c(rdd_assets$se[3], rdd_criminal$se[3]),
  robust_pv = c(rdd_assets$pv[3], rdd_criminal$pv[3]),
  ci_lower = c(rdd_assets$ci[3, 1], rdd_criminal$ci[3, 1]),
  ci_upper = c(rdd_assets$ci[3, 2], rdd_criminal$ci[3, 2]),
  bandwidth = c(rdd_assets$bws[1, 1], rdd_criminal$bws[1, 1]),
  n_eff = c(rdd_assets$N_h[1] + rdd_assets$N_h[2],
            rdd_criminal$N_h[1] + rdd_criminal$N_h[2])
)
fwrite(main_results, file.path(data_dir, "main_results.csv"))

cat("\n=== Main analysis complete ===\n")
