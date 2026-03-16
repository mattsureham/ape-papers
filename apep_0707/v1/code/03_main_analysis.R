# 03_main_analysis.R — Main analysis: MEES effect on F+G shares
# Design: Cross-LA DiD exploiting rental intensity variation

source("00_packages.R")

data_dir <- "../data"
panel <- fread(file.path(data_dir, "panel_la_quarter.csv"))
eng_ts <- fread(file.path(data_dir, "england_timeseries.csv"))

# ============================================================================
# PART 1: Descriptive — England-level time series
# ============================================================================

cat("=== England F+G share time series ===\n")

# Key dates:
# 2015 Q1: MEES regulations announced
# 2018 Q2: MEES enforced for new tenancies
# 2020 Q2: MEES extended to all existing tenancies

eng_ts[, period := fcase(
  year < 2015, "Pre-announcement",
  year >= 2015 & (year < 2018 | (year == 2018 & q <= 1)), "Anticipatory",
  year >= 2018 & (year < 2020 | (year == 2020 & q <= 1)), "New tenancies",
  default = "All tenancies"
)]

period_means <- eng_ts[, .(
  mean_fg = mean(fg_share, na.rm = TRUE),
  mean_f = mean(f_share, na.rm = TRUE),
  mean_g = mean(g_share, na.rm = TRUE),
  n_quarters = .N
), by = period]

cat("F+G share by MEES period:\n")
print(period_means)

# ============================================================================
# PART 2: Main DiD — F+G share ~ PostMEES × RentalIntensity
# ============================================================================

cat("\n=== Main DiD specification ===\n")

# The identification strategy:
# - MEES regulates RENTAL properties only (score < 39 cannot be let)
# - LAs with higher pre-MEES rental share should see larger F+G declines
# - This is a continuous treatment intensity design
# - Treatment: pre_rental_share × post_mees
# - Outcome: fg_share (share of F+G rated EPCs)

# Ensure panel is balanced and well-defined
panel <- panel[!is.na(fg_share) & !is.na(pre_rental_share) & total_rated >= 10]
cat("Panel after filters:", nrow(panel), "obs\n")

# Main specification: TWFE with LA and quarter FE
# Cluster SE at LA level (324 clusters)
m1 <- feols(
  fg_share ~ post_mees:pre_rental_share | la_code + quarter,
  data = panel,
  cluster = ~la_code
)

cat("\nModel 1: TWFE with continuous treatment intensity\n")
summary(m1)

# Model 2: Include post_mees main effect (absorbed by time FE, but explicit)
# With separate pre/post rental share effects
panel[, post_announce := as.integer(year >= 2015)]
panel[, post_new := as.integer(year > 2018 | (year == 2018 & q >= 2))]
panel[, post_all := as.integer(year > 2020 | (year == 2020 & q >= 2))]

m2 <- feols(
  fg_share ~ post_announce:pre_rental_share +
    post_new:pre_rental_share +
    post_all:pre_rental_share | la_code + quarter,
  data = panel,
  cluster = ~la_code
)

cat("\nModel 2: Staggered MEES phases × rental intensity\n")
summary(m2)

# Model 3: Tercile-based (for robustness and readability)
m3 <- feols(
  fg_share ~ i(rental_tercile, post_mees, ref = "Low") | la_code + quarter,
  data = panel,
  cluster = ~la_code
)

cat("\nModel 3: Tercile-based DiD\n")
summary(m3)

# ============================================================================
# PART 3: Event study — dynamic effects by year
# ============================================================================

cat("\n=== Event study ===\n")

# Create year relative to MEES implementation (2018)
panel[, event_year := year - 2018]

# Cap at ±7 years
panel[, event_year_c := pmax(pmin(event_year, 7), -7)]

# Event study with continuous treatment intensity
m_event <- feols(
  fg_share ~ i(event_year_c, pre_rental_share, ref = -1) | la_code + quarter,
  data = panel,
  cluster = ~la_code
)

cat("\nEvent study coefficients:\n")
summary(m_event)

# ============================================================================
# PART 4: Magnitude interpretation
# ============================================================================

cat("\n=== Magnitude interpretation ===\n")

# Mean F+G share pre-MEES
pre_fg <- panel[post_mees == 0, mean(fg_share, na.rm = TRUE)]
post_fg <- panel[post_mees == 1, mean(fg_share, na.rm = TRUE)]
cat("Mean F+G share pre-MEES:", round(pre_fg, 4), "\n")
cat("Mean F+G share post-MEES:", round(post_fg, 4), "\n")
cat("Raw decline:", round(pre_fg - post_fg, 4), "\n")

# Main coefficient interpretation
coef_main <- coef(m1)[[1]]
se_main <- se(m1)[[1]]
cat("\nMain DiD coefficient:", round(coef_main, 4), "\n")
cat("SE:", round(se_main, 4), "\n")

# At mean rental share:
mean_rental <- panel[, mean(pre_rental_share, na.rm = TRUE)]
cat("Mean pre-MEES rental share:", round(mean_rental, 3), "\n")
cat("Implied effect at mean rental share:", round(coef_main * mean_rental, 4), "\n")
cat("As % of pre-MEES F+G share:", round(coef_main * mean_rental / pre_fg * 100, 1), "%\n")

# At high vs low tercile means
high_mean <- panel[rental_tercile == "High", mean(pre_rental_share, na.rm = TRUE)]
low_mean <- panel[rental_tercile == "Low", mean(pre_rental_share, na.rm = TRUE)]
cat("\nHigh rental tercile mean:", round(high_mean, 3), "\n")
cat("Low rental tercile mean:", round(low_mean, 3), "\n")
cat("Differential effect (high - low):", round(coef_main * (high_mean - low_mean), 4), "\n")

# ============================================================================
# PART 5: Save diagnostics
# ============================================================================

diagnostics <- list(
  n_treated = sum(panel$rental_tercile == "High" & panel$post_mees == 1),
  n_pre = uniqueN(panel[post_mees == 0]$quarter),
  n_obs = nrow(panel),
  n_la = uniqueN(panel$la_code),
  n_quarters = uniqueN(panel$quarter),
  pre_fg_mean = pre_fg,
  post_fg_mean = post_fg,
  coef_main = coef_main,
  se_main = se_main,
  mean_rental_share = mean_rental
)

jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                     auto_unbox = TRUE, pretty = TRUE)

cat("\nDiagnostics saved.\n")

# Save model objects for tables
save(m1, m2, m3, m_event, file = file.path(data_dir, "models.RData"))
cat("Models saved.\n")
