## 02_clean_data.R — Clean and merge Fingertips data
## APEP-0691: Sugar Tax Without Sticker Shock

source("00_packages.R")

# ============================================================================
# Load raw data
# ============================================================================

dental_raw  <- fread("../data/dental_raw.csv")
obesity_raw <- fread("../data/obesity_raw.csv")
copd_raw    <- fread("../data/copd_raw.csv")
imd_raw     <- fread("../data/imd_raw.csv")

# ============================================================================
# Explore area types and filter to English upper-tier LAs
# ============================================================================

# English upper-tier local authorities: E06 (Unitary), E08 (Metro boroughs),
# E09 (London boroughs), E10 (Counties)
english_la_pattern <- "^E0[6-9]|^E10"

cat("=== Dental data structure ===\n")
cat("Area types present:\n")
print(dental_raw[, .N, by = .(`Area Type`)][order(-N)])
cat("\nArea code prefixes:\n")
dental_raw[, prefix := substr(`Area Code`, 1, 3)]
print(dental_raw[, .N, by = prefix][order(-N)])

# Filter dental to English LAs
dental <- dental_raw[grepl(english_la_pattern, `Area Code`)]
cat("\nDental after LA filter:", nrow(dental), "rows,",
    length(unique(dental$`Area Code`)), "LAs\n")
cat("Time periods:", paste(sort(unique(dental$`Time period`)), collapse = ", "), "\n")

# Filter to the "Persons" sex and relevant age
dental <- dental[Sex == "Persons"]
cat("Dental after sex filter:", nrow(dental), "rows\n")

# Keep key columns
dental <- dental[, .(
  area_code = `Area Code`,
  area_name = `Area Name`,
  time_period = `Time period`,
  value = Value,
  count = Count,
  denominator = Denominator,
  lower_ci = `Lower CI 95.0 limit`,
  upper_ci = `Upper CI 95.0 limit`
)]

# Create numeric year from academic year format (e.g., "2007/08" -> 2007)
dental[, year := as.integer(substr(time_period, 1, 4))]

cat("\n=== Obesity data structure ===\n")
obesity_raw[, prefix := substr(`Area Code`, 1, 3)]
cat("Area code prefixes:\n")
print(obesity_raw[, .N, by = prefix][order(-N)])

# Filter obesity to English LAs
obesity <- obesity_raw[grepl(english_la_pattern, `Area Code`) & Sex == "Persons"]
cat("Obesity after LA + sex filter:", nrow(obesity), "rows,",
    length(unique(obesity$`Area Code`)), "LAs\n")
cat("Time periods:", paste(sort(unique(obesity$`Time period`)), collapse = ", "), "\n")

obesity <- obesity[, .(
  area_code = `Area Code`,
  area_name = `Area Name`,
  time_period = `Time period`,
  value = Value,
  count = Count,
  denominator = Denominator,
  lower_ci = `Lower CI 95.0 limit`,
  upper_ci = `Upper CI 95.0 limit`
)]
obesity[, year := as.integer(substr(time_period, 1, 4))]

cat("\n=== COPD data structure ===\n")
copd_raw[, prefix := substr(`Area Code`, 1, 3)]

# Filter COPD to English LAs
copd <- copd_raw[grepl(english_la_pattern, `Area Code`) & Sex == "Persons"]
cat("COPD after LA + sex filter:", nrow(copd), "rows,",
    length(unique(copd$`Area Code`)), "LAs\n")
cat("Time periods:", paste(sort(unique(copd$`Time period`)), collapse = ", "), "\n")

copd <- copd[, .(
  area_code = `Area Code`,
  area_name = `Area Name`,
  time_period = `Time period`,
  value = Value,
  count = Count,
  denominator = Denominator,
  lower_ci = `Lower CI 95.0 limit`,
  upper_ci = `Upper CI 95.0 limit`
)]
copd[, year := as.integer(substr(time_period, 1, 4))]

# ============================================================================
# IMD deprivation — get LA-level scores
# ============================================================================

cat("\n=== IMD data structure ===\n")
imd_raw[, prefix := substr(`Area Code`, 1, 3)]
cat("Area code prefixes:\n")
print(imd_raw[, .N, by = prefix][order(-N)])

# Filter to English LAs matching our outcome data
imd <- imd_raw[grepl(english_la_pattern, `Area Code`) & Sex == "Persons"]
cat("IMD after LA filter:", nrow(imd), "rows,",
    length(unique(imd$`Area Code`)), "LAs\n")

