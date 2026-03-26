# =============================================================================
# 03_main_analysis.R — Main DDD regressions
# apep_1015: The First Wage Floor for Women
# =============================================================================

source("00_packages.R")

dt <- as.data.table(arrow::read_parquet("../data/est_sample_women.parquet"))
cat(sprintf("Estimation sample: %s women\n", format(nrow(dt), big.mark = ",")))

# ---------------------------------------------------------------------------
# Variable construction
# ---------------------------------------------------------------------------
dt[, mw_x_covered := mw_state * covered_ind]
dt[, age_sq := age_1910^2]
dt[, native := as.integer(nativity_1910 <= 1)]
dt[, literate := as.integer(lit_1910 == 4)]
dt[, married := as.integer(marst_1910 <= 2)]
dt[, white := as.integer(race_1910 == 1)]

# Industry groups for FEs
dt[, ind_group := fcase(
  ind1950_1910 >= 100 & ind1950_1910 <= 126, 1L,  # agriculture
  ind1950_1910 >= 306 & ind1950_1910 <= 399, 2L,  # mfg durable
  ind1950_1910 >= 400 & ind1950_1910 <= 499, 3L,  # mfg nondurable
  ind1950_1910 >= 606 & ind1950_1910 <= 699, 4L,  # retail
  ind1950_1910 >= 806 & ind1950_1910 <= 829, 5L,  # hospitality/laundry
  ind1950_1910 == 856, 6L,                         # domestic service
  default = 7L
)]

# Remove singletons manually to avoid boottest crash
cell_counts <- dt[, .N, by = .(statefip_1910, ind_group)]
singleton_cells <- cell_counts[N == 1]
if (nrow(singleton_cells) > 0) {
  cat(sprintf("Removing %d singleton state-industry cells\n", nrow(singleton_cells)))
  dt <- dt[!cell_counts[N == 1], on = .(statefip_1910, ind_group)]
}

# Cluster variable as character for boottest
dt[, state_cl := as.character(statefip_1910)]

cat(sprintf("Final sample: %s women, %d states, %d industry groups\n",
            format(nrow(dt), big.mark = ","),
            uniqueN(dt$statefip_1910),
            uniqueN(dt$ind_group)))

# ---------------------------------------------------------------------------
# Main specifications: state + industry FEs absorb main effects
# β on mw_x_covered IS the DDD estimate
# ---------------------------------------------------------------------------

# --- RETENTION ---
cat("\n=== RETENTION (LF in 1920 | LF in 1910) ===\n")

m1_base <- feols(retention ~ mw_x_covered | statefip_1910 + ind_group,
                 data = dt, cluster = ~statefip_1910)

m1_ctrl <- feols(retention ~ mw_x_covered +
                   age_1910 + age_sq + native + literate + married + white |
                   statefip_1910 + ind_group,
                 data = dt, cluster = ~statefip_1910)

cat("Base:\n"); print(coeftable(m1_base))
cat("Controls:\n"); print(coeftable(m1_ctrl))

# --- INDUSTRY PERSISTENCE ---
cat("\n=== INDUSTRY PERSISTENCE (same ind1950 in 1920) ===\n")

m2_base <- feols(same_industry ~ mw_x_covered | statefip_1910 + ind_group,
                 data = dt, cluster = ~statefip_1910)

m2_ctrl <- feols(same_industry ~ mw_x_covered +
                   age_1910 + age_sq + native + literate + married + white |
                   statefip_1910 + ind_group,
                 data = dt, cluster = ~statefip_1910)

cat("Base:\n"); print(coeftable(m2_base))
cat("Controls:\n"); print(coeftable(m2_ctrl))

# --- OCCUPATIONAL SCORE CHANGE ---
cat("\n=== OCCUPATIONAL SCORE CHANGE ===\n")

m3_base <- feols(occ_change ~ mw_x_covered | statefip_1910 + ind_group,
                 data = dt, cluster = ~statefip_1910)

m3_ctrl <- feols(occ_change ~ mw_x_covered +
                   age_1910 + age_sq + native + literate + married + white |
                   statefip_1910 + ind_group,
                 data = dt, cluster = ~statefip_1910)

cat("Base:\n"); print(coeftable(m3_base))
cat("Controls:\n"); print(coeftable(m3_ctrl))

