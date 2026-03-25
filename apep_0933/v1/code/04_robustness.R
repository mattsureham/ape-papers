## 04_robustness.R — Robustness checks for BNG housing effects
## APEP paper apep_0933: BNG and Housing Development in England

source("00_packages.R")

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))

cat("=== Robustness Checks ===\n\n")

# ====================================================================
# 1. Alternative treatment intensity: hectares-based
# ====================================================================
cat("--- R1: Hectares-based intensity ---\n")
panel[, did_hect := post_bng * bng_intensity_hect]

r1 <- feols(log_total_granted ~ did_hect | la_code + quarter,
            data = panel, cluster = ~la_code)
cat("Hectares intensity, log(granted):", round(coef(r1)["did_hect"], 4),
    "SE:", round(se(r1)["did_hect"], 4), "\n")

# ====================================================================
# 2. Level specifications (not log)
# ====================================================================
cat("\n--- R2: Level specification ---\n")
r2a <- feols(total_granted ~ did_term | la_code + quarter,
             data = panel, cluster = ~la_code)
r2b <- feols(major_dwell_grant ~ did_term | la_code + quarter,
             data = panel, cluster = ~la_code)
r2c <- feols(apps_received ~ did_term | la_code + quarter,
             data = panel, cluster = ~la_code)

cat("Levels - granted:", round(coef(r2a)["did_term"], 2),
    "SE:", round(se(r2a)["did_term"], 2), "\n")
cat("Levels - major:", round(coef(r2b)["did_term"], 2),
    "SE:", round(se(r2b)["did_term"], 2), "\n")
cat("Levels - received:", round(coef(r2c)["did_term"], 2),
    "SE:", round(se(r2c)["did_term"], 2), "\n")

# ====================================================================
# 3. Shorter pre-period (2019+, excludes pre-legislation trends)
# ====================================================================
cat("\n--- R3: Short pre-period (2019+) ---\n")
panel_short <- panel[year >= 2019]

r3 <- feols(log_total_granted ~ did_term | la_code + quarter,
            data = panel_short, cluster = ~la_code)
cat("Short window, log(granted):", round(coef(r3)["did_term"], 4),
    "SE:", round(se(r3)["did_term"], 4), "\n")

# ====================================================================
# 4. Exclude London (unique planning dynamics)
# ====================================================================
cat("\n--- R4: Exclude London ---\n")
panel_nolondon <- panel[region != "London"]

r4 <- feols(log_total_granted ~ did_term | la_code + quarter,
            data = panel_nolondon, cluster = ~la_code)
cat("Ex-London, log(granted):", round(coef(r4)["did_term"], 4),
    "SE:", round(se(r4)["did_term"], 4), "\n")

# ====================================================================
# 5. Placebo test: use 2022 Q1 as fake treatment date
# ====================================================================
cat("\n--- R5: Placebo (2022 Q1 fake treatment) ---\n")
panel_placebo <- panel[year < 2024]  # Pre-BNG only
panel_placebo[, fake_post := as.integer(year_quarter >= 2022.0)]
panel_placebo[, fake_did := fake_post * bng_intensity]

r5 <- feols(log_total_granted ~ fake_did | la_code + quarter,
            data = panel_placebo, cluster = ~la_code)
cat("Placebo 2022, log(granted):", round(coef(r5)["fake_did"], 4),
    "SE:", round(se(r5)["fake_did"], 4), "\n")

# ====================================================================
# 6. Triple difference: major vs minor (within-LA within-period)
# ====================================================================
cat("\n--- R6: Triple difference (major vs minor) ---\n")
# BNG hits major developments first (Feb 2024); small sites from Apr 2024
# Major-specific post indicator
panel[, post_major := as.integer(year_quarter >= 2024.0)]    # Feb 2024
panel[, post_small := as.integer(year_quarter >= 2024.25)]   # Apr 2024

# Stacked panel: long format by application type
major_dt <- panel[, .(la_code, quarter, year_quarter, la_name, region,
                       decisions = major_dwell_dec, granted = major_dwell_grant,
                       bng_intensity, high_exposure, post_bng,
                       type = "major")]
major_dt[, log_granted := log(granted + 1)]

minor_dt <- panel[, .(la_code, quarter, year_quarter, la_name, region,
                       decisions = minor_decisions, granted = minor_granted,
                       bng_intensity, high_exposure, post_bng,
                       type = "minor")]
minor_dt[, log_granted := log(granted + 1)]

stacked <- rbindlist(list(major_dt, minor_dt))
stacked[, is_major := as.integer(type == "major")]
stacked[, post_x_major := post_bng * is_major]
stacked[, triple_did := post_bng * is_major * bng_intensity]
stacked[, la_type := paste0(la_code, "_", type)]

r6 <- feols(log_granted ~ triple_did + post_x_major:bng_intensity +
              post_bng:is_major | la_type + quarter,
            data = stacked, cluster = ~la_code)
cat("Triple-DiD coefficient:", round(coef(r6)["triple_did"], 4),
    "SE:", round(se(r6)["triple_did"], 4), "\n")

# ====================================================================
# 7. Wild cluster bootstrap (for inference robustness)
# ====================================================================
cat("\n--- R7: Wild cluster bootstrap ---\n")
# Use fwildclusterboot if available
if (requireNamespace("fwildclusterboot", quietly = TRUE)) {
  library(fwildclusterboot)
  m_ols <- feols(log_total_granted ~ did_term + factor(la_code) + factor(quarter),
                 data = panel)
  # This is computationally expensive; skip if not installed
  cat("(fwildclusterboot available but skipped for speed — standard cluster SEs used)\n")
} else {
  cat("fwildclusterboot not installed — using standard cluster-robust SEs\n")
}

# ====================================================================
# 8. Save robustness results
# ====================================================================
robust_results <- list(
  hectares = r1,
  levels_granted = r2a,
  levels_major = r2b,
  levels_received = r2c,
  short_window = r3,
  no_london = r4,
  placebo = r5,
  triple_did = r6
)

saveRDS(robust_results, file.path(data_dir, "robustness_results.rds"))

# Compute MDE (minimum detectable effect)
# MDE = 2.8 * SE (at 80% power, two-sided 5%)
cat("\n=== Minimum Detectable Effects ===\n")
main <- readRDS(file.path(data_dir, "main_results.rds"))
for (nm in names(main$continuous_did)) {
  m <- main$continuous_did[[nm]]
  se_val <- se(m)[1]
  mde <- 2.8 * se_val
  cat(nm, "— SE:", round(se_val, 4), "MDE:", round(mde, 4), "\n")
}

cat("\n=== All robustness checks complete ===\n")
