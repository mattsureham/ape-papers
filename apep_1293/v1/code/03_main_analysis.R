## ==============================================================
## 03_main_analysis.R — apep_1293
## Shift-share DiD + DDD: firearms policy and homicide
## ==============================================================

source("code/00_packages.R")

panel <- fread("data/analysis_panel.csv")
panel[, mun_code := as.character(mun_code)]

# Full panel 2013-2023 (2023 = Lula reversal year)
panel_main <- panel[year <= 2023]

cat("=== Main Analysis Panel ===\n")
cat(sprintf("Observations: %s\n", format(nrow(panel_main), big.mark = ",")))
cat(sprintf("Municipalities: %d\n", uniqueN(panel_main$mun_code)))
cat(sprintf("Years: %d-%d\n", min(panel_main$year), max(panel_main$year)))
cat(sprintf("Treated (has_club = 1): %d municipalities\n",
            uniqueN(panel_main[has_club == 1]$mun_code)))

## ------------------------------------------------------------------
## 1. DiD: Firearm homicide rate ~ Post2019 × ClubDensity
##    (Shift-share specification)
## ------------------------------------------------------------------

cat("\n=== Specification 1: Continuous Treatment (Club Density) ===\n")

# Firearm homicides only
fire <- panel_main[cause_group == "firearm_homicide"]

# Spec 1a: TWFE with continuous treatment intensity
spec1a <- feols(rate ~ post2019_clubs | mun_code + year,
                data = fire, cluster = ~mun_code)
cat("\nSpec 1a: rate ~ Post2019 × ClubDensity | FE(mun, year)\n")
print(summary(spec1a))

# Spec 1b: Binary treatment (has club in 2018)
spec1b <- feols(rate ~ post2019_hasclub | mun_code + year,
                data = fire, cluster = ~mun_code)
cat("\nSpec 1b: rate ~ Post2019 × HasClub | FE(mun, year)\n")
print(summary(spec1b))

## ------------------------------------------------------------------
## 2. Event Study
## ------------------------------------------------------------------

cat("\n=== Specification 2: Event Study ===\n")

# Create year indicators interacted with treatment
fire[, year_f := factor(year)]

# Event study with continuous treatment
es_cont <- feols(rate ~ i(year, club_density, ref = 2018) | mun_code + year,
                 data = fire, cluster = ~mun_code)
cat("\nEvent study (continuous treatment):\n")
print(summary(es_cont))

# Event study with binary treatment
es_bin <- feols(rate ~ i(year, has_club, ref = 2018) | mun_code + year,
                data = fire, cluster = ~mun_code)
cat("\nEvent study (binary treatment):\n")
print(summary(es_bin))

## ------------------------------------------------------------------
## 3. DDD: Firearm vs Non-firearm × Post2019 × ClubDensity
## ------------------------------------------------------------------

cat("\n=== Specification 3: DDD ===\n")

# DDD specification
panel_main[, post2019_clubs_firearm := post_2019 * club_density * firearm]
panel_main[, post2019_firearm := post_2019 * firearm]
panel_main[, clubs_firearm := club_density * firearm]

# Full DDD with all interactions absorbed by FE
# Y_{mct} = α_{mc} + γ_{ct} + δ_{mt} + β * Post2019 × ClubDensity × Firearm + ε
ddd <- feols(rate ~ post2019_clubs_firearm |
               mun_code^cause_group + year^cause_group + mun_code^year,
             data = panel_main, cluster = ~mun_code)
cat("\nDDD: rate ~ Post2019 × ClubDensity × Firearm | FE(mun×cause, year×cause, mun×year)\n")
print(summary(ddd))

# DDD with binary treatment
panel_main[, post2019_hasclub_firearm := post_2019 * has_club * firearm]

ddd_bin <- feols(rate ~ post2019_hasclub_firearm |
                   mun_code^cause_group + year^cause_group + mun_code^year,
                 data = panel_main, cluster = ~mun_code)
cat("\nDDD (binary): rate ~ Post2019 × HasClub × Firearm | FE\n")
print(summary(ddd_bin))

## ------------------------------------------------------------------
## 4. Heterogeneity: Urban vs Rural
## ------------------------------------------------------------------

cat("\n=== Specification 4: Heterogeneity ===\n")

