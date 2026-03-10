## ==============================================================
## 04_robustness.R — Robustness checks for reversal ratio estimates
## APEP-0579: Policy Reversals Meta-Natural Experiment
## ==============================================================

source("00_packages.R")
data_dir <- "../data"

results <- readRDS(file.path(data_dir, "all_models.rds"))
rob_results <- list()

## ---------------------------------------------------------------
## A) PLACEBO OUTCOMES — each reform's built-in control
## ---------------------------------------------------------------
cat("=== A) PLACEBO OUTCOMES ===\n")

# Denmark: Non-food HICP should not respond to fat tax
dk <- fread(file.path(data_dir, "dk_clean.csv"))
dk[, date := as.Date(date)]
dk_nonfood <- dk[treated == 0]
# "Placebo" treated: clothing (CP03) vs others
dk_nonfood[, placebo_treated := fifelse(coicop == "CP03", 1L, 0L)]
dk_nonfood_on <- dk_nonfood[period %in% c("pre", "policy_on")]
if (uniqueN(dk_nonfood_on$placebo_treated) > 1) {
  m_dk_placebo <- feols(values ~ placebo_treated:policy_on | coicop + date,
                         data = dk_nonfood_on, cluster = ~coicop)
  rob_results$dk_placebo <- list(
    test = "Denmark: non-food placebo (CP03 vs other non-food)",
    beta = coef(m_dk_placebo)[1],
    se = se(m_dk_placebo)[1],
    N = nobs(m_dk_placebo)
  )
  cat("  Denmark placebo: β =", round(coef(m_dk_placebo)[1], 4), "\n")
}

# Poland: Men 60-64 as alternative comparison — their retirement age also changed
# (from 65→67), so we expect some effect but potentially different magnitude.
# Also test: women 55-59 vs men 55-59 (neither at retirement threshold).
pl <- fread(file.path(data_dir, "pl_clean.csv"))
pl[, date := as.Date(date)]
pl[, group := paste(sex, age, sep = "_")]

# Placebo 1: Men 60-64 vs Men 55-59 (men's retirement age changed 65→67)
pl_men <- pl[sex == "M"]
pl_men[, placebo_treated := fifelse(age == "Y60-64", 1L, 0L)]
pl_men_on <- pl_men[period %in% c("pre", "policy_on")]
if (nrow(pl_men_on) > 10) {
  m_pl_men <- feols(values ~ placebo_treated:policy_on | group + date,
                     data = pl_men_on, vcov = "hetero")
  rob_results$pl_men_placebo <- list(
    test = "Poland: men 60-64 vs men 55-59 (men's ret. age also changed)",
    beta = coef(m_pl_men)[1],
    se = se(m_pl_men)[1],
    N = nobs(m_pl_men)
  )
  cat("  Poland men placebo: β =", round(coef(m_pl_men)[1], 4),
      " SE =", round(se(m_pl_men)[1], 4), "\n")
}

# Placebo 2: Women 55-59 vs Men 55-59 (neither at retirement threshold)
# Use HC1 robust SEs instead of cluster (only 2 clusters → degenerate VCOV)
pl_placebo <- pl[age == "Y55-59"]
pl_placebo[, placebo_treated := fifelse(sex == "F", 1L, 0L)]
pl_placebo_on <- pl_placebo[period %in% c("pre", "policy_on")]
if (nrow(pl_placebo_on) > 10) {
  m_pl_placebo <- feols(values ~ placebo_treated:policy_on | group + date,
                         data = pl_placebo_on, vcov = "hetero")
  rob_results$pl_placebo <- list(
    test = "Poland: women vs men age 55-59 (neither at retirement threshold)",
    beta = coef(m_pl_placebo)[1],
    se = se(m_pl_placebo)[1],
    N = nobs(m_pl_placebo)
  )
  cat("  Poland 55-59 placebo: β =", round(coef(m_pl_placebo)[1], 4),
      " SE =", round(se(m_pl_placebo)[1], 4), "\n")
}

## ---------------------------------------------------------------
## B) ALTERNATIVE COMPARISON GROUPS
## ---------------------------------------------------------------
cat("\n=== B) ALTERNATIVE COMPARISON GROUPS ===\n")

