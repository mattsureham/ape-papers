# =============================================================================
# 03_main_analysis.R — Main DiD and RDD estimation
# APEP Paper apep_0552: Stranded by the Label?
# =============================================================================

source("00_packages.R")

cat("=== Loading analysis panel ===\n")
df <- arrow::read_parquet(file.path(data_dir, "analysis_panel.parquet"))
setDT(df)
cat("Rows:", nrow(df), "\n")

# =============================================================================
# 1. Summary Statistics
# =============================================================================

cat("\n=== Summary Statistics ===\n")

# Overall summary by DPE rating
sumstats_rating <- df[, .(
  N = .N,
  Mean_Price = mean(price),
  SD_Price = sd(price),
  Mean_PriceSqm = mean(price_sqm),
  SD_PriceSqm = sd(price_sqm),
  Mean_Surface = mean(surface_reelle_bati, na.rm = TRUE),
  Pct_Apartment = mean(is_apartment) * 100,
  Mean_Rooms = mean(nombre_pieces_principales, na.rm = TRUE)
), by = dpe_rating][order(dpe_rating)]

cat("Summary by DPE rating:\n")
print(sumstats_rating)
fwrite(sumstats_rating, file.path(data_dir, "sumstats_by_rating.csv"))

# Pre vs Post comparison for G-rated properties
sumstats_prepost <- df[, .(
  N = .N,
  Mean_Price = mean(price),
  SD_Price = sd(price),
  Mean_PriceSqm = mean(price_sqm),
  SD_PriceSqm = sd(price_sqm),
  Mean_Surface = mean(surface_reelle_bati, na.rm = TRUE)
), by = .(dpe_rating, post_reform)][order(dpe_rating, post_reform)]

fwrite(sumstats_prepost, file.path(data_dir, "sumstats_prepost.csv"))

# Full sample summary stats for paper Table 1
sumstats_full <- df[, .(
  Variable = c("Price (EUR)", "Price per sqm (EUR)", "Surface (sqm)",
               "Rooms", "Apartment (%)", "Post-reform (%)",
               "DPE G (%)", "DPE F (%)", "DPE E (%)", "DPE D (%)",
               "DPE C (%)", "DPE B (%)", "DPE A (%)"),
  Mean = c(mean(price), mean(price_sqm), mean(surface_reelle_bati, na.rm = TRUE),
           mean(nombre_pieces_principales, na.rm = TRUE),
           mean(is_apartment) * 100, mean(post_reform) * 100,
           mean(is_G) * 100, mean(is_F) * 100, mean(is_E) * 100,
           mean(dpe_rating == "D") * 100, mean(dpe_rating == "C") * 100,
           mean(dpe_rating == "B") * 100, mean(dpe_rating == "A") * 100),
  SD = c(sd(price), sd(price_sqm), sd(surface_reelle_bati, na.rm = TRUE),
         sd(nombre_pieces_principales, na.rm = TRUE),
         NA, NA, NA, NA, NA, NA, NA, NA, NA),
  N = rep(.N, 13)
)]

fwrite(sumstats_full, file.path(data_dir, "sumstats_full.csv"))

# =============================================================================
# 2. Main DiD: G-rating × Post-reform
# =============================================================================

cat("\n=== Main DiD Analysis ===\n")

# Specification 1: Simple DiD — G vs D (baseline comparison)
# G-rated properties face imminent ban; D-rated are safe
df_GD <- df[dpe_rating %in% c("G", "D")]

m1 <- feols(log_price ~ is_G * post_reform +
              surface_reelle_bati + nombre_pieces_principales + is_apartment |
              code_commune + yq,
            data = df_GD,
            cluster = ~code_commune)

# Specification 2: G vs F (adjacent grades — narrower comparison)
df_GF <- df[dpe_rating %in% c("G", "F")]

m2 <- feols(log_price ~ is_G * post_reform +
              surface_reelle_bati + nombre_pieces_principales + is_apartment |
              code_commune + yq,
            data = df_GF,
            cluster = ~code_commune)

# Specification 3: Passoire (F+G) vs safe (C+D)
df_passoire <- df[dpe_rating %in% c("C", "D", "F", "G")]

