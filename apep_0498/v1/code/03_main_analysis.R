## =============================================================================
## 03_main_analysis.R — Main DiD estimation
## APEP-0498: The Austerity Mortality Gradient
## =============================================================================

source("00_packages.R")

## ---------------------------------------------------------------------------
## 1. Load analysis panel
## ---------------------------------------------------------------------------
panel <- fread(file.path(DATA_DIR, "analysis_panel.csv"))
cat(sprintf("Loaded panel: %d obs, %d LAs, years %d-%d\n",
            nrow(panel), uniqueN(panel$la_code),
            min(panel$year), max(panel$year)))

## Use the grants-restricted panel for main analysis
panel_grants <- fread(file.path(DATA_DIR, "analysis_panel_grants.csv"))
cat(sprintf("Grants panel: %d obs, %d LAs\n", nrow(panel_grants), uniqueN(panel_grants$la_code)))

## Pre-COVID subsample (PRIMARY)
panel_pre_covid <- panel_grants[year <= 2019]

## ---------------------------------------------------------------------------
## 2. TWFE Continuous Treatment DiD (Primary Specification)
## ---------------------------------------------------------------------------
cat("\n=== PRIMARY: Continuous Treatment DiD (2006-2019) ===\n")

## Outcome 1: Drug misuse deaths
m1_drug <- feols(drug_death_rate ~ ph_grant_per_head | la_code + year,
                 data = panel_pre_covid[!is.na(drug_death_rate) & !is.na(ph_grant_per_head)],
                 cluster = ~la_code)

## Outcome 2: Alcohol-specific mortality
m1_alc <- feols(alcohol_mortality ~ ph_grant_per_head | la_code + year,
                data = panel_pre_covid[!is.na(alcohol_mortality) & !is.na(ph_grant_per_head)],
                cluster = ~la_code)

## Outcome 3: Under-75 all-cause mortality
m1_u75 <- feols(under75_mortality ~ ph_grant_per_head | la_code + year,
                data = panel_pre_covid[!is.na(under75_mortality) & !is.na(ph_grant_per_head)],
                cluster = ~la_code)

## Mechanism: Drug treatment completion
m1_treat <- feols(drug_treatment_opiate ~ ph_grant_per_head | la_code + year,
                  data = panel_pre_covid[!is.na(drug_treatment_opiate) & !is.na(ph_grant_per_head)],
                  cluster = ~la_code)

cat("\n--- Continuous Treatment Results (pre-COVID) ---\n")
cat("Coefficient = effect of £1 increase in real PH spend per head\n\n")
etable(m1_drug, m1_alc, m1_u75, m1_treat,
       headers = c("Drug Deaths", "Alcohol Mort", "Under-75 Mort", "Treatment Rate"),
       se.below = TRUE)

## ---------------------------------------------------------------------------
## 3. Full panel with COVID controls (Secondary)
## ---------------------------------------------------------------------------
cat("\n=== SECONDARY: Full Panel 2006-2024 ===\n")

## COVID control: dummy out 2020-2021
panel[, covid_period := as.integer(year %in% 2020:2021)]

m2_drug <- feols(drug_death_rate ~ ph_grant_per_head + covid_period | la_code + year,
                 data = panel[!is.na(drug_death_rate) & !is.na(ph_grant_per_head)],
                 cluster = ~la_code)

m2_alc <- feols(alcohol_mortality ~ ph_grant_per_head + covid_period | la_code + year,
                data = panel[!is.na(alcohol_mortality) & !is.na(ph_grant_per_head)],
                cluster = ~la_code)

m2_u75 <- feols(under75_mortality ~ ph_grant_per_head + covid_period | la_code + year,
                data = panel[!is.na(under75_mortality) & !is.na(ph_grant_per_head)],
                cluster = ~la_code)

cat("\n--- Full Panel Results ---\n")
etable(m2_drug, m2_alc, m2_u75,
       headers = c("Drug Deaths", "Alcohol Mort", "Under-75 Mort"),
       se.below = TRUE)

## ---------------------------------------------------------------------------
## 4. Tercile-Based DiD (Group × Post interaction)
## ---------------------------------------------------------------------------
cat("\n=== TERCILE-BASED DiD ===\n")