# France: Use only DE as control instead of DE+NL+BE+AT
fr <- fread(file.path(data_dir, "fr_clean.csv"))
fr[, date := as.Date(date)]
fr_de <- fr[geo %in% c("FR", "DE")]
fr_de_total <- fr_de[nace_r2 == "B-S" & lcstruct == "D1_D4_MD5" & s_adj == "SCA" & unit == "I20"]
if (nrow(fr_de_total) == 0) {
  fr_de_total <- fr_de[nace_r2 %in% c("B-S", "B-S_X_O")]
  if (nrow(fr_de_total) > 0) fr_de_total <- fr_de_total[, .SD[1], by = .(geo, date)]
}

fr_de_on <- fr_de_total[period %in% c("pre", "policy_on")]
fr_de_off <- fr_de_total[period %in% c("pre", "post_repeal")]

if (nrow(fr_de_on) > 5) {
  # Use heteroskedasticity-robust SEs (only 2 geo clusters — clustering is degenerate)
  m_fr_de_on <- feols(values ~ treated:policy_on | geo + date, data = fr_de_on,
                       vcov = "hetero")
  m_fr_de_off <- feols(values ~ treated:post_repeal | geo + date, data = fr_de_off,
                        vcov = "hetero")
  rob_results$fr_de_only <- list(
    test = "France: DE-only control",
    beta_on = coef(m_fr_de_on)[1],
    se_on = se(m_fr_de_on)[1],
    beta_off = coef(m_fr_de_off)[1],
    se_off = se(m_fr_de_off)[1]
  )
  cat("  France (DE control): β_ON =", round(coef(m_fr_de_on)[1], 4),
      " SE =", round(se(m_fr_de_on)[1], 4),
      " β_OFF =", round(coef(m_fr_de_off)[1], 4),
      " SE =", round(se(m_fr_de_off)[1], 4), "\n")
}

## ---------------------------------------------------------------
## C) BANDWIDTH SENSITIVITY
## ---------------------------------------------------------------
cat("\n=== C) BANDWIDTH SENSITIVITY ===\n")

# Denmark: vary pre/post window symmetrically
dk_bw_results <- list()
for (bw in c(6, 12, 18, 24)) {
  dk_bw <- dk[event_time_on >= -bw & event_time_on <= bw]
  dk_bw_on <- dk_bw[period %in% c("pre", "policy_on")]
  if (nrow(dk_bw_on) > 20 && uniqueN(dk_bw_on$policy_on) > 1) {
    m_bw <- feols(values ~ treated:policy_on | coicop + date, data = dk_bw_on,
                   cluster = ~coicop)
    dk_bw_results[[as.character(bw)]] <- data.table(
      bandwidth = bw,
      beta_on = coef(m_bw)[1],
      se_on = se(m_bw)[1],
      N = nobs(m_bw)
    )
  }
}

if (length(dk_bw_results) > 0) {
  dk_bw_dt <- rbindlist(dk_bw_results)
  fwrite(dk_bw_dt, file.path(data_dir, "dk_bandwidth_sensitivity.csv"))
  cat("  Denmark bandwidth results:\n")
  print(dk_bw_dt)
}

## ---------------------------------------------------------------
## D) LEAVE-ONE-OUT META-REGRESSION
## ---------------------------------------------------------------
cat("\n=== D) LEAVE-ONE-OUT META-REGRESSION ===\n")

rr_table <- fread(file.path(data_dir, "reversal_ratios.csv"))
# Exclude Italy (near-zero β_ON produces uninformative RR)
rr_meta <- rr_table[!is.na(reversal_ratio) & reform != "Italy Reddito di Cittadinanza"]

if (nrow(rr_meta) >= 3) {
  rr_meta[, log_duration := log(duration_months)]
  rr_meta[, price_instrument := fifelse(domain %in% c("Price/consumption", "Tax/labor"), 1L, 0L)]

  loo_results <- list()
  for (i in seq_len(nrow(rr_meta))) {
    rr_loo <- rr_meta[-i]
    if (nrow(rr_loo) >= 3) {
      m_loo <- lm(reversal_ratio ~ log_duration + price_instrument, data = rr_loo)
      loo_results[[i]] <- data.table(
        dropped = rr_meta$reform[i],
        intercept = coef(m_loo)[1],
        b_duration = coef(m_loo)[2],
        b_price = coef(m_loo)[3]
      )
    } else {
      m_loo <- lm(reversal_ratio ~ log_duration, data = rr_loo)
      loo_results[[i]] <- data.table(
        dropped = rr_meta$reform[i],
        intercept = coef(m_loo)[1],
        b_duration = coef(m_loo)[2],
        b_price = NA_real_
      )
    }
  }
  loo_dt <- rbindlist(loo_results)
  fwrite(loo_dt, file.path(data_dir, "leave_one_out.csv"))
  cat("  Leave-one-out meta-regression:\n")
  print(loo_dt)
}

