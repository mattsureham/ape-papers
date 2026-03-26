# 03_main_analysis.R — Main econometric analysis
# Czech EET and Business Dynamics (apep_0989)

source("00_packages.R")

# ===================================================================
# STRATEGY: Use 2-digit NACE divisions to increase cross-sectional units
# Each 2-digit division inherits its parent section's EET phase timing
# This gives ~100 divisions × 5 countries = ~500 units (vs 45 with sections)
# ===================================================================

# Load raw enterprise data
sbs_ind <- readRDS("../data/eurostat_sbs_na_ind_r2.rds")
sbs_svc <- readRDS("../data/eurostat_sbs_na_1a_se_r2.rds")
sbs_con <- readRDS("../data/eurostat_sbs_na_con_r2.rds")
sbs_trd <- readRDS("../data/eurostat_sbs_na_dt_r2.rds")

sbs_all <- bind_rows(sbs_ind, sbs_svc, sbs_con, sbs_trd)

# Extract 2-digit NACE divisions (codes like C10, G47, H49, etc.)
enterprises_2d <- sbs_all %>%
  filter(indic_sb == "V11110",
         nchar(nace_r2) %in% c(2, 3),  # 2-digit divisions (letter + 2 digits = 3 chars, or 2 chars like F)
         !is.na(values)) %>%
  # Keep only proper 2-digit codes (letter + 2 digits)
  filter(grepl("^[A-Z][0-9]{2}$", nace_r2) | nace_r2 %in% c("F")) %>%
  mutate(
    section = substr(nace_r2, 1, 1),
    year = time
  ) %>%
  select(geo, nace_r2, section, year, n_enterprises = values) %>%
  filter(year >= 2008, year <= 2020)

cat("2-digit divisions available:", n_distinct(enterprises_2d$nace_r2), "\n")
cat("By section:\n")
print(table(enterprises_2d$section[!duplicated(paste(enterprises_2d$nace_r2, enterprises_2d$geo))]))

# Map sections to EET phases
eet_section_map <- c(
  "I" = 2017, "G" = 2017,  # Phases 1-2
  "H" = 2018, "M" = 2018,  # Phase 3
  "C" = 2018               # Phase 4
)

# Build analysis panel
panel_2d <- enterprises_2d %>%
  mutate(
    treatment_year = ifelse(geo == "CZ", eet_section_map[section], NA_real_),
    treated = ifelse(!is.na(treatment_year) & year >= treatment_year, 1, 0),
    # Cohort year for CS-DiD (Inf = never-treated)
    cohort_year = ifelse(!is.na(treatment_year), treatment_year, 0),
    unit_id = paste(geo, nace_r2, sep = "_"),
    ln_enterprises = log(n_enterprises)
  )

cat("\n--- 2-Digit Division Panel ---\n")
cat("Observations:", nrow(panel_2d), "\n")
cat("Unique units:", n_distinct(panel_2d$unit_id), "\n")
cat("CZ treated units:", n_distinct(panel_2d$unit_id[panel_2d$geo == "CZ" & !is.na(panel_2d$treatment_year)]), "\n")
cat("Control units:", n_distinct(panel_2d$unit_id[is.na(panel_2d$treatment_year)]), "\n")

# Check balance: do all units have all years?
unit_year_count <- panel_2d %>%
  group_by(unit_id) %>%
  summarize(n_years = n(), .groups = "drop")
cat("\nPanel balance:\n")
print(table(unit_year_count$n_years))

# Keep only balanced panel (units with all 13 years)
balanced_units <- unit_year_count$unit_id[unit_year_count$n_years == 13]
panel_bal <- panel_2d %>% filter(unit_id %in% balanced_units)
cat("\nBalanced panel:", nrow(panel_bal), "obs,", n_distinct(panel_bal$unit_id), "units\n")
cat("CZ treated (balanced):", n_distinct(panel_bal$unit_id[panel_bal$geo == "CZ" & !is.na(panel_bal$treatment_year)]), "\n")

# ===================================================================
# MAIN SPECIFICATION 1: Sun-Abraham Event Study (fixest::sunab)
# ===================================================================
cat("\n=== Specification 1: Sun-Abraham Event Study ===\n")

# Event time relative to treatment
panel_bal <- panel_bal %>%
  mutate(
    event_time = ifelse(cohort_year > 0, year - cohort_year, NA_integer_)
  )

# Sun-Abraham: cohort × period decomposition
# Use never-treated units as control group
est_sunab <- feols(ln_enterprises ~ sunab(cohort_year, year) | unit_id + year,
                   data = panel_bal,
                   cluster = ~unit_id)

cat("Sun-Abraham estimates:\n")
print(summary(est_sunab))

# ===================================================================
# MAIN SPECIFICATION 2: Standard TWFE DiD
# ===================================================================
cat("\n=== Specification 2: TWFE DiD ===\n")

est_twfe <- feols(ln_enterprises ~ treated | unit_id + year,
                  data = panel_bal,
                  cluster = ~unit_id)

cat("TWFE estimate:\n")
print(summary(est_twfe))

# ===================================================================
# SPECIFICATION 3: Callaway-Sant'Anna (did package)
# ===================================================================
cat("\n=== Specification 3: Callaway-Sant'Anna ===\n")

