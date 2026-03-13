## 04_robustness.R — Robustness checks and pre-trend tests
## APEP-0642: Regulatory Whack-a-Mole

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

# ============================================================
# 1. Pre-trend test (event study without year FE)
# ============================================================
cat("=== Pre-trend tests ===\n")

# Event study for air: fc_id FE only, no year FE
# (year FE causes collinearity with event-time given treatment-timing structure)
df_air <- df[medium_cat == "Air"]

es_air_noyr <- feols(log_releases_w ~ i(event_time, ref = -1) | fc_id,
                     data = df_air, cluster = ~frs_id)
cat("Air event study (no year FE):\n")
print(summary(es_air_noyr))

# Pre-trend F-test: joint significance of t=-5 to t=-2
pre_coefs <- coef(es_air_noyr)[grep("event_time::-[2-5]", names(coef(es_air_noyr)))]
cat("\nPre-treatment coefficients (air):", pre_coefs, "\n")

# Wald test for pre-trends
wald_pre <- wald(es_air_noyr, "event_time::-[2-5]")
cat("Pre-trend Wald test p-value:", wald_pre$p, "\n")

# Event study for non-air (pooled)
df_nonair <- df[medium_cat != "Air"]
es_nonair_noyr <- feols(log_releases_w ~ i(event_time, ref = -1) | fcm_id,
                        data = df_nonair, cluster = ~frs_id)
cat("\nNon-air event study (no year FE):\n")
print(summary(es_nonair_noyr))

# ============================================================
# 2. Alternative clustering
# ============================================================
cat("\n=== Alternative clustering ===\n")

# Baseline: cluster at facility
m_fac <- feols(log_releases_w ~ post_air + post_nonair | fcm_id + year_f,
               data = df, cluster = ~frs_id)

# Cluster at state level
m_state <- feols(log_releases_w ~ post_air + post_nonair | fcm_id + year_f,
                 data = df, cluster = ~ST)

# Two-way cluster: facility + year
m_2way <- feols(log_releases_w ~ post_air + post_nonair | fcm_id + year_f,
                data = df, cluster = ~frs_id + YEAR)

cat("Clustering comparison:\n")
cat(sprintf("  Facility:  Post×Air = %.4f (%.4f), Post×NonAir = %.4f (%.4f)\n",
            coef(m_fac)["post_air"], se(m_fac)["post_air"],
            coef(m_fac)["post_nonair"], se(m_fac)["post_nonair"]))
cat(sprintf("  State:     Post×Air = %.4f (%.4f), Post×NonAir = %.4f (%.4f)\n",
            coef(m_state)["post_air"], se(m_state)["post_air"],
            coef(m_state)["post_nonair"], se(m_state)["post_nonair"]))
cat(sprintf("  Fac+Year:  Post×Air = %.4f (%.4f), Post×NonAir = %.4f (%.4f)\n",
            coef(m_2way)["post_air"], se(m_2way)["post_air"],
            coef(m_2way)["post_nonair"], se(m_2way)["post_nonair"]))

# ============================================================
# 3. Levels specification (not log)
# ============================================================
cat("\n=== Levels specification ===\n")

m_levels <- feols(releases_w ~ post_air + post_nonair | fcm_id + year_f,
                  data = df, cluster = ~frs_id)
cat("Levels: Post×Air =", round(coef(m_levels)["post_air"], 2),
    "  Post×NonAir =", round(coef(m_levels)["post_nonair"], 2), "\n")

# Inverse hyperbolic sine (handles zeros without +1 assumption)
df[, ihs_releases := log(releases + sqrt(releases^2 + 1))]
m_ihs <- feols(ihs_releases ~ post_air + post_nonair | fcm_id + year_f,
               data = df, cluster = ~frs_id)
cat("IHS: Post×Air =", round(coef(m_ihs)["post_air"], 4),
    "  Post×NonAir =", round(coef(m_ihs)["post_nonair"], 4), "\n")

# ============================================================
# 4. Narrower event window (±3 years)
# ============================================================
cat("\n=== Narrower event window (±3) ===\n")

df_narrow <- df[event_time >= -3 & event_time <= 3]
m_narrow <- feols(log_releases_w ~ post_air + post_nonair | fcm_id + year_f,
                  data = df_narrow, cluster = ~frs_id)
