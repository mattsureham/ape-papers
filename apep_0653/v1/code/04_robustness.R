# 04_robustness.R — Robustness checks
# apep_0653: Data Breach Notification Laws and Firm Dynamics

source("00_packages.R")

panel_agg <- readRDS("../data/panel_aggregate.rds")
results <- readRDS("../data/main_results.rds")

# ==============================================================================
# 1. Sun-Abraham interaction-weighted estimator
# ==============================================================================

cat("=== Sun-Abraham Estimates ===\n")

# Create relative time variable
panel_agg <- panel_agg %>%
  mutate(rel_time = year - bnl_year)

sa_entry <- feols(ESTABS_ENTRY_RATE ~ sunab(bnl_year, year) | state_id + year,
                  data = panel_agg, cluster = ~state_id)
sa_exit <- feols(ESTABS_EXIT_RATE ~ sunab(bnl_year, year) | state_id + year,
                 data = panel_agg, cluster = ~state_id)
sa_netjc <- feols(NET_JOB_CREATION_RATE ~ sunab(bnl_year, year) | state_id + year,
                  data = panel_agg, cluster = ~state_id)

cat("SA Entry ATT:", round(summary(sa_entry, agg = "ATT")$coeftable[1, 1], 4),
    "SE:", round(summary(sa_entry, agg = "ATT")$coeftable[1, 2], 4), "\n")
cat("SA Exit ATT:", round(summary(sa_exit, agg = "ATT")$coeftable[1, 1], 4),
    "SE:", round(summary(sa_exit, agg = "ATT")$coeftable[1, 2], 4), "\n")
cat("SA Net JC ATT:", round(summary(sa_netjc, agg = "ATT")$coeftable[1, 1], 4),
    "SE:", round(summary(sa_netjc, agg = "ATT")$coeftable[1, 2], 4), "\n")

# ==============================================================================
# 2. Exclude California (first mover, tech hub confound)
# ==============================================================================

cat("\n=== Exclude California ===\n")

panel_noca <- panel_agg %>% filter(state_fips != "06")

cs_noca <- att_gt(
  yname = "ESTABS_ENTRY_RATE",
  tname = "year",
  idname = "state_id",
  gname = "first_treat",
  data = panel_noca,
  control_group = "notyettreated",
  est_method = "dr",
  clustervars = "state_id"
)
cs_noca_agg <- aggte(cs_noca, type = "simple")
cat("ATT (excl CA):", round(cs_noca_agg$overall.att, 4),
    "SE:", round(cs_noca_agg$overall.se, 4), "\n")

# ==============================================================================
# 3. Exclude 2005 mega-cohort
# ==============================================================================

cat("\n=== Exclude 2005 Mega-Cohort ===\n")

panel_no2005 <- panel_agg %>% filter(bnl_year != 2005)

cs_no2005 <- att_gt(
  yname = "ESTABS_ENTRY_RATE",
  tname = "year",
  idname = "state_id",
  gname = "first_treat",
  data = panel_no2005,
  control_group = "notyettreated",
  est_method = "dr",
  clustervars = "state_id"
)
cs_no2005_agg <- aggte(cs_no2005, type = "simple")
cat("ATT (excl 2005):", round(cs_no2005_agg$overall.att, 4),
    "SE:", round(cs_no2005_agg$overall.se, 4), "\n")

# ==============================================================================
# 4. Leave-one-out cohort analysis
# ==============================================================================

cat("\n=== Leave-One-Out by Cohort ===\n")

cohorts <- unique(panel_agg$bnl_year)
loo_results <- data.frame()

for (coh in cohorts) {
  df_loo <- panel_agg %>% filter(bnl_year != coh)
  cs_loo <- tryCatch({
    fit <- att_gt(
      yname = "ESTABS_ENTRY_RATE",
      tname = "year",
      idname = "state_id",
      gname = "first_treat",
      data = df_loo,
      control_group = "notyettreated",
      est_method = "dr",
      clustervars = "state_id"
    )
    agg <- aggte(fit, type = "simple")
    data.frame(excluded_cohort = coh, att = agg$overall.att, se = agg$overall.se)
  }, error = function(e) {
    data.frame(excluded_cohort = coh, att = NA, se = NA)
  })
  loo_results <- bind_rows(loo_results, cs_loo)
}

cat("LOO range:", round(min(loo_results$att, na.rm = TRUE), 4), "to",
    round(max(loo_results$att, na.rm = TRUE), 4), "\n")
print(loo_results)

# ==============================================================================
# 5. Save robustness results
# ==============================================================================

rob_results <- list(
  sa_entry = sa_entry,
  sa_exit = sa_exit,
  sa_netjc = sa_netjc,
  cs_noca_agg = cs_noca_agg,
  cs_no2005_agg = cs_no2005_agg,
  loo_results = loo_results
)

saveRDS(rob_results, "../data/robustness_results.rds")
cat("\n-> data/robustness_results.rds\n")
