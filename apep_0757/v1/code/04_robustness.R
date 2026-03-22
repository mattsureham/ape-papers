# ============================================================
# 04_robustness.R — Robustness checks
# apep_0757: The Racial Anatomy of Food Desert Formation
# ============================================================

source("00_packages.R")
library(fixest)
library(data.table)

data_dir <- "../data"

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))

# ----------------------------------------------------------
# 1. Event-study: pre-trends check
# ----------------------------------------------------------
cat("=== Event-study pre-trends ===\n")

# Create relative time to first treatment
panel[, rel_time := time_id - first_treat]
panel[first_treat == 0, rel_time := -999L]  # Never-treated

# Bin at ±12 quarters
panel[, rel_time_bin := pmax(pmin(rel_time, 12L), -12L)]
panel[first_treat == 0, rel_time_bin := -999L]

# Event study for separation rate (key outcome)
panel_sep <- panel[!is.na(sep_rate) & rel_time_bin >= -12]

# Interaction event study: rel_time × black
es_sep <- feols(sep_rate ~ i(rel_time_bin, black, ref = -1) +
                  i(rel_time_bin, ref = -1) |
                  county_fips + time_id + race_label,
                data = panel_sep[rel_time_bin != -999],
                cluster = ~county_fips)

cat("  Event study (sep_rate × black) estimated\n")
cat("  Key pre-treatment coefficients (black interaction):\n")
es_coefs <- coef(es_sep)
es_se <- sqrt(diag(vcov(es_sep)))
black_terms <- grep("rel_time_bin.*black", names(es_coefs))
for (i in black_terms) {
  t <- names(es_coefs)[i]
  cat("    ", t, ":", round(es_coefs[i], 4), "(", round(es_se[i], 4), ")\n")
}

saveRDS(es_sep, file.path(data_dir, "es_sep.rds"))

# ----------------------------------------------------------
# 2. Heterogeneity: by county Black population share
# ----------------------------------------------------------
cat("\n=== Heterogeneity by Black employment share ===\n")

# Compute pre-treatment Black share of food retail employment
pre_shares <- panel[treated == 0 & !is.na(Emp),
                    .(total_emp = sum(Emp, na.rm = TRUE)),
                    by = .(county_fips, race_label)]
pre_shares_wide <- dcast(pre_shares, county_fips ~ race_label,
                          value.var = "total_emp", fill = 0)
pre_shares_wide[, black_share := black / (black + white + 0.01)]
pre_shares_wide[, high_black := as.integer(black_share > median(black_share))]

panel <- merge(panel, pre_shares_wide[, .(county_fips, black_share, high_black)],
               by = "county_fips", all.x = TRUE)

# DDD in high vs low Black share counties
ddd_high <- feols(sep_rate ~ treated * black | county_fips + time_id + race_label,
                  data = panel[high_black == 1 & !is.na(sep_rate)],
                  cluster = ~county_fips)
ddd_low <- feols(sep_rate ~ treated * black | county_fips + time_id + race_label,
                 data = panel[high_black == 0 & !is.na(sep_rate)],
                 cluster = ~county_fips)

cat("  High Black share counties:\n")
cat("    treated:black =", round(coef(ddd_high)["treated:black"], 4),
    "(SE:", round(sqrt(vcov(ddd_high)["treated:black", "treated:black"]), 4), ")\n")
cat("  Low Black share counties:\n")
cat("    treated:black =", round(coef(ddd_low)["treated:black"], 4),
    "(SE:", round(sqrt(vcov(ddd_low)["treated:black", "treated:black"]), 4), ")\n")

saveRDS(ddd_high, file.path(data_dir, "ddd_high_black.rds"))
saveRDS(ddd_low, file.path(data_dir, "ddd_low_black.rds"))

# ----------------------------------------------------------
# 3. Alternative clustering: state level
# ----------------------------------------------------------
cat("\n=== Alternative clustering: state ===\n")

panel[, state_fips := substr(county_fips, 1, 2)]

ddd_state_cluster <- feols(sep_rate ~ treated * black | county_fips + time_id + race_label,
                           data = panel[!is.na(sep_rate)],
                           cluster = ~state_fips)
cat("  State-clustered:\n")
cat("    treated:black =", round(coef(ddd_state_cluster)["treated:black"], 4),
    "(SE:", round(sqrt(vcov(ddd_state_cluster)["treated:black", "treated:black"]), 4), ")\n")

saveRDS(ddd_state_cluster, file.path(data_dir, "ddd_state_cluster.rds"))

# ----------------------------------------------------------
# 4. Placebo: NAICS 44-45 excluding 445
# ----------------------------------------------------------
cat("\n=== Placebo not available (single industry) — skipping ===\n")
# QWI query was for NAICS 445 only; would need separate query for placebo

# ----------------------------------------------------------
# 5. Save robustness results
# ----------------------------------------------------------
cat("\n=== Saving robustness results ===\n")

robustness <- list(
  es_sep = es_sep,
  ddd_high = ddd_high,
  ddd_low = ddd_low,
  ddd_state_cluster = ddd_state_cluster
)
saveRDS(robustness, file.path(data_dir, "robustness_results.rds"))

cat("=== Robustness complete ===\n")
