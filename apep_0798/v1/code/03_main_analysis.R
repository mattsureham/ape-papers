# ==============================================================================
# 03_main_analysis.R — Main econometric analysis
# Paper: Frictionless Highways (apep_0798)
# ==============================================================================

source("code/00_packages.R")

data_dir <- "data"

# ── Load Data ────────────────────────────────────────────────────────────────
mob <- fread(file.path(data_dir, "mobility_weekly_panel.csv"))
plaza_cross <- fread(file.path(data_dir, "plaza_cross_section.csv"))
district_treat <- fread(file.path(data_dir, "district_treatment.csv"))

cat("=== MAIN ANALYSIS ===\n")
cat(sprintf("Panel: %d district-weeks, %d districts\n",
            nrow(mob), uniqueN(mob$sub_region_2)))

# ── Create district ID for FE ────────────────────────────────────────────────
mob[, district_id := as.factor(sub_region_2)]
mob[, state_id := as.factor(sub_region_1)]
mob[, week_id := as.factor(year_week)]

# Standardize n_plazas (continuous treatment)
mob[, n_plazas_std := n_plazas / sd(n_plazas[n_plazas > 0], na.rm = TRUE)]

# ── 1. Summary Statistics ────────────────────────────────────────────────────
cat("\n--- Table 1: Summary Statistics ---\n")

summ_pre <- mob[post_mandate == 0, .(
  mean_transit = mean(transit, na.rm = TRUE),
  sd_transit = sd(transit, na.rm = TRUE),
  mean_workplace = mean(workplace, na.rm = TRUE),
  sd_workplace = sd(workplace, na.rm = TRUE),
  mean_retail = mean(retail, na.rm = TRUE),
  sd_retail = sd(retail, na.rm = TRUE),
  n_dist = uniqueN(sub_region_2),
  n_weeks = uniqueN(year_week)
), by = has_plaza]

summ_post <- mob[post_mandate == 1, .(
  mean_transit = mean(transit, na.rm = TRUE),
  sd_transit = sd(transit, na.rm = TRUE),
  mean_workplace = mean(workplace, na.rm = TRUE),
  sd_workplace = sd(workplace, na.rm = TRUE),
  mean_retail = mean(retail, na.rm = TRUE),
  sd_retail = sd(retail, na.rm = TRUE)
), by = has_plaza]

cat("Pre-mandate:\n"); print(summ_pre)
cat("Post-mandate:\n"); print(summ_post)

# ── 2. Main DiD: Transit Mobility ───────────────────────────────────────────
cat("\n--- Main DiD Specifications ---\n")

# Specification 1: Basic DiD with district + week FE
did1 <- feols(
  transit ~ has_plaza:post_mandate | district_id + week_id,
  data = mob,
  cluster = ~state_id
)
cat("Spec 1 (district + week FE):\n")
print(summary(did1))

# Specification 2: Add state × week FE (preferred)
did2 <- feols(
  transit ~ has_plaza:post_mandate | district_id + state_id^week_id,
  data = mob,
  cluster = ~state_id
)
cat("Spec 2 (district + state×week FE, preferred):\n")
print(summary(did2))

# Specification 3: Continuous treatment (# plazas)
did3 <- feols(
  transit ~ n_plazas_std:post_mandate | district_id + state_id^week_id,
  data = mob,
  cluster = ~state_id
)
cat("Spec 3 (continuous treatment, state×week FE):\n")
print(summary(did3))

# ── 3. Event Study ───────────────────────────────────────────────────────────
cat("\n--- Event Study ---\n")

# Bin event months at edges to avoid singletons
mob[, event_month_bin := fcase(
  event_month < -11, -12L,
  event_month > 19, 20L,
  default = event_month
)]

# Event study: month-level interaction
es <- feols(
  transit ~ i(event_month_bin, has_plaza, ref = -1) | district_id + state_id^week_id,
  data = mob,
  cluster = ~state_id
)
cat("Event study coefficients:\n")
es_coefs <- coeftable(es)
print(es_coefs)

# ── 4. Alternative Outcomes ──────────────────────────────────────────────────
cat("\n--- Alternative Outcomes ---\n")

# Workplace mobility
did_work <- feols(
  workplace ~ has_plaza:post_mandate | district_id + state_id^week_id,
  data = mob,
  cluster = ~state_id
)
cat("Workplace mobility DiD:\n")
print(summary(did_work))

# Retail mobility
did_retail <- feols(
  retail ~ has_plaza:post_mandate | district_id + state_id^week_id,
  data = mob,
  cluster = ~state_id
)
cat("Retail mobility DiD:\n")
print(summary(did_retail))

# Residential (placebo — should be null or opposite)
did_resid <- feols(
  residential ~ has_plaza:post_mandate | district_id + state_id^week_id,
  data = mob,
  cluster = ~state_id
)
cat("Residential (placebo) DiD:\n")
print(summary(did_resid))

# ── 5. Treatment Intensity Heterogeneity ─────────────────────────────────────
cat("\n--- Heterogeneity by Traffic Intensity ---\n")

# By traffic tercile
did_het <- feols(
  transit ~ i(traffic_tercile, post_mandate, ref = "No Plaza") |
    district_id + state_id^week_id,
  data = mob[!is.na(traffic_tercile)],
  cluster = ~state_id
)
cat("Heterogeneity by traffic tercile:\n")
print(summary(did_het))

# ── 6. Save Results ─────────────────────────────────────────────────────────
results <- list(
  did1 = did1,
  did2 = did2,
  did3 = did3,
  es = es,
  did_work = did_work,
  did_retail = did_retail,
  did_resid = did_resid,
  did_het = did_het
)
saveRDS(results, file.path(data_dir, "main_results.rds"))

# ── 7. Diagnostics ──────────────────────────────────────────────────────────
diag <- list(
  n_treated = uniqueN(mob[has_plaza == 1]$sub_region_2),
  n_pre = uniqueN(mob[post_mandate == 0]$year_week),
  n_obs = nrow(mob),
  n_districts = uniqueN(mob$sub_region_2),
  n_states = uniqueN(mob$sub_region_1),
  n_plazas_total = nrow(plaza_cross),
  pre_sd_transit = sd(mob[post_mandate == 0]$transit, na.rm = TRUE),
  pre_sd_workplace = sd(mob[post_mandate == 0]$workplace, na.rm = TRUE)
)
jsonlite::write_json(diag, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)

cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d, pre_sd_transit=%.1f\n",
            diag$n_treated, diag$n_pre, diag$n_obs, diag$pre_sd_transit))

cat("\nMain analysis complete.\n")
