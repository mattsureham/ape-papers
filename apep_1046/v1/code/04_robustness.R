## 04_robustness.R — Robustness checks
## apep_1046: Cross-hazard injury substitution

source("00_packages.R")

panel <- fread("../data/panel_establishment.csv")
mfg <- panel[sector_group == "manufacturing"]
mfg[, high_silica := as.integer(naics3 %in% c(327, 331, 332))]
mfg[, post := as.integer(year >= 2022)]

## Helper: create hazard-long panel from an establishment panel
make_hazard_long <- function(dt) {
  hazard_vars <- c("total_injuries_rate", "total_respiratory_conditions_rate",
                    "total_hearing_loss_rate", "total_skin_disorders_rate",
                    "total_other_illnesses_rate")
  hl <- melt(dt,
    id.vars = c("establishment_id", "year", "naics3",
                "high_silica", "post", "emp", "hours", "state"),
    measure.vars = hazard_vars,
    variable.name = "hazard_var", value.name = "rate"
  )
  hl[, hazard := gsub("total_|_rate", "", hazard_var)]
  hl[, targeted := as.integer(hazard == "respiratory_conditions")]
  hl[, non_targeted := 1L - targeted]
  hl[, hs_nt_post := high_silica * non_targeted * post]
  hl[, estab_hazard := paste0(establishment_id, "_", hazard)]
  hl[, estab_year := paste0(establishment_id, "_", year)]
  hl[, hazard_year := paste0(hazard, "_", year)]
  p99 <- quantile(hl$rate, 0.99, na.rm = TRUE)
  hl[, rate_w := pmin(pmax(rate, 0), p99)]
  hl
}

## ── R1: Exclude COVID years (2020-2021) ─────────────────────────────
cat("=== R1: Excluding COVID years 2020-2021 ===\n")
mfg_nocovid <- mfg[!year %in% c(2020, 2021)]
hl_nocovid <- make_hazard_long(mfg_nocovid)

r1 <- feols(rate_w ~ hs_nt_post |
              estab_hazard + hazard_year + estab_year,
            data = hl_nocovid, cluster = ~establishment_id)
summary(r1)

## ── R2: Broader silica definition (add NAICS 324, 321) ──────────────
cat("\n=== R2: Broader silica definition ===\n")
mfg2 <- copy(mfg)
mfg2[, high_silica := as.integer(naics3 %in% c(327, 331, 332, 324, 321))]
mfg2[, post := as.integer(year >= 2022)]
hl2 <- make_hazard_long(mfg2)

r2 <- feols(rate_w ~ hs_nt_post |
              estab_hazard + hazard_year + estab_year,
            data = hl2, cluster = ~establishment_id)
summary(r2)

## ── R3: Narrower silica definition (only NAICS 327) ─────────────────
cat("\n=== R3: Narrower silica definition (NAICS 327 only) ===\n")
mfg3 <- copy(mfg)
mfg3[, high_silica := as.integer(naics3 == 327)]
mfg3[, post := as.integer(year >= 2022)]
hl3 <- make_hazard_long(mfg3)

r3 <- feols(rate_w ~ hs_nt_post |
              estab_hazard + hazard_year + estab_year,
            data = hl3, cluster = ~establishment_id)
summary(r3)

## ── R4: DAFW (days away from work) as outcome ───────────────────────
cat("\n=== R4: Days away from work (DAFW) rate ===\n")
mfg[, dafw_rate := as.numeric(total_dafw_days) / hours * 200000]
mfg[is.na(dafw_rate), dafw_rate := 0]
p99_dafw <- quantile(mfg$dafw_rate, 0.99, na.rm = TRUE)
mfg[, dafw_rate_w := pmin(pmax(dafw_rate, 0), p99_dafw)]

r4 <- feols(dafw_rate_w ~ high_silica:post | establishment_id + year,
            data = mfg, cluster = ~establishment_id)
summary(r4)