cat("Narrow window: Post×Air =", round(coef(m_narrow)["post_air"], 4),
    "  SE =", round(se(m_narrow)["post_air"], 4), "\n")
cat("              Post×NonAir =", round(coef(m_narrow)["post_nonair"], 4),
    "  SE =", round(se(m_narrow)["post_nonair"], 4), "\n")

# ============================================================
# 5. Exclude 2020 (COVID disruption)
# ============================================================
cat("\n=== Excluding 2020 (COVID) ===\n")

df_nocovid <- df[YEAR != 2020]
m_nocovid <- feols(log_releases_w ~ post_air + post_nonair | fcm_id + year_f,
                   data = df_nocovid, cluster = ~frs_id)
cat("No COVID: Post×Air =", round(coef(m_nocovid)["post_air"], 4),
    "  SE =", round(se(m_nocovid)["post_air"], 4), "\n")
cat("          Post×NonAir =", round(coef(m_nocovid)["post_nonair"], 4),
    "  SE =", round(se(m_nocovid)["post_nonair"], 4), "\n")

# ============================================================
# 6. Placebo test: CWA (water) inspections → air releases
# ============================================================
cat("\n=== Placebo: CWA inspections ===\n")

# Load full panel including never-inspected facilities
panel_full <- fread(file.path(data_dir, "panel_long_full.csv"))
# NOTE: For a proper CWA placebo, we'd need ICIS-NPDES data (water inspections)
# For now, test: effect of inspection on ALWAYS-REPORTED chemicals
# (chemicals that report consistently across all media)

# Alternative placebo: Effect on facilities in states with
# high vs low enforcement intensity
state_intensity <- df[, .(n_insp = sum(inspected)),
                      by = ST][order(-n_insp)]
high_enforcement <- state_intensity[1:15, ST]

df_high <- df[ST %in% high_enforcement]
df_low <- df[!ST %in% high_enforcement]

m_high <- feols(log_releases_w ~ post_air + post_nonair | fcm_id + year_f,
                data = df_high, cluster = ~frs_id)
m_low <- feols(log_releases_w ~ post_air + post_nonair | fcm_id + year_f,
               data = df_low, cluster = ~frs_id)

cat("High-enforcement states:\n")
cat("  Post×Air =", round(coef(m_high)["post_air"], 4),
    "  Post×NonAir =", round(coef(m_high)["post_nonair"], 4), "\n")
cat("Low-enforcement states:\n")
cat("  Post×Air =", round(coef(m_low)["post_air"], 4),
    "  Post×NonAir =", round(coef(m_low)["post_nonair"], 4), "\n")

# ============================================================
# 7. Industry heterogeneity
# ============================================================
cat("\n=== Industry heterogeneity ===\n")

# Get 2-digit NAICS
df[, naics2 := substr(as.character(naics), 1, 2)]

# Top industries by number of facility-chemicals
top_ind <- df[, .(n = uniqueN(fc_id)), by = naics2][order(-n)][1:5]
cat("Top industries:\n")
print(top_ind)

for (n2 in top_ind$naics2) {
  d <- df[naics2 == n2]
  if (nrow(d) > 1000 && uniqueN(d$frs_id) >= 30) {
    mod <- feols(log_releases_w ~ post_air + post_nonair | fcm_id + year_f,
                 data = d, cluster = ~frs_id)
    cat(sprintf("  NAICS %s: PostAir=%.4f (%.4f) PostNonAir=%.4f (%.4f) N=%d\n",
                n2, coef(mod)["post_air"], se(mod)["post_air"],
                coef(mod)["post_nonair"], se(mod)["post_nonair"], nrow(d)))
  }
}

# ============================================================
# 8. Save robustness results
# ============================================================
saveRDS(list(
  es_air_noyr = es_air_noyr,
  es_nonair_noyr = es_nonair_noyr,
  m_fac = m_fac,
  m_state = m_state,
  m_2way = m_2way,
  m_levels = m_levels,
  m_ihs = m_ihs,
  m_narrow = m_narrow,
  m_nocovid = m_nocovid,
  m_high = m_high,
  m_low = m_low
), file.path(data_dir, "robustness_models.rds"))

cat("\n=== Robustness complete ===\n")
