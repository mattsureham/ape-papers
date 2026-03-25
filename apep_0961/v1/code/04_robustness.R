# 04_robustness.R — Robustness checks
# apep_0961: Swiss tobacco billboard bans and healthcare costs

source("00_packages.R")

panel_total <- readRDS("../data/panel_total.rds")
panel_cat   <- readRDS("../data/panel_cat.rds")
results     <- readRDS("../data/main_results.rds")

# ============================================================================
# 1. Wild Cluster Bootstrap (small N = 26 cantons)
# ============================================================================
cat("=== Wild Cluster Bootstrap ===\n")

twfe_total <- feols(ln_cost ~ treated_post | canton_id + year,
                    data = panel_total, cluster = ~canton_id)

boot_result <- tryCatch({
  boottest(twfe_total,
           param = "treated_post",
           B = 9999,
           clustid = "canton_id",
           type = "rademacher")
}, error = function(e) {
  cat("Wild cluster bootstrap error:", conditionMessage(e), "\n")
  cat("Falling back to standard cluster-robust inference.\n")
  NULL
})

if (!is.null(boot_result)) {
  cat("Wild cluster bootstrap p-value:", pval(boot_result), "\n")
  cat("Wild cluster bootstrap CI:", confint(boot_result), "\n")
}

# ============================================================================
# 2. Leave-one-out (drop each treated canton)
# ============================================================================
cat("\n=== Leave-One-Out Analysis ===\n")

treated_cantons <- unique(panel_total$canton_iso[panel_total$treated_ever == 1])
loo_results <- data.table(
  dropped_canton = character(),
  att = numeric(),
  se = numeric()
)

for (drop_canton in treated_cantons) {
  panel_loo <- panel_total[canton_iso != drop_canton]
  panel_loo[, canton_id_loo := as.integer(as.factor(canton_iso))]

  cs_loo <- tryCatch({
    att_gt(
      yname = "ln_cost", tname = "year", idname = "canton_id_loo",
      gname = "ban_year", data = as.data.frame(panel_loo),
      control_group = "nevertreated", anticipation = 0,
      est_method = "dr", base_period = "universal"
    )
  }, error = function(e) NULL)

  if (!is.null(cs_loo)) {
    agg_loo <- aggte(cs_loo, type = "simple")
    loo_results <- rbind(loo_results, data.table(
      dropped_canton = drop_canton,
      att = agg_loo$overall.att,
      se = agg_loo$overall.se
    ))
  }
}

cat("Leave-one-out results:\n")
print(loo_results)
cat(sprintf("ATT range: [%.4f, %.4f]\n", min(loo_results$att), max(loo_results$att)))

# ============================================================================
# 3. Individual cost category regressions
# ============================================================================
cat("\n=== Individual Cost Category Regressions ===\n")

categories <- unique(panel_cat$cost_group)
cat_results <- data.table(
  category = character(),
  type = character(),
  att = numeric(),
  se = numeric(),
  pval = numeric()
)

for (cat_name in categories) {
  panel_c <- panel_cat[cost_group == cat_name]
  panel_c[, cat_canton_id := as.integer(as.factor(canton_iso))]

  cs_c <- tryCatch({
    att_gt(
      yname = "ln_cost", tname = "year", idname = "cat_canton_id",
      gname = "ban_year", data = as.data.frame(panel_c),
      control_group = "nevertreated", anticipation = 0,
      est_method = "dr", base_period = "universal"
    )
  }, error = function(e) NULL)

  if (!is.null(cs_c)) {
    agg_c <- aggte(cs_c, type = "simple")
    cat_type <- unique(panel_c$category_type)
    cat_results <- rbind(cat_results, data.table(
      category = cat_name,
      type = cat_type,
      att = agg_c$overall.att,
      se = agg_c$overall.se,
      pval = 2 * pnorm(-abs(agg_c$overall.att / agg_c$overall.se))
    ))
  }
}

cat("Category-level ATTs:\n")
print(cat_results[order(type, category)])

# ============================================================================
# 4. Levels specification (CHF per capita, not log)
# ============================================================================
cat("\n=== Levels Specification ===\n")

cs_levels <- att_gt(
  yname = "cost_pc", tname = "year", idname = "canton_id", gname = "ban_year",
  data = as.data.frame(panel_total), control_group = "nevertreated",
  anticipation = 0, est_method = "dr", base_period = "universal"
)
agg_levels <- aggte(cs_levels, type = "simple")
cat("Levels ATT (CHF/capita):\n")
summary(agg_levels)

# ============================================================================
# 5. Anticipation test (allow 1-2 years anticipation)
# ============================================================================
cat("\n=== Anticipation Tests ===\n")

for (antic in 1:2) {
  cs_antic <- tryCatch({
    att_gt(
      yname = "ln_cost", tname = "year", idname = "canton_id", gname = "ban_year",
      data = as.data.frame(panel_total), control_group = "nevertreated",
      anticipation = antic, est_method = "dr", base_period = "universal"
    )
  }, error = function(e) NULL)

  if (!is.null(cs_antic)) {
    agg_antic <- aggte(cs_antic, type = "simple")
    cat(sprintf("Anticipation = %d: ATT = %.4f (SE = %.4f)\n",
                antic, agg_antic$overall.att, agg_antic$overall.se))
  }
}

# ============================================================================
# 6. Save robustness results
# ============================================================================
robustness <- list(
  boot_result = boot_result,
  loo_results = loo_results,
  cat_results = cat_results,
  agg_levels = agg_levels
)
saveRDS(robustness, "../data/robustness_results.rds")

cat("\nRobustness checks complete.\n")
