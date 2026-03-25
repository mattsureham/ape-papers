## ============================================================================
## 03_main_analysis.R — Callaway-Sant'Anna DiD for NIBRS adoption effects
## ============================================================================

paper_dir <- here::here()
if (!requireNamespace("here", quietly = TRUE)) install.packages("here", repos = "https://cloud.r-project.org")
setwd(here::here())
source("code/00_packages.R")

panel <- readRDS("data/analysis_panel.rds")
cat("Loaded analysis panel:", nrow(panel), "obs\n")

## ---------------------------------------------------------------------------
## 1. TWFE baseline (for comparison — known to be biased with staggered adoption)
## ---------------------------------------------------------------------------

cat("\n=== TWFE BASELINE (for comparison only) ===\n")

twfe_violent <- feols(log_violent_rate ~ treated | state_id + year,
                      data = panel, cluster = ~state_id)
twfe_murder <- feols(log_murder_rate ~ treated | state_id + year,
                     data = panel, cluster = ~state_id)
twfe_property <- feols(log_property_rate ~ treated | state_id + year,
                       data = panel, cluster = ~state_id)
twfe_robbery <- feols(log_robbery_rate ~ treated | state_id + year,
                      data = panel, cluster = ~state_id)
twfe_burglary <- feols(log_burglary_rate ~ treated | state_id + year,
                       data = panel, cluster = ~state_id)

cat("TWFE (log violent):", round(coef(twfe_violent)["treated"], 4), "\n")
cat("TWFE (log murder):", round(coef(twfe_murder)["treated"], 4), "\n")
cat("TWFE (log property):", round(coef(twfe_property)["treated"], 4), "\n")
cat("TWFE (log robbery):", round(coef(twfe_robbery)["treated"], 4), "\n")
cat("TWFE (log burglary):", round(coef(twfe_burglary)["treated"], 4), "\n")

## ---------------------------------------------------------------------------
## 2. Callaway-Sant'Anna (robust to staggered adoption)
## ---------------------------------------------------------------------------

cat("\n=== CALLAWAY-SANT'ANNA DiD ===\n")

# Prepare data for CS-DiD
cs_data <- panel %>%
  mutate(
    # CS-DiD requires: idname, tname, gname (first treat year, 0 = never)
    id = state_id,
    t = year,
    g = first_treat
  ) %>%
  filter(!is.na(log_violent_rate))

# Main specification: Property crime (most affected by hierarchy rule)
cat("\n--- Property Crime Rate (Primary Outcome) ---\n")
cs_property <- att_gt(
  yname = "log_property_rate",
  tname = "t",
  idname = "id",
  gname = "g",
  data = cs_data,
  control_group = "nevertreated",
  base_period = "universal",
  anticipation = 0,
  est_method = "reg",
  allow_unbalanced_panel = TRUE,
  bstrap = TRUE,
  biters = 1000,
  cband = TRUE,
  pl = FALSE
)

# Aggregate: overall ATT
agg_property <- aggte(cs_property, type = "simple", na.rm = TRUE)
cat("Overall ATT (log property rate):", round(agg_property$overall.att, 4),
    " SE:", round(agg_property$overall.se, 4), "\n")

# Aggregate: event study
es_property <- aggte(cs_property, type = "dynamic",
                     min_e = -6, max_e = 6, na.rm = TRUE)

cat("\n--- Violent Crime Rate ---\n")
cs_violent <- att_gt(
  yname = "log_violent_rate",
  tname = "t",
  idname = "id",
  gname = "g",
  data = cs_data,
  control_group = "nevertreated",
  base_period = "universal",
  anticipation = 0,
  est_method = "reg",
  allow_unbalanced_panel = TRUE,
  bstrap = TRUE,
  biters = 1000,
  cband = TRUE,
  pl = FALSE
)
agg_violent <- aggte(cs_violent, type = "simple", na.rm = TRUE)
es_violent <- aggte(cs_violent, type = "dynamic", min_e = -6, max_e = 6, na.rm = TRUE)
cat("Overall ATT (log violent rate):", round(agg_violent$overall.att, 4),
    " SE:", round(agg_violent$overall.se, 4), "\n")

cat("\n--- Murder Rate (PLACEBO) ---\n")
cs_murder <- att_gt(
  yname = "log_murder_rate",
  tname = "t",
  idname = "id",
  gname = "g",
  data = cs_data,
  control_group = "nevertreated",
  base_period = "universal",
  anticipation = 0,
  est_method = "reg",
  allow_unbalanced_panel = TRUE,
  bstrap = TRUE,
  biters = 1000,
  cband = TRUE,
  pl = FALSE
)
agg_murder <- aggte(cs_murder, type = "simple", na.rm = TRUE)
es_murder <- aggte(cs_murder, type = "dynamic", min_e = -6, max_e = 6, na.rm = TRUE)
cat("Overall ATT (log murder rate):", round(agg_murder$overall.att, 4),
    " SE:", round(agg_murder$overall.se, 4), "\n")

