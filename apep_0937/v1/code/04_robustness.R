# 04_robustness.R — Robustness checks
# apep_0937: Grenfell fire and fire safety industry formation

source("00_packages.R")

data_dir <- "../data/"
tables_dir <- "../tables/"

panel <- fread(file.path(data_dir, "panel.csv"))
panel[, inc_ym := as.Date(inc_ym)]
panel[, la_code := as.factor(la_code)]

cat("Panel loaded:", nrow(panel), "obs\n")

# ===========================================================================
# 1. Placebo dates: pretend Grenfell happened in 2013 and 2015
# ===========================================================================
cat("\n=== Placebo Date Tests ===\n")

for (placebo_year in c(2013, 2015)) {
  placebo_date <- as.Date(paste0(placebo_year, "-06-01"))
  panel_sub <- panel[inc_ym >= as.Date(paste0(placebo_year - 5, "-01-01")) &
                       inc_ym < as.Date(paste0(placebo_year + 2, "-07-01"))]
  panel_sub[, post_placebo := as.integer(inc_ym >= placebo_date)]
  panel_sub[, treat_placebo := flat_share * post_placebo]

  m_pl <- feols(fire_incorp ~ treat_placebo | la_code + inc_ym,
                data = panel_sub, cluster = ~la_code)
  cat(sprintf("  Placebo %d: β = %.4f (SE = %.4f, p = %.3f)\n",
              placebo_year, coef(m_pl)["treat_placebo"],
              se(m_pl)["treat_placebo"], pvalue(m_pl)["treat_placebo"]))
}

# ===========================================================================
# 2. Alternative treatment intensity: top-quartile vs bottom-quartile LAs
# ===========================================================================
cat("\n=== Binary Treatment (Top vs Bottom Quartile) ===\n")

q75 <- quantile(panel$flat_share, 0.75, na.rm = TRUE)
q25 <- quantile(panel$flat_share, 0.25, na.rm = TRUE)

panel[, high_flat := as.integer(flat_share >= q75)]
panel[, low_flat := as.integer(flat_share <= q25)]

panel_binary <- panel[high_flat == 1 | low_flat == 1]
panel_binary[, treated := high_flat]
panel_binary[, binary_treat := treated * post_grenfell]

m_binary <- feols(fire_incorp ~ binary_treat | la_code + inc_ym,
                  data = panel_binary, cluster = ~la_code)

cat("  β (HighFlat × Post):", round(coef(m_binary)["binary_treat"], 4), "\n")
cat("  SE:", round(se(m_binary)["binary_treat"], 4), "\n")
cat("  p-value:", round(pvalue(m_binary)["binary_treat"], 4), "\n")
cat("  N:", nobs(m_binary), "\n")

# ===========================================================================
# 3. Triple-difference: fire safety vs control SICs
# ===========================================================================
cat("\n=== Triple Difference (Fire vs Control SICs) ===\n")

# Stack fire and control outcomes
panel_long <- rbind(
  panel[, .(la_code, inc_ym, incorp = fire_incorp, sic_group = "fire",
            flat_share, post_grenfell, treat_x_post)],
  panel[, .(la_code, inc_ym, incorp = control_incorp, sic_group = "control",
            flat_share, post_grenfell, treat_x_post)]
)
panel_long[, fire := as.integer(sic_group == "fire")]
panel_long[, triple := flat_share * post_grenfell * fire]
panel_long[, fire_x_post := fire * post_grenfell]
panel_long[, flat_x_fire := flat_share * fire]
panel_long[, la_sic := paste0(la_code, "_", sic_group)]

m_ddd <- feols(incorp ~ triple + fire_x_post + flat_x_fire + treat_x_post |
                 la_sic + inc_ym,
               data = panel_long, cluster = ~la_code)

cat("  β (FlatShare × Post × Fire):", round(coef(m_ddd)["triple"], 4), "\n")
cat("  SE:", round(se(m_ddd)["triple"], 4), "\n")
cat("  p-value:", round(pvalue(m_ddd)["triple"], 4), "\n")

# ===========================================================================
# 4. Leave-one-out: drop London boroughs
# ===========================================================================
cat("\n=== Leave-One-Out: Excluding London ===\n")

