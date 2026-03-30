## 03_main_analysis.R — Callaway-Sant'Anna staggered DiD
## apep_1157: Seguro Popular and Cause-Specific Infant Mortality

source("00_packages.R")

panel <- fread("../data/panel_clean.csv")
cat(sprintf("Analysis panel: %d obs, %d municipalities\n",
            nrow(panel), length(unique(panel$mun_id))))

# ============================================================
# PART 1: Callaway-Sant'Anna estimation
# ============================================================
# The `did` package requires:
#   yname: outcome
#   tname: time period
#   idname: unit identifier
#   gname: first treatment period (0 for never-treated)

# Set never-treated coding: did package expects 0 for never-treated
# All municipalities have first_treat in 2002-2005 (no never-treated)
# Use not-yet-treated as controls

cat("\n=== CALLAWAY-SANT'ANNA ESTIMATION ===\n")

# Main outcome: amenable mortality rate
cat("\n--- Amenable Mortality Rate ---\n")
cs_amenable <- att_gt(
  yname = "amenable_mr",
  tname = "year",
  idname = "mun_num",
  gname = "first_treat",
  data = as.data.frame(panel),
  control_group = "notyettreated",
  base_period = "universal",
  est_method = "dr",
  clustervars = "state_code",
  print_details = FALSE
)

# Aggregate to event study
es_amenable <- aggte(cs_amenable, type = "dynamic", min_e = -4, max_e = 8)
cat("Event study (amenable):\n")
summary(es_amenable)

# Overall ATT
att_amenable <- aggte(cs_amenable, type = "simple")
cat("\nOverall ATT (amenable):\n")
summary(att_amenable)

# Non-amenable outcome (placebo)
cat("\n--- Non-Amenable Mortality Rate (Placebo) ---\n")
cs_nonamenable <- att_gt(
  yname = "non_amenable_mr",
  tname = "year",
  idname = "mun_num",
  gname = "first_treat",
  data = as.data.frame(panel),
  control_group = "notyettreated",
  base_period = "universal",
  est_method = "dr",
  clustervars = "state_code",
  print_details = FALSE
)

es_nonamenable <- aggte(cs_nonamenable, type = "dynamic", min_e = -4, max_e = 8)
cat("Event study (non-amenable):\n")
summary(es_nonamenable)

att_nonamenable <- aggte(cs_nonamenable, type = "simple")
cat("\nOverall ATT (non-amenable):\n")
summary(att_nonamenable)

# Overall IMR
cat("\n--- Overall Infant Mortality Rate ---\n")
cs_imr <- att_gt(
  yname = "imr",
  tname = "year",
  idname = "mun_num",
  gname = "first_treat",
  data = as.data.frame(panel),
  control_group = "notyettreated",
  base_period = "universal",
  est_method = "dr",
  clustervars = "state_code",
  print_details = FALSE
)

es_imr <- aggte(cs_imr, type = "dynamic", min_e = -4, max_e = 8)
cat("Event study (IMR):\n")
summary(es_imr)

att_imr <- aggte(cs_imr, type = "simple")
cat("\nOverall ATT (IMR):\n")
summary(att_imr)

# Neonatal mortality
cat("\n--- Neonatal Mortality Rate ---\n")
cs_nmr <- att_gt(
  yname = "nmr",
  tname = "year",
  idname = "mun_num",
  gname = "first_treat",
  data = as.data.frame(panel),
  control_group = "notyettreated",
  base_period = "universal",
  est_method = "dr",
  clustervars = "state_code",
  print_details = FALSE
)

att_nmr <- aggte(cs_nmr, type = "simple")
cat("\nOverall ATT (neonatal):\n")
summary(att_nmr)

# ============================================================
# PART 2: TWFE comparison (for robustness discussion)
# ============================================================
cat("\n=== TWFE COMPARISON (fixest) ===\n")

twfe_amenable <- feols(amenable_mr ~ treated | mun_num + year,
                       data = panel, cluster = ~state_code)
twfe_nonamenable <- feols(non_amenable_mr ~ treated | mun_num + year,
                          data = panel, cluster = ~state_code)
twfe_imr <- feols(imr ~ treated | mun_num + year,
                  data = panel, cluster = ~state_code)

cat("TWFE results:\n")
cat(sprintf("  Amenable MR:     coef = %.3f, SE = %.3f, p = %.4f\n",
            coef(twfe_amenable)["treated"],
            se(twfe_amenable)["treated"],
            pvalue(twfe_amenable)["treated"]))
cat(sprintf("  Non-amenable MR: coef = %.3f, SE = %.3f, p = %.4f\n",
            coef(twfe_nonamenable)["treated"],
            se(twfe_nonamenable)["treated"],
            pvalue(twfe_nonamenable)["treated"]))
cat(sprintf("  Overall IMR:     coef = %.3f, SE = %.3f, p = %.4f\n",
            coef(twfe_imr)["treated"],
            se(twfe_imr)["treated"],
            pvalue(twfe_imr)["treated"]))

# ============================================================
# PART 3: Save results for tables
# ============================================================

results <- list(
  cs_amenable = cs_amenable,
  cs_nonamenable = cs_nonamenable,
  cs_imr = cs_imr,
  cs_nmr = cs_nmr,
  es_amenable = es_amenable,
  es_nonamenable = es_nonamenable,
  es_imr = es_imr,
  att_amenable = att_amenable,
  att_nonamenable = att_nonamenable,
  att_imr = att_imr,
  att_nmr = att_nmr,
  twfe_amenable = twfe_amenable,
  twfe_nonamenable = twfe_nonamenable,
  twfe_imr = twfe_imr
)

saveRDS(results, "../data/main_results.rds")

# Write diagnostics.json for validation
diag <- list(
  n_treated = length(unique(panel[treated == 1, mun_num])),
  n_pre = length(unique(panel[year < min(panel$first_treat), year])),
  n_obs = nrow(panel),
  n_municipalities = length(unique(panel$mun_id)),
  n_states = length(unique(panel$state_code)),
  att_amenable = as.numeric(att_amenable$overall.att),
  se_amenable = as.numeric(att_amenable$overall.se),
  att_nonamenable = as.numeric(att_nonamenable$overall.att),
  se_nonamenable = as.numeric(att_nonamenable$overall.se),
  att_imr = as.numeric(att_imr$overall.att),
  se_imr = as.numeric(att_imr$overall.se)
)

jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)
cat("\nResults and diagnostics saved.\n")
