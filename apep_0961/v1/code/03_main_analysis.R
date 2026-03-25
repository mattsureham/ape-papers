# 03_main_analysis.R — Main DiD estimation
# apep_0961: Swiss tobacco billboard bans and healthcare costs

source("00_packages.R")

panel_total <- readRDS("../data/panel_total.rds")
panel_cat   <- readRDS("../data/panel_cat.rds")

# ============================================================================
# 1. Callaway & Sant'Anna — Main specification (total costs)
# ============================================================================
cat("=== Callaway & Sant'Anna: Total Per-Capita Healthcare Costs ===\n\n")

# CS-DiD requires: yname, tname, idname, gname (treatment cohort year, 0=never)
cs_total <- att_gt(
  yname       = "ln_cost",
  tname       = "year",
  idname      = "canton_id",
  gname       = "ban_year",
  data        = as.data.frame(panel_total),
  control_group = "nevertreated",
  anticipation  = 0,
  est_method    = "dr",  # doubly robust
  base_period   = "universal"
)

cat("Group-time ATTs:\n")
summary(cs_total)

# Aggregate: simple ATT
agg_simple <- aggte(cs_total, type = "simple")
cat("\n=== Simple ATT (overall) ===\n")
summary(agg_simple)

# Aggregate: dynamic (event-study)
agg_dynamic <- aggte(cs_total, type = "dynamic", min_e = -10, max_e = 15)
cat("\n=== Dynamic ATT (event study) ===\n")
summary(agg_dynamic)

# Aggregate: by cohort group
agg_group <- aggte(cs_total, type = "group")
cat("\n=== Group-specific ATTs ===\n")
summary(agg_group)

# ============================================================================
# 2. TWFE comparison (for sign-flip detection)
# ============================================================================
cat("\n=== TWFE Comparison ===\n")

twfe_total <- feols(ln_cost ~ treated_post | canton_id + year,
                    data = panel_total, cluster = ~canton_id)
summary(twfe_total)

# Sun & Abraham (interaction-weighted)
panel_total[, cohort := fifelse(ban_year == 0, 10000L, ban_year)]
sa_total <- feols(ln_cost ~ sunab(cohort, year) | canton_id + year,
                  data = panel_total, cluster = ~canton_id)
cat("\n=== Sun & Abraham ===\n")
summary(sa_total)

# ============================================================================
# 3. Category-level analysis (smoking-related vs placebo)
# ============================================================================
cat("\n=== Category-Level Analysis ===\n")

# Smoking-related categories
panel_smoke <- panel_cat[category_type == "smoking_related"]
panel_smoke[, cat_id := as.integer(as.factor(paste(canton_iso, cost_group)))]

# Aggregate smoking-related costs per canton-year
smoke_agg <- panel_cat[category_type == "smoking_related",
                       .(cost_pc = sum(cost_pc)), by = .(canton_iso, year, ban_year,
                                                          treated_ever, treated_post,
                                                          years_since_ban, canton_name)]
smoke_agg[, canton_id := as.integer(as.factor(canton_iso))]
smoke_agg[, ln_cost := log(cost_pc)]

cs_smoke <- att_gt(
  yname = "ln_cost", tname = "year", idname = "canton_id", gname = "ban_year",
  data = as.data.frame(smoke_agg), control_group = "nevertreated",
  anticipation = 0, est_method = "dr", base_period = "universal"
)
agg_smoke <- aggte(cs_smoke, type = "simple")
cat("\nSmoking-related categories ATT:\n")
summary(agg_smoke)

agg_smoke_dyn <- aggte(cs_smoke, type = "dynamic", min_e = -10, max_e = 15)

# Placebo categories
placebo_agg <- panel_cat[category_type == "placebo",
                         .(cost_pc = sum(cost_pc)), by = .(canton_iso, year, ban_year,
                                                            treated_ever, treated_post,
                                                            years_since_ban, canton_name)]
placebo_agg[, canton_id := as.integer(as.factor(canton_iso))]
placebo_agg[, ln_cost := log(cost_pc)]

cs_placebo <- att_gt(
  yname = "ln_cost", tname = "year", idname = "canton_id", gname = "ban_year",
  data = as.data.frame(placebo_agg), control_group = "nevertreated",
  anticipation = 0, est_method = "dr", base_period = "universal"
)
agg_placebo <- aggte(cs_placebo, type = "simple")
cat("\nPlacebo categories ATT:\n")
summary(agg_placebo)

agg_placebo_dyn <- aggte(cs_placebo, type = "dynamic", min_e = -10, max_e = 15)

# ============================================================================
# 4. Save results
# ============================================================================
results <- list(
  cs_total = cs_total,
  agg_simple = agg_simple,
  agg_dynamic = agg_dynamic,
  agg_group = agg_group,
  twfe_total = twfe_total,
  sa_total = sa_total,
  cs_smoke = cs_smoke,
  agg_smoke = agg_smoke,
  agg_smoke_dyn = agg_smoke_dyn,
  cs_placebo = cs_placebo,
  agg_placebo = agg_placebo,
  agg_placebo_dyn = agg_placebo_dyn
)
saveRDS(results, "../data/main_results.rds")

# ============================================================================
# 5. Write diagnostics.json
# ============================================================================
min_ban_excl_first <- min(panel_total$ban_year[panel_total$ban_year > min(panel_total$year)])
diagnostics <- list(
  n_treated = length(unique(panel_total$canton_iso[panel_total$treated_ever == 1])),
  n_pre = length(unique(panel_total$year[panel_total$year < min_ban_excl_first])),
  n_obs = nrow(panel_total),
  n_cantons = length(unique(panel_total$canton_iso)),
  n_years = length(unique(panel_total$year)),
  att_total = agg_simple$overall.att,
  se_total = agg_simple$overall.se,
  twfe_coef = coef(twfe_total)["treated_post"],
  twfe_se = sqrt(vcov(twfe_total)["treated_post", "treated_post"]),
  att_smoke = agg_smoke$overall.att,
  se_smoke = agg_smoke$overall.se,
  att_placebo = agg_placebo$overall.att,
  se_placebo = agg_placebo$overall.se
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)

cat("\n=== Key Results Summary ===\n")
cat(sprintf("Total ATT (CS-DiD):     %.4f (SE: %.4f)\n", agg_simple$overall.att, agg_simple$overall.se))
cat(sprintf("TWFE coefficient:        %.4f (SE: %.4f)\n", coef(twfe_total)["treated_post"],
            sqrt(vcov(twfe_total)["treated_post", "treated_post"])))
cat(sprintf("Smoking-related ATT:     %.4f (SE: %.4f)\n", agg_smoke$overall.att, agg_smoke$overall.se))
cat(sprintf("Placebo ATT:             %.4f (SE: %.4f)\n", agg_placebo$overall.att, agg_placebo$overall.se))
cat("\nDiagnostics saved to data/diagnostics.json\n")
