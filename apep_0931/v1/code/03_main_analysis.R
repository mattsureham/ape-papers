## 03_main_analysis.R — apep_0931: IAP and Economic Development
## Main DiD analysis

source("code/00_packages.R")

# ── Load data ───────────────────────────────────────────────────────
df <- fread("data/analysis_panel.csv")
census <- fread("data/census_long_panel.csv")

cat(sprintf("Analysis panel: %d obs, %d districts, %d years\n",
            nrow(df), uniqueN(df$pc11_district_id), uniqueN(df$year)))
cat(sprintf("IAP districts: %d, Control: %d\n",
            uniqueN(df[iap == 1]$pc11_district_id),
            uniqueN(df[iap == 0]$pc11_district_id)))

# ── Table 1: Summary Statistics ─────────────────────────────────────
# Pre-treatment means by IAP status
pre <- df[year <= 2010]

summ <- rbind(
  pre[, .(
    Variable = "Nightlights (calibrated)",
    IAP_Mean = mean(dmsp_total_light_cal, na.rm = TRUE),
    IAP_SD = sd(dmsp_total_light_cal, na.rm = TRUE),
    Control_Mean = NA_real_, Control_SD = NA_real_
  )],
  fill = TRUE
)

# Better: compute by group
summ_iap <- pre[iap == 1, .(
  light_mean = mean(dmsp_total_light_cal, na.rm = TRUE),
  light_sd = sd(dmsp_total_light_cal, na.rm = TRUE),
  ln_light_mean = mean(ln_light, na.rm = TRUE),
  ln_light_sd = sd(ln_light, na.rm = TRUE),
  pop_mean = mean(pop_2001, na.rm = TRUE),
  lit_mean = mean(lit_rate_2001, na.rm = TRUE),
  st_mean = mean(st_share_2001, na.rm = TRUE),
  N_districts = uniqueN(pc11_district_id)
)]

summ_ctrl <- pre[iap == 0, .(
  light_mean = mean(dmsp_total_light_cal, na.rm = TRUE),
  light_sd = sd(dmsp_total_light_cal, na.rm = TRUE),
  ln_light_mean = mean(ln_light, na.rm = TRUE),
  ln_light_sd = sd(ln_light, na.rm = TRUE),
  pop_mean = mean(pop_2001, na.rm = TRUE),
  lit_mean = mean(lit_rate_2001, na.rm = TRUE),
  st_mean = mean(st_share_2001, na.rm = TRUE),
  N_districts = uniqueN(pc11_district_id)
)]

cat("\n=== Pre-Treatment Summary (1994-2010) ===\n")
cat("IAP districts:\n")
print(summ_iap)
cat("\nControl districts:\n")
print(summ_ctrl)

# ── Main Specification: DiD with district and year FE ───────────────
cat("\n=== Main Results: DiD ===\n")

# (1) Basic DiD
m1 <- feols(ln_light ~ treat_post | pc11_district_id + year,
            data = df, cluster = ~pc11_district_id)
cat("Model 1: Basic DiD (all districts)\n")
print(summary(m1))

# (2) Within IAP-states only
m2 <- feols(ln_light ~ treat_post | pc11_district_id + year,
            data = df[in_iap_state == 1], cluster = ~pc11_district_id)
cat("\nModel 2: Within IAP-states only\n")
print(summary(m2))

# (3) State-by-year FE (absorbs state-specific trends)
m3 <- feols(ln_light ~ treat_post | pc11_district_id + pc11_state_id^year,
            data = df, cluster = ~pc11_district_id)
cat("\nModel 3: State x Year FE\n")
print(summary(m3))

# (4) Levels specification
m4 <- feols(dmsp_total_light_cal ~ treat_post | pc11_district_id + year,
            data = df, cluster = ~pc11_district_id)
cat("\nModel 4: Levels (total light)\n")
print(summary(m4))

# ── Event Study ─────────────────────────────────────────────────────
cat("\n=== Event Study ===\n")

# Event study with year-2009 as reference (-1)
df[, event_fac := factor(event_time)]
df[, event_fac := relevel(event_fac, ref = "-1")]

es <- feols(ln_light ~ i(event_time, iap, ref = -1) | pc11_district_id + year,
            data = df, cluster = ~pc11_district_id)
cat("Event study coefficients:\n")
print(summary(es))

# Save event study coefficients for table
es_coefs <- as.data.table(coeftable(es), keep.rownames = TRUE)
es_coefs[, event_time := as.integer(gsub("event_time::-?\\d+:iap", "",
                                          gsub("event_time::", "", rn)))]
fwrite(es_coefs, "data/event_study_coefs.csv")

# ── Heterogeneity: by tribal share ──────────────────────────────────
cat("\n=== Heterogeneity ===\n")

# Use Census 2011 for heterogeneity (same IDs as SHRUG)
pca11 <- fread("data/pca11_district.csv")
st_share <- pca11[, .(pc11_district_id,
                       st_share = fifelse(pc11_pca_tot_p > 0,
                                          pc11_pca_p_st / pc11_pca_tot_p, NA_real_))]
df <- merge(df, st_share, by = "pc11_district_id", all.x = TRUE)

iap_st <- unique(df[iap == 1 & !is.na(st_share), .(pc11_district_id, st_share)])
med_st <- median(iap_st$st_share, na.rm = TRUE)
cat(sprintf("Median ST share among IAP districts: %.3f\n", med_st))

df[, high_st := as.integer(st_share >= med_st)]

# High-ST IAP districts vs all controls in IAP states
high_st_ids <- iap_st[st_share >= med_st]$pc11_district_id
low_st_ids <- iap_st[st_share < med_st]$pc11_district_id

m_high_st <- feols(ln_light ~ treat_post | pc11_district_id + year,
                   data = df[pc11_district_id %in% high_st_ids | iap == 0],
                   cluster = ~pc11_district_id)
cat("High-ST IAP districts:\n")
cat(sprintf("  beta = %.4f (SE = %.4f, p = %.4f)\n",
            coef(m_high_st)["treat_post"], se(m_high_st)["treat_post"],
            pvalue(m_high_st)["treat_post"]))

m_low_st <- feols(ln_light ~ treat_post | pc11_district_id + year,
                  data = df[pc11_district_id %in% low_st_ids | iap == 0],
                  cluster = ~pc11_district_id)
cat("Low-ST IAP districts:\n")
cat(sprintf("  beta = %.4f (SE = %.4f, p = %.4f)\n",
            coef(m_low_st)["treat_post"], se(m_low_st)["treat_post"],
            pvalue(m_low_st)["treat_post"]))

# ── Save key results for diagnostics.json ───────────────────────────
diagnostics <- list(
  n_treated = uniqueN(df[iap == 1]$pc11_district_id),
  n_pre = length(unique(df[year < 2011]$year)),
  n_obs = nrow(df),
  n_districts = uniqueN(df$pc11_district_id),
  main_coef = coef(m1)["treat_post"],
  main_se = se(m1)["treat_post"],
  main_pval = pvalue(m1)["treat_post"]
)
write_json(diagnostics, "data/diagnostics.json", auto_unbox = TRUE)

# ── Save model objects ──────────────────────────────────────────────
saveRDS(list(m1 = m1, m2 = m2, m3 = m3, m4 = m4, es = es,
             m_high_st = m_high_st, m_low_st = m_low_st,
             summ_iap = summ_iap, summ_ctrl = summ_ctrl),
        "data/main_results.rds")

cat("\nMain analysis complete. Results saved.\n")
