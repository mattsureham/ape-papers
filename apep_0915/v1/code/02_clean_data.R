## 02_clean_data.R — Clean and construct analysis dataset
## apep_0915: HAP Emission Bunching at CAA Thresholds

source("00_packages.R")

data_dir <- "../data"

cat("=== Loading raw NEI data ===\n")
nei <- readRDS(file.path(data_dir, "nei_facility_summaries_2012_2021.rds"))
cat("  Raw data:", nrow(nei), "rows x", ncol(nei), "cols\n")

# Clean column names (spaces -> underscores, lowercase)
old_names <- names(nei)
new_names <- gsub("[^a-z0-9]", "_", tolower(old_names))
new_names <- gsub("_+", "_", new_names)
new_names <- gsub("_$", "", new_names)
setnames(nei, old_names, new_names)

cat("  Cleaned column names:\n")
cat("  ", paste(names(nei), collapse = ", "), "\n")

## --- Filter to HAP emissions ---
cat("\n=== Filtering to HAP emissions ===\n")

# Check pollutant types
cat("  Pollutant type values:\n")
print(nei[, .N, by = pollutant_type_s][order(-N)][1:10])

cat("\n  HAP type values:\n")
print(nei[, .N, by = hap_type][order(-N)][1:10])

# Filter to HAP rows — use hap_type column
# HAPs should have a non-empty hap_type field
nei_hap <- nei[!is.na(hap_type) & hap_type != ""]
cat("\n  After filtering to HAP rows:", nrow(nei_hap), "rows\n")

# If that's too few, try pollutant_type_s
if (nrow(nei_hap) < 100000) {
  cat("  WARNING: Few HAP-flagged rows. Trying pollutant_type_s filter...\n")
  nei_hap <- nei[grepl("HAP", pollutant_type_s, ignore.case = TRUE)]
  cat("  After pollutant_type_s HAP filter:", nrow(nei_hap), "rows\n")
}

## --- Convert emissions to tons ---
cat("\n=== Converting emissions to tons ===\n")

# Check emission units
cat("  Emission UOM values:\n")
print(nei_hap[, .N, by = emissions_uom][order(-N)])

nei_hap[, emis_raw := as.numeric(total_emissions)]

# Convert to tons based on UOM
nei_hap[, emis_tons := fcase(
  toupper(emissions_uom) == "TON", emis_raw,
  toupper(emissions_uom) == "TONS", emis_raw,
  toupper(emissions_uom) == "LB", emis_raw / 2000,
  toupper(emissions_uom) == "LBS", emis_raw / 2000,
  default = emis_raw  # assume tons if unclear
)]

# Drop missing/zero
nei_hap <- nei_hap[!is.na(emis_tons) & emis_tons > 0]
cat("  After dropping missing/zero:", nrow(nei_hap), "rows\n")

## --- Aggregate to facility × year level ---
cat("\n=== Constructing facility panels ===\n")

# For the 10-ton threshold: max single-HAP emission per facility-year
# For the 25-ton threshold: total combined HAP per facility-year
fac_panel <- nei_hap[, .(
  max_single_hap_tons = max(emis_tons, na.rm = TRUE),
  total_hap_tons = sum(emis_tons, na.rm = TRUE),
  n_pollutants = .N,
  top_pollutant = pollutant_desc[which.max(emis_tons)]
), by = .(facility_id = eis_facility_id,
          nei_year,
          state,
          naics = primary_naics_code)]

cat("  Facility-year observations:", nrow(fac_panel), "\n")
cat("  Unique facilities:", uniqueN(fac_panel$facility_id), "\n")
cat("  Years:", paste(sort(unique(fac_panel$nei_year)), collapse = ", "), "\n")

## --- Add treatment indicators ---
fac_panel[, `:=`(
  post_oiai = as.integer(nei_year >= 2018),
  near_10ton = as.integer(max_single_hap_tons >= 5 & max_single_hap_tons <= 20),
  near_25ton = as.integer(total_hap_tons >= 15 & total_hap_tons <= 40),
  above_10ton = as.integer(max_single_hap_tons >= 10),
  above_25ton = as.integer(total_hap_tons >= 25),
  dist_10ton = max_single_hap_tons - 10,
  dist_25ton = total_hap_tons - 25
)]

## --- Distribution near 10-ton threshold ---
cat("\n--- Distribution near 10-ton threshold (1-ton bins) ---\n")
bins_10 <- fac_panel[max_single_hap_tons >= 5 & max_single_hap_tons <= 15,
                      .(count = .N),
                      by = .(ton_bin = floor(max_single_hap_tons))][order(ton_bin)]
print(bins_10)

cat("\n--- By pre/post period ---\n")
bins_10_period <- fac_panel[max_single_hap_tons >= 5 & max_single_hap_tons <= 15,
                            .(count = .N),
                            by = .(period = ifelse(post_oiai == 1, "Post", "Pre"),
                                   ton_bin = floor(max_single_hap_tons))][order(period, ton_bin)]
print(dcast(bins_10_period, ton_bin ~ period, value.var = "count"))

## --- Summary statistics ---
cat("\n=== Summary Statistics ===\n")
cat("  Total facility-years:", nrow(fac_panel), "\n")
cat("  Unique facilities:", uniqueN(fac_panel$facility_id), "\n")
cat("  Near 10-ton (5-20 tons):", sum(fac_panel$near_10ton), "\n")
cat("  Near 25-ton (15-40 tons):", sum(fac_panel$near_25ton), "\n")
cat("  Pre-2018 facility-years:", sum(fac_panel$post_oiai == 0), "\n")
cat("  Post-2018 facility-years:", sum(fac_panel$post_oiai == 1), "\n")
cat("\n  Mean max single HAP (tons):", round(mean(fac_panel$max_single_hap_tons), 4), "\n")
cat("  Median:", round(median(fac_panel$max_single_hap_tons), 4), "\n")
cat("  SD:", round(sd(fac_panel$max_single_hap_tons), 4), "\n")

cat("\n  Top 10 states:\n")
print(head(fac_panel[, .(n = uniqueN(facility_id)), by = state][order(-n)], 10))

## --- Save ---
saveRDS(fac_panel, file.path(data_dir, "analysis_panel.rds"))
cat("\nSaved analysis_panel.rds (",
    round(file.size(file.path(data_dir, "analysis_panel.rds")) / 1e6, 1), "MB)\n")