# Prepare data for CS-DiD
cs_data <- panel_bal %>%
  mutate(
    gvar = ifelse(cohort_year == 0, 0, cohort_year),  # 0 = never-treated
    unit_num = as.integer(factor(unit_id))
  )

tryCatch({
  cs_out <- att_gt(
    yname = "ln_enterprises",
    gname = "gvar",
    idname = "unit_num",
    tname = "year",
    data = as.data.frame(cs_data),
    control_group = "notyettreated",
    base_period = "universal"
  )

  cat("CS-DiD group-time ATTs:\n")
  print(summary(cs_out))

  # Aggregate to overall ATT
  cs_agg <- aggte(cs_out, type = "simple")
  cat("\nOverall ATT:", cs_agg$overall.att, "SE:", cs_agg$overall.se, "\n")

  # Aggregate to event study
  cs_es <- aggte(cs_out, type = "dynamic")
  cat("\nEvent-study ATTs:\n")
  print(summary(cs_es))

  saveRDS(cs_out, "../data/cs_did_results.rds")
  saveRDS(cs_agg, "../data/cs_agg_results.rds")
  saveRDS(cs_es, "../data/cs_es_results.rds")
}, error = function(e) {
  cat("CS-DiD error:", e$message, "\n")
  cat("Proceeding with Sun-Abraham as primary estimator.\n")
})

# ===================================================================
# SPECIFICATION 4: By-sector effects (heterogeneity)
# ===================================================================
cat("\n=== Specification 4: Heterogeneous Effects by Sector ===\n")

# Interact treatment with EET section
panel_bal <- panel_bal %>%
  mutate(
    eet_section = ifelse(geo == "CZ" & !is.na(treatment_year), section, "control")
  )

est_hetero <- feols(ln_enterprises ~ i(eet_section, treated, ref = "control") | unit_id + year,
                    data = panel_bal,
                    cluster = ~unit_id)

cat("Heterogeneous effects by sector:\n")
print(summary(est_hetero))

# ===================================================================
# SPECIFICATION 5: Czech-only within-country DiD
# ===================================================================
cat("\n=== Specification 5: Czech-only, EET vs non-EET sectors ===\n")

cz_only <- panel_bal %>% filter(geo == "CZ")

est_cz <- feols(ln_enterprises ~ treated | unit_id + year,
                data = cz_only,
                cluster = ~unit_id)

cat("CZ-only DiD:\n")
print(summary(est_cz))

# ===================================================================
# MECHANISM: Business demography (births vs deaths)
# ===================================================================
cat("\n=== Mechanism: Business births and deaths ===\n")

bd_panel <- readRDS("../data/panel_demography.rds")

# Births
bd_births <- bd_panel %>%
  filter(!is.na(births)) %>%
  mutate(ln_births = log(births + 1))

if (nrow(bd_births) > 0) {
  est_births <- feols(ln_births ~ treated | unit_id + year,
                      data = bd_births %>% mutate(unit_id = paste(geo, nace_r2, leg_form, sep = "_")),
                      cluster = ~unit_id)
  cat("Effect on births:\n")
  print(summary(est_births))
}

# Deaths
bd_deaths <- bd_panel %>%
  filter(!is.na(deaths)) %>%
  mutate(ln_deaths = log(deaths + 1))

if (nrow(bd_deaths) > 0) {
  est_deaths <- feols(ln_deaths ~ treated | unit_id + year,
                      data = bd_deaths %>% mutate(unit_id = paste(geo, nace_r2, leg_form, sep = "_")),
                      cluster = ~unit_id)
  cat("Effect on deaths:\n")
  print(summary(est_deaths))
}

# ===================================================================
# MECHANISM: VAT revenue
# ===================================================================
cat("\n=== Mechanism: VAT Revenue ===\n")

tax_panel <- readRDS("../data/panel_vat.rds") %>%
  filter(year >= 2008, year <= 2022)

est_vat <- feols(ln_vat ~ cz_post | geo + year,
                 data = tax_panel,
                 cluster = ~geo)

cat("VAT revenue effect:\n")
print(summary(est_vat))

# ===================================================================
# SAVE MAIN RESULTS
# ===================================================================
main_results <- list(
  sunab = est_sunab,
  twfe = est_twfe,
  cz_only = est_cz,
  hetero = est_hetero,
  vat = est_vat
)
saveRDS(main_results, "../data/main_results.rds")

# ===================================================================
# DIAGNOSTICS for validate_v1.py
# ===================================================================
cat("\n=== Writing diagnostics.json ===\n")

n_treated_units <- n_distinct(panel_bal$unit_id[panel_bal$treated == 1])
n_pre <- length(unique(panel_bal$year[panel_bal$year < 2017]))
n_obs <- nrow(panel_bal)

diagnostics <- list(
  n_treated = n_treated_units,
  n_pre = n_pre,
  n_obs = n_obs,
  n_units = n_distinct(panel_bal$unit_id),
  n_years = n_distinct(panel_bal$year),
  countries = unique(panel_bal$geo),
  sectors_treated = unique(panel_bal$section[panel_bal$treated == 1]),
  twfe_coef = coef(est_twfe)["treated"],
  twfe_se = sqrt(diag(vcov(est_twfe)))["treated"]
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

cat("Diagnostics written:\n")
cat("  n_treated:", n_treated_units, "\n")
cat("  n_pre:", n_pre, "\n")
cat("  n_obs:", n_obs, "\n")

cat("\n=== Main analysis complete ===\n")
