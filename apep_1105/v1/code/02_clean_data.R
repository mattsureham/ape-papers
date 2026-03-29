# =============================================================================
# 02_clean_data.R — Merge and construct analysis dataset
# apep_1105: Treatment Dividend of Supply-Side Opioid Restrictions
# =============================================================================
source("00_packages.R")

# Load data
arcos <- fread("../data/arcos_county_hcp_share.csv")
mat <- fread("../data/tmsis_county_mat.csv")
sud <- fread("../data/tmsis_county_sud_placebo.csv")
controls <- fread("../data/county_controls.csv")

cat(sprintf("ARCOS counties: %d\n", nrow(arcos)))
cat(sprintf("T-MSIS MAT counties: %d\n", nrow(mat)))
cat(sprintf("T-MSIS SUD placebo counties: %d\n", nrow(sud)))
cat(sprintf("Census control counties: %d\n", nrow(controls)))

# Standardize FIPS codes
arcos[, fips := sprintf("%05s", as.character(fips))]
mat[, fips := sprintf("%05s", as.character(county_fips5))]
sud[, fips := sprintf("%05s", as.character(county_fips5))]
controls[, fips := sprintf("%05s", as.character(fips))]

# Merge ARCOS instrument with T-MSIS outcomes
df <- merge(arcos[, .(fips, state_abb, hcp_share, total_pills, hcp_pills, oxy_pills)],
            mat[, .(fips, total_mat_claims, total_mat_beneficiaries, total_mat_paid,
                     n_months, n_providers, mat_claims_per_month, mat_beneficiaries_per_month,
                     methadone_claims, buprenorphine_claims, naltrexone_claims)],
            by = "fips", all = FALSE)

cat(sprintf("Merged ARCOS-MAT: %d counties\n", nrow(df)))

# Add placebo SUD
df <- merge(df, sud[, .(fips, sud_placebo_claims, sud_claims_per_month)],
            by = "fips", all.x = TRUE)
df[is.na(sud_placebo_claims), sud_placebo_claims := 0]
df[is.na(sud_claims_per_month), sud_claims_per_month := 0]

# Add controls
df <- merge(df, controls, by = "fips", all.x = TRUE)
cat(sprintf("With controls: %d counties\n", nrow(df)))

# Drop counties with missing population
df <- df[!is.na(population) & population > 0]
cat(sprintf("After dropping missing population: %d counties\n", nrow(df)))

# =============================================================================
# Construct outcome variables (per capita)
# =============================================================================
df[, mat_rate := (mat_claims_per_month / population) * 1000]  # per 1000 pop per month
df[, mat_beneficiary_rate := (mat_beneficiaries_per_month / population) * 1000]
df[, sud_placebo_rate := (sud_claims_per_month / population) * 1000]
df[, methadone_rate := (methadone_claims / n_months / population) * 1000]
df[, buprenorphine_rate := (buprenorphine_claims / n_months / population) * 1000]
df[, naltrexone_rate := (naltrexone_claims / n_months / population) * 1000]

# Per capita opioid prescribing (pre-rescheduling)
df[, pills_per_cap := total_pills / population]
df[, log_pop := log(population)]

# State fixed effects
df[, state_fips := substr(fips, 1, 2)]

# Quintiles of HCP share for nonlinearity test
df[, hcp_quintile := cut(hcp_share,
                         breaks = quantile(hcp_share, probs = seq(0, 1, 0.2), na.rm = TRUE),
                         labels = paste0("Q", 1:5),
                         include.lowest = TRUE)]

# Log outcomes (for elasticity interpretation)
df[, log_mat_rate := log(mat_rate + 0.001)]
df[, log_sud_rate := log(sud_placebo_rate + 0.001)]

# Urbanicity indicator
df[, urban := as.integer(urban_code <= 2)]  # Metro counties

# =============================================================================
# Summary statistics
# =============================================================================
cat("\n=== Analysis Dataset Summary ===\n")
cat(sprintf("N counties: %d\n", nrow(df)))
cat(sprintf("N states: %d\n", uniqueN(df$state_fips)))

cat("\n--- Instrument (HCP Share) ---\n")
cat(sprintf("Mean: %.3f, SD: %.3f\n", mean(df$hcp_share), sd(df$hcp_share)))
cat(sprintf("IQR: [%.3f, %.3f]\n", quantile(df$hcp_share, 0.25), quantile(df$hcp_share, 0.75)))

cat("\n--- MAT Outcomes (per 1000 pop per month) ---\n")
cat(sprintf("MAT claims rate: mean=%.3f, sd=%.3f, median=%.3f\n",
            mean(df$mat_rate), sd(df$mat_rate), median(df$mat_rate)))
cat(sprintf("Methadone rate: mean=%.3f, sd=%.3f\n",
            mean(df$methadone_rate), sd(df$methadone_rate)))
cat(sprintf("Buprenorphine rate: mean=%.4f, sd=%.4f\n",
            mean(df$buprenorphine_rate), sd(df$buprenorphine_rate)))

cat("\n--- Placebo Outcome ---\n")
cat(sprintf("Non-opioid SUD rate: mean=%.3f, sd=%.3f\n",
            mean(df$sud_placebo_rate), sd(df$sud_placebo_rate)))

cat("\n--- Controls ---\n")
cat(sprintf("Population: mean=%s, median=%s\n",
            format(mean(df$population), big.mark=","),
            format(median(df$population), big.mark=",")))
cat(sprintf("Poverty rate: mean=%.3f\n", mean(df$poverty_rate, na.rm=TRUE)))
cat(sprintf("Urban counties: %d (%.1f%%)\n",
            sum(df$urban, na.rm=TRUE), mean(df$urban, na.rm=TRUE)*100))

# Save analysis dataset
fwrite(df, "../data/analysis_dataset.csv")
cat("\nSaved analysis_dataset.csv\n")