# IMD score — higher = more deprived
imd_scores <- imd[, .(
  area_code = `Area Code`,
  area_name = `Area Name`,
  imd_score = Value
)]

# Remove duplicates (keep first)
imd_scores <- unique(imd_scores, by = "area_code")

cat("\nIMD score distribution:\n")
cat("  Mean:", round(mean(imd_scores$imd_score, na.rm = TRUE), 2), "\n")
cat("  SD:", round(sd(imd_scores$imd_score, na.rm = TRUE), 2), "\n")
cat("  Min:", round(min(imd_scores$imd_score, na.rm = TRUE), 2), "\n")
cat("  Max:", round(max(imd_scores$imd_score, na.rm = TRUE), 2), "\n")
cat("  N LAs:", sum(!is.na(imd_scores$imd_score)), "\n")

# Create deprivation quintiles
imd_scores[, imd_quintile := cut(imd_score,
                                  breaks = quantile(imd_score, probs = 0:5/5, na.rm = TRUE),
                                  labels = 1:5, include.lowest = TRUE)]
imd_scores[, imd_quintile := as.integer(imd_quintile)]

# Standardize IMD for regression (mean 0, SD 1)
imd_scores[, imd_std := (imd_score - mean(imd_score, na.rm = TRUE)) /
             sd(imd_score, na.rm = TRUE)]

# ============================================================================
# Merge outcomes with IMD
# ============================================================================

# Treatment period indicators
# Announcement: March 2016 → academic year 2016/17 onward
# Implementation: April 2018 → academic year 2018/19 onward

dental_panel <- merge(dental, imd_scores, by = "area_code", all.x = TRUE,
                      suffixes = c("", ".imd"))
dental_panel[, post_announce := as.integer(year >= 2016)]
dental_panel[, post_implement := as.integer(year >= 2018)]
dental_panel <- dental_panel[!is.na(imd_score) & !is.na(value)]

cat("\n=== Dental panel ===\n")
cat("Observations:", nrow(dental_panel), "\n")
cat("LAs:", length(unique(dental_panel$area_code)), "\n")
cat("Waves:", length(unique(dental_panel$year)), "\n")
cat("Years:", paste(sort(unique(dental_panel$year)), collapse = ", "), "\n")
cat("Pre-announcement waves:", sum(unique(dental_panel$year) < 2016), "\n")
cat("Post-announcement waves:", sum(unique(dental_panel$year) >= 2016), "\n")

obesity_panel <- merge(obesity, imd_scores, by = "area_code", all.x = TRUE,
                       suffixes = c("", ".imd"))
obesity_panel[, post_announce := as.integer(year >= 2016)]
obesity_panel[, post_implement := as.integer(year >= 2018)]
obesity_panel <- obesity_panel[!is.na(imd_score) & !is.na(value)]

cat("\n=== Obesity panel ===\n")
cat("Observations:", nrow(obesity_panel), "\n")
cat("LAs:", length(unique(obesity_panel$area_code)), "\n")
cat("Years:", paste(sort(unique(obesity_panel$year)), collapse = ", "), "\n")
cat("Pre-announcement years:", sum(unique(obesity_panel$year) < 2016), "\n")
cat("Post-announcement years:", sum(unique(obesity_panel$year) >= 2016), "\n")

copd_panel <- merge(copd, imd_scores, by = "area_code", all.x = TRUE,
                    suffixes = c("", ".imd"))
copd_panel[, post_announce := as.integer(year >= 2016)]
copd_panel[, post_implement := as.integer(year >= 2018)]
copd_panel <- copd_panel[!is.na(imd_score) & !is.na(value)]

cat("\n=== COPD panel ===\n")
cat("Observations:", nrow(copd_panel), "\n")
cat("LAs:", length(unique(copd_panel$area_code)), "\n")
cat("Years:", paste(sort(unique(copd_panel$year)), collapse = ", "), "\n")

# ============================================================================
# Save cleaned panels
# ============================================================================

fwrite(dental_panel, "../data/dental_panel.csv")
fwrite(obesity_panel, "../data/obesity_panel.csv")
fwrite(copd_panel, "../data/copd_panel.csv")
fwrite(imd_scores, "../data/imd_scores.csv")

cat("\n=== All panels saved successfully ===\n")
