## 03_main_analysis.R — Main DiD estimation
## APEP paper apep_0814: El Salvador gang removal and homicide geography

source("00_packages.R")

data_dir <- "../data"
panel <- fread(file.path(data_dir, "panel.csv"))

message("Panel: ", nrow(panel), " obs, ", length(unique(panel$muni_id)),
        " municipalities, ", length(unique(panel$year)), " years")

# ─────────────────────────────────────────────────────────────────────────────
# 1. Summary statistics
# ─────────────────────────────────────────────────────────────────────────────
message("\n=== Summary Statistics ===")

# Pre vs Post comparison
pre <- panel[post == 0]
post_df <- panel[post == 1]

cat("\n--- Pre-2019 (2002-2018) ---\n")
cat("Homicide rate (per 10K): mean=", round(mean(pre$hom_rate_10k, na.rm=T), 2),
    " sd=", round(sd(pre$hom_rate_10k, na.rm=T), 2),
    " median=", round(median(pre$hom_rate_10k, na.rm=T), 2), "\n")

cat("\n--- Post-2019 (2019-2021) ---\n")
cat("Homicide rate (per 10K): mean=", round(mean(post_df$hom_rate_10k, na.rm=T), 2),
    " sd=", round(sd(post_df$hom_rate_10k, na.rm=T), 2),
    " median=", round(median(post_df$hom_rate_10k, na.rm=T), 2), "\n")

cat("\n--- Difference ---\n")
cat("Mean change: ", round(mean(post_df$hom_rate_10k, na.rm=T) -
                            mean(pre$hom_rate_10k, na.rm=T), 2), "\n")

# Gang intensity summary
cat("\n--- Gang detention rate per 100K ---\n")
gang_sum <- panel[year == 2018]
cat("Mean:", round(mean(gang_sum$gang_rate, na.rm=T), 1),
    " SD:", round(sd(gang_sum$gang_rate, na.rm=T), 1),
    " Min:", round(min(gang_sum$gang_rate, na.rm=T), 1),
    " Max:", round(max(gang_sum$gang_rate, na.rm=T), 1), "\n")

# ─────────────────────────────────────────────────────────────────────────────
# 2. Main specification: Continuous intensity DiD
# ─────────────────────────────────────────────────────────────────────────────
message("\n=== Main DiD Estimation ===")

# Specification 1: ln(homrate + 1) ~ gang_rate_std × post | muni + year
m1 <- feols(ln_hom ~ gang_rate_std:post | muni_id + year,
            data = panel, cluster = ~muni_id)

# Specification 2: Levels (homrate ~ gang_rate_std × post)
m2 <- feols(hom_rate_10k ~ gang_rate_std:post | muni_id + year,
            data = panel, cluster = ~muni_id)

# Specification 3: With department × year trends
# Rebuild dept factor from NAME_1 (may have NAs from merge)
panel[, dept_id := as.integer(as.factor(NAME_1))]
# Drop obs without department info for this spec
panel_dept <- panel[!is.na(dept_id)]
m3 <- feols(ln_hom ~ gang_rate_std:post | muni_id + year + dept_id[year],
            data = panel_dept, cluster = ~muni_id)

# Specification 4: Binary treatment (high vs low gang)
m4 <- feols(ln_hom ~ high_gang:post | muni_id + year,
            data = panel, cluster = ~muni_id)

cat("\n--- Main results ---\n")
cat("M1 (Log, continuous): β =", round(coef(m1), 4),
    " SE =", round(se(m1), 4),
    " p =", round(pvalue(m1), 4), "\n")
cat("M2 (Level, continuous): β =", round(coef(m2), 4),
    " SE =", round(se(m2), 4),
    " p =", round(pvalue(m2), 4), "\n")
cat("M3 (Log, dept trends): β =", round(coef(m3), 4),
    " SE =", round(se(m3), 4),
    " p =", round(pvalue(m3), 4), "\n")
cat("M4 (Log, binary): β =", round(coef(m4), 4),
    " SE =", round(se(m4), 4),
    " p =", round(pvalue(m4), 4), "\n")

