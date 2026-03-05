## 03_main_analysis.R — Main DiD and event-study analysis for apep_0529

source("00_packages.R")

data_dir <- "../data"

## ============================================================
## Load data
## ============================================================
panel <- fread(file.path(data_dir, "circ_election_panel.csv"))
scrutins <- fread(file.path(data_dir, "scrutins_panel.csv"))
deputes <- fread(file.path(data_dir, "deputes_panel.csv"))

cat("Panel:", nrow(panel), "rows\n")
cat("Treated obs:", sum(panel$treated_group == 1), "\n")
cat("Control obs:", sum(panel$treated_group == 0), "\n")

## ============================================================
## A. LOCAL DIVISIVENESS: DiD on ENP and RN share
## ============================================================
cat("\n=== LOCAL DIVISIVENESS ANALYSIS ===\n")

## A1. Two-way FE: constituency + year FE
## Primary outcome: ENP
m1_enp <- fixest::feols(enp ~ post | circ_id + year, data = panel, cluster = ~circ_id)
cat("=== Model 1: ENP ~ post | circ_id + year ===\n")
print(summary(m1_enp))

## Secondary: RN share
m1_rn <- fixest::feols(rn_share ~ post | circ_id + year, data = panel, cluster = ~circ_id)
cat("\n=== Model 2: RN share ~ post | circ_id + year ===\n")
print(summary(m1_rn))

## Green share
m1_green <- fixest::feols(green_share ~ post | circ_id + year, data = panel, cluster = ~circ_id)
cat("\n=== Model 3: Green share ~ post | circ_id + year ===\n")
print(summary(m1_green))

## Turnout (restricted to 2012+ where data available)
panel_turnout <- panel[!is.na(turnout_rate)]
m1_turnout <- fixest::feols(turnout_rate ~ post | circ_id + year, data = panel_turnout, cluster = ~circ_id)
cat("\n=== Model 4: Turnout ~ post | circ_id + year (2012+) ===\n")
print(summary(m1_turnout))

## A1b. Sun-Abraham staggered DiD (robust to heterogeneous effects)
panel[, cohort_sa := fifelse(treated_group == 1 & !is.na(treatment_year), treatment_year, 10000L)]
m_sa_enp <- fixest::feols(enp ~ sunab(cohort_sa, year) | circ_id + year,
                          data = panel, cluster = ~circ_id)
cat("\n=== Sun-Abraham (ENP) ===\n")
print(summary(m_sa_enp))

m_sa_rn <- fixest::feols(rn_share ~ sunab(cohort_sa, year) | circ_id + year,
                         data = panel, cluster = ~circ_id)
cat("\n=== Sun-Abraham (RN share) ===\n")
print(summary(m_sa_rn))

## A2. Event study (requires treated group to have variation in event_time)
## Create event_time for treated constituencies
panel[treated_group == 1, event_time := year - treatment_year]
panel[treated_group == 0, event_time := NA_integer_]

## For event study with fixest, use sunab() or i() with event_time
## Need to bin event_time since elections are every 5 years (irregular)
panel[treated_group == 1, rel_period := as.factor(event_time)]

## Event study with fixest: interact treated × year dummies
## Create interaction terms for each year
panel[, year_f := as.factor(year)]
panel[, treated_x_year := treated_group * year]

## Event study specification
## Use 2017 as reference year (last pre-treatment for Wave 1)
m_es <- fixest::feols(enp ~ i(year, treated_group, ref = 2017) | circ_id + year,
                      data = panel,
                      cluster = ~circ_id)
cat("\n=== Event Study: ENP ===\n")
print(summary(m_es))

## RN event study
m_es_rn <- fixest::feols(rn_share ~ i(year, treated_group, ref = 2017) | circ_id + year,
                         data = panel,
                         cluster = ~circ_id)
cat("\n=== Event Study: RN share ===\n")
print(summary(m_es_rn))

## Save event study coefficients for plotting
es_enp <- as.data.table(fixest::coeftable(m_es), keep.rownames = "term")
es_enp[, outcome := "ENP"]

es_rn <- as.data.table(fixest::coeftable(m_es_rn), keep.rownames = "term")
es_rn[, outcome := "RN Share"]

es_all <- rbind(es_enp, es_rn, fill = TRUE)
fwrite(es_all, file.path(data_dir, "event_study_coefficients.csv"))

## A3. Continuous treatment intensity
m_intensity <- fixest::feols(enp ~ post:zfe_area_share | circ_id + year,
                             data = panel,
                             cluster = ~circ_id)
cat("\n=== Continuous Intensity: ENP ===\n")
print(summary(m_intensity))

m_intensity_rn <- fixest::feols(rn_share ~ post:zfe_area_share | circ_id + year,
                                data = panel,
                                cluster = ~circ_id)
cat("\n=== Continuous Intensity: RN share ===\n")
print(summary(m_intensity_rn))

