## 03_main_analysis.R — Main DiD analysis
## apep_1408: PNIS coca substitution in Colombia

source("00_packages.R")

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))

## ─────────────────────────────────────────────────
## 1. Callaway-Sant'Anna ATT(g,t)
## ─────────────────────────────────────────────────

cat("=== Callaway-Sant'Anna Estimation ===\n")

# Ensure panel is balanced and sorted
panel_cs <- panel %>%
  # Use numeric municipality ID
  mutate(muni_id = as.integer(factor(codmpio))) %>%
  arrange(muni_id, year)

# Check balance
muni_years <- panel_cs %>% count(muni_id)
cat("Min years per muni:", min(muni_years$n), "\n")
cat("Max years per muni:", max(muni_years$n), "\n")
cat("Unique treatment groups:", paste(sort(unique(panel_cs$first_treat)), collapse = ", "), "\n")

# Run CS with never-treated comparison
cs_out <- att_gt(
  yname = "ihs_coca",
  tname = "year",
  idname = "muni_id",
  gname = "first_treat",
  data = panel_cs,
  control_group = "nevertreated",
  anticipation = 0,
  bstrap = TRUE,
  cband = TRUE,
  biters = 1000
)

cat("\n--- ATT(g,t) Summary ---\n")
print(summary(cs_out))

# Save CS output
saveRDS(cs_out, file.path(data_dir, "cs_results.rds"))

## ─────────────────────────────────────────────────
## 2. Event study aggregation
## ─────────────────────────────────────────────────

es <- aggte(cs_out, type = "dynamic", min_e = -10, max_e = 6)
cat("\n--- Event Study ---\n")
print(summary(es))

saveRDS(es, file.path(data_dir, "es_results.rds"))

## ─────────────────────────────────────────────────
## 3. Simple aggregate ATT
## ─────────────────────────────────────────────────

agg <- aggte(cs_out, type = "simple")
cat("\n--- Simple ATT ---\n")
print(summary(agg))

saveRDS(agg, file.path(data_dir, "agg_results.rds"))

## ─────────────────────────────────────────────────
## 4. Group-specific ATTs
## ─────────────────────────────────────────────────

group_agg <- aggte(cs_out, type = "group")
cat("\n--- Group-Specific ATTs ---\n")
print(summary(group_agg))

saveRDS(group_agg, file.path(data_dir, "group_results.rds"))

## ─────────────────────────────────────────────────
## 5. TWFE comparison (for reference)
## ─────────────────────────────────────────────────

cat("\n=== TWFE Comparison ===\n")

twfe_basic <- feols(
  ihs_coca ~ post | codmpio + year,
  data = panel_cs,
  cluster = ~codmpio
)
cat("TWFE basic:\n")
print(summary(twfe_basic))

# Sun-Abraham robust estimator
panel_cs <- panel_cs %>%
  mutate(
    cohort = if_else(first_treat == 0, Inf, as.numeric(first_treat))
  )

sunab_est <- feols(
  ihs_coca ~ sunab(cohort, year) | codmpio + year,
  data = panel_cs,
  cluster = ~codmpio
)
cat("\nSun-Abraham:\n")
print(summary(sunab_est))

saveRDS(twfe_basic, file.path(data_dir, "twfe_results.rds"))
saveRDS(sunab_est, file.path(data_dir, "sunab_results.rds"))

## ─────────────────────────────────────────────────
## 6. Eradication outcome
## ─────────────────────────────────────────────────

cat("\n=== Eradication Analysis ===\n")

cs_erad <- att_gt(
  yname = "ihs_erad",
  tname = "year",
  idname = "muni_id",
  gname = "first_treat",
  data = panel_cs %>% filter(year >= 2007),
  control_group = "nevertreated",
  anticipation = 0,
  bstrap = TRUE,
  biters = 1000
)

es_erad <- aggte(cs_erad, type = "dynamic", min_e = -5, max_e = 5)
agg_erad <- aggte(cs_erad, type = "simple")

cat("Eradication event study:\n")
print(summary(es_erad))
cat("Eradication simple ATT:\n")
print(summary(agg_erad))

saveRDS(cs_erad, file.path(data_dir, "cs_erad_results.rds"))
saveRDS(es_erad, file.path(data_dir, "es_erad_results.rds"))

## ─────────────────────────────────────────────────
## 7. Diagnostics for validator
## ─────────────────────────────────────────────────

n_treated <- n_distinct(panel_cs$muni_id[panel_cs$first_treat > 0])
n_pre <- length(unique(panel_cs$year[panel_cs$year < 2017]))
n_obs <- nrow(panel_cs)

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  att_simple = agg$overall.att,
  att_se = agg$overall.se,
  n_municipalities = n_distinct(panel_cs$codmpio),
  n_years = n_distinct(panel_cs$year)
)

write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)
cat("\nDiagnostics saved. n_treated =", n_treated, ", n_pre =", n_pre, ", n_obs =", n_obs, "\n")
