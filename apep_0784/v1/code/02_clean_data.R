# 02_clean_data.R — Clean and construct analysis dataset
# APEP paper apep_0784: OSHA Heat NEP

source("00_packages.R")

data_dir <- "../data/"

# ============================================================
# 1. Load and stack all ITA years
# ============================================================
cat("=== Loading ITA Data ===\n")

ita_files <- list.files(data_dir, pattern = "^ita_20[0-9]{2}\\.csv$", full.names = TRUE)
cat(sprintf("  Found %d ITA files\n", length(ita_files)))

all_years <- lapply(ita_files, function(f) {
  dt <- fread(f, select = c("company_name", "establishment_name", "state", "zip_code",
                             "naics_code", "industry_description",
                             "annual_average_employees", "total_hours_worked",
                             "no_injuries_illnesses", "total_deaths",
                             "total_dafw_cases", "total_djtr_cases", "total_other_cases",
                             "total_injuries", "total_skin_disorders",
                             "total_respiratory_conditions", "total_other_illnesses",
                             "total_poisonings", "total_hearing_loss",
                             "establishment_type", "size", "year_filing_for"))
  dt
})

ita <- rbindlist(all_years, fill = TRUE)
cat(sprintf("  Combined: %d rows\n", nrow(ita)))

# ============================================================
# 2. Clean variables
# ============================================================
cat("\n=== Cleaning Variables ===\n")

# Year
ita[, year := as.integer(year_filing_for)]
ita <- ita[year >= 2016 & year <= 2023]

# State — standardize
ita[, state := toupper(trimws(state))]
ita <- ita[nchar(state) == 2]  # Keep only valid 2-letter state codes

# NAICS code — extract 2-digit supersector
ita[, naics2 := substr(as.character(naics_code), 1, 2)]

# Hours and employees
ita[, hours := as.numeric(total_hours_worked)]
ita[, employees := as.numeric(annual_average_employees)]

# Drop observations with zero or missing hours (can't compute rates)
ita <- ita[!is.na(hours) & hours > 0]
ita <- ita[!is.na(employees) & employees > 0]

# ============================================================
# 3. Classify industries as NEP-targeted (high-heat) vs. not
# ============================================================
cat("\n=== Classifying Industries ===\n")

# OSHA Heat NEP (CPL 03-00-024) targets:
# - Agriculture (11)
# - Construction (23)
# - Manufacturing (31-33)
# - Transportation/Warehousing (48-49) — outdoor/loading dock
# - Admin/Waste/Remediation (56) — includes landscaping (NAICS 561730)
# - Accommodation/Food (72) — outdoor restaurants, kitchens
#
# Non-targeted (low-heat) comparison industries:
# - Information (51), Finance (52), Real Estate (53), Professional (54),
# - Management (55), Education (61), Healthcare (62), Other (81)

high_heat_naics <- c("11", "21", "22", "23", "31", "32", "33", "48", "49", "56", "72")
low_heat_naics <- c("42", "44", "45", "51", "52", "53", "54", "55", "61", "62", "71", "81")

ita[, high_heat := as.integer(naics2 %in% high_heat_naics)]
ita[, industry_group := ifelse(high_heat == 1, "High-Heat (NEP-Targeted)",
                                "Low-Heat (Non-Targeted)")]

# Keep only classifiable industries
ita <- ita[naics2 %in% c(high_heat_naics, low_heat_naics)]

cat(sprintf("  High-heat establishments: %d\n", sum(ita$high_heat == 1)))
cat(sprintf("  Low-heat establishments: %d\n", sum(ita$high_heat == 0)))

# ============================================================
# 4. Compute injury rates
# ============================================================
cat("\n=== Computing Injury Rates ===\n")

# Total Recordable Case (TRC) rate per 200,000 hours worked
# This is the standard OSHA rate formula
ita[, total_cases := total_deaths + total_dafw_cases + total_djtr_cases + total_other_cases]
ita[, trc_rate := (total_cases / hours) * 200000]

# Illness rate (skin + respiratory + other illness + poisoning)
ita[, total_illnesses := total_skin_disorders + total_respiratory_conditions +
      total_other_illnesses + total_poisonings]
