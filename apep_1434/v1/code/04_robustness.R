##############################################################################
# 04_robustness.R — Robustness and falsification tests
# apep_1434: When Scandals Go Dark
##############################################################################

source("00_packages.R")

panel <- readRDS("data/analysis_panel.rds")

cat("=== Robustness Checks ===\n\n")

###########################################################################
# 1. Placebo test: mega-events on LAGGED hearings
# If mega-events don't predict prior hearings, timing is exogenous
###########################################################################
cat("--- Placebo: mega-events → lagged hearings ---\n")

placebo1 <- feols(
  lag1_hearings ~ mega | agency_code + year + quarter,
  data = panel,
  cluster = ~agency_code
)

placebo2 <- feols(
  lag2_hearings ~ mega | agency_code + year + quarter,
  data = panel,
  cluster = ~agency_code
)

etable(placebo1, placebo2, headers = c("Lag 1", "Lag 2"))

###########################################################################
# 2. Alternative clustering
###########################################################################
cat("\n--- Alternative clustering ---\n")

# Two-way: agency × year
rf_cluster_ay <- feols(
  n_hearings ~ mega | agency_code + year + quarter,
  data = panel,
  cluster = ~agency_code + year
)

# Month-level
rf_cluster_m <- feols(
  n_hearings ~ mega | agency_code + year + quarter,
  data = panel,
  cluster = ~ym
)

etable(rf_cluster_ay, rf_cluster_m,
       headers = c("Agency × Year", "Month"))

###########################################################################
# 3. Permutation test: randomly shuffle mega-event indicator
###########################################################################
cat("\n--- Permutation test ---\n")

set.seed(42)
n_perms <- 1000

# Get actual reduced-form coefficient
load("data/main_results.RData")
actual_coef <- coeftable(rf2)["mega", "Estimate"]

perm_coefs <- numeric(n_perms)
for (p in seq_len(n_perms)) {
  # Shuffle mega-event across months (within agency)
  panel_perm <- panel |>
    group_by(agency_code) |>
    mutate(mega_perm = sample(mega)) |>
    ungroup()

  perm_fit <- feols(
    n_hearings ~ mega_perm | agency_code + year + quarter,
    data = panel_perm,
    cluster = ~agency_code
  )

  perm_coefs[p] <- coeftable(perm_fit)["mega_perm", "Estimate"]
}

perm_pvalue <- mean(abs(perm_coefs) >= abs(actual_coef))
cat("Permutation p-value (1000 draws):", perm_pvalue, "\n")
cat("Actual coefficient:", actual_coef, "\n")
cat("Permutation mean:", mean(perm_coefs), "SD:", sd(perm_coefs), "\n")

###########################################################################
# 4. Subperiod stability
###########################################################################
cat("\n--- Subperiod stability ---\n")

rf_early <- feols(
  n_hearings ~ mega | agency_code + year + quarter,
  data = panel |> filter(year <= 2016),
  cluster = ~agency_code
)

rf_late <- feols(
  n_hearings ~ mega | agency_code + year + quarter,
  data = panel |> filter(year >= 2017),
  cluster = ~agency_code
)

etable(rf_early, rf_late, headers = c("2009-2016", "2017-2024"))

###########################################################################
# 5. Heterogeneity: divided vs unified government
###########################################################################
cat("\n--- Heterogeneity: divided government ---\n")

rf_divided <- feols(
  n_hearings ~ mega | agency_code + year + quarter,
  data = panel |> filter(divided_gov == 1),
  cluster = ~agency_code
)

rf_unified <- feols(
  n_hearings ~ mega | agency_code + year + quarter,
  data = panel |> filter(divided_gov == 0),
  cluster = ~agency_code
)

etable(rf_divided, rf_unified, headers = c("Divided", "Unified"))

###########################################################################
# 6. Heterogeneity: high-profile vs low-profile agencies
###########################################################################
cat("\n--- Heterogeneity: agency profile ---\n")

rf_high <- feols(
  n_hearings ~ mega | agency_code + year + quarter,
  data = panel |> filter(high_profile == 1),
  cluster = ~agency_code
)

rf_low <- feols(
  n_hearings ~ mega | agency_code + year + quarter,
  data = panel |> filter(high_profile == 0),
  cluster = ~agency_code
)

etable(rf_high, rf_low, headers = c("High-profile", "Low-profile"))

###########################################################################
# 7. Excluding COVID period (2020-2021)
###########################################################################
cat("\n--- Excluding COVID period ---\n")

rf_nocovid <- feols(
  n_hearings ~ mega | agency_code + year + quarter,
  data = panel |> filter(!(year %in% c(2020, 2021))),
  cluster = ~agency_code
)

etable(rf_nocovid, headers = "Excluding 2020-2021")

###########################################################################
# 8. Olympics only (purest instrument)
###########################################################################
cat("\n--- Olympics only ---\n")

event_months <- readRDS("data/event_months.rds")

panel_olympics <- panel |>
  left_join(
    event_months |>
      mutate(has_olympics = grepl("Olympics", events)) |>
      select(ym, has_olympics),
    by = "ym"
  ) |>
  mutate(
    has_olympics = replace_na(has_olympics, FALSE),
    olympics = as.integer(has_olympics)
  )

rf_olympics <- feols(
  n_hearings ~ olympics | agency_code + year + quarter,
  data = panel_olympics,
  cluster = ~agency_code
)

etable(rf_olympics, headers = "Olympics only")

###########################################################################
# 9. Save
###########################################################################
save(placebo1, placebo2, rf_cluster_ay, rf_cluster_m,
     rf_early, rf_late, rf_divided, rf_unified,
     rf_high, rf_low, rf_nocovid, rf_olympics,
     perm_pvalue, perm_coefs, actual_coef,
     file = "data/robustness_results.RData")

cat("\n=== Robustness checks complete ===\n")
