# ==============================================================================
# 03_main_analysis.R — Main Regressions for apep_0588
# Frozen Out: Russian Gas Shock and Excess Winter Mortality
# ==============================================================================

source("00_packages.R")

data_dir <- "../data/"

dt <- fread(paste0(data_dir, "panel_total.csv"))
dt_age <- fread(paste0(data_dir, "panel_age.csv"))
dt_hicp <- fread(paste0(data_dir, "panel_hicp.csv"))

# Ensure factor types
dt[, geo := as.factor(geo)]
dt[, yw := as.factor(yw)]

# ==============================================================================
# 1. First Stage: Gas Dependence → Energy Prices
# ==============================================================================
cat("=== FIRST STAGE: Gas Dependence → Energy Prices ===\n")

# Monthly HICP energy YoY change
dt_hicp[, geo := as.factor(geo)]
dt_hicp[, ym := as.factor(paste0(year, "-", sprintf("%02d", month)))]

fs1 <- feols(hicp_yoy ~ gas_post | geo + ym, data = dt_hicp, cluster = "geo")
cat("\nFirst stage (HICP energy YoY % change):\n")
summary(fs1)

# Save first-stage results
fs_res <- data.table(
  spec = "First Stage: HICP Energy YoY",
  coef = coef(fs1)["gas_post"],
  se = sqrt(vcov(fs1)["gas_post", "gas_post"]),
  n = nobs(fs1),
  n_countries = uniqueN(dt_hicp$geo)
)
fwrite(fs_res, paste0(data_dir, "results_first_stage.csv"))

# ==============================================================================
# 2. Main Specification: Deaths per 100k ~ Gas Dependence x Post-Winter
# ==============================================================================
cat("\n=== MAIN RESULTS: Mortality ===\n")

# Specification 1: Basic (country + week FE)
m1 <- feols(deaths_pc ~ gas_post | geo + yw, data = dt, cluster = "geo")
cat("\nModel 1 (Country + Year-Week FE):\n")
summary(m1)

# Specification 2: With HDD control
m2 <- feols(deaths_pc ~ gas_post + hdd | geo + yw, data = dt, cluster = "geo")
cat("\nModel 2 (+ Heating Degree Days):\n")
summary(m2)

# Specification 3: Log deaths (semi-elasticity)
dt[, log_deaths_pc := log(deaths_pc + 1)]
m3 <- feols(log_deaths_pc ~ gas_post | geo + yw, data = dt, cluster = "geo")
cat("\nModel 3 (Log deaths per 100k):\n")
summary(m3)

# Specification 4: Excess deaths (relative to 2015-2019 baseline)
m4 <- feols(excess_deaths_pc ~ gas_post | geo + yw, data = dt[year >= 2018], cluster = "geo")
cat("\nModel 4 (Excess deaths per 100k, 2018+):\n")
summary(m4)

# Specification 5: Drop COVID years entirely (cleanest sample)
dt_clean <- dt[!(year %in% c(2020, 2021))]
m5 <- feols(deaths_pc ~ gas_post | geo + yw, data = dt_clean, cluster = "geo")
cat("\nModel 5 (Drop 2020-2021, no COVID contamination):\n")
summary(m5)

# Specification 6: Interaction with gas heating share (double treatment intensity)
m6 <- feols(deaths_pc ~ gas_heating_post | geo + yw, data = dt_clean, cluster = "geo")
cat("\nModel 6 (Gas Dep x Gas Heating Share x Post, clean sample):\n")
summary(m6)

# Save main results
main_results <- data.table(
  spec = c("(1) Country + YW FE",
           "(2) + HDD Control",
           "(3) Log Deaths",
           "(4) Excess Deaths (2018+)",
           "(5) Drop COVID (2020-21)",
           "(6) Gas x Heating (clean)"),
  coef = c(coef(m1)["gas_post"], coef(m2)["gas_post"],
           coef(m3)["gas_post"], coef(m4)["gas_post"],
           coef(m5)["gas_post"], coef(m6)["gas_heating_post"]),
  se = c(sqrt(vcov(m1)["gas_post", "gas_post"]),
         sqrt(vcov(m2)["gas_post", "gas_post"]),
         sqrt(vcov(m3)["gas_post", "gas_post"]),
         sqrt(vcov(m4)["gas_post", "gas_post"]),
         sqrt(vcov(m5)["gas_post", "gas_post"]),
         sqrt(vcov(m6)["gas_heating_post", "gas_heating_post"])),
  n = c(nobs(m1), nobs(m2), nobs(m3), nobs(m4), nobs(m5), nobs(m6)),
  outcome = c("Deaths/100k", "Deaths/100k", "Log Deaths/100k",
              "Excess Deaths/100k", "Deaths/100k", "Deaths/100k")
)
main_results[, pval := 2 * pnorm(-abs(coef / se))]
main_results[, stars := fcase(
  pval < 0.01, "***",
  pval < 0.05, "**",
  pval < 0.10, "*",
  default = ""
)]
fwrite(main_results, paste0(data_dir, "results_main.csv"))