## ============================================================
## B. NATIONAL DIVISIVENESS: Roll-call polarization
## ============================================================
cat("\n=== NATIONAL DIVISIVENESS ===\n")

## Compute Rice index for climate votes over time
## Rice index = |%Pour - %Contre| for the majority party/group
## For a full analysis we'd need individual MP votes, but with aggregate scrutin data
## we can track the number and passage rate of climate votes

## Year-level summary of climate votes
scrutins[, year := as.integer(format(date, "%Y"))]
climate_by_year <- scrutins[is_climate == 1, .(
  n_climate_votes = .N,
  pct_adopted = mean(sort == "adopte" | sort == "adopt\u00e9", na.rm = TRUE)
), by = year]

cat("Climate votes by year:\n")
print(climate_by_year[order(year)])

## Save national-level descriptive data
fwrite(climate_by_year, file.path(data_dir, "national_climate_votes.csv"))

## ============================================================
## C. SPILLBACK ANALYSIS: MP behavior
## ============================================================
cat("\n=== SPILLBACK ANALYSIS ===\n")

## Link deputies to ZFE exposure in their constituency
zfe_exp <- fread(file.path(data_dir, "zfe_constituency_exposure.csv"))

## Normalize circ_id format: remove leading zeros from constituency number
## ZFE data uses "34_01", deputy data uses "34_1"
normalize_circ_id <- function(x) {
  parts <- strsplit(x, "_")
  sapply(parts, function(p) paste0(p[1], "_", as.integer(p[2])))
}
zfe_exp[, circ_id_norm := normalize_circ_id(circ_id)]
deputes[, circ_id_norm := normalize_circ_id(circ_id)]

deputes <- merge(deputes,
                 zfe_exp[, .(circ_id_norm, zfe_area_share, zfe_treated)],
                 by = "circ_id_norm", all.x = TRUE)
deputes[is.na(zfe_treated), zfe_treated := 0L]
deputes[is.na(zfe_area_share), zfe_area_share := 0]

cat("MPs in ZFE constituencies:", sum(deputes$zfe_treated == 1),
    "of", nrow(deputes), "\n")

## Summary of party composition by ZFE exposure
cat("\nMP party groups by ZFE exposure:\n")
print(deputes[, .N, by = .(zfe_treated, groupe_sigle)][order(-zfe_treated, -N)])

## Save MP-ZFE exposure data
fwrite(deputes, file.path(data_dir, "deputes_with_exposure.csv"))

## ============================================================
## D. HETEROGENEITY: By wave and mandate type
## ============================================================
cat("\n=== HETEROGENEITY ===\n")

## Wave-specific effects
panel[treated_group == 1 & !is.na(wave), wave_f := as.factor(wave)]
m_wave <- fixest::feols(enp ~ post:i(wave) | circ_id + year,
                        data = panel[treated_group == 1 | treated_group == 0],
                        cluster = ~circ_id)
cat("Wave-specific effects on ENP:\n")
print(summary(m_wave))

## ============================================================
## E. Save summary statistics
## ============================================================
cat("\n=== Summary statistics ===\n")

## Full panel summary stats
summary_stats <- panel[, .(
  N = .N,
  n_circ = uniqueN(circ_id),
  n_years = uniqueN(year),
  mean_enp = round(mean(enp, na.rm = TRUE), 2),
  sd_enp = round(sd(enp, na.rm = TRUE), 2),
  mean_rn = round(mean(rn_share, na.rm = TRUE), 3),
  sd_rn = round(sd(rn_share, na.rm = TRUE), 3),
  mean_green = round(mean(green_share, na.rm = TRUE), 3),
  sd_green = round(sd(green_share, na.rm = TRUE), 3),
  mean_turnout = round(mean(turnout_rate, na.rm = TRUE), 3),
  sd_turnout = round(sd(turnout_rate, na.rm = TRUE), 3)
), by = treated_group]

print(summary_stats)
fwrite(summary_stats, file.path(data_dir, "summary_stats.csv"))

## Outcome means by year and treatment group
panel_means <- panel[, .(
  mean_enp = mean(enp, na.rm = TRUE),
  mean_rn = mean(rn_share, na.rm = TRUE),
  mean_green = mean(green_share, na.rm = TRUE),
  mean_turnout = mean(turnout_rate, na.rm = TRUE),
  n = .N
), by = .(year, treated_group)]

fwrite(panel_means, file.path(data_dir, "panel_means.csv"))

## ============================================================
## F. Save regression results for tables
## ============================================================

## Store all models in a list for table generation
models <- list(
  enp_did = m1_enp,
  rn_did = m1_rn,
  green_did = m1_green,
  turnout_did = m1_turnout,
  enp_es = m_es,
  rn_es = m_es_rn,
  enp_intensity = m_intensity,
  rn_intensity = m_intensity_rn
)

saveRDS(models, file.path(data_dir, "regression_models.rds"))

cat("\n=== ANALYSIS COMPLETE ===\n")
