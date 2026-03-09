# =============================================================================
# 04_robustness.R — Robustness checks and sensitivity
# APEP Paper apep_0552: Stranded by the Label?
# =============================================================================

source("00_packages.R")

cat("=== Loading analysis panel ===\n")
df <- arrow::read_parquet(file.path(data_dir, "analysis_panel.parquet"))
setDT(df)

models <- readRDS(file.path(data_dir, "main_models.rds"))

# =============================================================================
# 1. Bandwidth Sensitivity (RDD)
# =============================================================================

cat("\n=== RDD Bandwidth Sensitivity ===\n")

if ("kwh_m2_year" %in% names(df)) {
  df_rdd <- df[post_reform == 1 & !is.na(kwh_m2_year)]

  bandwidths <- c(25, 35, 50, 75, 100, 150)
  bw_results <- list()

  for (bw in bandwidths) {
    df_bw <- df_rdd[abs(kwh_m2_year - 420) <= bw]
    df_bw[, above := as.integer(kwh_m2_year >= 420)]
    df_bw[, kwh_c := kwh_m2_year - 420]

    m <- feols(log_price ~ above + kwh_c + above:kwh_c +
                 surface_reelle_bati + nombre_pieces_principales + is_apartment |
                 code_commune + yq,
               data = df_bw,
               cluster = ~code_commune)

    bw_results[[as.character(bw)]] <- data.table(
      Bandwidth = bw,
      Estimate = coef(m)["above"],
      SE = se(m)["above"],
      N = nobs(m)
    )
    cat("  BW =", bw, "kWh: coef =", round(coef(m)["above"], 4),
        ", SE =", round(se(m)["above"], 4), ", N =", nobs(m), "\n")
  }

  bw_sensitivity <- rbindlist(bw_results)
  bw_sensitivity[, ci_lower := Estimate - 1.96 * SE]
  bw_sensitivity[, ci_upper := Estimate + 1.96 * SE]
  fwrite(bw_sensitivity, file.path(data_dir, "rdd_bw_sensitivity.csv"))
}

# =============================================================================
# 2. Donut RDD (exclude observations near threshold)
# =============================================================================

cat("\n=== Donut RDD ===\n")

if ("kwh_m2_year" %in% names(df)) {
  donut_sizes <- c(5, 10, 15, 20)
  donut_results <- list()

  for (donut in donut_sizes) {
    df_donut <- df_rdd[abs(kwh_m2_year - 420) > donut & abs(kwh_m2_year - 420) <= 100]
    df_donut[, above := as.integer(kwh_m2_year >= 420)]
    df_donut[, kwh_c := kwh_m2_year - 420]

    m <- feols(log_price ~ above + kwh_c + above:kwh_c +
                 surface_reelle_bati + nombre_pieces_principales + is_apartment |
                 code_commune + yq,
               data = df_donut,
               cluster = ~code_commune)

    donut_results[[as.character(donut)]] <- data.table(
      Donut = donut,
      Estimate = coef(m)["above"],
      SE = se(m)["above"],
      N = nobs(m)
    )
  }

  donut_sensitivity <- rbindlist(donut_results)
  fwrite(donut_sensitivity, file.path(data_dir, "rdd_donut_sensitivity.csv"))
  cat("Donut RDD results:\n")
  print(donut_sensitivity)
}

# =============================================================================
# 3. Polynomial Order Sensitivity (RDD)
# =============================================================================

cat("\n=== Polynomial Sensitivity ===\n")

if ("kwh_m2_year" %in% names(df)) {
  poly_results <- list()

  for (p in 1:3) {
    rdd_p <- rdrobust(
      y = df_rdd$log_price,
      x = df_rdd$kwh_m2_year,
      c = 420,
      kernel = "triangular",
      p = p,
      cluster = as.numeric(as.factor(df_rdd$code_commune))
    )

    poly_results[[as.character(p)]] <- data.table(
      Polynomial = p,
      Estimate = rdd_p$coef["Conventional", ],
      SE_robust = rdd_p$se["Robust", ],
      BW = rdd_p$bws["h", "left"]
    )
  }

  poly_sensitivity <- rbindlist(poly_results)
  fwrite(poly_sensitivity, file.path(data_dir, "rdd_poly_sensitivity.csv"))
  cat("Polynomial sensitivity:\n")
  print(poly_sensitivity)
}

# =============================================================================
# 4. Alternative Post-Reform Windows
# =============================================================================

cat("\n=== Alternative timing ===\n")

# Test different "reform" dates:
# a) Loi Climat bill introduction (Feb 2021)
# b) Loi Climat enactment (Aug 2021)
# c) Rent freeze on FG (Jan 2023)
# d) G rental ban (Jan 2025)

df_GD <- df[dpe_rating %in% c("G", "D")]

timing_results <- list()
timing_dates <- c("2020-06-01", "2021-02-01", "2021-07-01", "2023-01-01")
timing_labels <- c("Convention Citoyenne", "Bill introduction",
                    "Law enacted", "Rent freeze")

for (i in seq_along(timing_dates)) {
  df_GD[, post_alt := as.integer(date_mutation >= as.Date(timing_dates[i]))]

  m <- feols(log_price ~ is_G * post_alt +
               surface_reelle_bati + nombre_pieces_principales + is_apartment |
               code_commune + yq,
             data = df_GD,
             cluster = ~code_commune)

  timing_results[[i]] <- data.table(
    Date = timing_dates[i],
    Label = timing_labels[i],
    Coefficient = coef(m)["is_G:post_alt"],
    SE = se(m)["is_G:post_alt"],
    N = nobs(m)
  )
}

timing_sensitivity <- rbindlist(timing_results)
fwrite(timing_sensitivity, file.path(data_dir, "timing_sensitivity.csv"))
cat("Timing sensitivity:\n")
print(timing_sensitivity)

