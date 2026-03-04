## ============================================================
## 03_main_analysis.R — Primary DiD estimation
## apep_0505: Council Tax Support Localization
## ============================================================

source("00_packages.R")

## ============================================================
## 1. Load Cleaned Data
## ============================================================
cat("=== Loading Cleaned Data ===\n")

panel <- readRDS(file.path(DATA_DIR, "analysis_panel.rds"))
treatment <- readRDS(file.path(DATA_DIR, "treatment_2018.rds"))
ro_short <- readRDS(file.path(DATA_DIR, "ro_short_panel.rds"))

cat("Panel:", nrow(panel), "obs,", n_distinct(panel$la_code), "LAs,",
    paste(range(panel$year), collapse = "-"), "\n")

## ============================================================
## 2. Continuous-Treatment DiD (Primary Specification)
## ============================================================
cat("\n=== Primary Specification: Continuous-Treatment DiD ===\n")

## Treatment: cut_intensity = -z(CTS_wa_per_cap)
## Higher cut_intensity = less generous scheme = more austerity
## Outcome: JSA claimant rate (per 100 working-age)
## Controls: LA FE + Year FE

## Model 1: cut_intensity × post
m1_jsa <- feols(jsa_rate ~ cut_intensity:post | la_code + year,
                data = panel, cluster = "la_code")
cat("\nModel 1: JSA rate ~ cut_intensity × post\n")
print(summary(m1_jsa))

## Model 2: Same with log property prices
m2_price <- feols(mean_log_price ~ cut_intensity:post | la_code + year,
                  data = panel[!is.na(mean_log_price)], cluster = "la_code")
cat("\nModel 2: log(price) ~ cut_intensity × post\n")
print(summary(m2_price))

## Model 3: Median property price level
m3_level <- feols(log(median_price) ~ cut_intensity:post | la_code + year,
                  data = panel[!is.na(median_price) & median_price > 0],
                  cluster = "la_code")
cat("\nModel 3: log(median price) ~ cut_intensity × post\n")
print(summary(m3_level))

## Model 4: Transaction volume
m4_trans <- feols(log(n_transactions + 1) ~ cut_intensity:post | la_code + year,
                  data = panel[!is.na(n_transactions)], cluster = "la_code")
cat("\nModel 4: log(transactions) ~ cut_intensity × post\n")
print(summary(m4_trans))

## ============================================================
## 3. Event Study (Dynamic Treatment Effects)
## ============================================================
cat("\n=== Event Study ===\n")

## Create event-time × treatment interaction
panel[, event_time := year - 2013]
panel[, et := factor(event_time)]
panel[, et := relevel(et, ref = "-1")]

## Event study: JSA rate
es_jsa <- feols(jsa_rate ~ i(event_time, cut_intensity, ref = -1) |
                  la_code + year,
                data = panel, cluster = "la_code")
cat("\nEvent Study: JSA rate\n")
print(summary(es_jsa))

## Event study: property prices
es_price <- feols(mean_log_price ~ i(event_time, cut_intensity, ref = -1) |
                    la_code + year,
                  data = panel[!is.na(mean_log_price)], cluster = "la_code")
cat("\nEvent Study: log property price\n")
print(summary(es_price))

## ============================================================
## 4. Quartile-Based DiD (Interpretable Groups)
## ============================================================
cat("\n=== Quartile-Based DiD ===\n")

## Binary treatment: Q1 (least generous) vs Q4 (most generous)
panel[, high_cut := as.integer(treat_quartile == "Q1_least_generous")]

## Restrict to Q1 vs Q4 for cleaner contrast
q1q4 <- panel[treat_quartile %in% c("Q1_least_generous", "Q4_most_generous")]

m5_binary <- feols(jsa_rate ~ high_cut:post | la_code + year,
                   data = q1q4, cluster = "la_code")
cat("\nModel 5: Q1 vs Q4 binary DiD (JSA rate)\n")
print(summary(m5_binary))

m6_binary_price <- feols(mean_log_price ~ high_cut:post | la_code + year,
                         data = q1q4[!is.na(mean_log_price)],
                         cluster = "la_code")
cat("\nModel 6: Q1 vs Q4 binary DiD (log price)\n")
print(summary(m6_binary_price))

## Use quartile dummies for dose-response
panel[, q2 := as.integer(treat_quartile == "Q2")]
panel[, q3 := as.integer(treat_quartile == "Q3")]
panel[, q4 := as.integer(treat_quartile == "Q4_most_generous")]

m7_dose <- feols(jsa_rate ~ q2:post + q3:post + q4:post | la_code + year,
                 data = panel, cluster = "la_code")
cat("\nModel 7: Dose-response quartiles (JSA rate, Q1 = reference)\n")
print(summary(m7_dose))

## ============================================================
## 5. Pensioner Placebo (Internal Validity)
## ============================================================
cat("\n=== Pensioner Placebo ===\n")