m3 <- feols(log_price ~ passoire * post_reform +
              surface_reelle_bati + nombre_pieces_principales + is_apartment |
              code_commune + yq,
            data = df_passoire,
            cluster = ~code_commune)

# Specification 4: Full gradient (omit D as reference)
m4 <- feols(log_price ~ i(dpe_rating, post_reform, ref = "D") +
              surface_reelle_bati + nombre_pieces_principales + is_apartment |
              code_commune + yq,
            data = df,
            cluster = ~code_commune)

# Print results
cat("\n--- Model 1: G vs D ---\n")
print(summary(m1))
cat("\n--- Model 2: G vs F ---\n")
print(summary(m2))
cat("\n--- Model 3: Passoire (FG) vs Safe (CD) ---\n")
print(summary(m3))

# Save coefficient tables
did_results <- data.table(
  Specification = c("G vs D", "G vs F", "Passoire vs Safe"),
  Coefficient = c(coef(m1)["is_G:post_reform"],
                  coef(m2)["is_G:post_reform"],
                  coef(m3)["passoire:post_reform"]),
  SE = c(se(m1)["is_G:post_reform"],
         se(m2)["is_G:post_reform"],
         se(m3)["passoire:post_reform"]),
  N = c(nobs(m1), nobs(m2), nobs(m3))
)
did_results[, pvalue := 2 * pnorm(-abs(Coefficient / SE))]
did_results[, stars := ifelse(pvalue < 0.01, "***",
                               ifelse(pvalue < 0.05, "**",
                                      ifelse(pvalue < 0.1, "*", "")))]

cat("\nDiD Results Summary:\n")
print(did_results)
fwrite(did_results, file.path(data_dir, "did_main_results.csv"))

# =============================================================================
# 3. Event Study — Dynamic treatment effects
# =============================================================================

cat("\n=== Event Study ===\n")

# Create semester relative to reform (2021S2 = 0)
df_GD[, semester_num := (year - 2021) * 2 + ifelse(month(date_mutation) > 6, 1, 0)]

# Event study: G × semester interactions
m_event <- feols(log_price ~ i(semester_num, is_G, ref = -1) +
                   surface_reelle_bati + nombre_pieces_principales + is_apartment |
                   code_commune + yq,
                 data = df_GD,
                 cluster = ~code_commune)

cat("Event study coefficients:\n")
print(summary(m_event))

# Extract event study coefficients
event_coefs <- data.table(
  semester = as.numeric(gsub("semester_num::(-?\\d+):is_G", "\\1",
                             names(coef(m_event)[grepl("semester_num", names(coef(m_event)))]))),
  estimate = as.numeric(coef(m_event)[grepl("semester_num", names(coef(m_event)))]),
  se = as.numeric(se(m_event)[grepl("semester_num", names(coef(m_event)))])
)
event_coefs[, ci_lower := estimate - 1.96 * se]
event_coefs[, ci_upper := estimate + 1.96 * se]

# Add reference period
event_coefs <- rbind(event_coefs,
                     data.table(semester = -1, estimate = 0, se = 0,
                                ci_lower = 0, ci_upper = 0))
event_coefs <- event_coefs[order(semester)]

fwrite(event_coefs, file.path(data_dir, "event_study_coefs.csv"))

# Joint test for pre-trends
pre_coefs <- event_coefs[semester < -1]
if (nrow(pre_coefs) > 0) {
  pretrend_fstat <- sum(pre_coefs$estimate^2 / pre_coefs$se^2) / nrow(pre_coefs)
  pretrend_pval <- pchisq(pretrend_fstat * nrow(pre_coefs), df = nrow(pre_coefs),
                           lower.tail = FALSE)
  cat("\nJoint pre-trend test: F =", round(pretrend_fstat, 3),
      ", p =", round(pretrend_pval, 3), "\n")
}

# =============================================================================
# 4. Triple-Difference: G × Post × Rental Share
# =============================================================================

cat("\n=== Triple-Difference (Rental Share Heterogeneity) ===\n")

