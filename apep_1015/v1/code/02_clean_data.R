# =============================================================================
# 02_clean_data.R — Construct analysis variables
# apep_1015: The First Wage Floor for Women
# =============================================================================

source("00_packages.R")

# ---------------------------------------------------------------------------
# Load data
# ---------------------------------------------------------------------------
women <- as.data.table(arrow::read_parquet("../data/women_1910_1920.parquet"))
cat(sprintf("Women loaded: %s rows\n", format(nrow(women), big.mark = ",")))

# ---------------------------------------------------------------------------
# Treatment coding: 14 states that enacted women's MW laws by 1920
# ---------------------------------------------------------------------------
mw_states <- c(
  4,   # Arizona (1917)
  5,   # Arkansas (1915)
  6,   # California (1913)
  8,   # Colorado (1913)
  20,  # Kansas (1915)
  25,  # Massachusetts (1912, advisory)
  27,  # Minnesota (1913)
  31,  # Nebraska (1913)
  38,  # North Dakota (1919)
  41,  # Oregon (1913)
  48,  # Texas (1919)
  49,  # Utah (1913)
  53,  # Washington (1913)
  55   # Wisconsin (1913)
)

women[, mw_state := as.integer(statefip_1910 %in% mw_states)]

# ---------------------------------------------------------------------------
# Industry classification using 1950 industry codes (ind1950)
# Covered by MW laws: manufacturing, laundry, retail, hospitality
# Exempt: domestic service, agriculture
#
# IPUMS ind1950 code ranges:
#   Agriculture:       100-126
#   Manufacturing:     306-499
#   Retail trade:      606-699 (roughly)
#   Laundries:         826-829
#   Hotels/Lodging:    806-817
#   Eating/Drinking:   818-826
#   Domestic service:  ind1950 is less useful; use occ1950 for domestic
#   Professional/Other: 868-899
#
# For a cleaner classification, we use broad categories:
#   Covered = manufacturing (306-499) + retail (606-699) + laundry (826-829)
#             + hotels/lodging (806-817) + eating/drinking (818-826)
#   Exempt  = agriculture (100-126) + private household (domestic, 856)
# ---------------------------------------------------------------------------

women[, covered_ind := as.integer(
  (ind1950_1910 >= 306 & ind1950_1910 <= 499) |  # Manufacturing
  (ind1950_1910 >= 606 & ind1950_1910 <= 699) |  # Retail trade
  (ind1950_1910 >= 806 & ind1950_1910 <= 829)    # Hotels, lodging, eating, laundry
)]

women[, exempt_ind := as.integer(
  (ind1950_1910 >= 100 & ind1950_1910 <= 126) |  # Agriculture
  (ind1950_1910 == 856)                            # Private household service
)]

# Flag women in the labor force in 1910
# occ1950 > 0 and < 979 (979 = not in labor force / not reported)
women[, in_lf_1910 := as.integer(occ1950_1910 > 0 & occ1950_1910 < 979)]

# Flag women in the labor force in 1920
women[, in_lf_1920 := as.integer(occ1950_1920 > 0 & occ1950_1920 < 979)]

# ---------------------------------------------------------------------------
# Outcome variables
# ---------------------------------------------------------------------------

# 1. Labor force retention: in LF in 1920 (conditional on being in LF in 1910)
women[, retention := in_lf_1920]

# 2. Industry persistence: same ind1950 in 1920 as 1910
women[, same_industry := as.integer(ind1950_1910 == ind1950_1920)]

# 3. Occupational upgrading: change in occscore
women[, occ_change := occscore_1920 - occscore_1910]

# 4. Entered labor force (for women NOT in LF in 1910): did they enter by 1920?
women[, lf_entry := in_lf_1920]