cat("\n=== MAIN RESULTS TABLE ===\n")
print(main_results)

# ==============================================================================
# 3. Built-in Placebos
# ==============================================================================
cat("\n=== PLACEBOS ===\n")

# Placebo 1: Summer (should be zero) — on CLEAN (non-COVID) sample
cat("\nPlacebo 1: Summer months (weeks 22-35), clean sample (no 2020-21):\n")
dt_clean_all <- dt[!(year %in% c(2020, 2021))]
p1 <- feols(deaths_pc ~ summer_post | geo + yw, data = dt_clean_all, cluster = "geo")
summary(p1)

# Placebo 2: Pre-COVID winter 2018/19 (gas dependence should not predict mortality)
dt_pre2 <- dt[year <= 2019]
dt_pre2[, fake_post2 := (year == 2018 & week >= 40) | (year == 2019 & week <= 13)]
dt_pre2[, fake_gas_post2 := gas_dep_2021 * as.numeric(fake_post2)]
p2 <- feols(deaths_pc ~ fake_gas_post2 | geo + yw, data = dt_pre2, cluster = "geo")
cat("\nPlacebo 2: Pre-COVID (winter 2018/19, fake treatment):\n")
summary(p2)

# Placebo 3: Pre-COVID winter 2017/18
dt_pre3 <- dt[year <= 2018]
dt_pre3[, fake_post3 := (year == 2017 & week >= 40) | (year == 2018 & week <= 13)]
dt_pre3[, fake_gas_post3 := gas_dep_2021 * as.numeric(fake_post3)]
p3 <- feols(deaths_pc ~ fake_gas_post3 | geo + yw, data = dt_pre3, cluster = "geo")
cat("\nPlacebo 3: Pre-COVID (winter 2017/18, fake treatment):\n")
summary(p3)

# Save placebo results
placebo_results <- data.table(
  test = c("Summer 2022-2024", "Pre-COVID winter 2018/19", "Pre-COVID winter 2017/18"),
  coef = c(coef(p1)["summer_post"], coef(p2)["fake_gas_post2"], coef(p3)["fake_gas_post3"]),
  se = c(sqrt(vcov(p1)["summer_post", "summer_post"]),
         sqrt(vcov(p2)["fake_gas_post2", "fake_gas_post2"]),
         sqrt(vcov(p3)["fake_gas_post3", "fake_gas_post3"])),
  n = c(nobs(p1), nobs(p2), nobs(p3)),
  expected = c("Zero", "Zero", "Zero")
)
placebo_results[, pval := 2 * pnorm(-abs(coef / se))]
fwrite(placebo_results, paste0(data_dir, "results_placebos.csv"))

cat("\n=== PLACEBO RESULTS ===\n")
print(placebo_results)

# ==============================================================================
# 4. Age-Gradient Analysis (Mechanism Test)
# ==============================================================================
cat("\n=== AGE-GRADIENT MECHANISM TEST ===\n")

dt_age[, geo := as.factor(geo)]
dt_age[, yw := as.factor(yw)]
dt_age[, age_broad := as.factor(age_broad)]

# Separate regressions by age group
age_groups <- unique(dt_age$age_broad)
age_results <- list()

for (ag in age_groups) {
  dta <- dt_age[age_broad == ag]
  if (nrow(dta) < 100) next

  dta[, gas_post := gas_dep_2021 * as.numeric(post_winter)]

  m_ag <- tryCatch(
    feols(deaths ~ gas_post | geo + yw, data = dta, cluster = "geo"),
    error = function(e) NULL
  )

  if (!is.null(m_ag)) {
    age_results[[ag]] <- data.table(
      age_group = ag,
      coef = coef(m_ag)["gas_post"],
      se = sqrt(vcov(m_ag)["gas_post", "gas_post"]),
      n = nobs(m_ag)
    )
    cat("\nAge group:", ag, "- Coef:", round(coef(m_ag)["gas_post"], 3),
        "SE:", round(sqrt(vcov(m_ag)["gas_post", "gas_post"]), 3), "\n")
  }
}

dt_age_results <- rbindlist(age_results)
dt_age_results[, pval := 2 * pnorm(-abs(coef / se))]
fwrite(dt_age_results, paste0(data_dir, "results_age_gradient.csv"))

cat("\n=== AGE GRADIENT RESULTS ===\n")
print(dt_age_results)

# ==============================================================================
# 5. Event Study (Dynamic Effects)
# ==============================================================================
cat("\n=== EVENT STUDY ===\n")

