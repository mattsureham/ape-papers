# =============================================================================
# 03_main_analysis.R — Primary Regressions
# APEP Paper apep_0547: No-Fault Eviction Abolition and Private Rental Supply
# =============================================================================

source("00_packages.R")

data_dir <- "../data"
panel <- fread(file.path(data_dir, "analysis_panel.csv"))
panel[, ym := as.Date(ym)]
cat("Loaded panel:", nrow(panel), "rows,", uniqueN(panel$la), "LAs\n")

# =============================================================================
# 1. DESCRIPTIVE EVIDENCE: Wales vs England Transaction Trends
# =============================================================================
cat("\n=== 1. Aggregate Trends ===\n")

agg_trends <- panel[, .(
  total_n = sum(n_transactions),
  mean_n = mean(n_transactions),
  mean_price = weighted.mean(mean_price, n_transactions, na.rm = TRUE)
), by = .(country, ym)]

fwrite(agg_trends, file.path(data_dir, "aggregate_trends.csv"))

# =============================================================================
# 2. PRIMARY DiD: Log transaction volumes
# =============================================================================
cat("\n=== 2. Primary DiD Estimation ===\n")

# Model 1: Simple DiD with LA and month FE
m1 <- feols(log_n ~ treated | la_id + ym_id, data = panel,
            cluster = ~la_id)
cat("\nModel 1: Simple DiD\n")
print(summary(m1))

# Model 2: DiD controlling for year-month trends
m2 <- feols(log_n ~ treated | la_id + ym_id, data = panel,
            cluster = ~la_id)

# Model 3: DiD with LA-specific linear trends
m3 <- feols(log_n ~ treated | la_id[t_rel] + ym_id, data = panel,
            cluster = ~la_id)
cat("\nModel 3: DiD with LA-specific trends\n")
print(summary(m3))

# =============================================================================
# 3. EVENT STUDY
# =============================================================================
cat("\n=== 3. Event Study ===\n")

# Create relative time indicators
# Bin endpoints: ≤-24 and ≥24
panel[, t_rel_binned := pmax(pmin(t_rel, 30), -48)]

# Drop t=-1 as reference period
panel[, t_rel_factor := factor(t_rel_binned)]
panel[, t_rel_factor := relevel(t_rel_factor, ref = as.character(-1))]

# Event study with fixest::sunab()-style estimation
# Since treatment is simultaneous (single cohort), sunab simplifies to standard event study
es <- feols(log_n ~ i(t_rel_binned, wales, ref = -1) | la_id + ym_id,
            data = panel, cluster = ~la_id)
cat("\nEvent Study:\n")
print(summary(es))

# Extract event study coefficients
es_coefs <- as.data.table(coeftable(es))
es_coefs[, term := rownames(coeftable(es))]

# Parse relative time from term names
es_coefs[, t := as.integer(str_extract(term, "-?\\d+"))]
es_coefs <- es_coefs[!is.na(t)]
setnames(es_coefs, c("estimate", "se", "t_stat", "p_value", "term", "t"))

# Add reference period
es_coefs <- rbind(es_coefs,
                   data.table(estimate = 0, se = 0, t_stat = NA, p_value = NA,
                              term = "ref", t = -1))
setorder(es_coefs, t)

# Save for plotting
fwrite(es_coefs, file.path(data_dir, "event_study_coefs.csv"))

# Pre-trend test: joint F-test on pre-treatment coefficients
pre_coefs <- es_coefs[t < -1 & t >= -24]
cat("\n--- Pre-trend test ---\n")
cat("Pre-treatment coefficients (t=-24 to t=-2):\n")
cat("  Mean:", round(mean(pre_coefs$estimate), 4), "\n")
cat("  Max absolute:", round(max(abs(pre_coefs$estimate)), 4), "\n")

# Joint Wald test of pre-treatment coefficients
pre_test <- wald(es, "t_rel_binned::-[2-9]|t_rel_binned::-[1-4][0-9]",
                 cluster = ~la_id)
cat("Joint pre-trend Wald test:\n")
print(pre_test)