# ---------------------------------------------------------------------------
# Estimation sample: Women in the labor force in 1910 in either
# covered or exempt industries (for DDD)
# ---------------------------------------------------------------------------
est_sample <- women[in_lf_1910 == 1 & (covered_ind == 1 | exempt_ind == 1)]
cat(sprintf("\nEstimation sample (women in LF 1910, covered or exempt): %s\n",
            format(nrow(est_sample), big.mark = ",")))

# Tabulate
cat("\n=== Treatment composition ===\n")
cat(sprintf("MW states: %s\n", format(sum(est_sample$mw_state == 1), big.mark = ",")))
cat(sprintf("Non-MW states: %s\n", format(sum(est_sample$mw_state == 0), big.mark = ",")))
cat(sprintf("Covered industries: %s\n", format(sum(est_sample$covered_ind == 1), big.mark = ",")))
cat(sprintf("Exempt industries: %s\n", format(sum(est_sample$exempt_ind == 1), big.mark = ",")))

# DDD cell counts
cat("\n=== DDD cells ===\n")
cells <- est_sample[, .N, by = .(mw_state, covered_ind)]
print(cells[order(mw_state, covered_ind)])

# Summary stats for outcomes
cat("\n=== Outcome means by DDD cell ===\n")
means <- est_sample[, .(
  retention = mean(retention, na.rm = TRUE),
  same_industry = mean(same_industry, na.rm = TRUE),
  occ_change = mean(occ_change, na.rm = TRUE),
  N = .N
), by = .(mw_state, covered_ind)]
print(means[order(mw_state, covered_ind)])

# DDD estimate (raw)
cat("\n=== Raw DDD (retention) ===\n")
m <- means[order(mw_state, covered_ind)]
# DDD = (MW_covered - MW_exempt) - (NonMW_covered - NonMW_exempt)
dd_mw <- m[mw_state == 1 & covered_ind == 1]$retention - m[mw_state == 1 & covered_ind == 0]$retention
dd_nonmw <- m[mw_state == 0 & covered_ind == 1]$retention - m[mw_state == 0 & covered_ind == 0]$retention
ddd <- dd_mw - dd_nonmw
cat(sprintf("DD (MW states): %.4f\n", dd_mw))
cat(sprintf("DD (Non-MW states): %.4f\n", dd_nonmw))
cat(sprintf("DDD: %.4f\n", ddd))

# ---------------------------------------------------------------------------
# Save analysis datasets
# ---------------------------------------------------------------------------
arrow::write_parquet(est_sample, "../data/est_sample_women.parquet")

# Also create state-level aggregates for summary statistics
state_summ <- est_sample[, .(
  n_women = .N,
  n_covered = sum(covered_ind),
  n_exempt = sum(exempt_ind),
  mean_age = mean(age_1910, na.rm = TRUE),
  mean_occscore = mean(occscore_1910, na.rm = TRUE),
  pct_native = mean(nativity_1910 <= 1, na.rm = TRUE),
  pct_literate = mean(lit_1910 == 4, na.rm = TRUE),
  pct_married = mean(marst_1910 <= 2, na.rm = TRUE),
  retention_rate = mean(retention, na.rm = TRUE)
), by = .(statefip_1910, mw_state)]
arrow::write_parquet(state_summ, "../data/state_summary.parquet")

cat("\nAnalysis data saved.\n")

# Full women dataset for LF entry analysis (women NOT in LF in 1910)
not_in_lf <- women[in_lf_1910 == 0 & (covered_ind == 1 | exempt_ind == 1)]
cat(sprintf("Women NOT in LF 1910 (covered/exempt): %s\n",
            format(nrow(not_in_lf), big.mark = ",")))

# Hmm, women not in LF wouldn't have industry codes in 1910.
# Let's check what fraction have nonzero ind1950
cat(sprintf("  Of those, with nonzero ind1950_1910: %s\n",
            format(sum(not_in_lf$ind1950_1910 > 0), big.mark = ",")))
# Most won't — they're classified by household head's characteristics
# So the DDD sample is women IN the LF in 1910

rm(women, not_in_lf)
gc()

cat("02_clean_data.R complete.\n")
