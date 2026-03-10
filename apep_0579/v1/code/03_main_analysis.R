## ==============================================================
## 03_main_analysis.R — Estimate switch-on and switch-off effects
## APEP-0579: Policy Reversals Meta-Natural Experiment
## ==============================================================

source("00_packages.R")
data_dir <- "../data"

results <- list()

## ---------------------------------------------------------------
## REFORM 1: Denmark fat tax
## Treated: food COICOP categories. Control: non-food.
## Unit: coicop × month. ON: Oct 2011. OFF: Jan 2013.
## ---------------------------------------------------------------
cat("=== REFORM 1: Denmark fat tax ===\n")

dk <- fread(file.path(data_dir, "dk_clean.csv"))
dk[, date := as.Date(date)]
dk[, coicop := as.character(coicop)]

# Switch-ON: pre vs policy-on
dk_on <- dk[period %in% c("pre", "policy_on")]
m_dk_on <- feols(values ~ treated:policy_on | coicop + date, data = dk_on,
                  cluster = ~coicop)

# Switch-OFF: pre vs post-repeal (measures residual effect relative to pre-policy)
dk_off <- dk[period %in% c("pre", "post_repeal")]
m_dk_off <- feols(values ~ treated:post_repeal | coicop + date, data = dk_off,
                   cluster = ~coicop)

cat("  β_ON =", round(coef(m_dk_on)[1], 4), "SE =", round(se(m_dk_on)[1], 4), "\n")
cat("  β_OFF =", round(coef(m_dk_off)[1], 4), "SE =", round(se(m_dk_off)[1], 4), "\n")

# Event study (full panel)
dk[, et_on_bin := fifelse(event_time_on < -12, -12L,
                   fifelse(event_time_on > 24, 24L, as.integer(event_time_on)))]
dk[, et_on_bin := relevel(factor(et_on_bin), ref = "-1")]

m_dk_es <- feols(values ~ i(et_on_bin, treated, ref = -1) | coicop + date,
                  data = dk, cluster = ~coicop)

results$dk <- list(
  reform = "Denmark fat tax",
  domain = "Price/consumption",
  duration_months = 15,
  beta_on = coef(m_dk_on)[1],
  se_on = se(m_dk_on)[1],
  beta_off = coef(m_dk_off)[1],
  se_off = se(m_dk_off)[1],
  N_on = nobs(m_dk_on),
  N_off = nobs(m_dk_off),
  model_on = m_dk_on,
  model_off = m_dk_off,
  model_es = m_dk_es
)

## ---------------------------------------------------------------
## REFORM 2: Czech Republic healthcare co-payments
## Treated: HF3 (household OOP). Control: HF1 (government).
## Unit: financing scheme × year. ON: 2008. OFF: 2015.
## ---------------------------------------------------------------
cat("\n=== REFORM 2: Czech healthcare co-payments ===\n")

cz <- fread(file.path(data_dir, "cz_clean.csv"))
cz[, icha11_hf := as.character(icha11_hf)]
cz <- cz[icha11_hf %in% c("HF1", "HF3")]

# Data only available from 2010 — no pre-policy period for 2008 reform
# Can only estimate the switch-OFF effect (co-payment removal in 2015)
# Use OOP share of total health expenditure as outcome
cz_wide <- dcast(cz[icha11_hf %in% c("HF3", "TOT_HF") & !is.na(values)],
                  year ~ icha11_hf, value.var = "values")
if (nrow(cz_wide) > 0 && "HF3" %in% names(cz_wide) && "TOT_HF" %in% names(cz_wide)) {
  cz_wide[, oop_share := HF3 / TOT_HF * 100]
  cz_wide[, post_repeal := fifelse(year >= 2015, 1L, 0L)]

  # Simple before/after: OOP share during co-payments vs after removal
  m_cz_off <- lm(oop_share ~ post_repeal, data = cz_wide)

  cat("  Czech data starts 2010 — no pre-policy period for β_ON\n")
  cat("  OOP share during co-payments:",
      round(mean(cz_wide[post_repeal == 0]$oop_share, na.rm = TRUE), 2), "%\n")
  cat("  OOP share after removal:",
      round(mean(cz_wide[post_repeal == 1]$oop_share, na.rm = TRUE), 2), "%\n")
  cat("  β_OFF (OOP share) =", round(coef(m_cz_off)["post_repeal"], 4),
      "SE =", round(summary(m_cz_off)$coefficients["post_repeal", "Std. Error"], 4), "\n")
  m_cz_on <- NULL
  m_cz_es <- NULL
} else {
  cat("  Czech data insufficient for any analysis\n")
  m_cz_on <- NULL
  m_cz_off <- NULL
  m_cz_es <- NULL
}