# Save Wald test result
wald_result <- data.table(
  f_stat = pre_test$stat,
  df1 = pre_test$df1,
  df2 = pre_test$df2,
  p_value = pre_test$p
)
fwrite(wald_result, file.path(data_dir, "wald_pretrend_test.csv"))
cat("Wald test F-stat:", round(pre_test$stat, 3),
    "df:", pre_test$df1, ",", pre_test$df2,
    "p-value:", round(pre_test$p, 4), "\n")

# =============================================================================
# 4. TRIPLE-DIFFERENCE (DDD): Wales × Post × High PRS
# =============================================================================
cat("\n=== 4. Triple-Difference (DDD) ===\n")

# DDD with PRS share as continuous intensity
m_ddd <- feols(log_n ~ treated * prs_share | la_id + ym_id, data = panel,
               cluster = ~la_id)
cat("\nDDD (continuous PRS share):\n")
print(summary(m_ddd))

# DDD with high-PRS indicator
m_ddd2 <- feols(log_n ~ treated * high_prs | la_id + ym_id, data = panel,
                cluster = ~la_id)
cat("\nDDD (high PRS indicator):\n")
print(summary(m_ddd2))

# =============================================================================
# 5. COMPOSITION ANALYSIS
# =============================================================================
cat("\n=== 5. Composition Analysis ===\n")

# Category B share (additional properties / buy-to-let proxy)
m_catb <- feols(cat_b_share ~ treated | la_id + ym_id, data = panel,
                cluster = ~la_id)
cat("\nCategory B share:\n")
print(summary(m_catb))

# Freehold share
m_fh <- feols(freehold_share ~ treated | la_id + ym_id, data = panel,
              cluster = ~la_id)
cat("\nFreehold share:\n")
print(summary(m_fh))

# Flat share (typical PRS stock)
m_flat <- feols(flat_share ~ treated | la_id + ym_id, data = panel,
                cluster = ~la_id)
cat("\nFlat share:\n")
print(summary(m_flat))

# New-build share
m_new <- feols(new_share ~ treated | la_id + ym_id, data = panel,
               cluster = ~la_id)
cat("\nNew-build share:\n")
print(summary(m_new))

# =============================================================================
# 6. PRICE EFFECTS
# =============================================================================
cat("\n=== 6. Price Effects ===\n")

panel[, log_price := log(mean_price)]

m_price <- feols(log_price ~ treated | la_id + ym_id, data = panel,
                 cluster = ~la_id)
cat("\nLog mean price:\n")
print(summary(m_price))

# =============================================================================
# 6b. PRICE EVENT STUDY
# =============================================================================
cat("\n=== 6b. Price Event Study ===\n")

es_price <- feols(log_price ~ i(t_rel_binned, wales, ref = -1) | la_id + ym_id,
                  data = panel, cluster = ~la_id)

es_price_coefs <- as.data.table(coeftable(es_price))
es_price_coefs[, term := rownames(coeftable(es_price))]
es_price_coefs[, t := as.integer(str_extract(term, "-?\\d+"))]
es_price_coefs <- es_price_coefs[!is.na(t)]
setnames(es_price_coefs, c("estimate", "se", "t_stat", "p_value", "term", "t"))
es_price_coefs <- rbind(es_price_coefs,
                         data.table(estimate = 0, se = 0, t_stat = NA, p_value = NA,
                                    term = "ref", t = -1))
setorder(es_price_coefs, t)
fwrite(es_price_coefs, file.path(data_dir, "price_event_study_coefs.csv"))
cat("Saved price event study coefficients\n")

# =============================================================================
# 7. PLACEBO: OWNER-OCCUPIED PROPERTIES
# =============================================================================
cat("\n=== 7. Owner-Occupied Placebo ===\n")

# Owner-occupied properties should NOT respond to eviction reform
# Proxy: Freehold detached houses are overwhelmingly owner-occupied
# Category A (standard residential) is more likely owner-occupied
# Category B (additional properties) includes buy-to-let

