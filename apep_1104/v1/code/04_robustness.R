# ── 04_robustness.R ────────────────────────────────────────────────
# Robustness checks for the 14th FC paper
# ───────────────────────────────────────────────────────────────────
source("code/00_packages.R")

panel <- fread("data/district_panel_clean.csv")
load("data/main_results.RData")

# ── 1. Heterogeneity by baseline economic activity ────────────────
cat("\n=== Heterogeneity: Baseline Light Quartiles ===\n")

# Split by baseline nightlight quartile
het_q1 <- feols(log_light ~ windfall_pc_z:post | district_id + year,
                data = panel[light_quartile == "Q1_darkest"],
                cluster = ~pc11_state_id)
het_q4 <- feols(log_light ~ windfall_pc_z:post | district_id + year,
                data = panel[light_quartile == "Q4_brightest"],
                cluster = ~pc11_state_id)

cat("Q1 (darkest districts):\n")
print(coeftable(het_q1))
cat("Q4 (brightest districts):\n")
print(coeftable(het_q4))

# ── 2. Leave-one-state-out sensitivity ────────────────────────────
cat("\n=== Leave-One-State-Out ===\n")
states <- unique(panel$pc11_state_id)
loo_results <- data.table(
  state_dropped = character(),
  coef = numeric(),
  se = numeric()
)

for (s in states) {
  m_loo <- feols(log_light ~ windfall_pc_z:post | district_id + year,
                 data = panel[pc11_state_id != s],
                 cluster = ~pc11_state_id)
  loo_results <- rbind(loo_results, data.table(
    state_dropped = s,
    coef = coef(m_loo)["windfall_pc_z:post"],
    se = se(m_loo)["windfall_pc_z:post"]
  ))
}

cat(sprintf("LOO range: [%.4f, %.4f] (main: %.4f)\n",
            min(loo_results$coef), max(loo_results$coef),
            coef(m1)["windfall_pc_z:post"]))

# ── 3. Placebo: 13th FC transition (2010-2015 using DMSP) ────────
cat("\n=== 13th FC Placebo (DMSP 2008-2013) ===\n")

# Load DMSP district-level data
shrug_dir <- normalizePath(file.path(getwd(), "..", "..", "..", "data", "india_shrug"))
dist_key <- fread(file.path(shrug_dir, "shrid_pc11dist_key.csv"))

dmsp <- fread(file.path(shrug_dir, "dmsp_shrid.csv"),
              select = c("shrid2", "dmsp_total_light_cal", "dmsp_num_cells", "year"))
dmsp <- merge(dmsp, dist_key, by = "shrid2", all.x = FALSE)

dmsp_dist <- dmsp[year %in% 2008:2013, .(
  total_light = sum(dmsp_total_light_cal, na.rm = TRUE),
  n_villages = .N
), by = .(pc11_state_id, pc11_district_id, year)]

rm(dmsp); gc()

dmsp_dist[, district_id := paste0(pc11_state_id, "_", pc11_district_id)]
dmsp_dist[, log_light := log(total_light + 1)]

# Merge 14th FC windfall (used as treatment in the placebo era)
fc_shares <- fread("data/fc14_state_shares.csv")
dmsp_dist <- merge(dmsp_dist, fc_shares[, .(pc11_state_id, windfall_pc_z)],
                   by = "pc11_state_id")

# Placebo treatment: use 2011 as fake cutoff (13th FC midpoint)
dmsp_dist[, post_placebo := as.integer(year >= 2011)]
dmsp_dist <- dmsp_dist[pc11_state_id != "36"]  # Drop Telangana

# Keep balanced
d_counts <- dmsp_dist[, .(n = uniqueN(year)), by = district_id]
dmsp_dist <- dmsp_dist[district_id %in% d_counts[n == 6, district_id]]

m_placebo <- feols(log_light ~ windfall_pc_z:post_placebo | district_id + year,
                   data = dmsp_dist, cluster = ~pc11_state_id)
cat("Placebo (DMSP 2008-2013, fake break at 2011):\n")
print(coeftable(m_placebo))

# ── 4. Alternative clustering ─────────────────────────────────────
cat("\n=== Alternative Clustering ===\n")

# Two-way clustering: state × year
m_twoway <- feols(log_light ~ windfall_pc_z:post | district_id + year,
                  data = panel, cluster = ~pc11_state_id + year)
cat("Two-way cluster (state × year):\n")
print(coeftable(m_twoway))

# ── 5. Excluding demonetization period (Nov 2016 - Mar 2017) ─────
cat("\n=== Excluding Demonetization Year ===\n")
m_no_demon <- feols(log_light ~ windfall_pc_z:post | district_id + year,
                    data = panel[year != 2017],
                    cluster = ~pc11_state_id)
cat("Excluding 2017:\n")
print(coeftable(m_no_demon))

# ── 6. VIIRS-only specification (2012-2023) ───────────────────────
cat("\n=== VIIRS-Only (2012-2023) ===\n")
m_viirs_only <- feols(log_light ~ windfall_pc_z:post | district_id + year,
                      data = panel[year >= 2012],
                      cluster = ~pc11_state_id)
cat("VIIRS-only (no sensor transition):\n")
print(coeftable(m_viirs_only))

# VIIRS-only with state trends
m_viirs_trends <- feols(log_light ~ windfall_pc_z:post | district_id + year +
                          pc11_state_id[as.numeric(year)],
                        data = panel[year >= 2012],
                        cluster = ~pc11_state_id)
cat("VIIRS-only + state trends:\n")
print(coeftable(m_viirs_trends))

# ── 7. Save robustness results ───────────────────────────────────
save(het_q1, het_q4, loo_results, m_placebo, m_twoway, m_no_demon,
     m_viirs_only, m_viirs_trends,
     file = "data/robustness_results.RData")
cat("\nRobustness results saved.\n")
