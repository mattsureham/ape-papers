## ── 04_robustness.R ────────────────────────────────────────────
## Robustness checks for CGWB paper tiger analysis

source("00_packages.R")

data_dir <- "../data"
wells_long <- fread(file.path(data_dir, "wells_long_clean.csv"))
district_panel <- fread(file.path(data_dir, "district_panel_clean.csv"))
assessment_data <- fread(file.path(data_dir, "assessment_rounds.csv"))
state_treatment <- fread(file.path(data_dir, "state_treatment.csv"))

cat("=== Robustness Checks ===\n")

## ── 1. Surge-state design ───────────────────────────────────────
## States with LARGE INCREASES in OE blocks 2004-2013
## This uses within-classification variation (the regulatory ratchet)
cat("\n--- Rob 1: Surge state design ---\n")

# Compute increase in OE blocks
assessment_wide <- dcast(assessment_data, state_code + n_total_blocks ~ round,
                         value.var = "n_overexploited")
assessment_wide[, delta_04_13 := `2013` - `2004`]
assessment_wide[, delta_share_04_13 := delta_04_13 / pmax(n_total_blocks, 1)]

# Define surge: states with >5 pp increase in OE share
surge_states <- assessment_wide[delta_share_04_13 > 0.05, state_code]
cat("Surge states (>5pp increase 2004-2013):", paste(surge_states, collapse = ", "), "\n")

wells_long[, surge := STATE %in% surge_states]
wells_long[, surge_post := surge & year >= 2009]  # Post = after 2009 assessment (first round with big changes)

fit_surge <- feols(
  depth_to_water ~ surge_post | WLCODE + year,
  data = wells_long,
  cluster = ~STATE
)
cat("Surge state DiD:\n")
summary(fit_surge)

## ── 2. Depletion rate by well type ──────────────────────────────
cat("\n--- Rob 2: By well type ---\n")

# Compute annual mean per well
wells_annual <- wells_long[, .(
  mean_depth = mean(depth_to_water, na.rm = TRUE)
), by = .(WLCODE, STATE, DISTRICT, SITE_TYPE, year, treated, post, treat_post)]

setorder(wells_annual, WLCODE, year)
wells_annual[, delta_depth := mean_depth - shift(mean_depth, 1), by = WLCODE]

# By well type
for (wtype in c("Dug Well", "Bore Well", "Tube Well")) {
  sub <- wells_annual[SITE_TYPE == wtype & !is.na(delta_depth)]
  if (nrow(sub) > 100) {
    fit_type <- feols(delta_depth ~ treat_post | WLCODE + year,
                      data = sub, cluster = ~STATE)
    cat(sprintf("\n%s (N=%d):\n", wtype, nrow(sub)))
    cat(sprintf("  β = %.3f, SE = %.3f, p = %.3f\n",
                coef(fit_type), se(fit_type), pvalue(fit_type)))
  }
}

## ── 3. Placebo treatment timing ─────────────────────────────────
cat("\n--- Rob 3: Placebo timing (2000 instead of 2004) ---\n")

# If treatment timing doesn't matter, the null should hold at fake dates too
wells_long[, placebo_post := year >= 2000]
wells_long[, placebo_treat := treated & placebo_post]

# Only use pre-2004 data for placebo
fit_placebo <- feols(
  depth_to_water ~ placebo_treat | WLCODE + year,
  data = wells_long[year <= 2004],
  cluster = ~STATE
)
cat("Placebo (2000 timing, pre-2004 data only):\n")
summary(fit_placebo)

## ── 4. Alternative control group: adjacent states ───────────────
cat("\n--- Rob 4: Adjacent-state comparison ---\n")

# Compare high-OE states with their geographic neighbors
# RJ neighbors: GJ, MP; PB neighbors: HR, HP; HR neighbors: UP; TN neighbors: KA, KL
adjacent_pairs <- list(
  c("RJ", "MP"), c("RJ", "GJ"),
  c("PB", "HP"), c("HR", "UP"),
  c("TN", "KL")
)

