# 04_robustness.R — Robustness checks for MEES analysis

source("00_packages.R")

data_dir <- "../data"
panel <- fread(file.path(data_dir, "panel_la_quarter.csv"))
eng_ts <- fread(file.path(data_dir, "england_timeseries.csv"))
eng_rental <- fread(file.path(data_dir, "england_rental_ts.csv"))

# Filter as in main analysis
panel <- panel[!is.na(fg_share) & !is.na(pre_rental_share) & total_rated >= 10]
panel[, post_mees := as.integer(year > 2018 | (year == 2018 & q >= 2))]

# ============================================================================
# PART 1: Placebo outcome — D band share (not regulated by MEES)
# ============================================================================

cat("=== Placebo: D band share ===\n")

# MEES threshold is at E/F boundary (score 39). The D band (55-68) is well above.
# If our cross-LA result is driven by MEES regulation, D share should NOT respond.
panel[, d_share := fifelse(total_rated > 0,
                           as.numeric(panel$n_lodgements) * 0 + # placeholder
                           NA_real_, NA_real_)]

# We need D count from original data — let's reload
d1_raw <- fread(file.path(data_dir, "d1_clean.csv"))
d1 <- d1_raw[4:.N]
setnames(d1, c("la_code", "la_name", "quarter", "n_lodgements", "floor_area",
               "band_a", "band_b", "band_c", "band_d", "band_e",
               "band_f", "band_g", "not_recorded"))
for (col in c("band_d", "band_e", "band_a", "band_b", "band_c", "band_f", "band_g")) {
  d1[, (col) := as.numeric(get(col))]
}
d1[, total_rated := band_a + band_b + band_c + band_d + band_e + band_f + band_g]
d1[, d_share := fifelse(total_rated > 0, band_d / total_rated, NA_real_)]
d1[, e_share := fifelse(total_rated > 0, band_e / total_rated, NA_real_)]
d1 <- d1[grepl("^E", la_code)]

# Merge D share into panel
panel_d <- merge(
  panel[, .(la_code, quarter, post_mees, pre_rental_share, rental_tercile)],
  d1[, .(la_code, quarter, d_share, e_share)],
  by = c("la_code", "quarter")
)

m_placebo_d <- feols(
  d_share ~ post_mees:pre_rental_share | la_code + quarter,
  data = panel_d[!is.na(d_share)],
  cluster = ~la_code
)

cat("Placebo (D band):\n")
summary(m_placebo_d)

# E band placebo — E is adjacent to threshold, might be affected
m_placebo_e <- feols(
  e_share ~ post_mees:pre_rental_share | la_code + quarter,
  data = panel_d[!is.na(e_share)],
  cluster = ~la_code
)

cat("\nE band (adjacent to threshold — may be affected):\n")
summary(m_placebo_e)

# ============================================================================
# PART 2: Alternative treatment intensity — binary high/low
# ============================================================================

cat("\n=== Binary treatment ===\n")

panel[, high_rental := as.integer(pre_rental_share > median(pre_rental_share, na.rm = TRUE))]

m_binary <- feols(
  fg_share ~ post_mees:high_rental | la_code + quarter,
  data = panel,
  cluster = ~la_code
)

cat("Binary (above/below median rental share):\n")
summary(m_binary)

# ============================================================================
# PART 3: England national ITS — structural break tests
# ============================================================================

cat("\n=== Structural break analysis ===\n")

eng_ts[, t := .I]
eng_ts[, post_announce := as.integer(year >= 2015)]
eng_ts[, post_new := as.integer(year > 2018 | (year == 2018 & q >= 2))]
eng_ts[, post_all := as.integer(year > 2020 | (year == 2020 & q >= 2))]

# ITS with three breaks
m_its <- lm(fg_share ~ t + post_announce + post_announce:t +
              post_new + post_new:t +
              post_all + post_all:t,
            data = eng_ts)

cat("ITS with three structural breaks:\n")
print(summary(m_its))

# Simpler: just test the level shift at each date
m_its_simple <- lm(fg_share ~ t + post_announce + post_new + post_all,
                    data = eng_ts)
cat("\nSimplified ITS:\n")
print(summary(m_its_simple))

# ============================================================================
# PART 4: Rental EPC lodgement surge — direct evidence
# ============================================================================

cat("\n=== Rental EPC lodgement surge ===\n")

eng_rental[, year := as.integer(sub("/.*", "", quarter))]
eng_rental[, q := as.integer(sub(".*/", "", quarter))]
eng_rental[, post_mees := as.integer(year > 2018 | (year == 2018 & q >= 2))]

# Pre vs post MEES rental volumes
pre_rental <- eng_rental[post_mees == 0, .(
  mean_rental = mean(total_rental),
  mean_share = mean(rental_share),
  mean_total = mean(total_all)
)]
post_rental <- eng_rental[post_mees == 1, .(
  mean_rental = mean(total_rental),
  mean_share = mean(rental_share),
  mean_total = mean(total_all)
)]

cat("Pre-MEES rental EPCs/quarter:", round(pre_rental$mean_rental), "\n")
cat("Post-MEES rental EPCs/quarter:", round(post_rental$mean_rental), "\n")
cat("Change:", round((post_rental$mean_rental / pre_rental$mean_rental - 1) * 100, 1), "%\n")
cat("\nPre-MEES rental share:", round(pre_rental$mean_share, 3), "\n")
cat("Post-MEES rental share:", round(post_rental$mean_share, 3), "\n")
cat("Change:", round((post_rental$mean_share - pre_rental$mean_share) * 100, 1), "pp\n")

# ============================================================================
# PART 5: Weighted regressions (weight by LA size)
# ============================================================================

cat("\n=== Weighted regression (by lodgement volume) ===\n")

m_weighted <- feols(
  fg_share ~ post_mees:pre_rental_share | la_code + quarter,
  data = panel,
  cluster = ~la_code,
  weights = ~total_rated
)

cat("Weighted by total rated EPCs:\n")
summary(m_weighted)

# ============================================================================
# PART 6: Excluding London (robustness)
# ============================================================================

cat("\n=== Excluding London ===\n")

panel[, is_london := grepl("^E09", la_code)]

m_no_london <- feols(
  fg_share ~ post_mees:pre_rental_share | la_code + quarter,
  data = panel[is_london == FALSE],
  cluster = ~la_code
)

cat("Excluding London boroughs:\n")
summary(m_no_london)

# Save all robustness results
save(m_placebo_d, m_placebo_e, m_binary, m_its, m_its_simple,
     m_weighted, m_no_london,
     file = file.path(data_dir, "robustness_models.RData"))

cat("\n=== Robustness complete ===\n")