## ── R5: Count outcomes (Poisson-like via log(count+1)) ──────────────
cat("\n=== R5: Log injury counts ===\n")
mfg[, log_injuries := log(total_injuries + 1)]
mfg[, log_resp := log(total_respiratory_conditions + 1)]
mfg[, log_hearing := log(total_hearing_loss + 1)]

r5a <- feols(log_injuries ~ high_silica:post | establishment_id + year,
             data = mfg, cluster = ~establishment_id)
cat("Log injuries:\n")
summary(r5a)

r5b <- feols(log_resp ~ high_silica:post | establishment_id + year,
             data = mfg, cluster = ~establishment_id)
cat("Log respiratory:\n")
summary(r5b)

## ── R6: Construction placebo (already treated by 2016 silica rule) ──
cat("\n=== R6: Construction vs Services placebo ===\n")
constr_svc <- panel[sector_group %in% c("construction", "services")]
constr_svc[, construction := as.integer(sector_group == "construction")]
constr_svc[, post := as.integer(year >= 2017)]  # construction rule was 2016

hl_cs <- melt(constr_svc,
  id.vars = c("establishment_id", "year", "naics3",
              "construction", "post", "emp", "hours", "state"),
  measure.vars = c("total_injuries_rate", "total_respiratory_conditions_rate",
                    "total_hearing_loss_rate", "total_skin_disorders_rate",
                    "total_other_illnesses_rate"),
  variable.name = "hazard_var", value.name = "rate"
)
hl_cs[, hazard := gsub("total_|_rate", "", hazard_var)]
hl_cs[, targeted := as.integer(hazard == "respiratory_conditions")]
hl_cs[, non_targeted := 1L - targeted]
hl_cs[, cs_nt_post := construction * non_targeted * post]
hl_cs[, estab_hazard := paste0(establishment_id, "_", hazard)]
hl_cs[, estab_year := paste0(establishment_id, "_", year)]
hl_cs[, hazard_year := paste0(hazard, "_", year)]
p99_cs <- quantile(hl_cs$rate, 0.99, na.rm = TRUE)
hl_cs[, rate_w := pmin(pmax(rate, 0), p99_cs)]

r6 <- feols(rate_w ~ cs_nt_post |
              estab_hazard + hazard_year + estab_year,
            data = hl_cs, cluster = ~establishment_id)
summary(r6)

## ── R7: DDD with manufacturing vs services (broader comparison) ─────
cat("\n=== R7: Manufacturing vs Services DDD ===\n")
mfg_svc <- panel[sector_group %in% c("manufacturing", "services")]
mfg_svc[, mfg := as.integer(sector_group == "manufacturing")]
mfg_svc[, post := as.integer(year >= 2019)]

hl_ms <- melt(mfg_svc,
  id.vars = c("establishment_id", "year", "naics3",
              "mfg", "post", "emp", "hours", "state"),
  measure.vars = c("total_injuries_rate", "total_respiratory_conditions_rate",
                    "total_hearing_loss_rate", "total_skin_disorders_rate",
                    "total_other_illnesses_rate"),
  variable.name = "hazard_var", value.name = "rate"
)
hl_ms[, hazard := gsub("total_|_rate", "", hazard_var)]
hl_ms[, targeted := as.integer(hazard == "respiratory_conditions")]
hl_ms[, non_targeted := 1L - targeted]
hl_ms[, mfg_nt_post := mfg * non_targeted * post]
hl_ms[, estab_hazard := paste0(establishment_id, "_", hazard)]
hl_ms[, estab_year := paste0(establishment_id, "_", year)]
hl_ms[, hazard_year := paste0(hazard, "_", year)]
p99_ms <- quantile(hl_ms$rate, 0.99, na.rm = TRUE)
hl_ms[, rate_w := pmin(pmax(rate, 0), p99_ms)]

r7 <- feols(rate_w ~ mfg_nt_post |
              estab_hazard + hazard_year + estab_year,
            data = hl_ms, cluster = ~establishment_id)
summary(r7)

## Save all robustness results
save(r1, r2, r3, r4, r5a, r5b, r6, r7, file = "../data/robustness_results.RData")
cat("\nAll robustness checks complete. Results saved.\n")
