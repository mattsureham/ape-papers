## 04_robustness.R — Robustness checks, balance tests, RI
## APEP-0642 v2: Regulatory Whack-a-Mole

source("00_packages.R")

data_dir <- "../data"

df <- fread(file.path(data_dir, "analysis_panel.csv"))
df[, log_releases := log(releases + 1)]
df[, fcm_id := paste(fc_id, medium, sep = "_")]
df[, year_f := factor(YEAR)]

# Winsorize at 99th percentile
for (m in unique(df$medium_cat)) {
  p99 <- quantile(df[medium_cat == m, releases], 0.99, na.rm = TRUE)
  df[medium_cat == m, releases_w := pmin(releases, p99)]
}
df[, log_releases_w := log(releases_w + 1)]

# Ensure CWA/RCRA columns exist
if (!"cwa_inspected" %in% names(df)) df[, cwa_inspected := 0L]
if (!"rcra_inspected" %in% names(df)) df[, rcra_inspected := 0L]

# ============================================================
# 1. BALANCE TEST: Treatment timing validation [V2 NEW]
# ============================================================
cat("=== Balance test: quasi-random timing ===\n")

# Regress first inspection year on pre-treatment facility characteristics
# Use facility-level data (one row per facility)
fac_chars <- df[event_time == -1 & medium_cat == "Air",
                .(first_insp_year, ST, naics,
                  pre_air = mean(releases_w),
                  pre_total = mean(releases)),
                by = frs_id]
fac_chars[, naics2 := substr(as.character(naics), 1, 2)]

# F-test: do pre-treatment characteristics predict inspection timing?
bal_mod <- lm(first_insp_year ~ pre_air + factor(naics2) + factor(ST),
              data = fac_chars)
bal_fstat <- summary(bal_mod)$fstatistic
bal_pval <- pf(bal_fstat[1], bal_fstat[2], bal_fstat[3], lower.tail = FALSE)
cat("Balance test F-stat:", round(bal_fstat[1], 2),
    "p-value:", round(bal_pval, 4), "\n")

# Save balance test results
balance_results <- list(
  f_stat = bal_fstat[1],
  df1 = bal_fstat[2],
  df2 = bal_fstat[3],
  p_value = bal_pval,
  n = nrow(fac_chars)
)
write_json(balance_results, file.path(data_dir, "balance_test.json"),
           auto_unbox = TRUE, pretty = TRUE)

# ============================================================
# 2. PRE-TREND TESTS
# ============================================================
cat("\n=== Pre-trend tests ===\n")

df_air <- df[medium_cat == "Air"]

# Event study (no year FE to avoid collinearity)
es_air_noyr <- feols(log_releases_w ~ i(event_time, ref = -1) | fc_id,
                     data = df_air, cluster = ~frs_id)

# Wald test for pre-trends
wald_pre <- wald(es_air_noyr, "event_time::-[2-5]")
cat("Air pre-trend Wald p-value:", wald_pre$p, "\n")

# Non-air pre-trends
df_nonair <- df[medium_cat != "Air"]
es_nonair_noyr <- feols(log_releases_w ~ i(event_time, ref = -1) | fcm_id,
                        data = df_nonair, cluster = ~frs_id)

# ============================================================
# 3. ALTERNATIVE CLUSTERING
# ============================================================
cat("\n=== Alternative clustering ===\n")

m_fac <- feols(log_releases_w ~ post_air + post_nonair | fcm_id + year_f,
               data = df, cluster = ~frs_id)
m_state <- feols(log_releases_w ~ post_air + post_nonair | fcm_id + year_f,
                 data = df, cluster = ~ST)
m_2way <- feols(log_releases_w ~ post_air + post_nonair | fcm_id + year_f,
                data = df, cluster = ~frs_id + YEAR)

cat(sprintf("Facility:  PostAir=%.4f (%.4f) PostNonAir=%.4f (%.4f)\n",
            coef(m_fac)["post_air"], se(m_fac)["post_air"],
            coef(m_fac)["post_nonair"], se(m_fac)["post_nonair"]))
cat(sprintf("State:     PostAir=%.4f (%.4f) PostNonAir=%.4f (%.4f)\n",
            coef(m_state)["post_air"], se(m_state)["post_air"],
            coef(m_state)["post_nonair"], se(m_state)["post_nonair"]))
cat(sprintf("Fac+Year:  PostAir=%.4f (%.4f) PostNonAir=%.4f (%.4f)\n",
            coef(m_2way)["post_air"], se(m_2way)["post_air"],
            coef(m_2way)["post_nonair"], se(m_2way)["post_nonair"]))

# ============================================================
# 4. FUNCTIONAL FORM ALTERNATIVES
# ============================================================
cat("\n=== Functional form alternatives ===\n")

# Levels
m_levels <- feols(releases_w ~ post_air + post_nonair | fcm_id + year_f,
                  data = df, cluster = ~frs_id)
cat("Levels: PostAir=", round(coef(m_levels)["post_air"], 2),
    " PostNonAir=", round(coef(m_levels)["post_nonair"], 2), "\n")

