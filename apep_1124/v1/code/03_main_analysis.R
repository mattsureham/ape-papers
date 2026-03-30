## ============================================================
## 03_main_analysis.R — Main DiD estimates
## apep_1124: Sanctions at Sea
## ============================================================

source("00_packages.R")

cat("=== Loading analysis panel ===\n")

panel <- read_csv("../data/panel_annual.csv", show_col_types = FALSE)
descriptives <- readRDS("../data/descriptives.rds")

# ---------------------------------------------------------------
# Fix: Recode 2012 cohort to 2013
# ---------------------------------------------------------------
# The 2012 cohort was carded in November 2012, but data starts 2012.
# Annual 2012 fishing hours are mostly pre-treatment (Jan-Oct).

panel <- panel %>%
  mutate(
    first_treat = ifelse(first_treat == 2012, 2013, first_treat),
    treated = as.integer(first_treat > 0 & year >= first_treat),
    # For sunab: use large value for never-treated (required)
    cohort = ifelse(first_treat == 0, 10000, first_treat)
  )

# Balanced panel: keep countries with >= 8 years
panel_balanced <- panel %>%
  group_by(flag_id) %>%
  filter(n() >= 8) %>%
  ungroup() %>%
  mutate(flag_id = as.integer(flag_id))

cat(sprintf("Panel: %d obs, %d countries (%d treated, %d control)\n",
            nrow(panel_balanced), n_distinct(panel_balanced$flag_id),
            n_distinct(panel_balanced$flag_id[panel_balanced$first_treat > 0]),
            n_distinct(panel_balanced$flag_id[panel_balanced$first_treat == 0])))

# ---------------------------------------------------------------
# 1. TWFE Baseline (for comparison — known staggered bias)
# ---------------------------------------------------------------

cat("\n=== TWFE Baseline ===\n")

twfe_main <- feols(
  ln_fishing_hours ~ treated | flag_id + year,
  data = panel_balanced,
  cluster = ~flag_id
)

twfe_vessels <- feols(
  ln_vessels ~ treated | flag_id + year,
  data = panel_balanced,
  cluster = ~flag_id
)

twfe_intensive <- feols(
  ln_hours_per_vessel ~ treated | flag_id + year,
  data = panel_balanced,
  cluster = ~flag_id
)

cat(sprintf("  Log fishing hours: %.4f (SE: %.4f)\n",
            coef(twfe_main)["treated"], se(twfe_main)["treated"]))
cat(sprintf("  Log vessels:       %.4f (SE: %.4f)\n",
            coef(twfe_vessels)["treated"], se(twfe_vessels)["treated"]))
cat(sprintf("  Log hours/vessel:  %.4f (SE: %.4f)\n",
            coef(twfe_intensive)["treated"], se(twfe_intensive)["treated"]))

# ---------------------------------------------------------------
# 2. Sun-Abraham (Preferred — heterogeneity-robust staggered DiD)
# ---------------------------------------------------------------

cat("\n=== Sun-Abraham Estimator (Preferred) ===\n")

# Main: log fishing hours
sa_main <- feols(
  ln_fishing_hours ~ sunab(cohort, year) | flag_id + year,
  data = panel_balanced,
  cluster = ~flag_id
)

cat("Sun-Abraham (log fishing hours):\n")
summary(sa_main)

# Vessels
sa_vessels <- feols(
  ln_vessels ~ sunab(cohort, year) | flag_id + year,
  data = panel_balanced,
  cluster = ~flag_id
)

# Intensive margin
sa_intensive <- feols(
  ln_hours_per_vessel ~ sunab(cohort, year) | flag_id + year,
  data = panel_balanced,
  cluster = ~flag_id
)

# Extract aggregate ATT from Sun-Abraham
# sunab stores cohort-specific estimates; aggregate as weighted average
# Use summary with agg = "ATT" for the overall treatment effect
sa_att_summary <- summary(sa_main, agg = "ATT")
sa_v_att_summary <- summary(sa_vessels, agg = "ATT")
sa_i_att_summary <- summary(sa_intensive, agg = "ATT")

