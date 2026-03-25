## 02_clean_data.R — Construct analysis panel
## APEP-0923: The End of Banking Secrecy

source("00_packages.R")

# ---------------------------------------------------------------
# 1. Load BIS bilateral data and AEOI dates
# ---------------------------------------------------------------
bis <- fread("../data/bis_ch_liabilities.csv")
aeoi <- fread("../data/aeoi_activation_dates.csv")
aeoi[, aeoi_start := as.Date(aeoi_start)]

cat("BIS panel:", nrow(bis), "obs,", uniqueN(bis$cp_country), "countries\n")
cat("AEOI dates:", nrow(aeoi), "countries\n")

# ---------------------------------------------------------------
# 2. Merge AEOI activation dates
# ---------------------------------------------------------------
panel <- merge(bis, aeoi, by = "cp_country", all.x = TRUE)

# Countries without AEOI activation date → never treated (as of 2020)
panel[is.na(aeoi_start), wave := 0L]
panel[wave == 0, aeoi_start := as.Date(NA)]

# Treatment indicator: 1 if AEOI is active in this quarter
panel[, aeoi_active := as.integer(!is.na(aeoi_start) & date >= aeoi_start)]

# Time to treatment (in quarters, for event study)
panel[, aeoi_start_quarter := as.integer(format(aeoi_start, "%Y")) * 4 +
        as.integer(format(aeoi_start, "%m")) %/% 3]
panel[, current_quarter := year * 4 + (quarter - 1)]
panel[, rel_quarter := current_quarter - aeoi_start_quarter]

# For never-treated, set rel_quarter to NA
panel[wave == 0, rel_quarter := NA_integer_]

cat("Treatment breakdown:\n")
cat("  AEOI countries:", uniqueN(panel[wave > 0]$cp_country), "\n")
cat("  Never-AEOI countries:", uniqueN(panel[wave == 0]$cp_country), "\n")
cat("  Treated obs:", sum(panel$aeoi_active), "\n")
cat("  Control obs:", sum(panel$aeoi_active == 0), "\n")

# ---------------------------------------------------------------
# 3. Create outcome variables
# ---------------------------------------------------------------

# Log deposits (main outcome)
panel[, log_deposits := log(deposits_usd_mn + 1)]

# Deposit growth rate (quarter-on-quarter)
setorder(panel, cp_country, date)
panel[, lag_deposits := shift(deposits_usd_mn, 1), by = cp_country]
panel[, deposit_growth := (deposits_usd_mn - lag_deposits) / lag_deposits]

# Deposit share (country j's share of total Swiss foreign liabilities)
panel[, total_deposits_q := sum(deposits_usd_mn, na.rm = TRUE), by = date]
panel[, deposit_share := deposits_usd_mn / total_deposits_q]

# ---------------------------------------------------------------
# 4. Construct country characteristics for heterogeneity
# ---------------------------------------------------------------

# Pre-AEOI deposit level (average 2014-2016) — treatment intensity proxy
pre_period <- panel[year >= 2014 & year <= 2016,
                    .(pre_deposits = mean(deposits_usd_mn, na.rm = TRUE),
                      pre_log_deposits = mean(log_deposits, na.rm = TRUE)),
                    by = cp_country]

panel <- merge(panel, pre_period, by = "cp_country", all.x = TRUE)

# Tax haven indicator (common classification)
tax_havens <- c("LU", "LI", "GG", "JE", "IM", "PA", "BH", "MU",
                "SG", "HK", "AE", "BM", "KY", "VG", "BS", "MC",
                "GI", "AN", "CW", "MO", "BN", "AI", "TC", "VI")
panel[, tax_haven := as.integer(cp_country %in% tax_havens)]

# EU membership indicator
eu_members <- c("AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR",
                "DE", "GR", "HU", "IE", "IT", "LV", "LT", "LU", "MT", "NL",
                "PL", "PT", "RO", "SK", "SI", "ES", "SE")
panel[, eu_member := as.integer(cp_country %in% eu_members)]

# ---------------------------------------------------------------
# 5. Sample restrictions
# ---------------------------------------------------------------

# Restrict to 2010-2023 (sufficient pre-period + avoid data sparsity)
panel <- panel[year >= 2010 & year <= 2023]

# Drop aggregate codes (5J = all countries, 5A = all reporting, etc.)
panel <- panel[!grepl("^[0-9]", cp_country)]

# Drop countries with insufficient data (< 20 quarters observed)
obs_count <- panel[, .N, by = cp_country]
keep_countries <- obs_count[N >= 20]$cp_country
panel <- panel[cp_country %in% keep_countries]

# Create numeric country ID for fixed effects
panel[, country_id := as.integer(factor(cp_country))]

# Create cohort variable for Callaway-Sant'Anna (year of treatment, 0 for never-treated)
panel[, cohort_year := ifelse(wave > 0, year(aeoi_start), 0)]

# Create time period index (quarterly: 2010Q1 = 1, 2010Q2 = 2, ...)
panel[, time_id := (year - 2010) * 4 + quarter]

cat("\n=== Analysis panel summary ===\n")
cat("Observations:", nrow(panel), "\n")
cat("Countries:", uniqueN(panel$cp_country), "\n")
cat("Quarters:", uniqueN(panel$period), "\n")
cat("Years:", min(panel$year), "-", max(panel$year), "\n")
cat("AEOI treated:", uniqueN(panel[wave > 0]$cp_country), "\n")
cat("Never treated:", uniqueN(panel[wave == 0]$cp_country), "\n")

cat("\nWave composition:\n")
print(panel[, .(countries = uniqueN(cp_country),
                mean_deposits = round(mean(deposits_usd_mn, na.rm = TRUE))),
            by = wave])

cat("\nOutcome distributions (log_deposits):\n")
cat("  Mean:", round(mean(panel$log_deposits, na.rm = TRUE), 2), "\n")
cat("  SD:", round(sd(panel$log_deposits, na.rm = TRUE), 2), "\n")
cat("  Min:", round(min(panel$log_deposits, na.rm = TRUE), 2), "\n")
cat("  Max:", round(max(panel$log_deposits, na.rm = TRUE), 2), "\n")

# ---------------------------------------------------------------
# 6. Save analysis panel
# ---------------------------------------------------------------
fwrite(panel, "../data/analysis_panel.csv")
cat("\nAnalysis panel saved:", nrow(panel), "observations\n")