## ---------------------------------------------------------------
## E) PRE-TREND TESTS
## ---------------------------------------------------------------
cat("\n=== E) PRE-TREND TESTS ===\n")

# Denmark pre-trend F-test
dk_pre <- dk[period == "pre"]
dk_pre[, time_trend := as.numeric(date - min(date))]
if (nrow(dk_pre) > 20) {
  m_dk_pre <- feols(values ~ treated:time_trend | coicop + date, data = dk_pre,
                     cluster = ~coicop)
  pval_dk <- coeftable(m_dk_pre)[1, "Pr(>|t|)"]
  cat("  Denmark pre-trend: coef =", round(coef(m_dk_pre)[1], 6),
      " p =", round(pval_dk, 4), "\n")
  rob_results$dk_pretrend <- list(
    test = "Denmark pre-trend F-test",
    coef = coef(m_dk_pre)[1],
    pvalue = pval_dk
  )
}

# Poland pre-trend F-test
pl_pre <- pl[period == "pre"]
pl_pre[, time_trend := as.numeric(date - min(date))]
if (nrow(pl_pre) > 10) {
  m_pl_pre <- feols(values ~ treated:time_trend | group + date, data = pl_pre,
                     cluster = ~group)
  pval_pl <- coeftable(m_pl_pre)[1, "Pr(>|t|)"]
  cat("  Poland pre-trend: coef =", round(coef(m_pl_pre)[1], 6),
      " p =", round(pval_pl, 4), "\n")
  rob_results$pl_pretrend <- list(
    test = "Poland pre-trend F-test",
    coef = coef(m_pl_pre)[1],
    pvalue = pval_pl
  )
}

# France pre-trend F-test (total economy, one obs per country-quarter)
fr_total <- fread(file.path(data_dir, "fr_clean.csv"))
fr_total[, date := as.Date(date)]
fr_total <- fr_total[nace_r2 == "B-S" & lcstruct == "D1_D4_MD5" & s_adj == "SCA" & unit == "I20"]
if (nrow(fr_total) == 0) {
  fr_total <- fread(file.path(data_dir, "fr_clean.csv"))
  fr_total[, date := as.Date(date)]
  fr_total <- fr_total[nace_r2 %in% c("B-S", "B-S_X_O")]
  if (nrow(fr_total) > 0) fr_total <- fr_total[, .SD[1], by = .(geo, date)]
}
fr_pre <- fr_total[period == "pre"]
fr_pre[, time_trend := as.numeric(date - min(date))]
if (nrow(fr_pre) > 10) {
  m_fr_pre <- feols(values ~ treated:time_trend | geo + date, data = fr_pre,
                     cluster = ~geo)
  pval_fr <- coeftable(m_fr_pre)[1, "Pr(>|t|)"]
  cat("  France pre-trend: coef =", round(coef(m_fr_pre)[1], 6),
      " p =", round(pval_fr, 4), "\n")
  rob_results$fr_pretrend <- list(
    test = "France pre-trend F-test",
    coef = coef(m_fr_pre)[1],
    pvalue = pval_fr
  )
}

## ---------------------------------------------------------------
## SAVE ROBUSTNESS RESULTS
## ---------------------------------------------------------------
saveRDS(rob_results, file.path(data_dir, "robustness_results.rds"))

# Summary table
rob_summary <- rbindlist(lapply(names(rob_results), function(nm) {
  r <- rob_results[[nm]]
  data.table(
    test = r$test,
    beta = if (!is.null(r$beta)) round(r$beta, 4) else NA_real_,
    se = if (!is.null(r$se)) round(r$se, 4) else NA_real_,
    beta_on = if (!is.null(r$beta_on)) round(r$beta_on, 4) else NA_real_,
    beta_off = if (!is.null(r$beta_off)) round(r$beta_off, 4) else NA_real_,
    pvalue = if (!is.null(r$pvalue)) round(r$pvalue, 4) else NA_real_
  )
}), fill = TRUE)

fwrite(rob_summary, file.path(data_dir, "robustness_summary.csv"))
cat("\nAll robustness checks completed.\n")
print(rob_summary)
