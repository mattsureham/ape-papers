# 04_robustness.R — Pre-trends, placebos, and robustness checks
# apep_0932

source("00_packages.R")

cat("Loading analysis sample...\n")
df <- readRDS("../data/analysis_sample.rds")
cat(sprintf("  %s observations.\n", format(nrow(df), big.mark = ",")))

# =============================================================================
# 1. PRE-TREND TEST: 1920→1930 occupational mobility by race × ND spending
#    Key identifying assumption: parallel pre-trends
# =============================================================================
cat("\n=== PRE-TREND TEST (1920→1930) ===\n")

# Must have valid 1920 occscore
df_pre <- df[!is.na(occscore_1920) & occscore_1920 > 0]
cat(sprintf("  Pre-trend sample: %s (with 1920 occscore)\n", format(nrow(df_pre), big.mark = ",")))

m_pre <- feols(d_occscore_20_30 ~ black * ndexp_std |
                 county_id + age_bin_1930 + occ1950_1920,
               data = df_pre, cluster = ~county_id)

coef_pre <- grep("black.*ndexp", names(coef(m_pre)), value = TRUE)
cat(sprintf("  Pre-trend DDD: β = %.4f (SE = %.4f)\n",
            coef(m_pre)[coef_pre],
            sqrt(vcov(m_pre)[coef_pre, coef_pre])))

# =============================================================================
# 2. PLACEBO: Women (largely excluded from WPA work relief)
# =============================================================================
cat("\n=== PLACEBO: WOMEN ===\n")

# Reload full panel to get women
mlp_full <- readRDS("../data/mlp_panel.rds")
fishback <- readRDS("../data/fishback_nd.rds")
bridge <- readRDS("../data/bridge_fips_icpsr.rds")

# Construct women sample with same filters
df_women <- mlp_full[sex_1930 == 2 & age_1930 >= 18 & age_1930 <= 55 &
                       race_1930 %in% c(1, 2) &
                       !is.na(countyicp_1930) & countyicp_1930 > 0 &
                       !is.na(occscore_1930) & !is.na(occscore_1940) &
                       occscore_1930 > 0 & occscore_1940 > 0]
rm(mlp_full)

# Add ICPSR state mapping
if (nrow(bridge) > 0 && "ICPSR1950_STATEN" %in% names(bridge)) {
  state_map <- unique(bridge[, .(FIPSTATE = as.integer(FIPSTATE),
                                  ICPSR1950_STATEN = as.integer(ICPSR1950_STATEN))])
  df_women <- merge(df_women, state_map, by.x = "statefip_1930", by.y = "FIPSTATE", all.x = TRUE)
  setnames(df_women, "ICPSR1950_STATEN", "icpsr_state_1930")
} else {
  df_women[, icpsr_state_1930 := statefip_1930]
}

# Build Fishback merge table
if ("ICPSR1950_STATEN" %in% names(fishback)) {
  fishback_merge <- fishback[!is.na(NDEXP_PC), .(statefip_fish = ICPSR1950_STATEN,
                                                   countyicp_fish = ICPSR1950_COUNTY,
                                                   ndexp_pc = NDEXP_PC)]
} else {
  # Use bridge to convert
  fishback_merge <- fishback[!is.na(NDEXP_PC)]
  # Try various column name patterns
  state_col <- grep("state|fips.*st|st.*fips", names(fishback_merge), ignore.case = TRUE, value = TRUE)[1]
  county_col <- grep("county|cnty", names(fishback_merge), ignore.case = TRUE, value = TRUE)[1]
  if (!is.na(state_col) && !is.na(county_col)) {
    fishback_merge <- fishback_merge[, .(statefip_fish = get(state_col),
                                          countyicp_fish = get(county_col),
                                          ndexp_pc = NDEXP_PC)]
  }
}

df_women <- merge(df_women, fishback_merge,
                  by.x = c("icpsr_state_1930", "countyicp_1930"),
                  by.y = c("statefip_fish", "countyicp_fish"), all.x = TRUE)
df_women <- df_women[!is.na(ndexp_pc)]

