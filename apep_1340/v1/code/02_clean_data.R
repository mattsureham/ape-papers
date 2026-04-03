# 02_clean_data.R — Construct analysis panel from HMDA tract-year data
source("00_packages.R")

data_dir <- "../data"

# ============================================================
# Load aggregated data
# ============================================================
df <- fread(file.path(data_dir, "hmda_tract_year.csv"))
df[, census_tract := as.character(census_tract)]
cat("Raw data:", nrow(df), "tract-year obs,", uniqueN(df$census_tract), "tracts\n")

# ============================================================
# Load reclassification data
# ============================================================
reclass <- fread(file.path(data_dir, "reclassified_tracts.csv"))
reclass[, census_tract := as.character(census_tract)]
cat("Reclassified tracts:", sum(reclass$status_changed), "\n")

# ============================================================
# Construct analysis variables
# ============================================================

# LMI status
df[, lmi := as.integer(income_pct <= 80)]

# Outcomes
df[, approval_rate := n_originated / n_applications]
df[, denial_rate := n_denied / n_applications]
df[, log_originations := log(n_originated + 1)]
df[, log_amount := log(total_loan_amount + 1)]

# Minority lending share
df[, minority_loans := n_black + n_hispanic]
df[, minority_share := minority_loans / pmax(n_originated, 1)]

# Purchase share
df[, purchase_share := n_purchase / pmax(n_originated, 1)]

# ============================================================
# Merge treatment assignment
# ============================================================
df <- merge(df, reclass[, .(census_tract, status_changed, gained_lmi, lost_lmi,
                             lmi_2023, lmi_2024, pct_2023, pct_2024, pct_change)],
            by = "census_tract", all.x = TRUE)

# Treatment indicators
df[, treated := as.integer(status_changed == TRUE)]
df[is.na(treated), treated := 0]

# Post indicator (2024 = post-treatment)
df[, post := as.integer(year >= 2024)]

# Interaction
df[, treat_post := treated * post]

# Separate gain/loss treatments
df[, gained_post := as.integer(gained_lmi == TRUE) * post]
df[is.na(gained_post), gained_post := 0]
df[, lost_post := as.integer(lost_lmi == TRUE) * post]
df[is.na(lost_post), lost_post := 0]

# Event-time variable (relative to 2024)
df[, event_time := year - 2024]

# ============================================================
# Sample restrictions
# ============================================================

# Drop tracts with very few loans (noisy)
df[, mean_apps := mean(n_applications, na.rm = TRUE), by = census_tract]
df_panel <- df[mean_apps >= 10]  # At least 10 applications per year on average
cat("After dropping thin tracts:", nrow(df_panel), "obs,",
    uniqueN(df_panel$census_tract), "tracts\n")

# Drop tracts with missing income_pct (no MSA assignment)
df_panel <- df_panel[!is.na(income_pct) & income_pct > 0]
cat("After dropping missing income_pct:", nrow(df_panel), "obs,",
    uniqueN(df_panel$census_tract), "tracts\n")

# Balanced panel: require obs in all 7 years
tract_counts <- df_panel[, .N, by = census_tract]
balanced_tracts <- tract_counts[N == 7]$census_tract
df_panel <- df_panel[census_tract %in% balanced_tracts]
cat("Balanced panel:", nrow(df_panel), "obs,",
    uniqueN(df_panel$census_tract), "tracts\n")

# ============================================================
# Summary statistics
# ============================================================
cat("\n=== Treatment Assignment ===\n")
cat("Control (never reclassified):", uniqueN(df_panel[treated == 0]$census_tract), "tracts\n")
cat("Treated (reclassified):", uniqueN(df_panel[treated == 1]$census_tract), "tracts\n")
cat("  Gained LMI:", uniqueN(df_panel[gained_lmi == TRUE]$census_tract), "tracts\n")
cat("  Lost LMI:", uniqueN(df_panel[lost_lmi == TRUE]$census_tract), "tracts\n")

cat("\n=== Outcome Means (pre-treatment, 2018-2023) ===\n")
pre <- df_panel[year < 2024]
cat("Mean originations:", round(mean(pre$n_originated, na.rm = TRUE), 1), "\n")
cat("Mean approval rate:", round(mean(pre$approval_rate, na.rm = TRUE), 3), "\n")
cat("Mean minority share:", round(mean(pre$minority_share, na.rm = TRUE), 3), "\n")
cat("Mean rate spread:", round(mean(pre$mean_rate_spread, na.rm = TRUE), 3), "\n")

# ============================================================
# Save clean panel
# ============================================================
fwrite(df_panel, file.path(data_dir, "analysis_panel.csv"))
cat("\nSaved analysis panel to", file.path(data_dir, "analysis_panel.csv"), "\n")
