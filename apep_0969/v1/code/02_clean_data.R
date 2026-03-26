# 02_clean_data.R — Clean and construct panel for DiD analysis
# Paper: The Compliance Cliff (apep_0969)
#
# Uses Labour Force Survey data: monthly hours worked by industry

source("00_packages.R")

# --- Load raw data ---
raw <- fread("../data/lfs_raw.csv")
cat(sprintf("Loaded raw data: %d rows\n", nrow(raw)))

# --- Parse time variable ---
# Time codes are like "2013000101" -> year=2013, month=01
raw[, year := as.integer(substr(time_code, 1, 4))]
raw[, month := as.integer(substr(time_code, 5, 8))]
# Fix: the format is actually YYYYMMMMDD where MMMM is month with padding
# e.g., 2013000101 = 2013, month position 5-6 is "00", then 7-8 is "01"
# Let me check: 2013000101, 2013000202, 2013000303...
# Pattern: YYYY00MMDD where MM is month
raw[, month := as.integer(substr(time_code, 7, 8))]
raw[, ym := as.Date(paste0(year, "-", sprintf("%02d", month), "-01"))]

# --- Variable labels ---
# tab_code 19 = days, 20 = hours
raw[, variable := ifelse(tab_code == "20", "hours", "days")]

# Sex labels
raw[, sex_label := fcase(
  sex == "0", "Both",
  sex == "1", "Male",
  sex == "2", "Female"
)]

# --- Industry labels ---
# From e-Stat metadata for Labour Force Survey
ind_labels <- data.table(
  industry_code = c("00", "01", "04", "05", "08", "09", "10", "35", "36",
                     "42", "51", "58", "59", "62", "67", "71", "75", "78",
                     "82", "85", "95", "98"),
  industry_name = c("All Industries", "Agriculture/Forestry", "Non-agricultural",
                     "Fisheries", "Mining", "Construction", "Manufacturing",
                     "Electricity/Gas/Water", "Information/Communications",
                     "Transport/Postal", "Wholesale/Retail", "Finance/Insurance",
                     "Real Estate", "Professional/Technical Services",
                     "Accommodations/Food", "Personal Services", "Education",
                     "Medical/Welfare", "Compound Services", "Other Services",
                     "Government", "Unclassifiable")
)
# Ensure industry codes are zero-padded 2-digit strings for consistent matching
raw[, industry_code := sprintf("%02d", as.integer(industry_code))]
ind_labels[, industry_code := sprintf("%02d", as.integer(industry_code))]
raw <- merge(raw, ind_labels, by = "industry_code", all.x = TRUE)

# --- Remove aggregate/uninformative categories ---
# Keep only specific industries, not "All Industries" (00), "Non-agricultural" (04),
# "Unclassifiable" (98)
exclude_codes <- c("00", "04", "98")
panel_raw <- raw[!industry_code %in% exclude_codes]

# --- Treatment assignment ---
# Exempt industries under the 2018 Work Style Reform Act (until April 2024):
#   Construction (09), Transport/Postal (42), Medical/Welfare (78)
exempt_codes <- c("09", "42", "78")
panel_raw[, exempt := as.integer(industry_code %in% exempt_codes)]

# Post-treatment: April 2024 onwards
panel_raw[, post := as.integer(ym >= as.Date("2024-04-01"))]

# Relative month (April 2024 = 0)
panel_raw[, rel_month := (year - 2024) * 12 + (month - 4)]

# --- Reshape: separate hours and days into columns ---
# Work with "Both sexes" for the main panel
main_both <- panel_raw[sex_label == "Both"]
panel <- dcast(main_both, industry_code + industry_name + exempt + year + month +
               ym + post + rel_month ~ variable, value.var = "value")

# Remove rows with missing hours
panel <- panel[!is.na(hours)]
cat(sprintf("Panel (both sexes): %d rows\n", nrow(panel)))

# --- Also create sex-specific panels for heterogeneity ---
male_panel <- panel_raw[sex_label == "Male" & variable == "hours",
                        .(industry_code, industry_name, exempt, year, month, ym,
                          post, rel_month, hours = value)]
female_panel <- panel_raw[sex_label == "Female" & variable == "hours",
                          .(industry_code, industry_name, exempt, year, month, ym,
                            post, rel_month, hours = value)]

# --- Numeric identifiers ---
panel[, ind_num := as.integer(factor(industry_code))]
panel[, ym_num := as.integer(factor(ym))]

# --- Restrict to analysis window ---
# Use April 2017 onwards for a clean pre-period
# (avoid first years that might have different industry classifications)
panel <- panel[ym >= as.Date("2017-04-01")]
male_panel <- male_panel[ym >= as.Date("2017-04-01")]
female_panel <- female_panel[ym >= as.Date("2017-04-01")]

cat(sprintf("Panel (analysis window 2017-04 to latest): %d rows\n", nrow(panel)))

# --- Summary statistics ---
cat("\n=== Summary Statistics ===\n")
cat(sprintf("Industries: %d\n", uniqueN(panel$industry_code)))
cat(sprintf("Time periods: %s to %s (%d months)\n",
            min(panel$ym), max(panel$ym), uniqueN(panel$ym)))
cat(sprintf("Pre-treatment months: %d\n", uniqueN(panel[post == 0, ym])))
cat(sprintf("Post-treatment months: %d\n", uniqueN(panel[post == 1, ym])))
cat(sprintf("Exempt industries: %s\n",
            paste(unique(panel[exempt == 1, industry_name]), collapse = ", ")))
cat(sprintf("Control industries: %d\n", uniqueN(panel[exempt == 0, industry_code])))

cat("\n--- Hours by group (pre-treatment) ---\n")
pre_summ <- panel[post == 0,
                  .(mean_hrs = round(mean(hours, na.rm = TRUE), 1),
                    sd_hrs = round(sd(hours, na.rm = TRUE), 1),
                    mean_days = round(mean(days, na.rm = TRUE), 1)),
                  by = .(exempt)]
print(pre_summ)

cat("\n--- Hours by industry (pre-treatment) ---\n")
ind_summ <- panel[post == 0,
                  .(mean_hrs = round(mean(hours, na.rm = TRUE), 1),
                    sd_hrs = round(sd(hours, na.rm = TRUE), 1)),
                  by = .(industry_code, industry_name, exempt)]
ind_summ <- ind_summ[order(-exempt, -mean_hrs)]
print(ind_summ, nrows = 30)

# --- Save cleaned panels ---
fwrite(panel, "../data/panel_clean.csv")
fwrite(male_panel, "../data/panel_male.csv")
fwrite(female_panel, "../data/panel_female.csv")

cat(sprintf("\nSaved panels: %d (main), %d (male), %d (female) rows\n",
            nrow(panel), nrow(male_panel), nrow(female_panel)))