ita[, illness_rate := (total_illnesses / hours) * 200000]

# Injury-only rate
ita[, injury_only := total_injuries]
ita[, injury_rate := (injury_only / hours) * 200000]

# DART rate (Days Away, Restricted, or Transferred)
ita[, dart_cases := total_dafw_cases + total_djtr_cases]
ita[, dart_rate := (dart_cases / hours) * 200000]

# Winsorize extreme rates (top 1%) to reduce outlier influence
for (v in c("trc_rate", "illness_rate", "injury_rate", "dart_rate")) {
  p99 <- quantile(ita[[v]], 0.99, na.rm = TRUE)
  ita[get(v) > p99, (v) := p99]
}

# ============================================================
# 5. Merge state heat exposure
# ============================================================
cat("\n=== Merging State Heat Data ===\n")

state_heat <- fread(file.path(data_dir, "state_heat.csv"))
ita <- merge(ita, state_heat, by = "state", all.x = TRUE)

# Drop states without heat data (e.g., territories)
ita <- ita[!is.na(hot_state)]

# ============================================================
# 6. Create treatment variables
# ============================================================
cat("\n=== Creating Treatment Variables ===\n")

# Post-NEP indicator (April 2022 — using annual data, 2022+ is post)
ita[, post := as.integer(year >= 2022)]

# DiD interaction
ita[, did := high_heat * post]

# Triple-DiD interaction
ita[, triple_did := high_heat * post * hot_state]

# Create industry-state identifier for FE
ita[, naics_state := paste0(naics2, "_", state)]

# Create establishment-level panel ID where possible
ita[, estab_id := paste0(establishment_name, "_", state, "_", zip_code, "_", naics_code)]

# ============================================================
# 7. Summary statistics
# ============================================================
cat("\n=== Summary Statistics ===\n")

# By industry group and period
summary_stats <- ita[, .(
  n_estab = .N,
  mean_employees = mean(employees, na.rm = TRUE),
  mean_hours = mean(hours, na.rm = TRUE),
  mean_trc_rate = mean(trc_rate, na.rm = TRUE),
  sd_trc_rate = sd(trc_rate, na.rm = TRUE),
  mean_illness_rate = mean(illness_rate, na.rm = TRUE),
  sd_illness_rate = sd(illness_rate, na.rm = TRUE),
  mean_dart_rate = mean(dart_rate, na.rm = TRUE),
  sd_dart_rate = sd(dart_rate, na.rm = TRUE)
), by = .(industry_group, post)]

print(summary_stats)

# Overall summary
overall <- ita[, .(
  n = .N,
  n_estab_unique = uniqueN(estab_id),
  n_states = uniqueN(state),
  years = paste(range(year), collapse = "-"),
  mean_trc = round(mean(trc_rate, na.rm = TRUE), 2),
  sd_trc = round(sd(trc_rate, na.rm = TRUE), 2),
  mean_dart = round(mean(dart_rate, na.rm = TRUE), 2),
  sd_dart = round(sd(dart_rate, na.rm = TRUE), 2)
)]

cat("\nOverall:\n")
print(overall)

# ============================================================
# 8. Save clean dataset
# ============================================================
cat("\n=== Saving Clean Dataset ===\n")

# Keep only needed columns
analysis_vars <- c("estab_id", "state", "year", "naics2", "naics_code",
                    "industry_description", "employees", "hours",
                    "total_cases", "total_illnesses", "injury_only", "dart_cases",
                    "total_deaths",
                    "trc_rate", "illness_rate", "injury_rate", "dart_rate",
                    "high_heat", "industry_group", "hot_state", "avg_summer_temp",
                    "post", "did", "triple_did", "naics_state")

analysis <- ita[, ..analysis_vars]
fwrite(analysis, file.path(data_dir, "analysis_panel.csv"))

cat(sprintf("  Saved analysis panel: %d obs × %d vars\n", nrow(analysis), ncol(analysis)))
cat(sprintf("  Years: %d-%d\n", min(analysis$year), max(analysis$year)))
cat(sprintf("  Unique establishments: %d\n", uniqueN(analysis$estab_id)))
cat(sprintf("  States: %d\n", uniqueN(analysis$state)))

cat("\nData cleaning complete.\n")