results$cz <- list(
  reform = "Czech healthcare co-payments",
  domain = "Health",
  duration_months = 84,
  beta_on = NA_real_,  # No pre-policy data
  se_on = NA_real_,
  beta_off = if (!is.null(m_cz_off)) coef(m_cz_off)["post_repeal"] else NA_real_,
  se_off = if (!is.null(m_cz_off)) summary(m_cz_off)$coefficients["post_repeal", "Std. Error"] else NA_real_,
  N_on = NA_integer_,
  N_off = if (!is.null(m_cz_off)) nobs(m_cz_off) else NA_integer_,
  model_on = NULL,
  model_off = m_cz_off,
  model_es = NULL,
  note = "No pre-policy data (SHA data starts 2010, co-payments introduced 2008)"
)

## ---------------------------------------------------------------
## REFORM 3: Italy RdC
## Treated: high-poverty NUTS2 regions. Control: low-poverty.
## Unit: NUTS2 × year. ON: 2019. OFF: 2024.
## ---------------------------------------------------------------
cat("\n=== REFORM 3: Italy Reddito di Cittadinanza ===\n")

it <- fread(file.path(data_dir, "it_clean.csv"))
it[, geo := as.character(geo)]

# Switch-ON
it_on <- it[period %in% c("pre", "policy_on")]
m_it_on <- feols(values ~ treated:policy_on | geo + year, data = it_on,
                  cluster = ~geo)

# Switch-OFF: pre vs post-repeal (measures residual effect relative to pre-policy)
it_off <- it[period %in% c("pre", "post_repeal")]
if (nrow(it_off[post_repeal == 1]) > 0) {
  m_it_off <- feols(values ~ treated:post_repeal | geo + year, data = it_off,
                     cluster = ~geo)
  cat("  β_ON =", round(coef(m_it_on)[1], 4), "SE =", round(se(m_it_on)[1], 4), "\n")
  cat("  β_OFF =", round(coef(m_it_off)[1], 4), "SE =", round(se(m_it_off)[1], 4), "\n")
} else {
  m_it_off <- NULL
  cat("  β_ON =", round(coef(m_it_on)[1], 4), "SE =", round(se(m_it_on)[1], 4), "\n")
  cat("  β_OFF: insufficient post-repeal data (RdC repealed 2023/2024)\n")
}

# Event study
it[, et_on_bin := fifelse(event_time_on < -3, -3L,
                   fifelse(event_time_on > 4, 4L, as.integer(event_time_on)))]
it[, et_on_bin := relevel(factor(et_on_bin), ref = "-1")]

m_it_es <- feols(values ~ i(et_on_bin, treated, ref = -1) | geo + year,
                  data = it, cluster = ~geo)

results$it <- list(
  reform = "Italy Reddito di Cittadinanza",
  domain = "Transfer/labor",
  duration_months = 57,  # April 2019 to January 2024 (operational reversal date)
  beta_on = coef(m_it_on)[1],
  se_on = se(m_it_on)[1],
  beta_off = if (!is.null(m_it_off)) coef(m_it_off)[1] else NA,
  se_off = if (!is.null(m_it_off)) se(m_it_off)[1] else NA,
  N_on = nobs(m_it_on),
  N_off = if (!is.null(m_it_off)) nobs(m_it_off) else NA,
  model_on = m_it_on,
  model_off = m_it_off,
  model_es = m_it_es
)

## ---------------------------------------------------------------
## REFORM 4: Poland retirement age
## Treated: Women 60-64. Control: Men 60-64, both sex 55-59.
## Unit: sex-age group × quarter. ON: 2013Q1. OFF: 2017Q4.
## ---------------------------------------------------------------
cat("\n=== REFORM 4: Poland retirement age reform ===\n")

pl <- fread(file.path(data_dir, "pl_clean.csv"))
pl[, date := as.Date(date)]
pl[, group := paste(sex, age, sep = "_")]

# Switch-ON
pl_on <- pl[period %in% c("pre", "policy_on")]
m_pl_on <- feols(values ~ treated:policy_on | group + date, data = pl_on,
                  cluster = ~group)