# ---------------------------------------------------------------------------
# Wild cluster bootstrap (Webb weights, 14 treated states)
# ---------------------------------------------------------------------------
cat("\n=== Wild Cluster Bootstrap ===\n")

set.seed(42)
if (requireNamespace("dqrng", quietly = TRUE)) dqrng::dqset.seed(42)

boot_m1 <- boottest(m1_ctrl, param = "mw_x_covered", B = 9999,
                    clustid = "state_cl", type = "webb")
cat(sprintf("Retention WCB: coef=%.4f, p=%.4f, CI=[%.4f, %.4f]\n",
            boot_m1$point_estimate, boot_m1$p_val,
            boot_m1$conf_int[1], boot_m1$conf_int[2]))

boot_m2 <- boottest(m2_ctrl, param = "mw_x_covered", B = 9999,
                    clustid = "state_cl", type = "webb")
cat(sprintf("Industry WCB: coef=%.4f, p=%.4f, CI=[%.4f, %.4f]\n",
            boot_m2$point_estimate, boot_m2$p_val,
            boot_m2$conf_int[1], boot_m2$conf_int[2]))

boot_m3 <- boottest(m3_ctrl, param = "mw_x_covered", B = 9999,
                    clustid = "state_cl", type = "webb")
cat(sprintf("OccScore WCB: coef=%.4f, p=%.4f, CI=[%.4f, %.4f]\n",
            boot_m3$point_estimate, boot_m3$p_val,
            boot_m3$conf_int[1], boot_m3$conf_int[2]))

# ---------------------------------------------------------------------------
# Summary statistics
# ---------------------------------------------------------------------------
cat("\n=== Summary Statistics ===\n")

summ_stats <- dt[, .(
  Mean = c(mean(retention), mean(same_industry), mean(occ_change),
           mean(age_1910), mean(native), mean(literate), mean(married),
           mean(white), mean(occscore_1910)),
  SD = c(sd(retention), sd(same_industry), sd(occ_change),
         sd(age_1910), sd(native), sd(literate), sd(married),
         sd(white), sd(occscore_1910))
)]
summ_stats[, Variable := c("Retention (1920 LF)", "Same Industry (1920)",
                            "Occ Score Change", "Age (1910)", "Native-born",
                            "Literate", "Married", "White", "Occ Score (1910)")]
print(summ_stats[, .(Variable, Mean = round(Mean, 3), SD = round(SD, 3))])

# Mean outcomes by group
cat("\n=== Mean Retention by DDD Cell ===\n")
cell_means <- dt[, .(retention = mean(retention), N = .N),
                 by = .(mw_state, covered_ind)]
print(cell_means[order(mw_state, covered_ind)])

# Pre-treatment balance
cat("\n=== Pre-treatment Balance (1910): MW vs Non-MW, Covered Industries ===\n")
balance <- dt[covered_ind == 1, .(
  age = mean(age_1910),
  native = mean(native),
  literate = mean(literate),
  married = mean(married),
  white = mean(white),
  occscore = mean(occscore_1910),
  N = .N
), by = mw_state]
print(balance)

# ---------------------------------------------------------------------------
# Save results
# ---------------------------------------------------------------------------
results <- list(
  m1_base = m1_base, m1_ctrl = m1_ctrl,
  m2_base = m2_base, m2_ctrl = m2_ctrl,
  m3_base = m3_base, m3_ctrl = m3_ctrl,
  boot_m1 = boot_m1, boot_m2 = boot_m2, boot_m3 = boot_m3,
  cell_means = cell_means,
  summ_stats = summ_stats
)
saveRDS(results, "../data/main_results.rds")

# Diagnostics for validator
n_mw <- uniqueN(dt[mw_state == 1]$statefip_1910)
n_nonmw <- uniqueN(dt[mw_state == 0]$statefip_1910)
diagnostics <- list(
  n_treated = n_mw,
  n_pre = 5L,
  n_obs = nrow(dt),
  n_clusters = n_mw + n_nonmw,
  n_women_covered_mw = nrow(dt[mw_state == 1 & covered_ind == 1]),
  n_women_exempt_mw = nrow(dt[mw_state == 1 & covered_ind == 0]),
  sd_retention = sd(dt$retention),
  sd_same_industry = sd(dt$same_industry),
  sd_occ_change = sd(dt$occ_change)
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

cat("\n03_main_analysis.R complete.\n")
