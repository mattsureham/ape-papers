## 04_robustness.R — Robustness checks
## apep_1130: SBA Size Standards and Geographic Procurement Redistribution

source("00_packages.R")

cat("=== Robustness Checks ===\n")

# ------------------------------------------------------------------
# 1. Load data
# ------------------------------------------------------------------
panel <- fread("../data/sector_panel.csv")
results <- readRDS("../data/main_results.rds")

# ------------------------------------------------------------------
# 2. Leave-one-cohort-out sensitivity
# ------------------------------------------------------------------
cat("\n--- Leave-one-cohort-out ---\n")

cohorts <- unique(panel[!is.na(treat_year)]$treat_year)
loco_results <- list()

for (drop_cohort in cohorts) {
  sub <- panel[is.na(treat_year) | treat_year != drop_cohort]
  sub[, post_sub := fifelse(!is.na(treat_year) & fiscal_year >= treat_year, 1L, 0L)]

  fit <- feols(log_total_sb ~ post_sub | sector_id + fiscal_year,
               data = sub, cluster = ~sector_id)
  loco_results[[as.character(drop_cohort)]] <- list(
    dropped_cohort = drop_cohort,
    coef = coef(fit)["post_sub"],
    se = sqrt(vcov(fit)["post_sub", "post_sub"]),
    n = nobs(fit)
  )
  cat(sprintf("  Drop %d: coef=%.4f (SE=%.4f), N=%d\n",
              drop_cohort, coef(fit)["post_sub"],
              sqrt(vcov(fit)["post_sub", "post_sub"]), nobs(fit)))
}

# ------------------------------------------------------------------
# 3. Placebo test: all-contracts (not just SB set-asides)
# ------------------------------------------------------------------
cat("\n--- Placebo: All Contracts (not just SB) ---\n")

# If size standards only affect SB set-asides, we should NOT see effects
# on total procurement (which includes full-and-open competition)
twfe_placebo <- feols(log_total_all ~ post | sector_id + fiscal_year,
                       data = panel, cluster = ~sector_id)
cat("TWFE placebo (total procurement):\n")
print(summary(twfe_placebo))

# ------------------------------------------------------------------
# 4. Alternative concentration: top-5 county share
# ------------------------------------------------------------------
cat("\n--- Alternative: Top-5 County Share ---\n")

if ("top5_share" %in% names(panel) && any(!is.na(panel$top5_share))) {
  twfe_top5 <- feols(top5_share ~ post | sector_id + fiscal_year,
                      data = panel[!is.na(top5_share)], cluster = ~sector_id)
  cat("TWFE: Top-5 county share of SB procurement:\n")
  print(summary(twfe_top5))
}

# ------------------------------------------------------------------
# 5. SB share of total procurement
# ------------------------------------------------------------------
cat("\n--- SB Share of Total Procurement ---\n")

twfe_sb_share <- feols(sb_share ~ post | sector_id + fiscal_year,
                        data = panel[!is.na(sb_share)], cluster = ~sector_id)
cat("TWFE: SB set-aside share of total procurement:\n")
print(summary(twfe_sb_share))

# ------------------------------------------------------------------
# 6. Wild cluster bootstrap (small number of clusters)
# ------------------------------------------------------------------
cat("\n--- Wild Cluster Bootstrap ---\n")

# With ~19 sectors, conventional cluster SEs may be unreliable
# Use wild cluster bootstrap from fixest
tryCatch({
  boot_twfe1 <- feols(log_total_sb ~ post | sector_id + fiscal_year,
                       data = panel, cluster = ~sector_id)
  # Wild bootstrap p-value
  boot_result <- boot(boot_twfe1, B = 999, cluster = ~sector_id)
  cat("Wild bootstrap results for log SB procurement:\n")
  print(boot_result)
}, error = function(e) {
  cat(sprintf("Wild bootstrap error: %s\n", e$message))
  cat("Using HC1 robust SEs instead:\n")
  robust_twfe <- feols(log_total_sb ~ post | sector_id + fiscal_year,
                        data = panel, vcov = "HC1")
  print(summary(robust_twfe))
})

# ------------------------------------------------------------------
# 7. Save robustness results
# ------------------------------------------------------------------
rob_results <- list(
  loco = loco_results,
  placebo_all = twfe_placebo,
  sb_share = twfe_sb_share
)
saveRDS(rob_results, "../data/robustness_results.rds")

cat("\n=== Robustness checks complete ===\n")
