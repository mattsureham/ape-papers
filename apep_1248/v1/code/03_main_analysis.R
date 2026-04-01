## 03_main_analysis.R — Double-difference estimation
## Effect of Colombia's 2012 payroll tax cut on benefit delivery quality
## Design: Small Firm × Post (2013+), comparing small (≤10) vs medium (11-50) firms

library(data.table)
library(fixest)
library(tidyverse)
library(jsonlite)

DATA_DIR <- file.path(dirname(getwd()), "data")
TABLE_DIR <- file.path(dirname(getwd()), "tables")
dir.create(TABLE_DIR, showWarnings = FALSE, recursive = TRUE)

# Load analytic data (all wage employees at small/medium firms, ages 18-65)
geih <- readRDS(file.path(DATA_DIR, "geih_analytic.rds"))
cat(sprintf("Analytic sample: %s obs\n", format(nrow(geih), big.mark = ",")))

# ---- Additional formality indicators ----
geih[, written := as.integer(p6450 == 2)]   # Written (not verbal) contract
geih[, pension := as.integer(p6920 == 1)]    # Contributing to pension

# "Thin formality": has pension registration but benefit index < 4
geih[, thin_formal := as.integer(pension == 1 & benefit_index < 4)]

# Event study relative year (2012 = 0, last pre-reform year)
geih[, year_rel := year - 2012]

# ======== TABLE 2: EXTENSIVE MARGIN (FORMALIZATION) ========
cat("\n=== TABLE 2: EXTENSIVE MARGIN — FORMALIZATION DiD ===\n")

# Col 1: Written contract
ext_written <- feols(written ~ small_firm:post + small_firm + post |
                       city + year_quarter,
                     data = geih, cluster = ~city)

# Col 2: Pension contribution
ext_pension <- feols(pension ~ small_firm:post + small_firm + post |
                       city + year_quarter,
                     data = geih, cluster = ~city)

# Col 3: Written contract with controls
ext_written_ctrl <- feols(written ~ small_firm:post + small_firm + post +
                            age + I(age^2) + female + factor(educ_level) |
                            city + year_quarter,
                          data = geih[!is.na(educ_level)], cluster = ~city)

# Col 4: Pension with controls
ext_pension_ctrl <- feols(pension ~ small_firm:post + small_firm + post +
                            age + I(age^2) + female + factor(educ_level) |
                            city + year_quarter,
                          data = geih[!is.na(educ_level)], cluster = ~city)

cat("Extensive margin (Small Firm × Post):\n")
cat(sprintf("  Written contract: %.4f (%.4f)\n",
            coef(ext_written)["small_firm:post"], se(ext_written)["small_firm:post"]))
cat(sprintf("  Pension:          %.4f (%.4f)\n",
            coef(ext_pension)["small_firm:post"], se(ext_pension)["small_firm:post"]))

# ======== TABLE 3: BENEFIT QUALITY (MAIN RESULT) ========
cat("\n=== TABLE 3: BENEFIT COMPLETENESS ===\n")

# Col 1: Benefit index (0-4), no controls
ben_did <- feols(benefit_index ~ small_firm:post + small_firm + post |
                   city + year_quarter,
                 data = geih[!is.na(benefit_index)],
                 cluster = ~city)

# Col 2: With individual controls
ben_did_ctrl <- feols(benefit_index ~ small_firm:post + small_firm + post +
                        age + I(age^2) + female + factor(educ_level) + hours |
                        city + year_quarter,
                      data = geih[!is.na(benefit_index) & !is.na(educ_level) & !is.na(hours)],
                      cluster = ~city)

# Col 3: With sector FE
ben_did_sector <- feols(benefit_index ~ small_firm:post + small_firm + post +
                          age + I(age^2) + female + factor(educ_level) + hours |
                          city + year_quarter + sector,
                        data = geih[!is.na(benefit_index) & !is.na(educ_level) &
                                      !is.na(hours) & !is.na(sector)],
                        cluster = ~city)

cat(sprintf("  Benefit index (no controls): %.4f (%.4f)\n",
            coef(ben_did)["small_firm:post"], se(ben_did)["small_firm:post"]))
cat(sprintf("  Benefit index (w/controls):  %.4f (%.4f)\n",
            coef(ben_did_ctrl)["small_firm:post"], se(ben_did_ctrl)["small_firm:post"]))
cat(sprintf("  Benefit index (w/sector FE): %.4f (%.4f)\n",
            coef(ben_did_sector)["small_firm:post"], se(ben_did_sector)["small_firm:post"]))

# ---- "Thin formality" test ----
# The gap between pension enrollment gain and benefit delivery
cat("\n=== THIN FORMALITY: Pension gain vs benefit gain ===\n")
cat(sprintf("  Pension DiD:        %.4f (%.4f)\n",
            coef(ext_pension)["small_firm:post"], se(ext_pension)["small_firm:post"]))
