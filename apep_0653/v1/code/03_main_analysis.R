# 03_main_analysis.R — Primary regressions
# apep_0653: Data Breach Notification Laws and Firm Dynamics

source("00_packages.R")

panel_agg <- readRDS("../data/panel_aggregate.rds")
panel_naics <- readRDS("../data/panel_naics.rds")

# ==============================================================================
# 1. Callaway-Sant'Anna: Aggregate establishment entry rate
# ==============================================================================

cat("=== CS-DiD: Aggregate Establishment Entry Rate ===\n")

cs_entry <- att_gt(
  yname = "ESTABS_ENTRY_RATE",
  tname = "year",
  idname = "state_id",
  gname = "first_treat",
  data = panel_agg,
  control_group = "notyettreated",
  est_method = "dr",
  clustervars = "state_id"
)

cs_entry_agg <- aggte(cs_entry, type = "simple")
cat("ATT (entry rate):", round(cs_entry_agg$overall.att, 4),
    "SE:", round(cs_entry_agg$overall.se, 4), "\n")

# Event study
cs_entry_es <- aggte(cs_entry, type = "dynamic", min_e = -5, max_e = 10)
cat("\nEvent study coefficients:\n")
print(data.frame(
  e = cs_entry_es$egt,
  att = round(cs_entry_es$att.egt, 4),
  se = round(cs_entry_es$se.egt, 4)
))

# ==============================================================================
# 2. CS-DiD: Aggregate establishment exit rate
# ==============================================================================

cat("\n=== CS-DiD: Aggregate Establishment Exit Rate ===\n")

cs_exit <- att_gt(
  yname = "ESTABS_EXIT_RATE",
  tname = "year",
  idname = "state_id",
  gname = "first_treat",
  data = panel_agg,
  control_group = "notyettreated",
  est_method = "dr",
  clustervars = "state_id"
)

cs_exit_agg <- aggte(cs_exit, type = "simple")
cat("ATT (exit rate):", round(cs_exit_agg$overall.att, 4),
    "SE:", round(cs_exit_agg$overall.se, 4), "\n")

# ==============================================================================
# 3. CS-DiD: Net job creation rate
# ==============================================================================

cat("\n=== CS-DiD: Net Job Creation Rate ===\n")

cs_netjc <- att_gt(
  yname = "NET_JOB_CREATION_RATE",
  tname = "year",
  idname = "state_id",
  gname = "first_treat",
  data = panel_agg,
  control_group = "notyettreated",
  est_method = "dr",
  clustervars = "state_id"
)

cs_netjc_agg <- aggte(cs_netjc, type = "simple")
cat("ATT (net JC rate):", round(cs_netjc_agg$overall.att, 4),
    "SE:", round(cs_netjc_agg$overall.se, 4), "\n")

# ==============================================================================
# 4. TWFE baseline comparison
# ==============================================================================

cat("\n=== TWFE Baseline ===\n")

twfe_entry <- feols(ESTABS_ENTRY_RATE ~ post | state_id + year,
                    data = panel_agg, cluster = ~state_id)
twfe_exit <- feols(ESTABS_EXIT_RATE ~ post | state_id + year,
                   data = panel_agg, cluster = ~state_id)
twfe_netjc <- feols(NET_JOB_CREATION_RATE ~ post | state_id + year,
                    data = panel_agg, cluster = ~state_id)

cat("TWFE Entry:", round(coef(twfe_entry), 4), "SE:", round(se(twfe_entry), 4), "\n")
cat("TWFE Exit:", round(coef(twfe_exit), 4), "SE:", round(se(twfe_exit), 4), "\n")
cat("TWFE Net JC:", round(coef(twfe_netjc), 4), "SE:", round(se(twfe_netjc), 4), "\n")

# ==============================================================================
# 5. Industry mechanism test: CS-DiD by data intensity
# ==============================================================================

cat("\n=== Industry Mechanism Test ===\n")

# Key sectors
sectors <- list(
  list(naics = "51", label = "Information (High Data)"),
  list(naics = "52", label = "Finance (High Data)"),
  list(naics = "54", label = "Professional/Technical (Medium)"),
  list(naics = "23", label = "Construction (Placebo)"),
  list(naics = "11", label = "Agriculture (Placebo)")
)

industry_results <- list()

for (s in sectors) {
  df <- panel_naics %>%
    filter(NAICS == s$naics, !is.na(ESTABS_ENTRY_RATE))

  if (nrow(df) < 200) {
    cat("  Skipping", s$label, "- too few obs:", nrow(df), "\n")
    next
  }

  # Ensure unique state-year panel
  df <- df %>%
    group_by(state_id, year) %>%
    slice(1) %>%
    ungroup()

  cs_fit <- tryCatch({
    att_gt(
      yname = "ESTABS_ENTRY_RATE",
      tname = "year",
      idname = "state_id",
      gname = "first_treat",
      data = df,
      control_group = "notyettreated",
      est_method = "dr",
      clustervars = "state_id"
    )
  }, error = function(e) {
    cat("  CS failed for", s$label, ":", conditionMessage(e), "\n")
    NULL
  })

  if (!is.null(cs_fit)) {
    agg_fit <- aggte(cs_fit, type = "simple")
    industry_results[[s$naics]] <- list(
      label = s$label,
      att = agg_fit$overall.att,
      se = agg_fit$overall.se,
      n = nrow(df)
    )
    cat("  ", s$label, ": ATT =", round(agg_fit$overall.att, 4),
        "SE =", round(agg_fit$overall.se, 4), "\n")
  }
}

# ==============================================================================
# 6. Save results
# ==============================================================================

results <- list(
  cs_entry = cs_entry,
  cs_entry_agg = cs_entry_agg,
  cs_entry_es = cs_entry_es,
  cs_exit = cs_exit,
  cs_exit_agg = cs_exit_agg,
  cs_netjc = cs_netjc,
  cs_netjc_agg = cs_netjc_agg,
  twfe_entry = twfe_entry,
  twfe_exit = twfe_exit,
  twfe_netjc = twfe_netjc,
  industry_results = industry_results,
  panel_agg = panel_agg
)

saveRDS(results, "../data/main_results.rds")

# Write diagnostics
n_treated <- n_distinct(panel_agg$state_fips[panel_agg$treated == 1])
n_pre <- length(unique(panel_agg$year[panel_agg$year < min(panel_agg$bnl_year)]))
n_obs <- nrow(panel_agg)

write_json(list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs
), "../data/diagnostics.json", auto_unbox = TRUE)

cat("\n-> data/main_results.rds")
cat("\n-> data/diagnostics.json (n_treated=", n_treated, ", n_pre=", n_pre, ", n_obs=", n_obs, ")\n")
