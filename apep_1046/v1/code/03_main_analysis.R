## 03_main_analysis.R — Triple-difference estimation
## apep_1046: Cross-hazard injury substitution from OSHA silica standard
##
## Design: Within-manufacturing, exploit variation in silica exposure intensity
## High-silica NAICS: 327 (stone/glass/cement), 331 (primary metals), 332 (fabricated metals)
## Low-silica NAICS: 311 (food), 312 (beverage), 313 (textile), 314 (textile products),
##                   315 (apparel), 322 (paper), 323 (printing), 325 (chemicals),
##                   326 (plastics), 335 (electrical), 336 (transportation equip),
##                   337 (furniture), 339 (misc)
##
## Silica standard: PEL reduced from 250 to 50 μg/m³
##   - Construction: June 23, 2016
##   - General industry: June 23, 2018 (PEL), engineering controls phased to 2021
##
## Post-treatment: 2022+ (first full year after June 2021 engineering controls deadline)
## Engineering controls are the most expensive compliance phase ($637M/year)
##
## Triple-diff:
##   β₃ = (ΔNonTargeted_highsilica - ΔNonTargeted_lowsilica) -
##        (ΔTargeted_highsilica - ΔTargeted_lowsilica)
##   where Targeted = respiratory_conditions, NonTargeted = injuries/hearing/skin/other

source("00_packages.R")

panel <- fread("../data/panel_establishment.csv")

## ── Restrict to manufacturing ────────────────────────────────────────
mfg <- panel[sector_group == "manufacturing"]
cat("Manufacturing establishments:", uniqueN(mfg$establishment_id), "\n")
cat("Manufacturing obs:", nrow(mfg), "\n")

## Define high-silica vs low-silica subsectors
mfg[, high_silica := as.integer(naics3 %in% c(327, 331, 332))]
mfg[, post := as.integer(year >= 2022)]

## Summary by silica intensity
cat("\n=== Establishments by silica exposure ===\n")
print(mfg[, .(
  n_estab = uniqueN(establishment_id),
  n_obs = .N,
  mean_emp = round(mean(emp), 0),
  mean_inj = round(mean(total_injuries_rate), 2),
  mean_resp = round(mean(total_respiratory_conditions_rate), 3),
  mean_hear = round(mean(total_hearing_loss_rate), 3)
), by = .(high_silica, post)])

## ── Create hazard-long panel ─────────────────────────────────────────
hazard_vars <- c("total_injuries_rate", "total_respiratory_conditions_rate",
                 "total_hearing_loss_rate", "total_skin_disorders_rate",
                 "total_other_illnesses_rate")

hl <- melt(
  mfg,
  id.vars = c("establishment_id", "year", "naics2", "naics3", "naics4",
              "high_silica", "post", "emp", "hours", "state"),
  measure.vars = hazard_vars,
  variable.name = "hazard_var",
  value.name = "rate"
)

hl[, hazard := gsub("total_|_rate", "", hazard_var)]

## Targeted = respiratory (silica causes respiratory disease)
## Non-targeted = everything else
hl[, targeted := as.integer(hazard == "respiratory_conditions")]
hl[, non_targeted := 1L - targeted]

## Create interaction terms
hl[, hs_post := high_silica * post]
hl[, nt_post := non_targeted * post]
hl[, hs_nt := high_silica * non_targeted]
hl[, hs_nt_post := high_silica * non_targeted * post]

## Factor versions for FEs
hl[, estab_f := as.factor(establishment_id)]
hl[, year_f := as.factor(year)]
hl[, hazard_f := as.factor(hazard)]
hl[, naics3_f := as.factor(naics3)]
hl[, estab_hazard := paste0(establishment_id, "_", hazard)]
hl[, estab_year := paste0(establishment_id, "_", year)]
hl[, hazard_year := paste0(hazard, "_", year)]

cat("\nHazard-long panel: ", nrow(hl), "rows,", uniqueN(hl$establishment_id), "establishments\n")

## ── Winsorize extreme rates ──────────────────────────────────────────
## Some establishments have very few hours → extreme rates
p99 <- quantile(hl$rate, 0.99, na.rm = TRUE)
p01 <- quantile(hl$rate, 0.01, na.rm = TRUE)
cat("Rate p1:", p01, " p99:", p99, "\n")
hl[, rate_w := pmin(pmax(rate, p01), p99)]