# Switch-OFF: pre vs post-repeal (measures residual effect relative to pre-policy)
pl_off <- pl[period %in% c("pre", "post_repeal")]
m_pl_off <- feols(values ~ treated:post_repeal | group + date, data = pl_off,
                   cluster = ~group)

cat("  β_ON =", round(coef(m_pl_on)[1], 4), "SE =", round(se(m_pl_on)[1], 4), "\n")
cat("  β_OFF =", round(coef(m_pl_off)[1], 4), "SE =", round(se(m_pl_off)[1], 4), "\n")

# Event study
pl[, et_on_bin := fifelse(event_time_on < -8, -8L,
                   fifelse(event_time_on > 12, 12L, as.integer(event_time_on)))]
pl[, et_on_bin := relevel(factor(et_on_bin), ref = "-1")]

m_pl_es <- feols(values ~ i(et_on_bin, treated, ref = -1) | group + date,
                  data = pl, cluster = ~group)

results$pl <- list(
  reform = "Poland retirement age",
  domain = "Labor",
  duration_months = 57,
  beta_on = coef(m_pl_on)[1],
  se_on = se(m_pl_on)[1],
  beta_off = coef(m_pl_off)[1],
  se_off = se(m_pl_off)[1],
  N_on = nobs(m_pl_on),
  N_off = nobs(m_pl_off),
  model_on = m_pl_on,
  model_off = m_pl_off,
  model_es = m_pl_es
)

## ---------------------------------------------------------------
## REFORM 5: France supertax
## Treated: FR. Control: DE, NL, BE, AT.
## Unit: country × quarter. ON: 2013Q1. OFF: 2015Q1.
## ---------------------------------------------------------------
cat("\n=== REFORM 5: France 75% supertax ===\n")

fr <- fread(file.path(data_dir, "fr_clean.csv"))
fr[, date := as.Date(date)]
fr[, geo := as.character(geo)]

# Need to pick a single NACE/lcstruct for clean comparison
# Use total economy and total labor costs — check what categories exist
cat("  Available nace_r2:", paste(head(unique(fr$nace_r2), 10), collapse = ", "), "\n")
cat("  Available lcstruct:", paste(head(unique(fr$lcstruct), 10), collapse = ", "), "\n")

# Use total economy (B-S), total labor costs (D1_D4_MD5), seasonally+calendar adjusted (SCA),
# index (I20) — exactly one obs per country-quarter
fr_total <- fr[nace_r2 == "B-S" & lcstruct == "D1_D4_MD5" & s_adj == "SCA" & unit == "I20"]
if (nrow(fr_total) < 20) {
  # Fallback: broader filter, then deduplicate
  fr_total <- fr[nace_r2 %in% c("B-S", "B-S_X_O") & lcstruct %in% c("D1_D4_MD5", "D1")]
  if (nrow(fr_total) > 0) fr_total <- fr_total[, .SD[1], by = .(geo, date)]
}
if (nrow(fr_total) < 20) {
  fr_total <- fr[, .SD[1], by = .(geo, date)]
}
cat("  France total-economy obs:", nrow(fr_total), "rows,",
    uniqueN(fr_total$geo), "countries,",
    uniqueN(fr_total$date), "quarters\n")
cat("    Per period — Pre:", nrow(fr_total[period == "pre"]),
    " On:", nrow(fr_total[period == "policy_on"]),
    " Off:", nrow(fr_total[period == "post_repeal"]), "\n")

# Switch-ON
fr_on <- fr_total[period %in% c("pre", "policy_on")]
m_fr_on <- feols(values ~ treated:policy_on | geo + date, data = fr_on,
                  cluster = ~geo)

# Switch-OFF: pre vs post-repeal (measures residual effect relative to pre-policy)
fr_off <- fr_total[period %in% c("pre", "post_repeal")]
m_fr_off <- feols(values ~ treated:post_repeal | geo + date, data = fr_off,
                   cluster = ~geo)

cat("  β_ON =", round(coef(m_fr_on)[1], 4), "SE =", round(se(m_fr_on)[1], 4), "\n")
cat("  β_OFF =", round(coef(m_fr_off)[1], 4), "SE =", round(se(m_fr_off)[1], 4), "\n")

# Event study
fr_total[, et_on_bin := fifelse(event_time_on < -8, -8L,
                          fifelse(event_time_on > 8, 8L, as.integer(event_time_on)))]