# Population terciles (as proxy for urbanization)
pop_terciles <- fire[year == 2018, .(mun_code, pop_2018)]
pop_terciles <- unique(pop_terciles)
pop_terciles[, pop_tercile := cut(pop_2018,
                                   breaks = quantile(pop_2018, c(0, 1/3, 2/3, 1)),
                                   labels = c("small", "medium", "large"),
                                   include.lowest = TRUE)]

fire <- merge(fire, pop_terciles[, .(mun_code, pop_tercile)],
              by = "mun_code", all.x = TRUE)

# Run separately by population size
for (pt in c("small", "medium", "large")) {
  sub <- fire[pop_tercile == pt]
  fit <- feols(rate ~ post2019_hasclub | mun_code + year,
               data = sub, cluster = ~mun_code)
  cat(sprintf("\n%s municipalities (N=%d): coef=%.3f, se=%.3f, p=%.4f\n",
              pt, nrow(sub), coef(fit), se(fit), fixest::pvalue(fit)))
}

## ------------------------------------------------------------------
## 5. Save results for tables
## ------------------------------------------------------------------

cat("\n=== Saving results ===\n")

results <- list(
  spec1a_cont = list(
    coef = coef(spec1a),
    se = se(spec1a),
    pval = fixest::pvalue(spec1a),
    nobs = nobs(spec1a),
    r2 = fitstat(spec1a, "r2")$r2
  ),
  spec1b_binary = list(
    coef = coef(spec1b),
    se = se(spec1b),
    pval = fixest::pvalue(spec1b),
    nobs = nobs(spec1b),
    r2 = fitstat(spec1b, "r2")$r2
  ),
  ddd_cont = list(
    coef = coef(ddd),
    se = se(ddd),
    pval = fixest::pvalue(ddd),
    nobs = nobs(ddd),
    r2 = fitstat(ddd, "r2")$r2
  ),
  ddd_binary = list(
    coef = coef(ddd_bin),
    se = se(ddd_bin),
    pval = fixest::pvalue(ddd_bin),
    nobs = nobs(ddd_bin),
    r2 = fitstat(ddd_bin, "r2")$r2
  )
)

# Save event study coefficients
es_coefs <- data.table(
  year = as.integer(gsub("year::", "", names(coef(es_bin)))),
  coef = coef(es_bin),
  se = se(es_bin)
)
es_coefs[, ci_lo := coef - 1.96 * se]
es_coefs[, ci_hi := coef + 1.96 * se]
fwrite(es_coefs, "data/event_study_coefs.csv")

# Save all models for table generation
saveRDS(list(spec1a = spec1a, spec1b = spec1b,
             ddd = ddd, ddd_bin = ddd_bin,
             es_cont = es_cont, es_bin = es_bin),
        "data/main_models.rds")

# Summary statistics for paper
fire_pre <- fire[year < 2019]
fire_post <- fire[year >= 2019]

sumstats <- data.table(
  variable = c("Firearm homicide rate (per 100K)",
               "Non-firearm homicide rate (per 100K)",
               "Population (thousands)",
               "Shooting clubs (2018)",
               "Club density (per 100K, 2018)"),
  mean = c(
    fire_pre[, weighted.mean(rate, population)],
    panel_main[cause_group == "nonfirearm_homicide" & year < 2019,
               weighted.mean(rate, population)],
    panel_main[year == 2018 & firearm == 1, mean(population / 1000)],
    panel_main[year == 2018 & firearm == 1, mean(clubs_2018)],
    panel_main[year == 2018 & firearm == 1 & club_density > 0, mean(club_density)]
  ),
  sd = c(
    fire_pre[, sd(rate)],
    panel_main[cause_group == "nonfirearm_homicide" & year < 2019, sd(rate)],
    panel_main[year == 2018 & firearm == 1, sd(population / 1000)],
    panel_main[year == 2018 & firearm == 1, sd(clubs_2018)],
    panel_main[year == 2018 & firearm == 1 & club_density > 0, sd(club_density)]
  )
)
fwrite(sumstats, "data/summary_stats.csv")

cat("\nAll results saved.\n")
cat(sprintf("Event study coefficients: data/event_study_coefs.csv\n"))
cat(sprintf("Models: data/main_models.rds\n"))
cat(sprintf("Summary stats: data/summary_stats.csv\n"))
