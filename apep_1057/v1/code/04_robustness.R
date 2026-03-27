# 04_robustness.R — Robustness checks
# apep_1057: The Consolidation Trap

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"

# ============================================================================
# 1. Load data and main results
# ============================================================================
panel <- fread(file.path(data_dir, "analysis_panel.csv"))
load(file.path(data_dir, "main_results.RData"))

cat("Panel loaded:", nrow(panel), "rows\n")

# ============================================================================
# 2. Placebo test: restrict to systems in ZIPs with NO deactivation events
#    but create artificial treatment from a random deactivation date
# ============================================================================
cat("\n=== Placebo: Random treatment timing ===\n")

set.seed(42)
never_treated <- panel[treated == FALSE]
unique_nt <- unique(never_treated$pwsid)

# Assign random treatment timing from the real treatment distribution
real_treat_times <- unique(panel$first_treat_idx[panel$first_treat_idx > 0])
placebo_treats <- data.table(
  pwsid = unique_nt,
  placebo_treat = sample(real_treat_times, length(unique_nt), replace = TRUE)
)

placebo_panel <- merge(never_treated, placebo_treats, by = "pwsid")
placebo_panel[, post_placebo := as.integer(qtr_idx >= placebo_treat)]

placebo_twfe <- feols(
  has_violation ~ post_placebo | pwsid + qtr_idx,
  data = placebo_panel,
  cluster = ~state
)
cat("Placebo TWFE:\n")
summary(placebo_twfe)

# ============================================================================
# 3. Leave-one-state-out robustness
# ============================================================================
cat("\n=== Leave-one-state-out ===\n")

loso_results <- list()
states_in_data <- unique(panel$state)
states_with_treated <- panel[treated == TRUE, unique(state)]

for (st in states_with_treated[1:min(length(states_with_treated), 50)]) {
  tryCatch({
    panel_loo <- panel[state != st]
    fit <- feols(has_violation ~ post | pwsid + qtr_idx,
                 data = panel_loo, cluster = ~state)
    loso_results[[st]] <- data.table(
      state_dropped = st,
      coef = coef(fit)["post"],
      se = sqrt(vcov(fit)["post", "post"])
    )
  }, error = function(e) {
    cat("  Skipped", st, ":", conditionMessage(e), "\n")
  })
}

loso_df <- rbindlist(loso_results)
cat("\nLeave-one-state-out: coefficient range [",
    round(min(loso_df$coef), 5), ",",
    round(max(loso_df$coef), 5), "]\n")
cat("Main estimate:", round(coef(twfe_binary)["post"], 5), "\n")

# ============================================================================
# 4. Dose-response: by number of deactivations and population absorbed
# ============================================================================
cat("\n=== Dose-response analysis ===\n")

# Terciles of absorbed population (among treated)
treated_info <- panel[treated == TRUE, .(
  pwsid, total_pop_deactivated, n_deactivated
)] |> unique()

tercile_cuts <- quantile(treated_info$total_pop_deactivated,
                          probs = c(1/3, 2/3), na.rm = TRUE)

panel[, dose_tercile := fcase(
  treated == FALSE, "Never treated",
  total_pop_deactivated <= tercile_cuts[1], "Low dose",
  total_pop_deactivated <= tercile_cuts[2], "Medium dose",
  default = "High dose"
)]

# TWFE by dose tercile (excluding never-treated for comparison vs low)
panel_treated <- panel[treated == TRUE]
panel_treated[, medium := as.integer(dose_tercile == "Medium dose")]
panel_treated[, high := as.integer(dose_tercile == "High dose")]

dose_fit <- feols(
  has_violation ~ post + post:medium + post:high | pwsid + qtr_idx,
  data = panel_treated,
  cluster = ~state
)
cat("\nDose-response TWFE (among treated):\n")
summary(dose_fit)

# ============================================================================
# 5. Restrict to California (SB 88 mandatory consolidation)
# ============================================================================
cat("\n=== California subsample (SB 88) ===\n")

panel_ca <- panel[state == "CA"]
cat("CA observations:", nrow(panel_ca), "\n")
cat("CA treated:", uniqueN(panel_ca$pwsid[panel_ca$treated == TRUE]), "\n")

if (uniqueN(panel_ca$pwsid[panel_ca$treated == TRUE]) >= 20) {
  ca_twfe <- feols(
    has_violation ~ post | pwsid + qtr_idx,
    data = panel_ca,
    cluster = ~pwsid  # cluster at system level within CA
  )
  cat("\nCA TWFE:\n")
  summary(ca_twfe)
} else {
  cat("Insufficient treated units in CA for separate analysis.\n")
  ca_twfe <- NULL
}

# ============================================================================
# 6. Alternative outcome: violation count (Poisson)
# ============================================================================
cat("\n=== Poisson regression ===\n")

poisson_fit <- fepois(
  n_health_viols ~ post | pwsid + qtr_idx,
  data = panel,
  cluster = ~state
)
cat("\nPoisson TWFE:\n")
summary(poisson_fit)

# ============================================================================
# 7. Wild cluster bootstrap — skipped (50+ clusters, standard CRSEs reliable)
# ============================================================================
cat("\n=== Wild Cluster Bootstrap ===\n")
cat("Skipped: 50+ state clusters make standard CRSEs reliable.\n")

# ============================================================================
# 8. Save robustness results
# ============================================================================
save(placebo_twfe, loso_df, dose_fit, ca_twfe, poisson_fit,
     file = file.path(data_dir, "robustness_results.RData"))

cat("\n=== Robustness checks complete ===\n")
