## 03_main_analysis.R — Callaway-Sant'Anna DiD + TWFE
## apep_1028: Right-to-Counsel and Community-Level Homelessness

source("00_packages.R")

panel <- readRDS("../data/panel.rds")

cat("=== Panel summary ===\n")
cat("Rows:", nrow(panel), "\n")
cat("CoCs:", n_distinct(panel$coc_code), "\n")
cat("Years:", paste(range(panel$year), collapse = "-"), "\n")
cat("Treated CoCs:", n_distinct(panel$coc_code[panel$first_treat > 0]), "\n")

# --- Assign numeric CoC ID for CS estimator ---
panel <- panel |>
  mutate(coc_id = as.integer(factor(coc_code)))

# ============================================================
# 1. CALLAWAY-SANT'ANNA: Total Homelessness
# ============================================================
cat("\n=== CS-DiD: Log Total Homeless ===\n")

cs_total <- att_gt(
  yname = "log_total",
  tname = "year",
  idname = "coc_id",
  gname = "first_treat",
  data = panel,
  control_group = "nevertreated",
  base_period = "universal"
)

# Aggregate to event study
es_total <- aggte(cs_total, type = "dynamic", min_e = -8, max_e = 6)
cat("\nEvent study (total homeless):\n")
summary(es_total)

# Aggregate to overall ATT
att_total <- aggte(cs_total, type = "simple")
cat("\nOverall ATT (total homeless):\n")
summary(att_total)

# ============================================================
# 2. CS-DiD: Sheltered Homelessness
# ============================================================
cat("\n=== CS-DiD: Log Sheltered Homeless ===\n")

cs_sheltered <- att_gt(
  yname = "log_sheltered",
  tname = "year",
  idname = "coc_id",
  gname = "first_treat",
  data = panel,
  control_group = "nevertreated",
  base_period = "universal"
)

es_sheltered <- aggte(cs_sheltered, type = "dynamic", min_e = -8, max_e = 6)
att_sheltered <- aggte(cs_sheltered, type = "simple")
cat("\nOverall ATT (sheltered):\n")
summary(att_sheltered)

# ============================================================
# 3. CS-DiD: Unsheltered Homelessness (placebo mechanism)
# ============================================================
cat("\n=== CS-DiD: Log Unsheltered Homeless ===\n")

cs_unsheltered <- att_gt(
  yname = "log_unsheltered",
  tname = "year",
  idname = "coc_id",
  gname = "first_treat",
  data = panel,
  control_group = "nevertreated",
  base_period = "universal"
)

es_unsheltered <- aggte(cs_unsheltered, type = "dynamic", min_e = -8, max_e = 6)
att_unsheltered <- aggte(cs_unsheltered, type = "simple")
cat("\nOverall ATT (unsheltered):\n")
summary(att_unsheltered)

# ============================================================
# 4. CS-DiD: Homeless Families
# ============================================================
cat("\n=== CS-DiD: Log Homeless Families ===\n")

# Families variable has NAs in early years — restrict to non-missing
panel_fam <- panel |> filter(!is.na(log_family))

cs_family <- att_gt(
  yname = "log_family",
  tname = "year",
  idname = "coc_id",
  gname = "first_treat",
  data = panel_fam,
  control_group = "nevertreated",
  base_period = "universal"
)

es_family <- aggte(cs_family, type = "dynamic", min_e = -8, max_e = 6)
att_family <- aggte(cs_family, type = "simple")
cat("\nOverall ATT (families):\n")
summary(att_family)

# ============================================================
# 5. TWFE for comparison
# ============================================================
cat("\n=== TWFE regressions ===\n")

twfe_total <- feols(log_total ~ treated | coc_id + year, data = panel,
                    cluster = ~coc_id)
twfe_sheltered <- feols(log_sheltered ~ treated | coc_id + year, data = panel,
                        cluster = ~coc_id)
twfe_unsheltered <- feols(log_unsheltered ~ treated | coc_id + year, data = panel,
                          cluster = ~coc_id)
twfe_family <- feols(log_family ~ treated | coc_id + year, data = panel_fam,
                     cluster = ~coc_id)

etable(twfe_total, twfe_sheltered, twfe_unsheltered, twfe_family,
       headers = c("Total", "Sheltered", "Unsheltered", "Families"))

# ============================================================
# 6. Save results
# ============================================================
results <- list(
  cs_total = cs_total,
  cs_sheltered = cs_sheltered,
  cs_unsheltered = cs_unsheltered,
  cs_family = cs_family,
  es_total = es_total,
  es_sheltered = es_sheltered,
  es_unsheltered = es_unsheltered,
  es_family = es_family,
  att_total = att_total,
  att_sheltered = att_sheltered,
  att_unsheltered = att_unsheltered,
  att_family = att_family,
  twfe_total = twfe_total,
  twfe_sheltered = twfe_sheltered,
  twfe_unsheltered = twfe_unsheltered,
  twfe_family = twfe_family
)

saveRDS(results, "../data/main_results.rds")

# --- Diagnostics for validator ---
diag <- list(
  n_treated = n_distinct(panel$coc_code[panel$first_treat > 0]),
  n_pre = length(2007:2016),  # 10 pre-periods for earliest (2017) cohort
  n_obs = nrow(panel)
)
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)

cat("\n=== Main analysis complete ===\n")
cat("n_treated:", diag$n_treated, "\n")
cat("n_pre:", diag$n_pre, "\n")
cat("n_obs:", diag$n_obs, "\n")
