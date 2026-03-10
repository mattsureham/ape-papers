## ============================================================
## 02_clean_data.R — Validate and describe clean panel
## apep_0573: EU Procurement Reform and Competition
## (Heavy lifting done in 01_fetch_data.R streaming mode)
## ============================================================

source(file.path(dirname(sys.frame(1)$ofile), "00_packages.R"))

cat("=== Loading clean data ===\n")
panel <- fread(file.path(data_dir, "panel_country_quarter.csv"))
panel_year <- fread(file.path(data_dir, "panel_country_year.csv"))
transposition <- fread(file.path(data_dir, "transposition_dates.csv"))

cat("  Panel (quarter):", nrow(panel), "obs,", uniqueN(panel$country), "countries,",
    uniqueN(panel$contract_year), "years\n")
cat("  Panel (year):", nrow(panel_year), "obs\n")

# ============================================================
# Summary statistics
# ============================================================
cat("\n=== Summary Statistics ===\n")

pre <- panel[contract_year < 2016]
post <- panel[contract_year >= 2016]

cat("Pre-treatment (2009-2015):\n")
cat("  Single-bidder share: ", round(weighted.mean(pre$single_bidder_share, pre$n_contracts, na.rm = TRUE), 3), "\n")
cat("  Mean bids:           ", round(weighted.mean(pre$mean_bids, pre$n_contracts, na.rm = TRUE), 2), "\n")
cat("  N contracts/quarter: ", round(mean(pre$n_contracts, na.rm = TRUE), 0), "\n")

cat("Post-treatment (2016-2023):\n")
cat("  Single-bidder share: ", round(weighted.mean(post$single_bidder_share, post$n_contracts, na.rm = TRUE), 3), "\n")
cat("  Mean bids:           ", round(weighted.mean(post$mean_bids, post$n_contracts, na.rm = TRUE), 2), "\n")
cat("  N contracts/quarter: ", round(mean(post$n_contracts, na.rm = TRUE), 0), "\n")

# Contract-level summary from yearly aggregates
sumstats_yearly <- fread(file.path(data_dir, "summary_stats_yearly.csv"))
cat("\nYearly summary:\n")
print(sumstats_yearly)

# Pre/post comparison for tables
prepost <- data.table(
  period = c("Pre (2009-2015)", "Post (2016-2023)"),
  single_bidder_share = c(
    weighted.mean(pre$single_bidder_share, pre$n_contracts, na.rm = TRUE),
    weighted.mean(post$single_bidder_share, post$n_contracts, na.rm = TRUE)
  ),
  mean_bids = c(
    weighted.mean(pre$mean_bids, pre$n_contracts, na.rm = TRUE),
    weighted.mean(post$mean_bids, post$n_contracts, na.rm = TRUE)
  ),
  n_contracts = c(sum(pre$n_contracts), sum(post$n_contracts))
)
fwrite(prepost, file.path(data_dir, "pre_post_comparison.csv"))
cat("\nPre/post comparison:\n")
print(prepost)

# Validation
stopifnot("Panel has 28 countries" = uniqueN(panel$country) == 28)
stopifnot("Panel has >= 10 years" = uniqueN(panel$contract_year) >= 10)
stopifnot("Single-bidder share in [0,1]" = all(panel$single_bidder_share >= 0 &
                                                  panel$single_bidder_share <= 1))

cat("\n02_clean_data.R complete.\n")