## ── Model 1: Basic DDD ──────────────────────────────────────────────
cat("\n=== MODEL 1: Basic Triple-Diff ===\n")
m1 <- feols(rate_w ~ hs_post + nt_post + hs_nt + hs_nt_post |
              establishment_id + year + hazard,
            data = hl, cluster = ~establishment_id)
summary(m1)

## ── Model 2: Saturated FEs (establishment×hazard + hazard×year) ─────
cat("\n=== MODEL 2: Saturated FEs ===\n")
m2 <- feols(rate_w ~ hs_nt_post |
              estab_hazard + hazard_year + estab_year,
            data = hl, cluster = ~establishment_id)
summary(m2)

## ── Model 3: Event study (year-by-year) ─────────────────────────────
cat("\n=== MODEL 3: Event Study ===\n")
## Use 2021 as base year (last pre-treatment year)
hl[, event_year := year - 2021]
hl[, ey_hs_nt := as.character(event_year)]
## Interact with high_silica × non_targeted
hl[event_year == 0, ey_hs_nt := NA]  # base year

## Create dummies for event study
for (k in c(-5, -4, -3, -2, -1, 1, 2, 3)) {
  var_name <- paste0("ey", ifelse(k < 0, "m", "p"), abs(k))
  hl[, (var_name) := as.integer(event_year == k) * high_silica * non_targeted]
}

m3 <- feols(rate_w ~ eym5 + eym4 + eym3 + eym2 + eym1 + eyp1 + eyp2 + eyp3 |
              estab_hazard + hazard_year + estab_year,
            data = hl, cluster = ~establishment_id)
cat("\nEvent study coefficients:\n")
summary(m3)

## ── Model 4: Heterogeneity by establishment size ────────────────────
cat("\n=== MODEL 4: Size heterogeneity ===\n")
hl[, small_firm := as.integer(emp < 500)]
hl[, hs_nt_post_small := hs_nt_post * small_firm]
hl[, hs_nt_post_large := hs_nt_post * (1 - small_firm)]

m4 <- feols(rate_w ~ hs_nt_post_small + hs_nt_post_large |
              estab_hazard + hazard_year + estab_year,
            data = hl, cluster = ~establishment_id)
summary(m4)

## ── Model 5: DiD on targeted hazard only (respiratory) ──────────────
cat("\n=== MODEL 5: DiD on respiratory only ===\n")
resp_only <- mfg[, .(establishment_id, year, naics3, high_silica, post,
                      rate = total_respiratory_conditions_rate, emp, hours)]
resp_only[, rate_w := pmin(pmax(rate, 0), quantile(rate, 0.99, na.rm = TRUE))]

m5 <- feols(rate_w ~ high_silica:post | establishment_id + year,
            data = resp_only, cluster = ~establishment_id)
summary(m5)

## ── Model 6: DiD on non-targeted (injuries) only ────────────────────
cat("\n=== MODEL 6: DiD on total injuries only ===\n")
inj_only <- mfg[, .(establishment_id, year, naics3, high_silica, post,
                     rate = total_injuries_rate, emp, hours)]
inj_only[, rate_w := pmin(pmax(rate, 0), quantile(rate, 0.99, na.rm = TRUE))]

m6 <- feols(rate_w ~ high_silica:post | establishment_id + year,
            data = inj_only, cluster = ~establishment_id)
summary(m6)

## ── Save results ─────────────────────────────────────────────────────
save(m1, m2, m3, m4, m5, m6, file = "../data/main_results.RData")

## Diagnostics for validator
n_treated <- uniqueN(mfg[high_silica == 1, establishment_id])
n_pre <- length(unique(mfg[post == 0, year]))
n_obs_total <- nrow(hl)

jsonlite::write_json(
  list(
    n_treated = n_treated,
    n_pre = n_pre,
    n_obs = n_obs_total,
    n_establishments = uniqueN(mfg$establishment_id),
    n_years = uniqueN(mfg$year)
  ),
  "../data/diagnostics.json",
  auto_unbox = TRUE
)

cat("\n=== Diagnostics ===\n")
cat("Treated establishments (high-silica):", n_treated, "\n")
cat("Pre-treatment periods:", n_pre, "\n")
cat("Total observations (hazard-long):", n_obs_total, "\n")
cat("Analysis complete. Results saved.\n")