# IHS
df[, ihs_releases := log(releases_w + sqrt(releases_w^2 + 1))]
m_ihs <- feols(ihs_releases ~ post_air + post_nonair | fcm_id + year_f,
               data = df, cluster = ~frs_id)
cat("IHS: PostAir=", round(coef(m_ihs)["post_air"], 4),
    " PostNonAir=", round(coef(m_ihs)["post_nonair"], 4), "\n")

# PPML (Poisson pseudo-maximum likelihood) for zero-inflated outcomes
cat("Running PPML...\n")
tryCatch({
  m_ppml <- fepois(releases_w ~ post_air + post_nonair | fcm_id + year_f,
                   data = df[releases_w >= 0], cluster = ~frs_id)
  cat("PPML: PostAir=", round(coef(m_ppml)["post_air"], 4),
      " PostNonAir=", round(coef(m_ppml)["post_nonair"], 4), "\n")
}, error = function(e) {
  cat("PPML failed:", conditionMessage(e), "\n")
  m_ppml <<- NULL
})

# Share specification: air_share = air / total
df_wide <- fread(file.path(data_dir, "ext_panel.csv"))
if ("Air" %in% names(df_wide) && "Land" %in% names(df_wide)) {
  df_wide[, total := Air + Water + Land + POTW]
  df_wide[total > 0, air_share := Air / total]
  df_wide[total > 0, land_share := Land / total]
  df_wide[, year_f := factor(YEAR)]

  m_share_air <- feols(air_share ~ post + cwa_inspected + rcra_inspected |
                         fc_id + year_f,
                       data = df_wide[!is.na(air_share)], cluster = ~frs_id)
  m_share_land <- feols(land_share ~ post + cwa_inspected + rcra_inspected |
                          fc_id + year_f,
                        data = df_wide[!is.na(land_share)], cluster = ~frs_id)
  cat("Share spec — Air share: Post=", round(coef(m_share_air)["post"], 4), "\n")
  cat("Share spec — Land share: Post=", round(coef(m_share_land)["post"], 4), "\n")
} else {
  m_share_air <- m_share_land <- NULL
}

# ============================================================
# 5. EVENT WINDOW SENSITIVITY
# ============================================================
cat("\n=== Event window sensitivity ===\n")

m_w3 <- feols(log_releases_w ~ post_air + post_nonair | fcm_id + year_f,
              data = df[event_time >= -3 & event_time <= 3], cluster = ~frs_id)
m_w4 <- feols(log_releases_w ~ post_air + post_nonair | fcm_id + year_f,
              data = df[event_time >= -4 & event_time <= 4], cluster = ~frs_id)
m_nocovid <- feols(log_releases_w ~ post_air + post_nonair | fcm_id + year_f,
                   data = df[YEAR != 2020], cluster = ~frs_id)

cat(sprintf("±3yr: PostAir=%.4f PostNonAir=%.4f\n",
            coef(m_w3)["post_air"], coef(m_w3)["post_nonair"]))
cat(sprintf("±4yr: PostAir=%.4f PostNonAir=%.4f\n",
            coef(m_w4)["post_air"], coef(m_w4)["post_nonair"]))
cat(sprintf("No 2020: PostAir=%.4f PostNonAir=%.4f\n",
            coef(m_nocovid)["post_air"], coef(m_nocovid)["post_nonair"]))

# ============================================================
# 6. HETEROGENEITY
# ============================================================
cat("\n=== Heterogeneity ===\n")

# 6a. Enforcement intensity (top 15 states by inspection count)
state_intensity <- df[, .(n_insp = sum(inspected)), by = ST][order(-n_insp)]
high_enforcement <- state_intensity[1:15, ST]

m_high <- feols(log_releases_w ~ post_air + post_nonair | fcm_id + year_f,
                data = df[ST %in% high_enforcement], cluster = ~frs_id)
m_low <- feols(log_releases_w ~ post_air + post_nonair | fcm_id + year_f,
               data = df[!ST %in% high_enforcement], cluster = ~frs_id)

cat(sprintf("High enforcement: PostAir=%.4f PostNonAir=%.4f\n",
            coef(m_high)["post_air"], coef(m_high)["post_nonair"]))
cat(sprintf("Low enforcement: PostAir=%.4f PostNonAir=%.4f\n",
            coef(m_low)["post_air"], coef(m_low)["post_nonair"]))

# 6b. Industry heterogeneity
df[, naics2 := substr(as.character(naics), 1, 2)]
top_ind <- df[, .(n = uniqueN(fc_id)), by = naics2][order(-n)][1:5]

industry_models <- list()
for (n2 in top_ind$naics2) {
  d <- df[naics2 == n2]
  if (nrow(d) > 1000 && uniqueN(d$frs_id) >= 30) {
    mod <- feols(log_releases_w ~ post_air + post_nonair | fcm_id + year_f,
                 data = d, cluster = ~frs_id)
    industry_models[[n2]] <- mod
    cat(sprintf("  NAICS %s: PostAir=%.4f PostNonAir=%.4f N=%d\n",
                n2, coef(mod)["post_air"], coef(mod)["post_nonair"], nrow(d)))
  }
}