# ─────────────────────────────────────────────────────────────────────────────
# 3. Event study
# ─────────────────────────────────────────────────────────────────────────────
message("\n=== Event Study ===")

# Bin endpoints: combine years < -8 and > 2
panel[, rel_year_binned := pmax(pmin(rel_year, 2), -8)]

# Event study with year -1 (2018) as reference
es <- feols(ln_hom ~ i(rel_year_binned, gang_rate_std, ref = -1) | muni_id + year,
            data = panel, cluster = ~muni_id)

# Also run a "short window" event study (2012-2021, 7 pre + 3 post)
# This focuses on the period with cleaner pre-trends
panel_short <- panel[year >= 2012]
panel_short[, rel_year_short := year - 2019]
es_short <- feols(ln_hom ~ i(rel_year_short, gang_rate_std, ref = -1) | muni_id + year,
                  data = panel_short, cluster = ~muni_id)

cat("\n--- Short-window event study (2012-2021) ---\n")
print(round(coeftable(es_short), 4))

# Print event study coefficients
es_coefs <- coeftable(es)
cat("\n--- Event study coefficients ---\n")
print(round(es_coefs, 4))

# ─────────────────────────────────────────────────────────────────────────────
# 4. Alternative intensity: 2015 homicide rate (peak year)
# ─────────────────────────────────────────────────────────────────────────────
message("\n=== Alternative intensity: 2015 homicide rate ===")

panel[, hom_2015_std := (hom_2015 - mean(hom_2015, na.rm = TRUE)) /
        sd(hom_2015, na.rm = TRUE)]

m5 <- feols(ln_hom ~ hom_2015_std:post | muni_id + year,
            data = panel, cluster = ~muni_id)

cat("M5 (2015 intensity): β =", round(coef(m5), 4),
    " SE =", round(se(m5), 4),
    " p =", round(pvalue(m5), 4), "\n")

# ─────────────────────────────────────────────────────────────────────────────
# 5. Pre-treatment SD for SDE calculation
# ─────────────────────────────────────────────────────────────────────────────
message("\n=== Pre-treatment statistics for SDE ===")
pre_sd_log <- sd(panel[post == 0]$ln_hom, na.rm = TRUE)
pre_sd_level <- sd(panel[post == 0]$hom_rate_10k, na.rm = TRUE)
pre_mean_level <- mean(panel[post == 0]$hom_rate_10k, na.rm = TRUE)

cat("SD(ln_hom), pre-2019:", round(pre_sd_log, 4), "\n")
cat("SD(hom_rate), pre-2019:", round(pre_sd_level, 4), "\n")
cat("Mean(hom_rate), pre-2019:", round(pre_mean_level, 4), "\n")

# ─────────────────────────────────────────────────────────────────────────────
# 6. Save diagnostics
# ─────────────────────────────────────────────────────────────────────────────
diagnostics <- list(
  n_treated = length(unique(panel[gang_quintile >= 4]$muni_id)),
  n_pre = length(unique(panel[post == 0]$year)),
  n_obs = nrow(panel),
  n_municipalities = length(unique(panel$muni_id)),
  n_years = length(unique(panel$year)),
  pre_sd_log = pre_sd_log,
  pre_sd_level = pre_sd_level,
  pre_mean_level = pre_mean_level,
  main_coef = as.numeric(coef(m1)),
  main_se = as.numeric(se(m1)),
  main_pvalue = as.numeric(pvalue(m1))
)

jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                     auto_unbox = TRUE, pretty = TRUE)

# Save model objects for table generation
save(m1, m2, m3, m4, m5, es, panel, pre_sd_log, pre_sd_level,
     file = file.path(data_dir, "models.RData"))

message("\n=== Analysis complete ===")
message("Main coefficient (gang_rate_std × post): ", round(coef(m1), 4))
message("Standard error: ", round(se(m1), 4))
message("p-value: ", round(pvalue(m1), 4))
message("Models and diagnostics saved.")