# Continuous interaction
m_triple_cont <- feols(log_price ~ is_G * post_reform * pct_rental +
                         surface_reelle_bati + nombre_pieces_principales + is_apartment |
                         code_commune + yq,
                       data = df_GD[!is.na(pct_rental)],
                       cluster = ~code_commune)

cat("\n--- Triple-Diff (continuous rental share) ---\n")
print(summary(m_triple_cont))

# Tercile interaction
m_triple_terc <- feols(log_price ~ is_G * post_reform * rental_tercile +
                         surface_reelle_bati + nombre_pieces_principales + is_apartment |
                         code_commune + yq,
                       data = df_GD[!is.na(rental_tercile)],
                       cluster = ~code_commune)

cat("\n--- Triple-Diff (rental terciles) ---\n")
print(summary(m_triple_terc))

# Extract triple-diff results
triple_results <- data.table(
  Variable = names(coef(m_triple_cont)),
  Coefficient = as.numeric(coef(m_triple_cont)),
  SE = as.numeric(se(m_triple_cont))
)
fwrite(triple_results, file.path(data_dir, "triple_diff_results.csv"))

# =============================================================================
# 5. RDD at G/F Threshold (420 kWh/m2/year)
# =============================================================================

cat("\n=== RDD at G/F Threshold ===\n")

if ("kwh_m2_year" %in% names(df)) {
  # Post-reform sample only for RDD
  df_rdd <- df[post_reform == 1 & !is.na(kwh_m2_year)]
  df_rdd[, above_420 := as.integer(kwh_m2_year >= 420)]

  # Center running variable at cutoff
  df_rdd[, kwh_centered := kwh_m2_year - 420]

  # rdrobust estimation
  cat("Running rdrobust at 420 kWh/m2/year...\n")
  rdd_main <- rdrobust(
    y = df_rdd$log_price,
    x = df_rdd$kwh_m2_year,
    c = 420,
    kernel = "triangular",
    p = 1,
    cluster = as.numeric(as.factor(df_rdd$code_commune))
  )

  cat("\nRDD at G/F threshold (420 kWh):\n")
  print(summary(rdd_main))

  # Save RDD results
  rdd_results <- data.table(
    Threshold = 420,
    Estimate = rdd_main$coef["Conventional", ],
    SE_robust = rdd_main$se["Robust", ],
    pval_robust = rdd_main$pv["Robust", ],
    BW_left = rdd_main$bws["h", "left"],
    BW_right = rdd_main$bws["h", "right"],
    N_left = rdd_main$N_h[1],
    N_right = rdd_main$N_h[2]
  )

  # RDD at F/E threshold (330 kWh) — comparison
  cat("\nRunning rdrobust at 330 kWh/m2/year (F/E boundary)...\n")
  rdd_FE <- rdrobust(
    y = df_rdd$log_price,
    x = df_rdd$kwh_m2_year,
    c = 330,
    kernel = "triangular",
    p = 1,
    cluster = as.numeric(as.factor(df_rdd$code_commune))
  )
  cat("RDD at F/E threshold:\n")
  print(summary(rdd_FE))

  rdd_results <- rbind(rdd_results, data.table(
    Threshold = 330,
    Estimate = rdd_FE$coef["Conventional", ],
    SE_robust = rdd_FE$se["Robust", ],
    pval_robust = rdd_FE$pv["Robust", ],
    BW_left = rdd_FE$bws["h", "left"],
    BW_right = rdd_FE$bws["h", "right"],
    N_left = rdd_FE$N_h[1],
    N_right = rdd_FE$N_h[2]
  ))

  # RDD at D/C threshold (250 kWh) — placebo
  cat("\nRunning rdrobust at 250 kWh/m2/year (D/C boundary, placebo)...\n")
  rdd_DC <- rdrobust(
    y = df_rdd$log_price,
    x = df_rdd$kwh_m2_year,
    c = 250,
    kernel = "triangular",
    p = 1,
    cluster = as.numeric(as.factor(df_rdd$code_commune))
  )
  cat("RDD at D/C threshold (placebo):\n")
  print(summary(rdd_DC))

  rdd_results <- rbind(rdd_results, data.table(
    Threshold = 250,
    Estimate = rdd_DC$coef["Conventional", ],
    SE_robust = rdd_DC$se["Robust", ],
    pval_robust = rdd_DC$pv["Robust", ],
    BW_left = rdd_DC$bws["h", "left"],
    BW_right = rdd_DC$bws["h", "right"],
    N_left = rdd_DC$N_h[1],
    N_right = rdd_DC$N_h[2]
  ))

  fwrite(rdd_results, file.path(data_dir, "rdd_results.csv"))
  cat("\nRDD results saved.\n")

  # ==========================================================================
  # 5b. Density test (McCrary) at G/F threshold
  # ==========================================================================

  cat("\n=== McCrary Density Test ===\n")
  density_test <- rddensity(df_rdd$kwh_m2_year, c = 420)
  cat("McCrary density test at 420 kWh:\n")
  cat("  T-statistic:", density_test$test$t_jk, "\n")
  cat("  P-value:", density_test$test$p_jk, "\n")

  density_results <- data.table(
    Threshold = 420,
    T_stat = density_test$test$t_jk,
    P_value = density_test$test$p_jk
  )

  # Density test at other thresholds
  for (c_val in c(330, 250)) {
    dt_test <- rddensity(df_rdd$kwh_m2_year, c = c_val)
    density_results <- rbind(density_results, data.table(
      Threshold = c_val,
      T_stat = dt_test$test$t_jk,
      P_value = dt_test$test$p_jk
    ))
  }

  fwrite(density_results, file.path(data_dir, "density_tests.csv"))

  # Pre-reform density test (to compare manipulation before/after)
  df_rdd_pre <- df[post_reform == 0 & !is.na(kwh_m2_year)]
  if (nrow(df_rdd_pre) > 100) {
    density_pre <- rddensity(df_rdd_pre$kwh_m2_year, c = 420)
    cat("Pre-reform density test at 420 kWh:\n")
    cat("  T-statistic:", density_pre$test$t_jk, "\n")
    cat("  P-value:", density_pre$test$p_jk, "\n")
  }

} else {
  cat("kwh_m2_year not available. Skipping RDD analysis.\n")
  cat("Analysis will rely on DiD with letter-grade indicators.\n")
}