# Restrict to adjacent-pair states
adj_states <- unique(unlist(adjacent_pairs))
fit_adj <- feols(
  depth_to_water ~ treat_post | WLCODE + year,
  data = wells_long[STATE %in% adj_states],
  cluster = ~STATE
)
cat("Adjacent-state comparison:\n")
summary(fit_adj)

## ── 5. Dose-response: OE share as continuous treatment ──────────
cat("\n--- Rob 5: Dose-response (state-level OE share) ---\n")

# Use the full variation in oe_share across rounds
# This exploits within-state changes in OE share over time
fit_dose <- feols(
  mean_depth ~ oe_share | district_id + year,
  data = district_panel[!is.na(oe_share)],
  cluster = ~STATE
)
cat("Dose-response (continuous oe_share):\n")
summary(fit_dose)

## ── 6. Monsoon vs non-monsoon quarter ───────────────────────────
cat("\n--- Rob 6: Monsoon seasonality ---\n")

# Monsoon (Jul-Sep = Q3) vs non-monsoon (Jan-Mar = Q1)
# Monsoon recharge should partially offset extraction
wells_long[, quarter := ceiling(month / 3)]
wells_long[, monsoon := quarter == 3]

# Pre-monsoon (Q2, Apr-Jun) is the critical depletion period
fit_premonsoon <- feols(
  depth_to_water ~ treat_post | WLCODE + year,
  data = wells_long[quarter == 2],
  cluster = ~STATE
)
cat("Pre-monsoon (Q2) only:\n")
summary(fit_premonsoon)

fit_postmonsoon <- feols(
  depth_to_water ~ treat_post | WLCODE + year,
  data = wells_long[quarter == 4],
  cluster = ~STATE
)
cat("\nPost-monsoon (Q4) only:\n")
summary(fit_postmonsoon)

## ── 7. Wild cluster bootstrap (few clusters) ────────────────────
cat("\n--- Rob 7: Wild cluster bootstrap ---\n")

# With only ~20 state clusters, standard cluster-robust SEs may be unreliable
# Use wild cluster bootstrap
if (requireNamespace("fwildclusterboot", quietly = TRUE)) {
  library(fwildclusterboot)

  # Simplified model for bootstrap
  wells_sample <- wells_long[sample(.N, min(.N, 200000))]
  fit_boot_base <- feols(
    depth_to_water ~ treat_post | WLCODE + year,
    data = wells_sample
  )

  boot_res <- tryCatch({
    boottest(fit_boot_base, param = "treat_postTRUE",
             B = 999, clustid = ~STATE,
             type = "mammen")
  }, error = function(e) {
    cat("Bootstrap error:", conditionMessage(e), "\n")
    NULL
  })

  if (!is.null(boot_res)) {
    cat("Wild cluster bootstrap p-value:", boot_res$p_val, "\n")
    cat("CI:", boot_res$conf_int, "\n")
  }
} else {
  cat("fwildclusterboot not available, skipping.\n")
}

## ── 8. Leave-one-state-out ──────────────────────────────────────
cat("\n--- Rob 8: Leave-one-state-out ---\n")

loso_results <- data.table()
for (st in unique(wells_long$STATE)) {
  fit_loso <- feols(
    depth_to_water ~ treat_post | WLCODE + year,
    data = wells_long[STATE != st],
    cluster = ~STATE
  )
  loso_results <- rbind(loso_results, data.table(
    dropped_state = st,
    coef = coef(fit_loso)["treat_postTRUE"],
    se = se(fit_loso)["treat_postTRUE"],
    pval = pvalue(fit_loso)["treat_postTRUE"]
  ))
}
cat("Leave-one-state-out coefficients:\n")
print(loso_results[order(coef)])
cat("Range:", round(min(loso_results$coef), 3), "to",
    round(max(loso_results$coef), 3), "\n")

## ── Save robustness results ─────────────────────────────────────
rob_results <- list(
  surge = fit_surge,
  placebo = fit_placebo,
  adjacent = fit_adj,
  dose = fit_dose,
  premonsoon = fit_premonsoon,
  postmonsoon = fit_postmonsoon,
  loso = loso_results
)
saveRDS(rob_results, file.path(data_dir, "robustness_results.rds"))

cat("\n=== Robustness checks complete ===\n")
