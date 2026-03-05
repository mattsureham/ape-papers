## 03_main_analysis.R — Main DiD estimation
## apep_0519: MuKEn 2014 Building Energy Codes and Heat Pump Adoption

source("00_packages.R")

data_dir <- "../data"
panel <- fread(file.path(data_dir, "analysis_panel.csv"))
longdiff <- fread(file.path(data_dir, "long_difference.csv"))
surface <- fread(file.path(data_dir, "surface_panel.csv"))

## ============================================================================
## 1. SUN-ABRAHAM (2021) HETEROGENEITY-ROBUST ESTIMATOR [CO-PRIMARY]
## ============================================================================
## This is the primary specification, robust to heterogeneous treatment effects
## under staggered adoption (Sun and Abraham, 2021; JASA).
## TWFE is estimated below as a comparison specification.

cat("=== SUN-ABRAHAM EVENT STUDY (CO-PRIMARY SPEC) ===\n\n")

## ref.p = -1: standard reference period (event time -1 normalized to zero).
## Given the 2016-2020 data gap, event time -1 is unobserved for cohorts
## 2017-2021. fixest handles this correctly: when a reference event-time has
## no data for a cohort, that event-time coefficient is simply not estimated
## for that cohort. The aggregated ATT (average post-treatment effect) is
## invariant to the choice of reference period.
m_sunab <- feols(share_heat_pump ~ sunab(cohort, year, ref.p = -1) | canton + year,
                 data = panel, cluster = ~canton)

cat("Sun-Abraham event study:\n")
summary(m_sunab)

## Extract aggregated ATT (average across cohorts and periods)
sunab_agg <- summary(m_sunab, agg = "ATT")
cat("\nSun-Abraham aggregated ATT:\n")
print(sunab_agg)

## Extract ATT coefficient, SE, and p-value
sunab_coeftable <- coeftable(sunab_agg)
sunab_att <- sunab_coeftable[1, "Estimate"]
sunab_se  <- sunab_coeftable[1, "Std. Error"]
sunab_pval <- sunab_coeftable[1, "Pr(>|t|)"]

cat(sprintf("\n  ATT = %.6f (SE = %.6f, p = %.4f)\n", sunab_att, sunab_se, sunab_pval))

## Save Sun-Abraham results to CSV
sunab_results <- data.table(
  estimator = "Sun-Abraham",
  ATT = sunab_att,
  SE = sunab_se,
  pvalue = sunab_pval,
  ci_lo = sunab_att - 1.96 * sunab_se,
  ci_hi = sunab_att + 1.96 * sunab_se
)
fwrite(sunab_results, file.path(data_dir, "sunab_results.csv"))
cat("Sun-Abraham results saved to data/sunab_results.csv\n")

## ============================================================================
## 2. TWO-WAY FIXED EFFECTS (TWFE) DiD [COMPARISON SPECIFICATION]
## ============================================================================
## Standard TWFE for comparison; known to be susceptible to heterogeneity bias
## under staggered adoption (Goodman-Bacon 2021, de Chaisemartin & D'Haultfoeuille 2020).
## Y_{ct} = alpha_c + gamma_t + beta * treated_{ct} + epsilon_{ct}

cat("\n=== TWFE ESTIMATION (COMPARISON SPEC) ===\n\n")

## Main specification: heat pump share
m1 <- feols(share_heat_pump ~ treated | canton + year, data = panel,
            cluster = ~canton)

## Oil share
m2 <- feols(share_oil ~ treated | canton + year, data = panel,
            cluster = ~canton)

## Fossil share (oil + gas + coal)
m3 <- feols(share_fossil ~ treated | canton + year, data = panel,
            cluster = ~canton)

## Gas share
m4 <- feols(share_gas ~ treated | canton + year, data = panel,
            cluster = ~canton)

## Wood share
m5 <- feols(share_wood ~ treated | canton + year, data = panel,
            cluster = ~canton)

## District heating share
m6 <- feols(share_district ~ treated | canton + year, data = panel,
            cluster = ~canton)

cat("Main TWFE results:\n")
etable(m1, m2, m3, m4, m5, m6,
       headers = c("Heat Pump", "Oil", "Fossil", "Gas", "Wood", "District"),
       se.below = TRUE, signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.1))

## ============================================================================
## 2. TREATMENT INTENSITY (YEARS SINCE ADOPTION)
## ============================================================================

cat("\n=== TREATMENT INTENSITY ===\n\n")

## Continuous treatment: years since adoption
m7 <- feols(share_heat_pump ~ years_treated | canton + year, data = panel,
            cluster = ~canton)

## Log specification
m8 <- feols(log_hp_share ~ treated | canton + year, data = panel,
            cluster = ~canton)

cat("Treatment intensity results:\n")
etable(m7, m8,
       headers = c("Years Treated", "Log HP Share"),
       se.below = TRUE, signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.1))

## ============================================================================
## 3. EARLY VS LATE ADOPTERS
## ============================================================================

cat("\n=== EARLY VS LATE ADOPTERS ===\n\n")

## Interaction: treated × early_adopter
m9 <- feols(share_heat_pump ~ treated + treated:early_adopter | canton + year,
            data = panel, cluster = ~canton)

## Differential effects by cohort (2017-2018 vs 2019 vs 2020+)
panel[, cohort_group := fcase(
  is.na(adoption_year), "Never",
  adoption_year <= 2018, "Early (2017-18)",
  adoption_year <= 2019, "Mid (2019)",
  default = "Late (2020+)"
)]
panel[, cohort_group := factor(cohort_group,
                                levels = c("Never", "Late (2020+)", "Mid (2019)", "Early (2017-18)"))]