# Create separate panels for Cat A and Cat B
panel[, log_cat_a := log(n_cat_a + 1)]
panel[, log_cat_b := log(n_cat_b + 1)]

m_cat_a <- feols(log_cat_a ~ treated | la_id + ym_id, data = panel,
                 cluster = ~la_id)
cat("\nCategory A (standard/owner-occ proxy):\n")
print(summary(m_cat_a))

m_cat_b_vol <- feols(log_cat_b ~ treated | la_id + ym_id, data = panel,
                     cluster = ~la_id)
cat("\nCategory B (additional/buy-to-let proxy):\n")
print(summary(m_cat_b_vol))

# Detached houses (owner-occupied proxy)
panel[, log_detached := log(n_detached + 1)]
m_detached <- feols(log_detached ~ treated | la_id + ym_id, data = panel,
                    cluster = ~la_id)
cat("\nDetached houses (owner-occ proxy):\n")
print(summary(m_detached))

# Flats (PRS proxy)
panel[, log_flat := log(n_flat + 1)]
m_flat_vol <- feols(log_flat ~ treated | la_id + ym_id, data = panel,
                    cluster = ~la_id)
cat("\nFlats (PRS proxy):\n")
print(summary(m_flat_vol))

# =============================================================================
# 8. SAVE RESULTS
# =============================================================================
cat("\n=== Saving Results ===\n")

results <- list(
  m1 = m1,           # Simple DiD
  m3 = m3,           # LA trends
  es = es,           # Event study
  m_ddd = m_ddd,     # DDD continuous
  m_ddd2 = m_ddd2,   # DDD binary
  m_catb = m_catb,   # Cat B share
  m_fh = m_fh,       # Freehold share
  m_flat = m_flat,   # Flat share
  m_new = m_new,     # New build share
  m_price = m_price, # Prices
  m_cat_a = m_cat_a, # Cat A volume (placebo)
  m_cat_b_vol = m_cat_b_vol, # Cat B volume
  m_detached = m_detached,   # Detached (placebo)
  m_flat_vol = m_flat_vol    # Flat volume
)

saveRDS(results, file.path(data_dir, "main_results.rds"))

# Save key coefficients as CSV for figures
key_results <- data.table(
  model = c("DiD (log transactions)", "DiD with LA trends",
            "DDD × PRS share", "DDD × high PRS",
            "Category B share", "Freehold share", "Flat share",
            "New-build share", "Log price",
            "Cat A volume (placebo)", "Cat B volume",
            "Detached (placebo)", "Flat volume"),
  estimate = c(coef(m1)["treated"], coef(m3)["treated"],
               coef(m_ddd)["treated:prs_share"], coef(m_ddd2)["treated:high_prs"],
               coef(m_catb)["treated"], coef(m_fh)["treated"], coef(m_flat)["treated"],
               coef(m_new)["treated"], coef(m_price)["treated"],
               coef(m_cat_a)["treated"], coef(m_cat_b_vol)["treated"],
               coef(m_detached)["treated"], coef(m_flat_vol)["treated"]),
  se = c(se(m1)["treated"], se(m3)["treated"],
         se(m_ddd)["treated:prs_share"], se(m_ddd2)["treated:high_prs"],
         se(m_catb)["treated"], se(m_fh)["treated"], se(m_flat)["treated"],
         se(m_new)["treated"], se(m_price)["treated"],
         se(m_cat_a)["treated"], se(m_cat_b_vol)["treated"],
         se(m_detached)["treated"], se(m_flat_vol)["treated"])
)

key_results[, ci_lo := estimate - 1.96 * se]
key_results[, ci_hi := estimate + 1.96 * se]
key_results[, stars := fifelse(abs(estimate/se) > 2.576, "***",
                        fifelse(abs(estimate/se) > 1.960, "**",
                          fifelse(abs(estimate/se) > 1.645, "*", "")))]

fwrite(key_results, file.path(data_dir, "key_results.csv"))
cat("\nKey results:\n")
print(key_results[, .(model, estimate = round(estimate, 4),
                       se = round(se, 4), stars)])

cat("\n=== Main analysis complete ===\n")