cat(sprintf("  Benefit index DiD:  %.4f (%.4f)\n",
            coef(ben_did)["small_firm:post"], se(ben_did)["small_firm:post"]))
cat(sprintf("  Thin formality DiD:\n"))

thin_did <- feols(thin_formal ~ small_firm:post + small_firm + post |
                    city + year_quarter,
                  data = geih[!is.na(thin_formal)],
                  cluster = ~city)
cat(sprintf("    Small×Post on P(pension=1 & benefits<4): %.4f (%.4f)\n",
            coef(thin_did)["small_firm:post"], se(thin_did)["small_firm:post"]))

# ======== TABLE 4: INDIVIDUAL BENEFITS (DECOMPOSITION) ========
cat("\n=== TABLE 4: INDIVIDUAL BENEFITS ===\n")

benefits <- c("benefit_vacation", "benefit_prima_nav", "benefit_cesantias", "benefit_pension")
benefit_labels <- c("Paid Vacation", "Prima de Navidad", "Cesantías", "Pension")

benefit_models <- list()
for (i in seq_along(benefits)) {
  bvar <- benefits[i]
  df_sub <- geih[!is.na(get(bvar)) & !is.na(educ_level)]

  mod <- feols(as.formula(paste0(bvar, " ~ small_firm:post + small_firm + post +
                 age + I(age^2) + female + factor(educ_level) |
                 city + year_quarter")),
               data = df_sub, cluster = ~city)

  benefit_models[[bvar]] <- mod
  cat(sprintf("  %s — DiD: %.4f (%.4f), p=%.4f\n",
              benefit_labels[i],
              coef(mod)["small_firm:post"], se(mod)["small_firm:post"],
              pvalue(mod)["small_firm:post"]))
}

# ======== EVENT STUDY (PRE-TRENDS TEST) ========
cat("\n=== EVENT STUDY ===\n")

# Event study: year_rel × small_firm interaction, ref=0 (2012)
es_pension <- feols(pension ~ i(year_rel, small_firm, ref = 0) +
                      small_firm + age + I(age^2) + female |
                      city + year_quarter,
                    data = geih, cluster = ~city)

es_benefits <- feols(benefit_index ~ i(year_rel, small_firm, ref = 0) +
                       small_firm + age + I(age^2) + female |
                       city + year_quarter,
                     data = geih[!is.na(benefit_index)], cluster = ~city)

cat("Event study for pension (year_rel × small_firm):\n")
for (yr in c(-1, 1, 2, 3, 4)) {
  term <- sprintf("year_rel::%d:small_firm", yr)
  if (term %in% names(coef(es_pension))) {
    cat(sprintf("  t=%+d: %.4f (%.4f)\n", yr, coef(es_pension)[term], se(es_pension)[term]))
  }
}

cat("\nEvent study for benefit index (year_rel × small_firm):\n")
for (yr in c(-1, 1, 2, 3, 4)) {
  term <- sprintf("year_rel::%d:small_firm", yr)
  if (term %in% names(coef(es_benefits))) {
    cat(sprintf("  t=%+d: %.4f (%.4f)\n", yr, coef(es_benefits)[term], se(es_benefits)[term]))
  }
}

# ---- Save diagnostics.json ----
n_treated <- nrow(geih[small_firm == 1 & post == 1])
n_pre <- length(unique(geih[post == 0]$year))
n_obs <- nrow(geih[!is.na(benefit_index)])

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_cities = length(unique(geih$city)),
  n_years = length(unique(geih$year)),
  did_coef_benefit_index = round(coef(ben_did_ctrl)["small_firm:post"], 4),
  did_se_benefit_index = round(se(ben_did_ctrl)["small_firm:post"], 4),
  did_coef_pension = round(coef(ext_pension)["small_firm:post"], 4),
  did_se_pension = round(se(ext_pension)["small_firm:post"], 4),
  mean_benefit_index_pre = round(mean(geih[post == 0]$benefit_index, na.rm = TRUE), 3),
  sd_benefit_index_pre = round(sd(geih[post == 0]$benefit_index, na.rm = TRUE), 3),
  mean_pension_pre = round(mean(geih[post == 0]$pension, na.rm = TRUE), 3),
  sd_pension_pre = round(sd(geih[post == 0]$pension, na.rm = TRUE), 3)
)

write_json(diagnostics, file.path(DATA_DIR, "diagnostics.json"), auto_unbox = TRUE)
cat(sprintf("\nDiagnostics saved: n_treated=%s, n_pre=%d, n_obs=%s\n",
            format(n_treated, big.mark = ","), n_pre, format(n_obs, big.mark = ",")))

# ---- Save model objects for tables script ----
save(ext_written, ext_pension, ext_written_ctrl, ext_pension_ctrl,
     ben_did, ben_did_ctrl, ben_did_sector,
     thin_did,
     benefit_models, es_pension, es_benefits,
     file = file.path(DATA_DIR, "main_models.RData"))

cat("\n=== Main analysis complete ===\n")