m10 <- feols(share_heat_pump ~ i(cohort_group, post, ref = "Never") | canton + year,
             data = panel, cluster = ~canton)

cat("Early vs late adopter results:\n")
etable(m9, m10,
       se.below = TRUE, signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.1))

## ============================================================================
## 4. LONG-DIFFERENCE ESTIMATION
## ============================================================================

cat("\n=== LONG-DIFFERENCE ===\n\n")

## Cross-sectional regression of HP share change on treatment exposure
longdiff[, treated_by_2021 := fifelse(!is.na(adoption_year) & adoption_year <= 2021, 1L, 0L)]

m11 <- lm(delta_hp_share ~ treated_by_2021, data = longdiff)
m12 <- lm(delta_hp_share ~ years_exposed, data = longdiff)

cat("Long-difference: Change in HP share (post minus pre)\n")
cat("  Treated by 2021 effect:", round(coef(m11)["treated_by_2021"], 4),
    " (SE:", round(summary(m11)$coefficients["treated_by_2021", "Std. Error"], 4), ")\n")
cat("  Per year of exposure:", round(coef(m12)["years_exposed"], 4),
    " (SE:", round(summary(m12)$coefficients["years_exposed", "Std. Error"], 4), ")\n")

## ============================================================================
## 5. SURFACE AREA ANALYSIS (2021-2023)
## ============================================================================

cat("\n=== SURFACE AREA ANALYSIS (2021-2023) ===\n\n")

## Surface panel already has treatment info from 02_clean_data.R
## Just ensure treated and years_treated exist
if (!"treated" %in% names(surface) || all(is.na(surface$treated))) {
  muken <- fread(file.path(data_dir, "muken_adoption.csv"))
  surface <- merge(surface, muken[, .(canton, adoption_year, adopted)],
                   by = "canton", all.x = TRUE)
  surface[, treated := fifelse(!is.na(adoption_year) & year >= adoption_year, 1L, 0L)]
  surface[, years_treated := fifelse(!is.na(adoption_year),
                                      pmax(0L, as.integer(year - adoption_year)), 0L)]
}

## TWFE on surface data (3 years, 26 cantons)
m13 <- feols(pct_heat_pump_surface ~ treated | canton + year, data = surface,
             cluster = ~canton)

m14 <- feols(pct_heat_pump_surface ~ years_treated | canton + year, data = surface,
             cluster = ~canton)

cat("Surface area results:\n")
etable(m13, m14,
       headers = c("Treated (Binary)", "Years Treated"),
       se.below = TRUE, signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.1))

## ============================================================================
## 7. SAVE RESULTS FOR TABLES AND FIGURES
## ============================================================================

## Save main coefficients as CSV
results <- data.table(
  model = c("TWFE: HP Share", "TWFE: Oil Share", "TWFE: Fossil Share",
            "TWFE: Gas Share", "TWFE: Wood Share", "TWFE: District",
            "Intensity: Years", "Log HP Share",
            "Early vs Late", "Surface: Binary", "Surface: Years",
            "Sun-Abraham ATT"),
  coef = c(coef(m1)["treated"], coef(m2)["treated"], coef(m3)["treated"],
           coef(m4)["treated"], coef(m5)["treated"], coef(m6)["treated"],
           coef(m7)["years_treated"], coef(m8)["treated"],
           coef(m9)["treated"], coef(m13)["treated"], coef(m14)["years_treated"],
           sunab_att),
  se = c(se(m1)["treated"], se(m2)["treated"], se(m3)["treated"],
         se(m4)["treated"], se(m5)["treated"], se(m6)["treated"],
         se(m7)["years_treated"], se(m8)["treated"],
         se(m9)["treated"], se(m13)["treated"], se(m14)["years_treated"],
         sunab_se),
  pval = c(fixest::pvalue(m1)["treated"], fixest::pvalue(m2)["treated"], fixest::pvalue(m3)["treated"],
           fixest::pvalue(m4)["treated"], fixest::pvalue(m5)["treated"], fixest::pvalue(m6)["treated"],
           fixest::pvalue(m7)["years_treated"], fixest::pvalue(m8)["treated"],
           fixest::pvalue(m9)["treated"], fixest::pvalue(m13)["treated"], fixest::pvalue(m14)["years_treated"],
           sunab_pval)
)
results[, ci_lo := coef - 1.96 * se]
results[, ci_hi := coef + 1.96 * se]

fwrite(results, file.path(data_dir, "main_results.csv"))

## Save model objects for table generation
save(m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12, m13, m14, m_sunab,
     file = file.path(data_dir, "main_models.RData"))

## Save summary stats
sumstats <- panel[, .(
  mean = mean(share_heat_pump, na.rm = TRUE),
  sd = sd(share_heat_pump, na.rm = TRUE),
  min = min(share_heat_pump, na.rm = TRUE),
  max = max(share_heat_pump, na.rm = TRUE),
  n = .N
), by = .(period = fifelse(year <= 2015, "Pre (2009-15)", "Post (2021-22)"),
          treated_by_2021 = fifelse(!is.na(adoption_year) & adoption_year <= 2021, "Treated", "Control"))]
fwrite(sumstats, file.path(data_dir, "summary_stats.csv"))

## Save long-difference data for figures
fwrite(longdiff, file.path(data_dir, "long_difference.csv"))

cat("\nAll main analysis results saved.\n")