# =============================================================================
# 6. DiDisc: Difference-in-Discontinuities
# =============================================================================

cat("\n=== Difference-in-Discontinuities ===\n")

if ("kwh_m2_year" %in% names(df)) {
  # Compare G/F threshold discontinuity pre vs post reform
  df_disc <- df[!is.na(kwh_m2_year)]
  df_disc[, kwh_centered := kwh_m2_year - 420]
  df_disc[, above_420 := as.integer(kwh_m2_year >= 420)]

  # Restrict to bandwidth around threshold
  bw <- 50  # kWh window
  df_disc_bw <- df_disc[abs(kwh_centered) <= bw]

  # DiDisc regression
  m_didisc <- feols(log_price ~ above_420 * post_reform +
                      kwh_centered * above_420 +
                      surface_reelle_bati + nombre_pieces_principales + is_apartment |
                      code_commune + yq,
                    data = df_disc_bw,
                    cluster = ~code_commune)

  cat("DiDisc results:\n")
  print(summary(m_didisc))

  didisc_results <- data.table(
    Variable = names(coef(m_didisc)),
    Coefficient = as.numeric(coef(m_didisc)),
    SE = as.numeric(se(m_didisc))
  )
  fwrite(didisc_results, file.path(data_dir, "didisc_results.csv"))
}

# =============================================================================
# 7. Save all model objects
# =============================================================================

cat("\n=== Saving model objects ===\n")

models_list <- list(
  m1_GvD = m1,
  m2_GvF = m2,
  m3_passoire = m3,
  m4_gradient = m4,
  m_event = m_event,
  m_triple_cont = m_triple_cont,
  m_triple_terc = m_triple_terc
)

if (exists("m_didisc")) models_list$m_didisc <- m_didisc

saveRDS(models_list, file.path(data_dir, "main_models.rds"))
cat("All models saved.\n")