# 6c. Treatment definition check: any inspection in year t [V2 NEW]
cat("\n=== Treatment definition robustness ===\n")
m_any_insp <- feols(log_releases_w ~ inspected:is_air + inspected:I(1 - is_air) |
                      fcm_id + year_f,
                    data = df, cluster = ~frs_id)
cat("Any-inspection-in-year spec:\n")
print(coeftable(m_any_insp))

# ============================================================
# 7. RANDOMIZATION INFERENCE [V2 NEW]
# ============================================================
cat("\n=== Randomization inference ===\n")

n_permutations <- 500
set.seed(42)

# For speed, do RI on the pooled triple-diff
# Permute first_insp_year across facilities
fac_years <- unique(df[!is.na(first_insp_year), .(frs_id, first_insp_year)])

ri_coefs <- data.table(iter = integer(), coef_air = numeric(), coef_nonair = numeric())

cat("Running", n_permutations, "permutations...\n")
for (i in seq_len(n_permutations)) {
  if (i %% 100 == 0) cat("  Permutation", i, "/", n_permutations, "\n")

  # Shuffle first_insp_year across facilities
  perm_years <- fac_years[sample(.N)]
  perm_years[, first_insp_perm := fac_years$first_insp_year]

  # Merge permuted years
  df_perm <- merge(df, perm_years[, .(frs_id, first_insp_perm)],
                   by = "frs_id", all.x = TRUE)
  df_perm[, post_perm := as.integer(!is.na(first_insp_perm) & YEAR >= first_insp_perm)]
  df_perm[, post_air_perm := post_perm * is_air]
  df_perm[, post_nonair_perm := post_perm * (1L - is_air)]

  tryCatch({
    mod_perm <- feols(log_releases_w ~ post_air_perm + post_nonair_perm |
                        fcm_id + year_f,
                      data = df_perm, cluster = ~frs_id)
    ri_coefs <- rbind(ri_coefs,
                      data.table(iter = i,
                                 coef_air = coef(mod_perm)["post_air_perm"],
                                 coef_nonair = coef(mod_perm)["post_nonair_perm"]))
  }, error = function(e) NULL)
}

# Compute RI p-values
actual_air <- coef(m_fac)["post_air"]
actual_nonair <- coef(m_fac)["post_nonair"]

ri_p_air <- mean(abs(ri_coefs$coef_air) >= abs(actual_air))
ri_p_nonair <- mean(abs(ri_coefs$coef_nonair) >= abs(actual_nonair))

cat("RI p-value (Post×Air):", round(ri_p_air, 4), "\n")
cat("RI p-value (Post×NonAir):", round(ri_p_nonair, 4), "\n")

fwrite(ri_coefs, file.path(data_dir, "ri_distribution.csv"))
write_json(list(ri_p_air = ri_p_air, ri_p_nonair = ri_p_nonair,
                n_permutations = n_permutations,
                actual_air = actual_air, actual_nonair = actual_nonair),
           file.path(data_dir, "ri_results.json"), auto_unbox = TRUE, pretty = TRUE)

# ============================================================
# 8. LEAVE-ONE-STATE-OUT [V2 NEW]
# ============================================================
cat("\n=== Leave-one-state-out ===\n")

states <- unique(df$ST[df$ST != ""])
loso_results <- data.table()

for (s in states) {
  d <- df[ST != s]
  if (nrow(d) > 10000) {
    mod <- feols(log_releases_w ~ post_air + post_nonair | fcm_id + year_f,
                 data = d, cluster = ~frs_id)
    loso_results <- rbind(loso_results,
                          data.table(state_dropped = s,
                                     coef_air = coef(mod)["post_air"],
                                     coef_nonair = coef(mod)["post_nonair"]))
  }
}

cat("Leave-one-state-out range:\n")
cat("  PostAir:", round(range(loso_results$coef_air), 4), "\n")
cat("  PostNonAir:", round(range(loso_results$coef_nonair), 4), "\n")
fwrite(loso_results, file.path(data_dir, "loso_results.csv"))

# ============================================================
# 9. Save all robustness models
# ============================================================
rob_models <- list(
  # Pre-trends
  es_air_noyr = es_air_noyr,
  es_nonair_noyr = es_nonair_noyr,
  wald_pre_p = wald_pre$p,
  # Clustering
  m_fac = m_fac, m_state = m_state, m_2way = m_2way,
  # Functional form
  m_levels = m_levels, m_ihs = m_ihs,
  m_share_air = m_share_air, m_share_land = m_share_land,
  # Windows
  m_w3 = m_w3, m_w4 = m_w4, m_nocovid = m_nocovid,
  # Heterogeneity
  m_high = m_high, m_low = m_low,
  industry_models = industry_models,
  # Treatment definition
  m_any_insp = m_any_insp,
  # Balance
  balance_results = balance_results,
  # RI
  ri_p_air = ri_p_air, ri_p_nonair = ri_p_nonair
)

if (exists("m_ppml") && !is.null(m_ppml)) rob_models$m_ppml <- m_ppml

saveRDS(rob_models, file.path(data_dir, "robustness_models.rds"))

cat("\n=== Robustness complete ===\n")