## The pensioner CTS expenditure should NOT predict outcomes
## because pensioners were protected from CTS cuts.
## If cut_pen_intensity predicts outcomes, our identification is suspect.

if ("cts_pen_per_cap" %in% names(panel) && any(!is.na(panel$cts_pen_per_cap))) {
  ## Construct pensioner "treatment" intensity
  panel[, pen_intensity := -scale(cts_pen_per_cap)[, 1]]

  m8_placebo_jsa <- feols(jsa_rate ~ pen_intensity:post | la_code + year,
                          data = panel[!is.na(pen_intensity)],
                          cluster = "la_code")
  cat("\nModel 8: Pensioner placebo (JSA rate ~ pen_intensity × post)\n")
  print(summary(m8_placebo_jsa))

  m9_placebo_price <- feols(mean_log_price ~ pen_intensity:post | la_code + year,
                            data = panel[!is.na(pen_intensity) & !is.na(mean_log_price)],
                            cluster = "la_code")
  cat("\nModel 9: Pensioner placebo (log price ~ pen_intensity × post)\n")
  print(summary(m9_placebo_price))
}

## ============================================================
## 6. Revenue Outturn Short Panel Analysis
## ============================================================
cat("\n=== RO Short Panel Analysis ===\n")

## Use the 2017-2024 panel for direct CTS-outcome relationship
if (nrow(ro_short) > 100) {
  ro_short[, la_code := ONS_code]

  ## Compute CTS generosity ratio: WA CTS / Total expenditure
  ro_short[, cts_share := RS_lctswa_net_exp / RS_totsx_net_exp]

  ## Merge JSA data for the short panel years
  jsa_all <- readRDS(file.path(DATA_DIR, "jsa_panel.rds"))
  ro_merged <- merge(ro_short, jsa_all[, .(la_code, year, jsa_count, wa_pop, jsa_rate)],
                     by.x = c("la_code", "fiscal_year"),
                     by.y = c("la_code", "year"),
                     all.x = TRUE)

  if (any(!is.na(ro_merged$jsa_rate))) {
    m10_cts_direct <- feols(jsa_rate ~ cts_wa_per_cap | la_code + fiscal_year,
                            data = ro_merged[!is.na(jsa_rate) & !is.na(cts_wa_per_cap)],
                            cluster = "la_code")
    cat("\nModel 10: Direct CTS-JSA relationship (short panel)\n")
    print(summary(m10_cts_direct))
  }
}

## ============================================================
## 7. Pre-Treatment Balance Check
## ============================================================
cat("\n=== Pre-Treatment Balance ===\n")

pre_panel <- panel[year < 2013]
pre_means <- pre_panel[, .(
  mean_jsa = mean(jsa_rate, na.rm = TRUE),
  mean_price = mean(median_price, na.rm = TRUE),
  mean_log_price = mean(mean_log_price, na.rm = TRUE),
  mean_trans = mean(n_transactions, na.rm = TRUE)
), by = treat_quartile]
cat("\nPre-reform means by treatment quartile:\n")
print(pre_means[order(treat_quartile)])

## Pre-trend test: regress outcome on treatment × linear trend (pre-period only)
pre_panel[, trend := year - 2008]
pretrend_jsa <- feols(jsa_rate ~ cut_intensity:trend | la_code + year,
                      data = pre_panel, cluster = "la_code")
cat("\nPre-trend test (JSA rate ~ cut_intensity × trend, pre-reform only):\n")
print(summary(pretrend_jsa))

pretrend_price <- feols(mean_log_price ~ cut_intensity:trend | la_code + year,
                        data = pre_panel[!is.na(mean_log_price)],
                        cluster = "la_code")
cat("\nPre-trend test (log price ~ cut_intensity × trend, pre-reform only):\n")
print(summary(pretrend_price))

## ============================================================
## 8. Save All Results
## ============================================================
cat("\n=== Saving Results ===\n")

results <- list(
  ## Primary specifications
  m1_jsa = m1_jsa,
  m2_price = m2_price,
  m3_level = m3_level,
  m4_trans = m4_trans,
  ## Event studies
  es_jsa = es_jsa,
  es_price = es_price,
  ## Quartile DiD
  m5_binary = m5_binary,
  m6_binary_price = m6_binary_price,
  m7_dose = m7_dose,
  ## Pre-trend tests
  pretrend_jsa = pretrend_jsa,
  pretrend_price = pretrend_price
)

## Add placebo models if they exist
if (exists("m8_placebo_jsa")) results$m8_placebo_jsa <- m8_placebo_jsa
if (exists("m9_placebo_price")) results$m9_placebo_price <- m9_placebo_price
if (exists("m10_cts_direct")) results$m10_cts_direct <- m10_cts_direct

saveRDS(results, file.path(DATA_DIR, "main_results.rds"))
saveRDS(panel, file.path(DATA_DIR, "analysis_panel_final.rds"))

cat("All results saved.\n")
cat("\n=== Main Analysis Complete ===\n")
