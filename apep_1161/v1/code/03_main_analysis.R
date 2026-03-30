# 03_main_analysis.R — Main DiD analysis
# apep_1161: The Compliance Upgrade

source("00_packages.R")

# ---- Load data ----
panel_pc <- fread("../data/analysis_panel_pc.csv")
panel_diesel <- fread("../data/analysis_panel_diesel.csv")
panel_petrol <- fread("../data/analysis_panel_petrol.csv")

cat("Panel dimensions: ", nrow(panel_pc), "obs,",
    uniqueN(panel_pc$postcode_area), "areas,",
    length(unique(panel_pc$year)), "years\n")

# ---- TABLE 1: Summary Statistics ----
# Split by treated vs never-treated, pre-treatment (2017-2018)
pre <- panel_pc[year <= 2018]

summ_treated <- pre[g_period > 0, .(
  mean_fail = mean(fail_rate),
  sd_fail = sd(fail_rate),
  mean_age = mean(avg_age, na.rm = TRUE),
  mean_mileage = mean(avg_mileage, na.rm = TRUE),
  mean_tests = mean(n_tests),
  n_areas = uniqueN(postcode_area)
)]

summ_control <- pre[g_period == 0, .(
  mean_fail = mean(fail_rate),
  sd_fail = sd(fail_rate),
  mean_age = mean(avg_age, na.rm = TRUE),
  mean_mileage = mean(avg_mileage, na.rm = TRUE),
  mean_tests = mean(n_tests),
  n_areas = uniqueN(postcode_area)
)]

cat("\n=== PRE-TREATMENT SUMMARY (2017-2018) ===\n")
cat("TREATED areas:\n")
print(summ_treated)
cat("\nCONTROL areas:\n")
print(summ_control)

# Save for paper
saveRDS(list(treated = summ_treated, control = summ_control),
        "../data/summary_stats.rds")

# ---- MAIN SPECIFICATION: TWFE as baseline ----
# Fail rate ~ Treated + FE(postcode_area + year)
fit_twfe <- feols(
  fail_rate ~ treated | postcode_area + year,
  data = panel_pc,
  cluster = ~postcode_area
)
cat("\n=== TWFE: Overall Fail Rate ===\n")
summary(fit_twfe)

# ---- CALLAWAY-SANT'ANNA ----
# Need balanced panel with numeric ID
cs_data <- panel_pc[, .(
  fail_rate = fail_rate,
  year = as.integer(year),
  pc_id = as.integer(pc_id),
  g_period = as.integer(g_period)
)]

# Ensure balanced panel
cs_balanced <- cs_data[, .N, by = pc_id][N == length(unique(cs_data$year))]
cs_data <- cs_data[pc_id %in% cs_balanced$pc_id]

cat("\nC-S balanced panel:", uniqueN(cs_data$pc_id), "areas\n")

cs_out <- tryCatch({
  att_gt(
    yname = "fail_rate",
    tname = "year",
    idname = "pc_id",
    gname = "g_period",
    data = as.data.frame(cs_data),
    control_group = "nevertreated",
    base_period = "universal"
  )
}, error = function(e) {
  cat("C-S estimation error:", e$message, "\n")
  NULL
})

if (!is.null(cs_out)) {
  cat("\n=== Callaway-Sant'Anna ATT ===\n")
  cs_agg <- aggte(cs_out, type = "simple")
  cat("Overall ATT:", cs_agg$overall.att, "\n")
  cat("SE:", cs_agg$overall.se, "\n")

  # Event study
  cs_es <- aggte(cs_out, type = "dynamic")
  cat("\n=== Event Study Coefficients ===\n")
  print(data.frame(
    e = cs_es$egt,
    att = round(cs_es$att.egt, 6),
    se = round(cs_es$se.egt, 6)
  ))

  saveRDS(list(cs_out = cs_out, cs_agg = cs_agg, cs_es = cs_es),
          "../data/cs_results.rds")
}

# ---- DIESEL vs PETROL PLACEBO ----
# Key test: diesel should show stronger effect (non-compliant at Euro 4)
# while same-vintage petrol vehicles (Euro 4 compliant) should not

# Euro 4 era vehicles only (2006-2010 registration)
fit_diesel_e4 <- feols(
  euro4_fail_rate ~ treated | postcode_area + year,
  data = panel_diesel[euro4_tests >= 50],
  cluster = ~postcode_area
)

fit_petrol_e4 <- feols(
  euro4_fail_rate ~ treated | postcode_area + year,
  data = panel_petrol[euro4_tests >= 50],
  cluster = ~postcode_area
)

cat("\n=== DIESEL Euro 4 Fail Rate ===\n")
summary(fit_diesel_e4)
cat("\n=== PETROL Euro 4 Fail Rate (placebo) ===\n")
summary(fit_petrol_e4)

# ---- OVERALL DIESEL vs PETROL ----
fit_diesel <- feols(
  fail_rate ~ treated | postcode_area + year,
  data = panel_diesel,
  cluster = ~postcode_area
)

fit_petrol <- feols(
  fail_rate ~ treated | postcode_area + year,
  data = panel_petrol,
  cluster = ~postcode_area
)

cat("\n=== DIESEL Overall Fail Rate ===\n")
summary(fit_diesel)
cat("\n=== PETROL Overall Fail Rate ===\n")
summary(fit_petrol)

# ---- COMPOSITION: Average vehicle age ----
fit_age <- feols(
  avg_age ~ treated | postcode_area + year,
  data = panel_pc,
  cluster = ~postcode_area
)

cat("\n=== Vehicle Age ===\n")
summary(fit_age)

# ---- Save all results ----
results <- list(
  twfe = fit_twfe,
  diesel = fit_diesel,
  petrol = fit_petrol,
  diesel_e4 = fit_diesel_e4,
  petrol_e4 = fit_petrol_e4,
  age = fit_age
)
saveRDS(results, "../data/main_results.rds")

# ---- Write diagnostics.json for validate_v1.py ----
# For staggered DiD: pre-periods vary by cohort. Report the median.
# Phase 1 (2019): 2 pre-years; Phase 2/3 (2021): 4; Phase 4 (2022): 5; Phase 5 (2023): 6
# The C-S event study produces 6 pre-period coefficients (e=-6 to e=-1)
cohort_pre <- panel_pc[g_period > 0, .(
  n_pre = uniqueN(year[year < first_treat_year])
), by = .(postcode_area, g_period)]
median_pre <- median(cohort_pre$n_pre)

diag <- list(
  n_treated = uniqueN(panel_pc[g_period > 0]$postcode_area),
  n_pre = as.integer(median_pre),
  n_obs = nrow(panel_pc)
)
write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)

cat("\nMain analysis complete. Results saved.\n")