# Create relative time: winters relative to shock (winter 2022/23 = 0)
# Winter = weeks 40-52 of year Y + weeks 1-13 of year Y+1
# Assign each week to a "winter" identifier
dt[, winter_id := fcase(
  week >= 40, as.integer(year),      # Oct-Dec → belongs to winter starting that year
  week <= 13, as.integer(year - 1L), # Jan-Mar → belongs to winter starting previous year
  default = NA_integer_              # Apr-Sep → not winter
)]

# Relative time: winter 2022/23 = 0 (shock winter)
dt[, rel_winter := winter_id - 2022L]

# Keep only winter weeks, DROP COVID winters (2019/20 and 2020/21)
# Also drop 2021/22 (Omicron contamination)
dt_winter <- dt[!is.na(winter_id) & !(winter_id %in% c(2019L, 2020L, 2021L))]

# Relative time: winter 2022/23 = 0 (first shock winter)
dt_winter[, rel_winter := winter_id - 2022L]
dt_winter[, rel_winter_f := factor(rel_winter)]

# Use winter 2018/19 (rel = -4, last clean pre-COVID) as reference
# Create separate interaction for each relative period
rel_periods <- sort(unique(dt_winter$rel_winter))
for (rp in rel_periods) {
  if (rp == -4) next  # reference period = winter 2018/19
  varname <- paste0("gas_rel_", ifelse(rp < 0, "m", "p"), abs(rp))
  dt_winter[, (varname) := gas_dep_2021 * as.numeric(rel_winter == rp)]
}

# Build formula dynamically
rel_vars <- grep("^gas_rel_", names(dt_winter), value = TRUE)
form_str <- paste0("deaths_pc ~ ", paste(rel_vars, collapse = " + "), " | geo + yw")

es_model <- feols(as.formula(form_str), data = dt_winter, cluster = "geo")
cat("\nEvent study results:\n")
summary(es_model)

# Extract coefficients
es_coefs <- data.table(
  var = rel_vars,
  coef = coef(es_model)[rel_vars],
  se = sqrt(diag(vcov(es_model)))[rel_vars]
)
# Parse relative winter from variable name
es_coefs[, rel_winter := as.numeric(gsub("gas_rel_[mp]", "", var))]
es_coefs[grepl("_m", var), rel_winter := -rel_winter]
es_coefs[, ci_lo := coef - 1.96 * se]
es_coefs[, ci_hi := coef + 1.96 * se]

# Add reference period (winter 2018/19 = -4)
es_coefs <- rbind(es_coefs[, .(rel_winter, coef, se, ci_lo, ci_hi)],
                  data.table(rel_winter = -4, coef = 0, se = 0, ci_lo = 0, ci_hi = 0))
setorder(es_coefs, rel_winter)

fwrite(es_coefs, paste0(data_dir, "results_event_study.csv"))

cat("\n=== EVENT STUDY COEFFICIENTS ===\n")
print(es_coefs)

# ==============================================================================
# 6. Heterogeneity: Gas Heating Share Interaction
# ==============================================================================
cat("\n=== HETEROGENEITY: GAS HEATING SHARE ===\n")

# Split by gas heating prevalence
med_heat <- median(unique(dt$gas_heating_share), na.rm = TRUE)
dt[, high_gas_heat := gas_heating_share >= med_heat]

# Separate regressions
m_high_heat <- feols(deaths_pc ~ gas_post | geo + yw,
                     data = dt[high_gas_heat == TRUE], cluster = "geo")
m_low_heat <- feols(deaths_pc ~ gas_post | geo + yw,
                    data = dt[high_gas_heat == FALSE], cluster = "geo")

cat("\nHigh gas heating share:\n")
summary(m_high_heat)
cat("\nLow gas heating share:\n")
summary(m_low_heat)

het_results <- data.table(
  subgroup = c("High gas heating (>=median)", "Low gas heating (<median)"),
  coef = c(coef(m_high_heat)["gas_post"], coef(m_low_heat)["gas_post"]),
  se = c(sqrt(vcov(m_high_heat)["gas_post", "gas_post"]),
         sqrt(vcov(m_low_heat)["gas_post", "gas_post"])),
  n = c(nobs(m_high_heat), nobs(m_low_heat))
)
het_results[, pval := 2 * pnorm(-abs(coef / se))]
fwrite(het_results, paste0(data_dir, "results_heterogeneity.csv"))

# ==============================================================================
# 7. Save all model objects for figures
# ==============================================================================
save(m1, m2, m3, m4, m5, m6, fs1, p1, p2, p3, es_model, es_coefs,
     m_high_heat, m_low_heat,
     file = paste0(data_dir, "models.RData"))

cat("\nMain analysis complete. All results saved.\n")
