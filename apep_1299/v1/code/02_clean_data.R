# 02_clean_data.R — Construct analysis dataset
# The Deportation Dividend: Immigration Judge Leniency and Origin-Country Remittances

source("00_packages.R")

# ===================================================================
# 1. Load and process EOIR case data
# ===================================================================
cat("=== Loading EOIR case data ===\n")

eoir <- as.data.table(arrow::read_parquet("../data/eoir_cases.parquet"))
cat(sprintf("  Loaded %s cases\n", format(nrow(eoir), big.mark = ",")))

# Extract completion year from date
eoir[, comp_year := as.integer(format(final_completion_date, "%Y"))]
# Fallback to ij_final_date if completion date missing
eoir[is.na(comp_year), comp_year := as.integer(format(ij_final_date, "%Y"))]

cat(sprintf("  Year range: %d - %d\n",
            min(eoir$comp_year, na.rm = TRUE), max(eoir$comp_year, na.rm = TRUE)))

# ===================================================================
# 2. Filter to completed cases with clear outcomes
# ===================================================================
cat("\n=== Filtering cases ===\n")

eoir_clean <- eoir[
  !is.na(nationality) & nationality != "" &
  !is.na(judge_name) & judge_name != "" &
  !is.na(case_outcome) & case_outcome != "" &
  !is.na(comp_year) &
  comp_year >= 2001 & comp_year <= 2023 &
  # Exclude generic/visiting judges
  !grepl("Visiting|IAD Judge|Clerical", judge_name, ignore.case = TRUE)
]

cat(sprintf("  After filtering: %s cases\n", format(nrow(eoir_clean), big.mark = ",")))

# Classify outcomes
# Grants: Relief Granted, Withholding variants
# Removals: Remove, Voluntary Departure
eoir_clean[, granted := as.integer(case_outcome %in% c(
  "Relief Granted",
  "Remove-INA Withholding Granted",
  "Remove-CAT Withholding Granted"
))]
eoir_clean[, removed := as.integer(case_outcome %in% c(
  "Remove",
  "Voluntary Departure"
))]

# Keep only cases with clear grant or removal
eoir_final <- eoir_clean[granted == 1 | removed == 1]
cat(sprintf("  Cases with clear grant/removal: %s\n",
            format(nrow(eoir_final), big.mark = ",")))
cat(sprintf("    Grants: %s (%.1f%%)\n",
            format(sum(eoir_final$granted), big.mark = ","),
            100 * mean(eoir_final$granted)))
cat(sprintf("    Removals: %s (%.1f%%)\n",
            format(sum(eoir_final$removed), big.mark = ","),
            100 * mean(eoir_final$removed)))

# ===================================================================
# 3. Compute judge leniency (leave-nationality-out)
# ===================================================================
cat("\n=== Computing judge leniency ===\n")

# For each judge × nationality, compute case counts and grants
judge_nat <- eoir_final[, .(
  n_cases = .N,
  n_grants = sum(granted)
), by = .(judge_name, nationality)]

# Judge totals (across all nationalities)
judge_totals <- eoir_final[, .(
  total_cases = .N,
  total_grants = sum(granted)
), by = judge_name]

# Leave-nationality-out leniency for each judge-nationality pair
judge_nat <- merge(judge_nat, judge_totals, by = "judge_name")
judge_nat[, leniency_loo := fifelse(
  total_cases - n_cases >= 50,  # Require at least 50 other-nationality cases
  (total_grants - n_grants) / (total_cases - n_cases),
  NA_real_
)]

cat(sprintf("  Unique judges: %d\n", uniqueN(judge_nat$judge_name)))
cat(sprintf("  Judge-nationality pairs with valid LOO: %d\n",
            sum(!is.na(judge_nat$leniency_loo))))
cat(sprintf("  Leniency range: [%.3f, %.3f], SD=%.3f\n",
            min(judge_nat$leniency_loo, na.rm = TRUE),
            max(judge_nat$leniency_loo, na.rm = TRUE),
            sd(judge_nat$leniency_loo, na.rm = TRUE)))

# ===================================================================
# 4. Assign LOO leniency to each case, then aggregate to nat × year
# ===================================================================
cat("\n=== Aggregating to nationality × year ===\n")

# Merge LOO leniency back to case level
eoir_iv <- merge(eoir_final, judge_nat[, .(judge_name, nationality, leniency_loo)],
                 by = c("judge_name", "nationality"), all.x = TRUE)

# Nationality × year aggregation
nat_year <- eoir_iv[!is.na(leniency_loo), .(
  n_cases = .N,
  n_grants = sum(granted),
  n_removed = sum(removed),
  grant_rate = mean(granted),
  # Instrument: case-weighted average LOO leniency
  leniency_iv = mean(leniency_loo),
  n_judges = uniqueN(judge_name)
), by = .(nationality, year = comp_year)]

cat(sprintf("  Nationality × year obs: %d\n", nrow(nat_year)))
cat(sprintf("  Nationalities: %d\n", uniqueN(nat_year$nationality)))

