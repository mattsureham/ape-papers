# 03_main_analysis.R — Main regressions
# apep_1057: The Consolidation Trap

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================================
# 1. Load analysis panel
# ============================================================================
panel <- fread(file.path(data_dir, "analysis_panel.csv"))

cat("Panel loaded:", nrow(panel), "rows\n")
cat("Systems:", uniqueN(panel$pwsid), "\n")
cat("Treated:", uniqueN(panel$pwsid[panel$treated == TRUE]), "\n")

# ============================================================================
# 2. TWFE Baseline
# ============================================================================
cat("\n=== TWFE Regressions ===\n")

# Model 1: Binary violation indicator
twfe_binary <- feols(
  has_violation ~ post | pwsid + qtr_idx,
  data = panel,
  cluster = ~state
)
cat("\nTWFE (binary violation):\n")
summary(twfe_binary)

# Model 2: Violation count
twfe_count <- feols(
  n_health_viols ~ post | pwsid + qtr_idx,
  data = panel,
  cluster = ~state
)
cat("\nTWFE (violation count):\n")
summary(twfe_count)

# Model 3: With population-served interaction (dose-response)
panel[, high_dose := as.integer(total_pop_deactivated > median(
  total_pop_deactivated[treated == TRUE], na.rm = TRUE))]
panel[treated == FALSE, high_dose := 0]

twfe_dose <- feols(
  has_violation ~ post + post:high_dose | pwsid + qtr_idx,
  data = panel,
  cluster = ~state
)
cat("\nTWFE (dose-response):\n")
summary(twfe_dose)

# ============================================================================
# 3. Callaway-Sant'Anna Staggered DiD
# ============================================================================
cat("\n=== Callaway-Sant'Anna ===\n")

# For CS: use 20% random sample of never-treated + all treated (memory/time)
set.seed(42)
nt_ids <- unique(panel$pwsid[panel$treated == FALSE])
nt_sample <- sample(nt_ids, min(7500, length(nt_ids)))
cs_panel <- panel[treated == TRUE | pwsid %in% nt_sample]

cs_data <- cs_panel[, .(
  id = as.integer(factor(pwsid)),
  time = qtr_idx,
  first_treat = first_treat_idx,
  y_binary = has_violation,
  y_count = n_health_viols,
  cluster_var = as.integer(factor(state))
)]

cat("CS sample:", uniqueN(cs_data$id), "systems,", nrow(cs_data), "obs\n")

# CS estimation — binary outcome
cs_binary <- att_gt(
  yname = "y_binary",
  tname = "time",
  idname = "id",
  gname = "first_treat",
  data = cs_data,
  control_group = "nevertreated",
  est_method = "dr",
  clustervars = "cluster_var",
  anticipation = 0,
  base_period = "varying"
)

cat("\nCS group-time ATTs computed.\n")

# Aggregate: simple ATT
cs_agg_simple <- aggte(cs_binary, type = "simple")
cat("\nCS Simple ATT:\n")
summary(cs_agg_simple)

# Aggregate: dynamic (event study)
cs_agg_dynamic <- aggte(cs_binary, type = "dynamic", min_e = -8, max_e = 12)
cat("\nCS Dynamic ATT:\n")
summary(cs_agg_dynamic)

# CS estimation — count outcome (same sample)
cs_count <- att_gt(
  yname = "y_count",
  tname = "time",
  idname = "id",
  gname = "first_treat",
  data = cs_data,
  control_group = "nevertreated",
  est_method = "reg",
  clustervars = "cluster_var",
  anticipation = 0,
  base_period = "varying"
)

cs_count_simple <- aggte(cs_count, type = "simple")
cat("\nCS Simple ATT (count):\n")
summary(cs_count_simple)

cs_count_dynamic <- aggte(cs_count, type = "dynamic", min_e = -8, max_e = 12)

# ============================================================================
# 4. Pre-trends test
# ============================================================================
cat("\n=== Pre-trends Assessment ===\n")

# Extract pre-treatment dynamic effects
es_data <- data.frame(
  e = cs_agg_dynamic$egt,
  att = cs_agg_dynamic$att.egt,
  se = cs_agg_dynamic$se.egt
)
es_data$ci_lower <- es_data$att - 1.96 * es_data$se
es_data$ci_upper <- es_data$att + 1.96 * es_data$se

pre_effects <- es_data[es_data$e < 0, ]
cat("Pre-treatment effects:\n")
print(pre_effects)

# Joint test: are pre-treatment effects jointly zero?
pre_signif <- sum(abs(pre_effects$att / pre_effects$se) > 1.96)
cat("\nPre-treatment periods with |t| > 1.96:", pre_signif, "out of",
    nrow(pre_effects), "\n")

# ============================================================================
# 5. Save results
# ============================================================================

# Diagnostics for validator
n_treated <- uniqueN(panel$pwsid[panel$treated == TRUE])
# Minimum pre-periods across treated units (each has ≥8 by construction)
n_pre <- panel[treated == TRUE, min(n_pre)]
n_obs <- nrow(panel)

write_json(list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  twfe_coef = coef(twfe_binary)["post"],
  twfe_se = sqrt(vcov(twfe_binary)["post", "post"]),
  cs_att = cs_agg_simple$overall.att,
  cs_se = cs_agg_simple$overall.se
), file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)

# Save event study data for reference
fwrite(es_data, file.path(data_dir, "event_study_data.csv"))

# Save CS count event study
es_count_data <- data.frame(
  e = cs_count_dynamic$egt,
  att = cs_count_dynamic$att.egt,
  se = cs_count_dynamic$se.egt
)
es_count_data$ci_lower <- es_count_data$att - 1.96 * es_count_data$se
es_count_data$ci_upper <- es_count_data$att + 1.96 * es_count_data$se
fwrite(es_count_data, file.path(data_dir, "event_study_count_data.csv"))

# Save all model objects
save(twfe_binary, twfe_count, twfe_dose,
     cs_binary, cs_agg_simple, cs_agg_dynamic,
     cs_count, cs_count_simple, cs_count_dynamic,
     es_data, es_count_data,
     file = file.path(data_dir, "main_results.RData"))

cat("\n=== Main analysis complete ===\n")
cat("TWFE binary coef:", round(coef(twfe_binary)["post"], 5), "\n")
cat("CS ATT:", round(cs_agg_simple$overall.att, 5), "\n")
