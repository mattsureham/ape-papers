# =============================================================================
# 04_robustness.R — Robustness and comparison outcomes
# apep_1243: Municipal Consolidation and Residential Sorting in Switzerland
# =============================================================================

source("00_packages.R")

panel <- fread(file.path(DATA_DIR, "analysis_panel.csv"))
panel[, current_bfs := as.factor(current_bfs)]

# Drop first-difference missing rows where needed
panel_share <- copy(panel[!is.na(foreign_share)])

# Baseline foreign-share robustness
r1 <- feols(
  foreign_share ~ post_merger | current_bfs + year,
  data = panel_share,
  cluster = ~current_bfs
)
r2 <- feols(
  foreign_share ~ post_merger | current_bfs + canton^year,
  data = panel_share,
  cluster = ~current_bfs
)
r3 <- feols(
  foreign_share ~ post_merger | current_bfs + year,
  data = panel_share,
  weights = ~baseline_total_pop,
  cluster = ~current_bfs
)

cutoff <- quantile(panel_share$baseline_total_pop, 0.99, na.rm = TRUE)
r4 <- feols(
  foreign_share ~ post_merger | current_bfs + year,
  data = panel_share[baseline_total_pop <= cutoff],
  cluster = ~current_bfs
)

robust_dt <- data.table(
  spec = c(
    "Baseline TWFE",
    "Canton x year FE",
    "Population-weighted",
    "Drop top 1% by size"
  ),
  estimate = c(
    coef(r1)["post_mergerTRUE"],
    coef(r2)["post_mergerTRUE"],
    coef(r3)["post_mergerTRUE"],
    coef(r4)["post_mergerTRUE"]
  ),
  se = c(
    summary(r1)$coeftable["post_mergerTRUE", "Std. Error"],
    summary(r2)$coeftable["post_mergerTRUE", "Std. Error"],
    summary(r3)$coeftable["post_mergerTRUE", "Std. Error"],
    summary(r4)$coeftable["post_mergerTRUE", "Std. Error"]
  ),
  n = c(nobs(r1), nobs(r2), nobs(r3), nobs(r4))
)
fwrite(robust_dt, file.path(DATA_DIR, "robustness_summary.csv"))

# Comparison outcomes
c1 <- feols(
  log_foreign ~ post_merger | current_bfs + year,
  data = panel[!is.na(log_foreign)],
  cluster = ~current_bfs
)
c2 <- feols(
  foreign_growth ~ post_merger | current_bfs + year,
  data = panel[!is.na(foreign_growth)],
  cluster = ~current_bfs
)
c3 <- feols(
  swiss_growth ~ post_merger | current_bfs + year,
  data = panel[!is.na(swiss_growth)],
  cluster = ~current_bfs
)
c4 <- feols(
  total_growth ~ post_merger | current_bfs + year,
  data = panel[!is.na(total_growth)],
  cluster = ~current_bfs
)

comparison_dt <- data.table(
  outcome = c(
    "Log foreign population",
    "Foreign population growth",
    "Swiss population growth",
    "Total population growth"
  ),
  estimate = c(
    coef(c1)["post_mergerTRUE"],
    coef(c2)["post_mergerTRUE"],
    coef(c3)["post_mergerTRUE"],
    coef(c4)["post_mergerTRUE"]
  ),
  se = c(
    summary(c1)$coeftable["post_mergerTRUE", "Std. Error"],
    summary(c2)$coeftable["post_mergerTRUE", "Std. Error"],
    summary(c3)$coeftable["post_mergerTRUE", "Std. Error"],
    summary(c4)$coeftable["post_mergerTRUE", "Std. Error"]
  ),
  n = c(nobs(c1), nobs(c2), nobs(c3), nobs(c4))
)
fwrite(comparison_dt, file.path(DATA_DIR, "comparison_outcomes.csv"))

# Split-sample heterogeneity by baseline foreign share
median_fs <- median(panel_share$baseline_foreign_share, na.rm = TRUE)
panel_share[, high_foreign := baseline_foreign_share >= median_fs]

h1 <- feols(
  foreign_share ~ post_merger | current_bfs + year,
  data = panel_share[high_foreign == TRUE],
  cluster = ~current_bfs
)
h2 <- feols(
  foreign_share ~ post_merger | current_bfs + year,
  data = panel_share[high_foreign == FALSE],
  cluster = ~current_bfs
)

hetero_dt <- data.table(
  sample = c("High baseline foreign share", "Low baseline foreign share"),
  estimate = c(
    coef(h1)["post_mergerTRUE"],
    coef(h2)["post_mergerTRUE"]
  ),
  se = c(
    summary(h1)$coeftable["post_mergerTRUE", "Std. Error"],
    summary(h2)$coeftable["post_mergerTRUE", "Std. Error"]
  ),
  n = c(nobs(h1), nobs(h2))
)
fwrite(hetero_dt, file.path(DATA_DIR, "heterogeneity_summary.csv"))

cat("Robustness analysis complete.\n")
