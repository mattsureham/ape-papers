# 02_clean_data.R — Clean PSC data and construct analysis variables

source("00_packages.R")

data_dir <- "../data"

cat("Loading data...\n")
df <- fread(file.path(data_dir, "psc_company_merged.csv"))
cat(sprintf("Companies: %s\n", format(nrow(df), big.mark = ",")))

# ============================================================================
# 1. Sector classification
# ============================================================================

df[, sic_section := fcase(
  sic_div %in% c("64", "65", "66"), "Financial",
  sic_div == "68", "Real Estate",
  sic_div %in% c("69", "70"), "Professional/HQ",
  sic_div == "82", "Business Support",
  sic_div %in% c("41", "42", "43"), "Construction",
  sic_div %in% c("45", "46", "47"), "Wholesale/Retail",
  sic_div %in% c("55", "56"), "Hospitality",
  sic_div %in% c("10":"33"), "Manufacturing",
  sic_div %in% c("86", "87", "88"), "Health/Social",
  sic_div %in% c("62", "63"), "IT/Tech",
  default = "Other"
)]

# High-risk sectors for AML (FATF / 4AMLD risk categories)
df[, high_risk := sic_section %in% c("Financial", "Real Estate",
                                       "Professional/HQ", "Business Support")]

# ============================================================================
# 2. Ownership configuration flags
# ============================================================================

# Focus on individual PSCs only (exclude corporate/legal person PSCs)
df[, n_indiv := n_individual]

# Key configurations for bunching analysis
df[, config := fcase(
  n_indiv == 0 & n_corporate > 0, "Corporate-only",
  n_indiv == 1 & n_band_75_100 == 1, "Sole owner (75-100%)",
  n_indiv == 1 & n_band_50_75 == 1, "Majority (50-75%)",
  n_indiv == 1 & n_band_25_50 == 1, "Quarter (25-50%)",
  n_indiv == 2 & n_band_25_50 == 2, "2-way equal (25-50%)",
  n_indiv == 2 & n_band_50_75 >= 1, "Majority + minority",
  n_indiv == 3 & n_band_25_50 >= 3, "3-way equal (25-50%)",
  n_indiv == 4 & n_band_25_50 == 4, "4-way equal (25-50%)",
  n_indiv == 4 & n_band_25_50 >= 1, "4-PSC mixed",
  n_indiv >= 5, "Dispersed (5+)",
  default = "Other"
)]

# Flag: exactly at the avoidance-relevant configurations
# 4-way equal split = each holds exactly 25%, all must disclose
# 5-way split = each holds 20%, NONE must disclose (below 25%)
df[, at_threshold_4 := n_indiv == 4 & n_band_25_50 == 4]
df[, below_threshold_5plus := n_indiv >= 5]
df[, has_foreign := n_foreign > 0]

cat("\n=== Configuration Distribution ===\n")
config_tab <- df[, .N, by = config][order(-N)]
config_tab[, pct := round(100 * N / sum(N), 1)]
print(config_tab)

# ============================================================================
# 3. Incorporation cohort for difference-in-bunching
# ============================================================================

# Era: Pre-PSC register, Post-PSC register, Post-ECCTA enforcement
df[, era := fcase(
  inc_year < 2016, "Pre-PSC",
  inc_year >= 2016 & inc_year < 2024, "Post-PSC",
  inc_year >= 2024, "Post-ECCTA",
  default = NA_character_
)]

# Year bins for temporal analysis
df[, inc_period := fcase(
  inc_year <= 2010, "2010 or earlier",
  inc_year %in% 2011:2015, "2011-2015",
  inc_year %in% 2016:2019, "2016-2019",
  inc_year %in% 2020:2023, "2020-2023",
  inc_year >= 2024, "2024+",
  default = NA_character_
)]

cat("\n=== Era Distribution ===\n")
print(df[!is.na(era), .N, by = era][order(era)])

# ============================================================================
# 4. Bunching analysis variables
# ============================================================================

# The bunching test: distribution of number of individual PSCs
# Under no strategic behavior: smooth distribution
# Under avoidance: excess mass at n=4 (each holds 25%)
#                  missing mass at n=3 (would need >25% each)
#                  excess mass at n>=5 (each holds <25%)

# Compute shares of ownership bands per company
df[, share_25_50 := n_band_25_50 / pmax(n_indiv, 1)]
df[, share_75_100 := n_band_75_100 / pmax(n_indiv, 1)]

# For companies with exactly 4 individual PSCs:
# If all 4 are in 25-50% band, they're at/just above threshold
df[n_indiv == 4, all_four_at_threshold := n_band_25_50 == 4]

cat("\n=== 4-PSC Companies: Ownership Configuration ===\n")
four_psc <- df[n_indiv == 4]
cat(sprintf("Total 4-individual-PSC companies: %d\n", nrow(four_psc)))
if (nrow(four_psc) > 0) {
  cat(sprintf("All 4 in 25-50%% band: %d (%.1f%%)\n",
              sum(four_psc$all_four_at_threshold, na.rm = TRUE),
              100 * mean(four_psc$all_four_at_threshold, na.rm = TRUE)))
}

# ============================================================================
# 5. Summary statistics
# ============================================================================

cat("\n=== Summary Statistics ===\n")
cat(sprintf("Total companies: %s\n", format(nrow(df), big.mark = ",")))
cat(sprintf("With SIC code: %s\n", format(sum(!is.na(df$sic_div)), big.mark = ",")))
cat(sprintf("With inc. date: %s\n", format(sum(!is.na(df$inc_date)), big.mark = ",")))
cat(sprintf("High-risk sector: %s (%.1f%%)\n",
            format(sum(df$high_risk, na.rm = TRUE), big.mark = ","),
            100 * mean(df$high_risk, na.rm = TRUE)))
cat(sprintf("Has foreign PSC: %s (%.1f%%)\n",
            format(sum(df$has_foreign), big.mark = ","),
            100 * mean(df$has_foreign)))
cat(sprintf("Has corporate PSC: %s (%.1f%%)\n",
            format(sum(df$has_corporate_psc), big.mark = ","),
            100 * mean(df$has_corporate_psc)))

cat("\n=== PSC Count by Sector Risk ===\n")
risk_tab <- df[!is.na(high_risk), .(
  mean_pscs = round(mean(n_pscs), 2),
  pct_4plus = round(100 * mean(n_indiv >= 4), 2),
  pct_equal_4 = round(100 * mean(at_threshold_4), 2),
  pct_foreign = round(100 * mean(has_foreign), 2),
  pct_corporate = round(100 * mean(has_corporate_psc), 2),
  N = .N
), by = high_risk]
print(risk_tab)

cat("\n=== PSC Count by Era ===\n")
era_tab <- df[!is.na(era), .(
  mean_pscs = round(mean(n_pscs), 2),
  pct_4plus = round(100 * mean(n_indiv >= 4), 2),
  pct_equal_4 = round(100 * mean(at_threshold_4), 2),
  N = .N
), by = era]
print(era_tab)

# ============================================================================
# 6. Save
# ============================================================================

fwrite(df, file.path(data_dir, "analysis_ready.csv"))
cat(sprintf("\nSaved analysis-ready data: %s companies\n",
            format(nrow(df), big.mark = ",")))