# London boroughs have LA codes starting with E09
panel_no_london <- panel[!grepl("^E09", la_code)]

m_no_london <- feols(fire_incorp ~ treat_x_post | la_code + inc_ym,
                     data = panel_no_london, cluster = ~la_code)

cat("  β (excl London):", round(coef(m_no_london)["treat_x_post"], 4), "\n")
cat("  SE:", round(se(m_no_london)["treat_x_post"], 4), "\n")
cat("  N:", nobs(m_no_london), "(dropped",
    nobs(feols(fire_incorp ~ treat_x_post | la_code + inc_ym,
               data = panel, cluster = ~la_code)) - nobs(m_no_london), "London obs)\n")

# ===========================================================================
# 5. Quarterly aggregation (reduces noise)
# ===========================================================================
cat("\n=== Quarterly Aggregation ===\n")

panel[, yq_date := as.Date(paste0(year, "-", sprintf("%02d", (quarter(inc_ym) - 1) * 3 + 1), "-01"))]

panel_q <- panel[, .(
  fire_incorp = sum(fire_incorp),
  control_incorp = sum(control_incorp),
  flat_share = first(flat_share),
  post_grenfell = max(post_grenfell)
), by = .(la_code, yq_date)]

panel_q[, treat_x_post := flat_share * post_grenfell]

m_quarterly <- feols(fire_incorp ~ treat_x_post | la_code + yq_date,
                     data = panel_q, cluster = ~la_code)

cat("  β (quarterly):", round(coef(m_quarterly)["treat_x_post"], 4), "\n")
cat("  SE:", round(se(m_quarterly)["treat_x_post"], 4), "\n")

# ===========================================================================
# 6. Wild cluster bootstrap (for inference robustness)
# ===========================================================================
cat("\n=== Wild Cluster Bootstrap ===\n")

# Use the main model with boottest from fwildclusterboot if available
if (requireNamespace("fwildclusterboot", quietly = TRUE)) {
  library(fwildclusterboot)
  boot_result <- boottest(
    feols(fire_incorp ~ treat_x_post | la_code + inc_ym, data = panel),
    param = "treat_x_post",
    clustid = "la_code",
    B = 999,
    type = "webb"
  )
  cat("  Bootstrap p-value:", round(boot_result$p_val, 4), "\n")
  cat("  Bootstrap 95% CI: [", round(boot_result$conf_int[1], 4), ",",
      round(boot_result$conf_int[2], 4), "]\n")
} else {
  cat("  fwildclusterboot not available; skipping bootstrap.\n")
  cat("  Install with: install.packages('fwildclusterboot')\n")
}

# ===========================================================================
# 7. Save robustness results
# ===========================================================================
robustness <- list(
  placebo_2013_coef = coef(feols(fire_incorp ~ I(flat_share * as.integer(inc_ym >= "2013-06-01")) |
    la_code + inc_ym, data = panel[inc_ym >= "2008-01-01" & inc_ym < "2015-06-01"],
    cluster = ~la_code))[[1]],
  placebo_2015_coef = coef(feols(fire_incorp ~ I(flat_share * as.integer(inc_ym >= "2015-06-01")) |
    la_code + inc_ym, data = panel[inc_ym >= "2010-01-01" & inc_ym < "2017-06-01"],
    cluster = ~la_code))[[1]],
  binary_coef = as.numeric(coef(m_binary)["binary_treat"]),
  binary_se = as.numeric(se(m_binary)["binary_treat"]),
  ddd_coef = as.numeric(coef(m_ddd)["triple"]),
  ddd_se = as.numeric(se(m_ddd)["triple"]),
  no_london_coef = as.numeric(coef(m_no_london)["treat_x_post"]),
  no_london_se = as.numeric(se(m_no_london)["treat_x_post"]),
  quarterly_coef = as.numeric(coef(m_quarterly)["treat_x_post"]),
  quarterly_se = as.numeric(se(m_quarterly)["treat_x_post"])
)

save(m_binary, m_ddd, m_no_london, m_quarterly,
     file = file.path(data_dir, "robustness_results.RData"))

jsonlite::write_json(robustness, file.path(data_dir, "robustness.json"),
                     auto_unbox = TRUE, pretty = TRUE)
cat("\nRobustness results saved.\n")