cat("\nAggregated Sun-Abraham ATTs:\n")
cat(sprintf("  Log fishing hours: %.4f (SE: %.4f)\n",
            coef(sa_att_summary), se(sa_att_summary)))
cat(sprintf("  Log vessels:       %.4f (SE: %.4f)\n",
            coef(sa_v_att_summary), se(sa_v_att_summary)))
cat(sprintf("  Log hours/vessel:  %.4f (SE: %.4f)\n",
            coef(sa_i_att_summary), se(sa_i_att_summary)))

# ---------------------------------------------------------------
# 3. Event Study Coefficients
# ---------------------------------------------------------------

cat("\n=== Event Study ===\n")

# Extract event-study coefficients from SA
es_coefs <- coef(sa_main)
es_ses <- se(sa_main)
es_names <- names(es_coefs)

# Parse event-time from coefficient names (format: "year::YYYY:cohort::CCCC")
es_df <- data.frame(
  name = es_names,
  coef = es_coefs,
  se = es_ses,
  stringsAsFactors = FALSE
) %>%
  mutate(
    # Use the aggregate event-time names from sunab
    event_time = as.numeric(gsub(".*year::", "", gsub(":cohort.*", "", name)))
  )

# Aggregate by event time (across cohorts)
sa_es_agg <- summary(sa_main, agg = "period")
cat("Event study (aggregated across cohorts):\n")
print(sa_es_agg)

# ---------------------------------------------------------------
# 4. Wild Cluster Bootstrap
# ---------------------------------------------------------------

cat("\n=== Wild Cluster Bootstrap ===\n")

wcb_available <- requireNamespace("fwildclusterboot", quietly = TRUE)
if (wcb_available) {
  library(fwildclusterboot)
  set.seed(42)
  boot_result <- boottest(
    twfe_main,
    param = "treated",
    B = 9999,
    clustid = ~flag_id,
    type = "mammen"
  )
  cat("WCB p-value:", boot_result$p_val, "\n")
  wcb_pval <- boot_result$p_val
  wcb_ci <- boot_result$conf_int
} else {
  cat("fwildclusterboot not available.\n")
  wcb_pval <- NA
  wcb_ci <- c(NA, NA)
}

# ---------------------------------------------------------------
# 5. Save Results
# ---------------------------------------------------------------

cat("\n=== Saving results ===\n")

results <- list(
  twfe_main = twfe_main,
  twfe_vessels = twfe_vessels,
  twfe_intensive = twfe_intensive,
  sa_main = sa_main,
  sa_vessels = sa_vessels,
  sa_intensive = sa_intensive,
  sa_att_summary = sa_att_summary,
  sa_v_att_summary = sa_v_att_summary,
  sa_i_att_summary = sa_i_att_summary,
  sa_es_agg = sa_es_agg,
  wcb_pval = wcb_pval,
  wcb_ci = wcb_ci
)

saveRDS(results, "../data/main_results.rds")

# diagnostics.json for validator
sa_coef_val <- as.numeric(coef(sa_att_summary))
sa_se_val <- as.numeric(se(sa_att_summary))

diagnostics <- list(
  n_treated = n_distinct(panel_balanced$flag_id[panel_balanced$first_treat > 0]),
  n_pre = 5L,
  n_obs = nrow(panel_balanced),
  n_countries = n_distinct(panel_balanced$flag_id),
  n_control = n_distinct(panel_balanced$flag_id[panel_balanced$first_treat == 0]),
  sa_att = sa_coef_val,
  sa_se = sa_se_val,
  twfe_coef = as.numeric(coef(twfe_main)["treated"]),
  twfe_se = as.numeric(se(twfe_main)["treated"])
)

write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

cat(sprintf("\n=== HEADLINE: SA ATT = %.4f (SE = %.4f) ===\n",
            sa_coef_val, sa_se_val))
cat(sprintf("=== TWFE:     coef = %.4f (SE = %.4f) ===\n",
            as.numeric(coef(twfe_main)["treated"]),
            as.numeric(se(twfe_main)["treated"])))