df_women[, black := as.integer(race_1930 == 2)]
df_women[, d_occscore_30_40 := occscore_1940 - occscore_1930]
df_women[, ndexp_std := (ndexp_pc - mean(ndexp_pc, na.rm = TRUE)) / sd(ndexp_pc, na.rm = TRUE)]
df_women[, county_id := paste0(statefip_1930, "_", countyicp_1930)]
df_women[, age_bin_1930 := cut(age_1930, breaks = c(17, 25, 35, 45, 56),
                                labels = c("18-25", "26-35", "36-45", "46-55"))]

cat(sprintf("  Women sample: %s\n", format(nrow(df_women), big.mark = ",")))

m_women <- feols(d_occscore_30_40 ~ black * ndexp_std |
                   county_id + age_bin_1930,
                 data = df_women, cluster = ~county_id)

coef_w <- grep("black.*ndexp", names(coef(m_women)), value = TRUE)
if (length(coef_w) > 0) {
  cat(sprintf("  Women placebo: β = %.4f (SE = %.4f)\n",
              coef(m_women)[coef_w],
              sqrt(vcov(m_women)[coef_w, coef_w])))
}

rm(df_women)

# =============================================================================
# 3. LEAVE-ONE-STATE-OUT
# =============================================================================
cat("\n=== LEAVE-ONE-STATE-OUT ===\n")

states <- unique(df$statefip_1930)
loo_results <- data.table(
  state_dropped = integer(),
  coef = numeric(),
  se = numeric()
)

for (s in states) {
  m_loo <- tryCatch({
    feols(d_occscore_30_40 ~ black * ndexp_std |
            county_id + age_bin_1930 + occ1950_1930,
          data = df[statefip_1930 != s], cluster = ~county_id)
  }, error = function(e) NULL)

  if (!is.null(m_loo)) {
    cn <- grep("black.*ndexp", names(coef(m_loo)), value = TRUE)
    if (length(cn) > 0) {
      loo_results <- rbind(loo_results, data.table(
        state_dropped = s,
        coef = coef(m_loo)[cn],
        se = sqrt(vcov(m_loo)[cn, cn])
      ))
    }
  }
}

cat(sprintf("  LOO range: [%.4f, %.4f]\n", min(loo_results$coef), max(loo_results$coef)))
cat(sprintf("  LOO mean: %.4f\n", mean(loo_results$coef)))

# =============================================================================
# 4. CONTINUOUS TREATMENT: quintiles instead of terciles
# =============================================================================
cat("\n=== QUINTILE SPECIFICATION ===\n")

df[, nd_quintile := cut(ndexp_pc,
                         breaks = quantile(ndexp_pc, probs = seq(0, 1, 0.2), na.rm = TRUE),
                         labels = paste0("Q", 1:5), include.lowest = TRUE)]

m_quint <- feols(d_occscore_30_40 ~ black * nd_quintile |
                   county_id + age_bin_1930 + occ1950_1930,
                 data = df, cluster = ~county_id)

cat("  Quintile interactions with Black:\n")
quint_coefs <- grep("black.*nd_quintile", names(coef(m_quint)), value = TRUE)
for (qc in quint_coefs) {
  cat(sprintf("    %s: %.4f\n", qc, coef(m_quint)[qc]))
}

# =============================================================================
# 5. FARM vs NON-FARM heterogeneity
# =============================================================================
cat("\n=== FARM vs NON-FARM ===\n")

df[, farm_worker_1930 := as.integer(farm_1930 == 2)]

m_farm <- feols(d_occscore_30_40 ~ black * ndexp_std |
                  county_id + age_bin_1930,
                data = df[farm_worker_1930 == 1], cluster = ~county_id)

m_nonfarm <- feols(d_occscore_30_40 ~ black * ndexp_std |
                     county_id + age_bin_1930,
                   data = df[farm_worker_1930 == 0], cluster = ~county_id)

cf <- grep("black.*ndexp", names(coef(m_farm)), value = TRUE)
cn <- grep("black.*ndexp", names(coef(m_nonfarm)), value = TRUE)
cat(sprintf("  Farm workers:     β = %.4f\n", coef(m_farm)[cf]))
cat(sprintf("  Non-farm workers: β = %.4f\n", coef(m_nonfarm)[cn]))

# =============================================================================
# 6. Save robustness results
# =============================================================================
save(m_pre, m_women, loo_results, m_quint, m_farm, m_nonfarm,
     file = "../data/robustness_models.RData")

cat("\nRobustness checks complete.\n")