# ===================================================================
# 5. Map nationality to ISO3
# ===================================================================
cat("\n=== Mapping nationality to ISO3 ===\n")

nat_iso3 <- data.table(
  nationality = c(
    "Mexico", "Guatemala", "Honduras", "El Salvador", "China",
    "India", "Haiti", "Brazil", "Colombia", "Ecuador",
    "Peru", "Dominican Republic", "Jamaica", "Nigeria", "Ethiopia",
    "Pakistan", "Philippines", "Vietnam", "Nicaragua", "Venezuela",
    "Ghana", "Kenya", "Egypt", "Bangladesh", "Cuba",
    "Guyana", "Trinidad And Tobago", "Costa Rica", "Panama", "Uruguay"
  ),
  iso3 = c(
    "MEX", "GTM", "HND", "SLV", "CHN",
    "IND", "HTI", "BRA", "COL", "ECU",
    "PER", "DOM", "JAM", "NGA", "ETH",
    "PAK", "PHL", "VNM", "NIC", "VEN",
    "GHA", "KEN", "EGY", "BGD", "CUB",
    "GUY", "TTO", "CRI", "PAN", "URY"
  )
)

nat_year <- merge(nat_year, nat_iso3, by = "nationality", all.x = TRUE)

# Check which nationalities in the data don't have ISO3 matches
unmatched <- nat_year[is.na(iso3), .(total_cases = sum(n_cases)), by = nationality][order(-total_cases)]
cat("  Unmatched nationalities (top 10 by cases):\n")
print(head(unmatched, 10))

# Try partial matching for remaining
# Common EOIR nationality names that differ from clean names
extra_matches <- data.table(
  nationality = c("Trinidad", "Korea, South", "Russia", "Ukraine", "Georgia",
                   "Albania", "Cameroon", "Guinea", "Senegal", "Mauritania",
                   "Ivory Coast", "Nepal", "Sri Lanka", "Burma", "Indonesia",
                   "Togo", "Congo", "Somalia", "Eritrea", "Lebanon"),
  iso3 = c("TTO", "KOR", "RUS", "UKR", "GEO",
            "ALB", "CMR", "GIN", "SEN", "MRT",
            "CIV", "NPL", "LKA", "MMR", "IDN",
            "TGO", "COD", "SOM", "ERI", "LBN")
)

for (i in seq_len(nrow(extra_matches))) {
  nat_year[is.na(iso3) & grepl(extra_matches$nationality[i], nationality, ignore.case = TRUE),
           iso3 := extra_matches$iso3[i]]
}

cat(sprintf("  Matched %d of %d nat-year obs to ISO3 (%d countries)\n",
            sum(!is.na(nat_year$iso3)), nrow(nat_year),
            uniqueN(nat_year$iso3[!is.na(nat_year$iso3)])))

# ===================================================================
# 6. Merge with World Bank data
# ===================================================================
cat("\n=== Merging with World Bank data ===\n")

wb_data <- fread("../data/wb_data.csv")

# Keep only observations with ISO3 match
analysis <- merge(nat_year[!is.na(iso3)], wb_data, by = c("iso3", "year"), all.x = TRUE)

# Create key variables
analysis[, log_remit := log(remittances_usd)]
analysis[, log_remit_pc := log(remittances_usd / population)]
analysis[, remit_gdp_share := remittances_usd / gdp_usd * 100]  # Percentage

# Filter to observations with non-missing key variables
analysis <- analysis[!is.na(log_remit) & !is.na(leniency_iv)]

# Require at least 100 cases per nationality-year for reliable estimates
analysis <- analysis[n_cases >= 100]

cat(sprintf("\n  Final analysis dataset: %d obs\n", nrow(analysis)))
cat(sprintf("  Countries: %d\n", uniqueN(analysis$iso3)))
cat(sprintf("  Years: %d - %d\n", min(analysis$year), max(analysis$year)))
cat(sprintf("  Total cases underlying: %s\n",
            format(sum(analysis$n_cases), big.mark = ",")))

# Summary stats
cat("\n  Key variable means:\n")
cat(sprintf("    Cases/country-year: %.0f\n", mean(analysis$n_cases)))
cat(sprintf("    Grant rate: %.3f (SD: %.3f)\n",
            mean(analysis$grant_rate), sd(analysis$grant_rate)))
cat(sprintf("    LOO leniency: %.3f (SD: %.3f)\n",
            mean(analysis$leniency_iv), sd(analysis$leniency_iv)))
cat(sprintf("    Remittances: $%.1f bn (SD: $%.1f bn)\n",
            mean(analysis$remittances_usd) / 1e9,
            sd(analysis$remittances_usd) / 1e9))
cat(sprintf("    Corr(grant_rate, leniency_iv): %.3f\n",
            cor(analysis$grant_rate, analysis$leniency_iv)))

# ===================================================================
# 7. Save analysis dataset
# ===================================================================
fwrite(analysis, "../data/analysis.csv")
saveRDS(analysis, "../data/analysis.rds")

cat("\n=== Clean data complete ===\n")
