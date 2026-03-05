## ============================================================
## 04_robustness.R — Robustness checks and sensitivity analysis
## apep_0516: PTZ Geographic Withdrawal and Housing Markets
## ============================================================

source("00_packages.R")

DATA_DIR <- "../data"

panel <- fread(file.path(DATA_DIR, "panel_main.csv"))
models_main <- readRDS(file.path(DATA_DIR, "models_main.rds"))

main <- panel[zone_group %in% c("B1", "B2/C") & !is.na(log_price_m2)]

# ============================================================
# 1. COVID EXCLUSION (drop 2020-2021)
# ============================================================

did_nocovid <- feols(log_price_m2 ~ did |
                       code_commune + year,
                     data = main[!(year %in% c(2020, 2021))],
                     cluster = ~code_departement)

cat("=== COVID EXCLUSION: Drop 2020-2021 ===\n")
summary(did_nocovid)

es_nocovid <- feols(log_price_m2 ~ i(event_time, treated, ref = -1) |
                      code_commune + year,
                    data = main[!(year %in% c(2020, 2021))],
                    cluster = ~code_departement)

es_nocovid_coefs <- as.data.table(coeftable(es_nocovid), keep.rownames = "term")
fwrite(es_nocovid_coefs, file.path(DATA_DIR, "event_study_nocovid_coefs.csv"))

# ============================================================
# 2. PRE-COVID ONLY (2014-2019)
# ============================================================

did_precovid <- feols(log_price_m2 ~ did |
                        code_commune + year,
                      data = main[year <= 2019],
                      cluster = ~code_departement)

cat("\n=== PRE-COVID ONLY (2014-2019) ===\n")
summary(did_precovid)

# ============================================================
# 3. ALTERNATIVE CONTROLS: B2/C vs A/Abis
# ============================================================

panel_alt <- panel[zone_group %in% c("A/Abis", "B2/C") & !is.na(log_price_m2)]

did_alt <- feols(log_price_m2 ~ did |
                   code_commune + year,
                 data = panel_alt,
                 cluster = ~code_departement)

cat("\n=== ALTERNATIVE CONTROL: B2/C vs A/Abis ===\n")
summary(did_alt)

# ============================================================
# 4. CONTINUOUS TREATMENT INTENSITY (pre-VEFA share)
# ============================================================

pre_vefa <- main[year < 2018,
  .(pre_vefa_share = sum(n_vefa, na.rm = TRUE) / sum(n_transactions, na.rm = TRUE)),
  by = code_commune
]

panel_int <- merge(main, pre_vefa, by = "code_commune", all.x = TRUE)
panel_int[is.na(pre_vefa_share), pre_vefa_share := 0]
panel_int[, intensity_did := pre_vefa_share * post]

did_intensity <- feols(log_price_m2 ~ intensity_did |
                         code_commune + year,
                       data = panel_int,
                       cluster = ~code_departement)

cat("\n=== CONTINUOUS TREATMENT INTENSITY ===\n")
summary(did_intensity)

# ============================================================
# 5. TRIMMED SAMPLE (drop extreme prices)
# ============================================================

p01 <- quantile(main$price_m2, 0.01, na.rm = TRUE)
p99 <- quantile(main$price_m2, 0.99, na.rm = TRUE)

did_trimmed <- feols(log_price_m2 ~ did |
                       code_commune + year,
                     data = main[price_m2 >= p01 & price_m2 <= p99],
                     cluster = ~code_departement)

cat("\n=== TRIMMED SAMPLE (1-99 percentile) ===\n")
summary(did_trimmed)

# ============================================================
# 6. HONESTDID SENSITIVITY
# ============================================================

tryCatch({
  es <- models_main$es_main
  beta <- coef(es)
  V <- vcov(es)

  # Determine pre/post periods from coefficient names
  n_coefs <- length(beta)
  # Event study has pre-periods (negative) and post-periods (positive)
  event_times <- as.integer(gsub(".*::([-0-9]+).*", "\\1", names(beta)))
  n_pre <- sum(event_times < 0)
  n_post <- sum(event_times > 0)

  if (n_pre >= 2 && n_post >= 2) {
    honest_result <- HonestDiD::createSensitivityResults(
      betahat = beta,
      sigma = V,
      numPrePeriods = n_pre,
      numPostPeriods = n_post,
      Mbarvec = seq(0.01, 0.05, by = 0.01),
      l_vec = basisVector(1, n_post)
    )

    honest_df <- as.data.table(honest_result)
    fwrite(honest_df, file.path(DATA_DIR, "honestdid_results.csv"))
    cat("\n=== HONESTDID SENSITIVITY ===\n")
    print(honest_df)
  } else {
    cat("\nHonestDiD: insufficient pre/post periods\n")
  }
}, error = function(e) {
  cat(sprintf("\nWARNING: HonestDiD failed: %s\n", e$message))
})

# ============================================================
# 7. PLACEBO: Existing housing only (partial placebo)
# ============================================================

main[, log_sale_price := log(price_m2_sale_apt)]

es_placebo <- feols(log_sale_price ~ i(event_time, treated, ref = -1) |
                      code_commune + year,
                    data = main[!is.na(log_sale_price)],
                    cluster = ~code_departement)

es_placebo_coefs <- as.data.table(coeftable(es_placebo), keep.rownames = "term")
fwrite(es_placebo_coefs, file.path(DATA_DIR, "event_study_placebo_coefs.csv"))

# ============================================================
# 8. BACON DECOMPOSITION CHECK
# ============================================================

bacon_check <- main[,
  .(mean_log_price = mean(log_price_m2, na.rm = TRUE),
    n_obs = .N),
  by = .(treated, post, zone_group)
]
fwrite(bacon_check, file.path(DATA_DIR, "bacon_check.csv"))
cat("\n=== BACON CHECK ===\n")
print(bacon_check)

# ============================================================
# 9. Save robustness models
# ============================================================

rob_models <- list(
  did_nocovid = did_nocovid,
  es_nocovid = es_nocovid,
  did_precovid = did_precovid,
  did_alt = did_alt,
  did_intensity = did_intensity,
  did_trimmed = did_trimmed,
  es_placebo = es_placebo
)

saveRDS(rob_models, file.path(DATA_DIR, "models_robustness.rds"))

cat("\n=== All robustness models saved ===\n")
