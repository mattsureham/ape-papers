## 04_robustness.R — Robustness checks and placebo tests
## apep_0649: Clean Air Zone property values

source("00_packages.R")
setDTthreads(4)

DATA_DIR <- "../data"

df <- fread(file.path(DATA_DIR, "analysis_panel.csv"))
df[, date := as.Date(date)]
df[, launch := as.Date(launch)]

# ═══════════════════════════════════════════════════════════════
# 1) BANDWIDTH SENSITIVITY
# ═══════════════════════════════════════════════════════════════

cat("=== BANDWIDTH SENSITIVITY ===\n")

bandwidths <- c(250, 500, 750, 1000, 1500)
bw_results <- list()

for (bw in bandwidths) {
  d <- df[abs(signed_dist_m) <= bw]
  if (nrow(d) > 100) {
    m <- feols(log_price ~ inside_post + inside + post +
                 signed_dist_m + I(signed_dist_m * inside) +
                 I(signed_dist_m * post) + I(signed_dist_m * inside_post) +
                 i(prop_type) |
                 city + year_quarter,
               data = d, cluster = ~postcode)
    bw_results[[as.character(bw)]] <- m
    cat(sprintf("  BW=%4d: N=%6d, β=%.4f (SE=%.4f)\n",
                bw, nrow(d), coef(m)["inside_post"], se(m)["inside_post"]))
  }
}

# ═══════════════════════════════════════════════════════════════
# 2) PRE-PERIOD PLACEBO (FALSIFICATION TEST)
# ═══════════════════════════════════════════════════════════════

cat("\n=== PRE-PERIOD PLACEBO ===\n")
cat("Testing: is there a discontinuity at the CAZ boundary BEFORE implementation?\n")

# Use only pre-treatment data, create a fake "post" at midpoint of pre-period
df_pre <- df[post == 0 & abs(signed_dist_m) <= 500]

if (nrow(df_pre) > 100) {
  # Create placebo post: 1 year before launch for each city
  df_pre[, placebo_post := as.integer(date >= (launch - 365))]
  df_pre[, placebo_inside_post := inside * placebo_post]

  m_pre <- feols(log_price ~ placebo_inside_post + inside + placebo_post +
                   signed_dist_m + I(signed_dist_m * inside) +
                   i(prop_type) |
                   city + year_quarter,
                 data = df_pre, cluster = ~postcode)
  cat(sprintf("  Pre-period placebo (500m): β=%.4f (SE=%.4f)\n",
              coef(m_pre)["placebo_inside_post"], se(m_pre)["placebo_inside_post"]))
} else {
  m_pre <- NULL
  cat("  Insufficient pre-period observations\n")
}

# ═══════════════════════════════════════════════════════════════
# 3) PLACEBO BOUNDARIES (SHIFTED)
# ═══════════════════════════════════════════════════════════════

cat("\n=== PLACEBO BOUNDARIES ===\n")

# Shift the boundary 500m outward: properties now 500-1000m from true boundary
# are "inside" the placebo zone
df500_true <- df[abs(signed_dist_m) <= 1500]  # Wider range for shifted boundary

# Shifted boundary: distance_shifted = signed_dist_m + 500
# Properties at +500 to +1000 are "outside" the true CAZ but "inside" the shifted one
df500_true[, signed_dist_shifted := signed_dist_m + 500]
df500_true[, inside_shifted := as.integer(signed_dist_shifted >= 0)]
df500_true[, inside_post_shifted := inside_shifted * post]

df_placebo_bw <- df500_true[abs(signed_dist_shifted) <= 500]

if (nrow(df_placebo_bw) > 100) {
  m_shifted <- feols(log_price ~ inside_post_shifted + inside_shifted + post +
                       signed_dist_shifted + I(signed_dist_shifted * inside_shifted) +
                       i(prop_type) |
                       city + year_quarter,
                     data = df_placebo_bw, cluster = ~postcode)
  cat(sprintf("  Shifted boundary (+500m): β=%.4f (SE=%.4f)\n",
              coef(m_shifted)["inside_post_shifted"], se(m_shifted)["inside_post_shifted"]))
} else {
  m_shifted <- NULL
  cat("  Insufficient observations for shifted boundary\n")
}

# ═══════════════════════════════════════════════════════════════
# 4) DONUT HOLE (EXCLUDE ±50m)
# ═══════════════════════════════════════════════════════════════

cat("\n=== DONUT HOLE ===\n")

df_donut <- df[abs(signed_dist_m) <= 500 & abs(signed_dist_m) >= 50]
if (nrow(df_donut) > 100) {
  m_donut <- feols(log_price ~ inside_post + inside + post +
                     signed_dist_m + I(signed_dist_m * inside) +
                     I(signed_dist_m * post) + I(signed_dist_m * inside_post) +
                     i(prop_type) |
                     city + year_quarter,
                   data = df_donut, cluster = ~postcode)
  cat(sprintf("  Donut (50-500m): N=%d, β=%.4f (SE=%.4f)\n",
              nrow(df_donut), coef(m_donut)["inside_post"], se(m_donut)["inside_post"]))
} else {
  m_donut <- NULL
  cat("  Insufficient observations\n")
}

# ═══════════════════════════════════════════════════════════════
# 5) PROPERTY TYPE HETEROGENEITY
# ═══════════════════════════════════════════════════════════════

cat("\n=== PROPERTY TYPE HETEROGENEITY ===\n")

df500 <- df[abs(signed_dist_m) <= 500]

prop_results <- list()
for (ptype in c("F", "T", "S", "D")) {
  d <- df500[prop_type == ptype]
  label <- c(F = "Flats", T = "Terraced", S = "Semi-detached", D = "Detached")[ptype]
  if (nrow(d) > 100) {
    m <- feols(log_price ~ inside_post + inside + post +
                 signed_dist_m + I(signed_dist_m * inside) |
                 city + year_quarter,
               data = d, cluster = ~postcode)
    prop_results[[ptype]] <- m
    cat(sprintf("  %s (N=%d): β=%.4f (SE=%.4f)\n",
                label, nrow(d), coef(m)["inside_post"], se(m)["inside_post"]))
  } else {
    cat(sprintf("  %s: too few observations (%d)\n", label, nrow(d)))
  }
}

# ═══════════════════════════════════════════════════════════════
# 6) SAVE ALL ROBUSTNESS RESULTS
# ═══════════════════════════════════════════════════════════════

save(bw_results, m_pre, m_shifted, m_donut, prop_results,
     file = file.path(DATA_DIR, "robustness_results.RData"))

cat("\n=== Robustness analysis complete ===\n")