# =============================================================================
# 5. Heterogeneity: Apartments vs Houses
# =============================================================================

cat("\n=== Heterogeneity by Property Type ===\n")

m_apt <- feols(log_price ~ is_G * post_reform +
                 surface_reelle_bati + nombre_pieces_principales |
                 code_commune + yq,
               data = df_GD[is_apartment == 1],
               cluster = ~code_commune)

m_house <- feols(log_price ~ is_G * post_reform +
                   surface_reelle_bati + nombre_pieces_principales |
                   code_commune + yq,
                 data = df_GD[is_apartment == 0],
                 cluster = ~code_commune)

cat("Apartments: coef =", round(coef(m_apt)["is_G:post_reform"], 4),
    ", SE =", round(se(m_apt)["is_G:post_reform"], 4), "\n")
cat("Houses: coef =", round(coef(m_house)["is_G:post_reform"], 4),
    ", SE =", round(se(m_house)["is_G:post_reform"], 4), "\n")

het_proptype <- data.table(
  Type = c("Apartment", "House"),
  Coefficient = c(coef(m_apt)["is_G:post_reform"],
                  coef(m_house)["is_G:post_reform"]),
  SE = c(se(m_apt)["is_G:post_reform"],
         se(m_house)["is_G:post_reform"]),
  N = c(nobs(m_apt), nobs(m_house))
)
fwrite(het_proptype, file.path(data_dir, "heterogeneity_proptype.csv"))

# =============================================================================
# 6. Heterogeneity: Urban vs Rural
# =============================================================================

cat("\n=== Heterogeneity by Urban/Rural ===\n")

# Use departement density as proxy
dept_density <- df_GD[, .(n_trans = .N), by = dept]
dept_density[, urban := as.integer(n_trans > median(n_trans))]

df_GD_urban <- merge(df_GD, dept_density[, .(dept, urban)], by = "dept")

m_urban <- feols(log_price ~ is_G * post_reform +
                   surface_reelle_bati + nombre_pieces_principales + is_apartment |
                   code_commune + yq,
                 data = df_GD_urban[urban == 1],
                 cluster = ~code_commune)

m_rural <- feols(log_price ~ is_G * post_reform +
                   surface_reelle_bati + nombre_pieces_principales + is_apartment |
                   code_commune + yq,
                 data = df_GD_urban[urban == 0],
                 cluster = ~code_commune)

het_urban <- data.table(
  Area = c("Urban", "Rural"),
  Coefficient = c(coef(m_urban)["is_G:post_reform"],
                  coef(m_rural)["is_G:post_reform"]),
  SE = c(se(m_urban)["is_G:post_reform"],
         se(m_rural)["is_G:post_reform"]),
  N = c(nobs(m_urban), nobs(m_rural))
)
fwrite(het_urban, file.path(data_dir, "heterogeneity_urban.csv"))

# =============================================================================
# 7. Pre-reform Placebo RDD
# =============================================================================

cat("\n=== Pre-reform Placebo RDD ===\n")

if ("kwh_m2_year" %in% names(df)) {
  df_rdd_pre <- df[post_reform == 0 & !is.na(kwh_m2_year)]

  if (nrow(df_rdd_pre) > 1000) {
    rdd_pre <- rdrobust(
      y = df_rdd_pre$log_price,
      x = df_rdd_pre$kwh_m2_year,
      c = 420,
      kernel = "triangular",
      p = 1,
      cluster = as.numeric(as.factor(df_rdd_pre$code_commune))
    )

    cat("Pre-reform RDD (placebo, should be ~0):\n")
    print(summary(rdd_pre))

    post_est <- if (exists("rdd_main", inherits = FALSE)) rdd_main$coef["Conventional", ] else NA
    post_se  <- if (exists("rdd_main", inherits = FALSE)) rdd_main$se["Robust", ] else NA
    placebo_result <- data.table(
      Period = c("Pre-reform (placebo)", "Post-reform"),
      Estimate = c(rdd_pre$coef["Conventional", ], post_est),
      SE = c(rdd_pre$se["Robust", ], post_se)
    )
    fwrite(placebo_result, file.path(data_dir, "rdd_placebo.csv"))
  }
}

# =============================================================================
# 8. Departement × Year FE (stricter controls)
# =============================================================================

cat("\n=== Stricter FE specifications ===\n")

m_strict <- feols(log_price ~ is_G * post_reform +
                    surface_reelle_bati + nombre_pieces_principales + is_apartment |
                    code_commune + dept^yq,
                  data = df_GD,
                  cluster = ~code_commune)

cat("Dept×YQ FE: coef =", round(coef(m_strict)["is_G:post_reform"], 4),
    ", SE =", round(se(m_strict)["is_G:post_reform"], 4), "\n")

strict_results <- data.table(
  FE = c("Commune + YQ", "Commune + Dept×YQ"),
  Coefficient = c(coef(models$m1_GvD)["is_G:post_reform"],
                  coef(m_strict)["is_G:post_reform"]),
  SE = c(se(models$m1_GvD)["is_G:post_reform"],
         se(m_strict)["is_G:post_reform"])
)
fwrite(strict_results, file.path(data_dir, "fe_sensitivity.csv"))

# =============================================================================
# 9. Save all robustness results
# =============================================================================

cat("\n=== All robustness checks complete ===\n")

robustness_models <- list(
  m_apt = m_apt,
  m_house = m_house,
  m_urban = m_urban,
  m_rural = m_rural,
  m_strict = m_strict
)
saveRDS(robustness_models, file.path(data_dir, "robustness_models.rds"))

cat("Robustness results saved to data/ directory.\n")
