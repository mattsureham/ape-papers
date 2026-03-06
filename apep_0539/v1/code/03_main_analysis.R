## 03_main_analysis.R — Main CS-DiD analysis
## APEP Paper apep_0539: Less Cash, Less Crime?

source("00_packages.R")
data_dir <- "../data"

panel <- fread(file.path(data_dir, "analysis_panel.csv"))
cat("Panel:", nrow(panel), "obs,", n_distinct(panel$state_abbr), "states\n")

# ===========================================================================
# 1. TWFE Baseline (for comparison only — we know this is potentially biased)
# ===========================================================================
cat("\n=== TWFE Regressions (baseline) ===\n")

# Property crime
twfe_property <- feols(log_property_crime ~ post_ebt | state_id + year,
                       data = panel, cluster = ~state_abbr)

# Burglary (mechanism-aligned)
twfe_burglary <- feols(log_burglary ~ post_ebt | state_id + year,
                       data = panel, cluster = ~state_abbr)

# Larceny (mechanism-aligned)
twfe_larceny <- feols(log_larceny ~ post_ebt | state_id + year,
                      data = panel, cluster = ~state_abbr)

# Robbery (mechanism-aligned)
twfe_robbery <- feols(log_robbery ~ post_ebt | state_id + year,
                      data = panel, cluster = ~state_abbr)

# Motor vehicle theft (PLACEBO — no mechanism)
twfe_mvt <- feols(log_mvt ~ post_ebt | state_id + year,
                  data = panel, cluster = ~state_abbr)

# Violent crime (weak/null expected)
twfe_violent <- feols(log_violent ~ post_ebt | state_id + year,
                      data = panel, cluster = ~state_abbr)

cat("TWFE Results:\n")
cat("  Property crime:", round(coef(twfe_property), 4),
    "(SE:", round(se(twfe_property), 4), ")\n")
cat("  Burglary:", round(coef(twfe_burglary), 4),
    "(SE:", round(se(twfe_burglary), 4), ")\n")
cat("  Larceny:", round(coef(twfe_larceny), 4),
    "(SE:", round(se(twfe_larceny), 4), ")\n")
cat("  Robbery:", round(coef(twfe_robbery), 4),
    "(SE:", round(se(twfe_robbery), 4), ")\n")
cat("  MVT (placebo):", round(coef(twfe_mvt), 4),
    "(SE:", round(se(twfe_mvt), 4), ")\n")
cat("  Violent:", round(coef(twfe_violent), 4),
    "(SE:", round(se(twfe_violent), 4), ")\n")

# Save TWFE results
saveRDS(list(property = twfe_property, burglary = twfe_burglary,
             larceny = twfe_larceny, robbery = twfe_robbery,
             mvt = twfe_mvt, violent = twfe_violent),
        file.path(data_dir, "twfe_results.rds"))

# ===========================================================================
# 2. Callaway-Sant'Anna CS-DiD (main specification)
# ===========================================================================
cat("\n=== Callaway-Sant'Anna CS-DiD ===\n")

# Property crime (main outcome)
cat("Running CS-DiD for property crime...\n")
cs_property <- att_gt(
  yname = "log_property_crime",
  tname = "year",
  idname = "state_id",
  gname = "first_treat",
  data = as.data.frame(panel),
  control_group = "notyettreated",
  anticipation = 0,
  base_period = "varying"
)

# Aggregate to overall ATT
agg_property <- aggte(cs_property, type = "simple")
cat("Property crime ATT:", round(agg_property$overall.att, 4),
    "(SE:", round(agg_property$overall.se, 4), ")\n")

# Dynamic aggregation (event study)
es_property <- aggte(cs_property, type = "dynamic",
                     min_e = -10, max_e = 10)

# Burglary
cat("Running CS-DiD for burglary...\n")
cs_burglary <- att_gt(
  yname = "log_burglary",
  tname = "year",
  idname = "state_id",
  gname = "first_treat",
  data = as.data.frame(panel),
  control_group = "notyettreated",
  anticipation = 0,
  base_period = "varying"
)
agg_burglary <- aggte(cs_burglary, type = "simple")
es_burglary <- aggte(cs_burglary, type = "dynamic",
                      min_e = -10, max_e = 10)
cat("Burglary ATT:", round(agg_burglary$overall.att, 4),
    "(SE:", round(agg_burglary$overall.se, 4), ")\n")

# Larceny
cat("Running CS-DiD for larceny...\n")
cs_larceny <- att_gt(
  yname = "log_larceny",
  tname = "year",
  idname = "state_id",
  gname = "first_treat",
  data = as.data.frame(panel),
  control_group = "notyettreated",
  anticipation = 0,
  base_period = "varying"
)
agg_larceny <- aggte(cs_larceny, type = "simple")
es_larceny <- aggte(cs_larceny, type = "dynamic",
                     min_e = -10, max_e = 10)
cat("Larceny ATT:", round(agg_larceny$overall.att, 4),
    "(SE:", round(agg_larceny$overall.se, 4), ")\n")