fr_total[, et_on_bin := relevel(factor(et_on_bin), ref = "-1")]

m_fr_es <- feols(values ~ i(et_on_bin, treated, ref = -1) | geo + date,
                  data = fr_total, cluster = ~geo)

results$fr <- list(
  reform = "France 75% supertax",
  domain = "Tax/labor",
  duration_months = 24,
  beta_on = coef(m_fr_on)[1],
  se_on = se(m_fr_on)[1],
  beta_off = coef(m_fr_off)[1],
  se_off = se(m_fr_off)[1],
  N_on = nobs(m_fr_on),
  N_off = nobs(m_fr_off),
  model_on = m_fr_on,
  model_off = m_fr_off,
  model_es = m_fr_es
)

## ---------------------------------------------------------------
## COMPUTE REVERSAL RATIOS
## ---------------------------------------------------------------
cat("\n=== REVERSAL RATIOS ===\n")

rr_table <- rbindlist(lapply(results, function(r) {
  # Suppress RR when β_ON is statistically indistinguishable from zero (|t| < 0.5)
  if (is.na(r$beta_off) || is.na(r$beta_on) || abs(r$beta_on) < 1e-10 ||
      (!is.na(r$se_on) && abs(r$beta_on / r$se_on) < 0.5)) {
    rr <- NA_real_
    rr_se <- NA_real_
  } else {
    rr <- r$beta_off / r$beta_on
    # Delta method SE: SE(RR) = |RR| * sqrt((SE_off/beta_off)^2 + (SE_on/beta_on)^2)
    rr_se <- abs(rr) * sqrt((r$se_off / r$beta_off)^2 + (r$se_on / r$beta_on)^2)
  }
  data.table(
    reform = r$reform,
    domain = r$domain,
    duration_months = r$duration_months,
    beta_on = r$beta_on,
    se_on = r$se_on,
    beta_off = r$beta_off,
    se_off = r$se_off,
    reversal_ratio = rr,
    rr_se = rr_se,
    N_on = r$N_on,
    N_off = r$N_off
  )
}))

# Classification: RR=0 → full reversal, RR=1 → complete hysteresis
rr_table[, hysteresis := fifelse(is.na(reversal_ratio), "Insufficient data",
                          fifelse(abs(reversal_ratio) < 0.15, "Full reversal",
                           fifelse(reversal_ratio >= 0.15 & reversal_ratio < 0.5, "Partial reversal",
                            fifelse(reversal_ratio >= 0.5 & reversal_ratio < 0.85, "Partial hysteresis",
                             fifelse(reversal_ratio >= 0.85 & reversal_ratio <= 1.15, "Complete hysteresis",
                              "Perverse dynamics")))))]

cat("\n")
print(rr_table[, .(reform, domain, duration_months, beta_on = round(beta_on, 3),
                    beta_off = round(beta_off, 3), RR = round(reversal_ratio, 3),
                    RR_SE = round(rr_se, 3), hysteresis)])

fwrite(rr_table, file.path(data_dir, "reversal_ratios.csv"))

## ---------------------------------------------------------------
## META-REGRESSION: RR as function of reform characteristics
## ---------------------------------------------------------------
cat("\n=== META-REGRESSION ===\n")

# Exclude Italy (near-zero β_ON produces uninformative RR)
rr_meta <- rr_table[!is.na(reversal_ratio) & reform != "Italy Reddito di Cittadinanza"]
if (nrow(rr_meta) >= 3) {
  # Simple cross-reform regression
  # RR = a + b * log(duration) + c * I(price_instrument)
  rr_meta[, log_duration := log(duration_months)]
  rr_meta[, price_instrument := fifelse(domain %in% c("Price/consumption", "Tax/labor"), 1L, 0L)]

  m_meta <- lm(reversal_ratio ~ log_duration + price_instrument, data = rr_meta)
  cat("\nMeta-regression results:\n")
  print(summary(m_meta))

  fwrite(data.table(
    term = names(coef(m_meta)),
    estimate = coef(m_meta),
    se = summary(m_meta)$coefficients[, 2],
    p_value = summary(m_meta)$coefficients[, 4]
  ), file.path(data_dir, "meta_regression.csv"))
}

## ---------------------------------------------------------------
## SAVE ALL MODELS
## ---------------------------------------------------------------
saveRDS(results, file.path(data_dir, "all_models.rds"))
cat("\nAll models saved.\n")