cat("\n--- Robbery Rate ---\n")
cs_robbery <- att_gt(
  yname = "log_robbery_rate",
  tname = "t",
  idname = "id",
  gname = "g",
  data = cs_data,
  control_group = "nevertreated",
  base_period = "universal",
  anticipation = 0,
  est_method = "reg",
  allow_unbalanced_panel = TRUE,
  bstrap = TRUE,
  biters = 1000,
  cband = TRUE,
  pl = FALSE
)
agg_robbery <- aggte(cs_robbery, type = "simple", na.rm = TRUE)
cat("Overall ATT (log robbery rate):", round(agg_robbery$overall.att, 4),
    " SE:", round(agg_robbery$overall.se, 4), "\n")

cat("\n--- Burglary Rate ---\n")
cs_burglary <- att_gt(
  yname = "log_burglary_rate",
  tname = "t",
  idname = "id",
  gname = "g",
  data = cs_data,
  control_group = "nevertreated",
  base_period = "universal",
  anticipation = 0,
  est_method = "reg",
  allow_unbalanced_panel = TRUE,
  bstrap = TRUE,
  biters = 1000,
  cband = TRUE,
  pl = FALSE
)
agg_burglary <- aggte(cs_burglary, type = "simple", na.rm = TRUE)
cat("Overall ATT (log burglary rate):", round(agg_burglary$overall.att, 4),
    " SE:", round(agg_burglary$overall.se, 4), "\n")

cat("\n--- Aggravated Assault Rate ---\n")
cs_assault <- att_gt(
  yname = "log_assault_rate",
  tname = "t",
  idname = "id",
  gname = "g",
  data = cs_data,
  control_group = "nevertreated",
  base_period = "universal",
  anticipation = 0,
  est_method = "reg",
  allow_unbalanced_panel = TRUE,
  bstrap = TRUE,
  biters = 1000,
  cband = TRUE,
  pl = FALSE
)
agg_assault <- aggte(cs_assault, type = "simple", na.rm = TRUE)
cat("Overall ATT (log assault rate):", round(agg_assault$overall.att, 4),
    " SE:", round(agg_assault$overall.se, 4), "\n")

## ---------------------------------------------------------------------------
## 3. Summary of results
## ---------------------------------------------------------------------------

cat("\n\n=== RESULTS SUMMARY ===\n")
results <- tibble(
  outcome = c("Property crime", "Violent crime", "Murder (placebo)",
              "Robbery", "Burglary", "Aggravated assault"),
  att = c(agg_property$overall.att, agg_violent$overall.att,
          agg_murder$overall.att, agg_robbery$overall.att,
          agg_burglary$overall.att, agg_assault$overall.att),
  se = c(agg_property$overall.se, agg_violent$overall.se,
         agg_murder$overall.se, agg_robbery$overall.se,
         agg_burglary$overall.se, agg_assault$overall.se),
  pct_change = (exp(c(agg_property$overall.att, agg_violent$overall.att,
                      agg_murder$overall.att, agg_robbery$overall.att,
                      agg_burglary$overall.att, agg_assault$overall.att)) - 1) * 100
)
results$stars <- ifelse(abs(results$att / results$se) > 2.576, "***",
                 ifelse(abs(results$att / results$se) > 1.96, "**",
                 ifelse(abs(results$att / results$se) > 1.645, "*", "")))

print(results)

## ---------------------------------------------------------------------------
## 4. Save results for table generation
## ---------------------------------------------------------------------------

# Save all CS-DiD objects
save(cs_property, cs_violent, cs_murder, cs_robbery, cs_burglary, cs_assault,
     agg_property, agg_violent, agg_murder, agg_robbery, agg_burglary, agg_assault,
     es_property, es_violent, es_murder,
     twfe_violent, twfe_murder, twfe_property, twfe_robbery, twfe_burglary,
     results, cs_data,
     file = "data/main_results.RData")

# Write diagnostics for validator
diagnostics <- list(
  n_treated = sum(cs_data$g > 0 & !duplicated(cs_data$id)),
  n_pre = max(cs_data$t[cs_data$g == 0]) - min(cs_data$t[cs_data$g == 0]),
  n_obs = nrow(cs_data)
)
jsonlite::write_json(diagnostics, "data/diagnostics.json", auto_unbox = TRUE)
cat("\nDiagnostics:", jsonlite::toJSON(diagnostics, auto_unbox = TRUE), "\n")

cat("\nAll results saved to data/main_results.RData\n")