# Robbery
cat("Running CS-DiD for robbery...\n")
cs_robbery <- att_gt(
  yname = "log_robbery",
  tname = "year",
  idname = "state_id",
  gname = "first_treat",
  data = as.data.frame(panel),
  control_group = "notyettreated",
  anticipation = 0,
  base_period = "varying"
)
agg_robbery <- aggte(cs_robbery, type = "simple")
es_robbery <- aggte(cs_robbery, type = "dynamic",
                     min_e = -10, max_e = 10)
cat("Robbery ATT:", round(agg_robbery$overall.att, 4),
    "(SE:", round(agg_robbery$overall.se, 4), ")\n")

# Motor vehicle theft (PLACEBO)
cat("Running CS-DiD for motor vehicle theft (placebo)...\n")
cs_mvt <- att_gt(
  yname = "log_mvt",
  tname = "year",
  idname = "state_id",
  gname = "first_treat",
  data = as.data.frame(panel),
  control_group = "notyettreated",
  anticipation = 0,
  base_period = "varying"
)
agg_mvt <- aggte(cs_mvt, type = "simple")
es_mvt <- aggte(cs_mvt, type = "dynamic",
                 min_e = -10, max_e = 10)
cat("MVT (placebo) ATT:", round(agg_mvt$overall.att, 4),
    "(SE:", round(agg_mvt$overall.se, 4), ")\n")

# Save all CS-DiD results
saveRDS(list(
  property = cs_property, burglary = cs_burglary,
  larceny = cs_larceny, robbery = cs_robbery, mvt = cs_mvt,
  agg_property = agg_property, agg_burglary = agg_burglary,
  agg_larceny = agg_larceny, agg_robbery = agg_robbery,
  agg_mvt = agg_mvt,
  es_property = es_property, es_burglary = es_burglary,
  es_larceny = es_larceny, es_robbery = es_robbery,
  es_mvt = es_mvt
), file.path(data_dir, "cs_did_results.rds"))

# ===========================================================================
# 3. Bacon Decomposition (diagnose TWFE)
# ===========================================================================
cat("\n=== Bacon Decomposition ===\n")

# Need balanced panel for Bacon
balanced_years <- panel %>%
  count(state_id) %>%
  filter(n == max(n)) %>%
  pull(state_id)

panel_balanced <- panel %>%
  filter(state_id %in% balanced_years)

if (nrow(panel_balanced) > 100) {
  tryCatch({
    bacon_out <- bacon(log_property_crime ~ post_ebt,
                       data = as.data.frame(panel_balanced),
                       id_var = "state_id",
                       time_var = "year")
    cat("Bacon decomposition:\n")
    bacon_summary <- bacon_out %>%
      group_by(type) %>%
      summarise(
        n_comparisons = n(),
        avg_weight = mean(weight),
        avg_estimate = mean(estimate),
        weighted_avg = weighted.mean(estimate, weight),
        .groups = "drop"
      )
    print(bacon_summary)
    saveRDS(bacon_out, file.path(data_dir, "bacon_decomp.rds"))
  }, error = function(e) {
    cat("Bacon decomposition failed:", e$message, "\n")
  })
}

# ===========================================================================
# 4. Summary of Main Results
# ===========================================================================
cat("\n")
cat("=" |> rep(60) |> paste(collapse = ""), "\n")
cat("MAIN RESULTS SUMMARY\n")
cat("=" |> rep(60) |> paste(collapse = ""), "\n")

results_df <- data.frame(
  Outcome = c("Property Crime", "Burglary", "Larceny-Theft",
              "Robbery", "Motor Vehicle Theft (Placebo)"),
  CS_ATT = c(agg_property$overall.att, agg_burglary$overall.att,
             agg_larceny$overall.att, agg_robbery$overall.att,
             agg_mvt$overall.att),
  CS_SE = c(agg_property$overall.se, agg_burglary$overall.se,
            agg_larceny$overall.se, agg_robbery$overall.se,
            agg_mvt$overall.se),
  TWFE_coef = c(coef(twfe_property), coef(twfe_burglary),
                coef(twfe_larceny), coef(twfe_robbery),
                coef(twfe_mvt)),
  TWFE_SE = c(se(twfe_property), se(twfe_burglary),
              se(twfe_larceny), se(twfe_robbery),
              se(twfe_mvt))
) %>%
  mutate(
    CS_pct = round((exp(CS_ATT) - 1) * 100, 2),
    CS_stars = case_when(
      abs(CS_ATT / CS_SE) > 2.576 ~ "***",
      abs(CS_ATT / CS_SE) > 1.96 ~ "**",
      abs(CS_ATT / CS_SE) > 1.645 ~ "*",
      TRUE ~ ""
    )
  )

print(results_df)
fwrite(results_df, file.path(data_dir, "main_results.csv"))

cat("\nInterpretation: Coefficients are in log points.\n")
cat("Property crime: EBT reduced property crime by ~",
    abs(results_df$CS_pct[1]), "%\n")
cat("Burglary: EBT reduced burglary by ~",
    abs(results_df$CS_pct[2]), "%\n")

cat("\n=== Main analysis complete ===\n")