if ("grant_tercile" %in% names(panel)) {
  ## Create group indicators
  panel_pre_covid[, large_cut := as.integer(grant_tercile == "Large cut")]
  panel_pre_covid[, moderate_cut := as.integer(grant_tercile == "Moderate change")]

  ## Group × Post
  panel_pre_covid[, large_cut_post := large_cut * post]
  panel_pre_covid[, moderate_cut_post := moderate_cut * post]

  m3_drug <- feols(drug_death_rate ~ large_cut_post + moderate_cut_post | la_code + year,
                   data = panel_pre_covid[!is.na(drug_death_rate) & !is.na(grant_tercile)],
                   cluster = ~la_code)

  m3_alc <- feols(alcohol_mortality ~ large_cut_post + moderate_cut_post | la_code + year,
                  data = panel_pre_covid[!is.na(alcohol_mortality) & !is.na(grant_tercile)],
                  cluster = ~la_code)

  m3_treat <- feols(drug_treatment_opiate ~ large_cut_post + moderate_cut_post | la_code + year,
                    data = panel_pre_covid[!is.na(drug_treatment_opiate) & !is.na(grant_tercile)],
                    cluster = ~la_code)

  cat("\n--- Tercile DiD Results ---\n")
  cat("Omitted group: Protected (smallest cuts / increases)\n\n")
  etable(m3_drug, m3_alc, m3_treat,
         headers = c("Drug Deaths", "Alcohol Mort", "Treatment Rate"),
         se.below = TRUE)
}

## ---------------------------------------------------------------------------
## 5. Event Study (Year-by-Year Treatment Effects)
## ---------------------------------------------------------------------------
cat("\n=== EVENT STUDY ===\n")

## Continuous treatment × year interactions
## Omit 2014 as reference year
panel_pre_covid[, year_fac := factor(year)]
panel_pre_covid[, year_fac := relevel(year_fac, ref = "2014")]

if ("baseline_grant" %in% names(panel_pre_covid)) {
  ## Use baseline spend as continuous exposure (higher baseline = more to lose)
  panel_pre_covid[, baseline_grant_std := (baseline_grant - mean(baseline_grant, na.rm = TRUE)) /
                    sd(baseline_grant, na.rm = TRUE)]

  es_drug <- feols(drug_death_rate ~ i(year, baseline_grant_std, ref = 2014) | la_code + year,
                   data = panel_pre_covid[!is.na(drug_death_rate) & !is.na(baseline_grant_std)],
                   cluster = ~la_code)

  es_alc <- feols(alcohol_mortality ~ i(year, baseline_grant_std, ref = 2014) | la_code + year,
                  data = panel_pre_covid[!is.na(alcohol_mortality) & !is.na(baseline_grant_std)],
                  cluster = ~la_code)

  es_treat <- feols(drug_treatment_opiate ~ i(year, baseline_grant_std, ref = 2014) | la_code + year,
                    data = panel_pre_covid[!is.na(drug_treatment_opiate) & !is.na(baseline_grant_std)],
                    cluster = ~la_code)

  cat("\nEvent study coefficients (drug deaths × baseline spend):\n")
  print(summary(es_drug))
}

## ---------------------------------------------------------------------------
## 6. Placebo Outcomes
## ---------------------------------------------------------------------------
cat("\n=== PLACEBO OUTCOMES ===\n")

## Cancer mortality (long latency — should NOT respond to short-term PH cuts)
if ("cancer_mortality" %in% names(panel_pre_covid)) {
  m_placebo_cancer <- feols(cancer_mortality ~ ph_grant_per_head | la_code + year,
                            data = panel_pre_covid[!is.na(cancer_mortality) & !is.na(ph_grant_per_head)],
                            cluster = ~la_code)
  cat("\nPlacebo: Cancer mortality\n")
  print(summary(m_placebo_cancer))
}

## Liver disease mortality (SHOULD respond — serves as positive control)
if ("liver_disease_mortality" %in% names(panel_pre_covid)) {
  m_pos_control <- feols(liver_disease_mortality ~ ph_grant_per_head | la_code + year,
                         data = panel_pre_covid[!is.na(liver_disease_mortality) & !is.na(ph_grant_per_head)],
                         cluster = ~la_code)
  cat("\nPositive control: Liver disease mortality\n")
  print(summary(m_pos_control))
}

## ---------------------------------------------------------------------------
## 7. Save results
## ---------------------------------------------------------------------------
results <- list(
  primary_drug = m1_drug,
  primary_alc = m1_alc,
  primary_u75 = m1_u75,
  primary_treat = m1_treat,
  full_drug = m2_drug,
  full_alc = m2_alc,
  full_u75 = m2_u75
)

if (exists("es_drug")) results$es_drug <- es_drug
if (exists("es_alc")) results$es_alc <- es_alc
if (exists("es_treat")) results$es_treat <- es_treat
if (exists("m3_drug")) results$tercile_drug <- m3_drug
if (exists("m3_alc")) results$tercile_alc <- m3_alc
if (exists("m_placebo_cancer")) results$placebo_cancer <- m_placebo_cancer

saveRDS(results, file.path(DATA_DIR, "main_results.rds"))
cat("\n✓ All results saved to", file.path(DATA_DIR, "main_results.rds"), "\n")
