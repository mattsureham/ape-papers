## 02_clean_data.R — Clean and construct analysis variables
## apep_0759: Simplified to Compete

source("00_packages.R")

data_dir <- "../data"
contracts <- readRDS(file.path(data_dir, "contracts_raw.rds"))
cat(sprintf("Loaded %s raw contracts\n", format(nrow(contracts), big.mark = ",")))

## ---- Treatment assignment ----
contracts[, treated := as.integer(band == "treated")]
contracts[, post := as.integer(fiscal_year >= 2021L)]
contracts[, did := treated * post]

## ---- Outcome variables ----
# 1. Number of offers (competition intensity)
contracts[, n_offers := as.numeric(num_offers)]
p99 <- quantile(contracts$n_offers, 0.99, na.rm = TRUE)
contracts[, n_offers_w := pmin(n_offers, p99)]

# 2. Competed indicator
contracts[, fully_competed := as.integer(extent_competed %in% c("A", "D", "E", "CDO", "F"))]
contracts[, not_competed := as.integer(extent_competed %in% c("B", "G", "NDO"))]

# 3. Small business indicator
contracts[, small_business := as.integer(!is.na(type_set_aside) & type_set_aside != "" &
                                          type_set_aside != "NONE")]

## ---- NAICS sector (2-digit) ----
# Use naics2 from the detail enrichment if available, otherwise derive from naics
contracts[is.na(naics2) & !is.na(naics), naics2 := substr(naics, 1, 2)]

# For analysis: keep contracts with at least extent_competed
contracts_full <- contracts[!is.na(extent_competed)]
cat(sprintf("With competition data: %s contracts\n", format(nrow(contracts_full), big.mark = ",")))

## ---- Agency grouping ----
contracts_full[, agency := awarding_agency]

## ---- Create naics2 factor for FE ----
contracts_full[is.na(naics2), naics2 := "99"]  # unknown sector

## ---- Fiscal year-quarter proxy ----
# We have fiscal year from the search; use it directly
contracts_full[, fyq := as.character(fiscal_year)]

## ---- Donut variable ----
contracts_full[, near_boundary := as.integer(
  (award_amount >= 145000 & award_amount <= 155000) |
  (award_amount >= 245000 & award_amount <= 255000)
)]

## ---- Summary ----
cat("\n--- Contract counts by band and period ---\n")
print(contracts_full[, .N, by = .(band, post)][order(band, post)])

cat("\n--- Mean outcomes by band × period ---\n")
print(contracts_full[, .(mean_offers = mean(n_offers_w, na.rm = TRUE),
                         pct_competed = mean(fully_competed, na.rm = TRUE),
                         pct_sb = mean(small_business, na.rm = TRUE),
                         pct_sole = mean(not_competed, na.rm = TRUE)),
                    by = .(band, post)][order(band, post)])

## ---- Save ----
fwrite(contracts_full, file.path(data_dir, "contracts_clean.csv"))
saveRDS(contracts_full, file.path(data_dir, "contracts_clean.rds"))
cat(sprintf("\nSaved %s clean contracts\n", format(nrow(contracts_full), big.mark = ",")))
