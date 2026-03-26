## 02_clean_data.R — Construct analysis panels
## apep_1007: Banking the Unbanked by Mandate

source("00_packages.R")

cat("=== Loading raw data ===\n")

# Transposition dates
trans <- fread("../data/transposition_dates.csv")
trans[, transposition_date := as.Date(transposition_date)]

# Global Findex
findex <- fread("../data/findex.csv")

# Eurostat: Internet banking (annual, better coverage than ECB PSS)
ibank <- if (file.exists("../data/eurostat_internet_banking.csv")) {
  fread("../data/eurostat_internet_banking.csv")
} else NULL

# Eurostat: Financial hardship
hardship <- if (file.exists("../data/eurostat_financial_hardship.csv")) {
  fread("../data/eurostat_financial_hardship.csv")
} else NULL

# Placebo: Internet info usage
internet_info <- if (file.exists("../data/eurostat_internet_info.csv")) {
  fread("../data/eurostat_internet_info.csv")
} else NULL

# ECB MIR
mir <- if (file.exists("../data/ecb_mir_deposits.csv")) {
  fread("../data/ecb_mir_deposits.csv")
} else NULL

# Population
pop <- if (file.exists("../data/population.csv")) {
  fread("../data/population.csv")
} else NULL

cat("=== Building main panel: Internet banking (annual) ===\n")

# EU27 country codes
eu27 <- trans$country_code

if (!is.null(ibank) && nrow(ibank) > 0) {
  # Filter to EU27 and reasonable years
  ibank <- ibank[country_code %in% eu27 & year >= 2008 & year <= 2024]

  # Merge with transposition info
  panel_ibank <- merge(ibank, trans[, .(country_code, treatment_year, pre_existing_law)],
                        by = "country_code", all.x = TRUE)

  # Treatment indicator: 1 if transposed by this year
  panel_ibank[, treated := fifelse(!is.na(treatment_year) & year >= treatment_year, 1L, 0L)]

  # For CS-DiD: group = first treatment year (0 for never-treated)
  panel_ibank[, group := fifelse(is.na(treatment_year), 0L, treatment_year)]

  # Numeric country ID
  panel_ibank[, country_id := as.integer(factor(country_code))]

  cat("  Internet banking panel:", nrow(panel_ibank), "obs,",
      uniqueN(panel_ibank$country_code), "countries,",
      uniqueN(panel_ibank$year), "years\n")

  # Count pre-periods by treatment group
  panel_ibank[, .(n_pre = sum(year < treatment_year[1]),
                   n_post = sum(year >= treatment_year[1]),
                   min_year = min(year),
                   max_year = max(year)),
               by = .(group)][order(group)] |> print()
}

cat("\n=== Building Global Findex panel ===\n")

findex_panel <- merge(findex, trans[, .(country_code, treatment_year, pre_existing_law)],
                       by = "country_code", all.x = TRUE)
findex_panel[, treated := fifelse(!is.na(treatment_year) & year >= treatment_year, 1L, 0L)]
findex_panel[, group := fifelse(is.na(treatment_year), 0L, treatment_year)]
findex_panel[, country_id := as.integer(factor(country_code))]

cat("  Findex panel:", nrow(findex_panel), "obs,",
    uniqueN(findex_panel$country_code), "countries\n")

cat("\n=== Building financial hardship panel ===\n")

if (!is.null(hardship) && nrow(hardship) > 0) {
  hardship <- hardship[country_code %in% eu27 & year >= 2008 & year <= 2024]
  panel_hardship <- merge(hardship,
                           trans[, .(country_code, treatment_year, pre_existing_law)],
                           by = "country_code", all.x = TRUE)
  panel_hardship[, treated := fifelse(!is.na(treatment_year) & year >= treatment_year, 1L, 0L)]
  panel_hardship[, group := fifelse(is.na(treatment_year), 0L, treatment_year)]
  panel_hardship[, country_id := as.integer(factor(country_code))]
  cat("  Hardship panel:", nrow(panel_hardship), "obs\n")
}

cat("\n=== Building placebo panel (internet info usage) ===\n")

if (!is.null(internet_info) && nrow(internet_info) > 0) {
  internet_info <- internet_info[country_code %in% eu27 & year >= 2008 & year <= 2024]
  panel_placebo <- merge(internet_info,
                          trans[, .(country_code, treatment_year, pre_existing_law)],
                          by = "country_code", all.x = TRUE)
  panel_placebo[, treated := fifelse(!is.na(treatment_year) & year >= treatment_year, 1L, 0L)]
  panel_placebo[, group := fifelse(is.na(treatment_year), 0L, treatment_year)]
  panel_placebo[, country_id := as.integer(factor(country_code))]
  cat("  Placebo panel:", nrow(panel_placebo), "obs\n")
}

cat("\n=== Building monthly MIR panel ===\n")

if (!is.null(mir) && nrow(mir) > 0) {
  mir <- mir[country_code %in% eu27]
  mir_panel <- merge(mir, trans[, .(country_code, transposition_date, treatment_year,
                                     pre_existing_law)],
                      by = "country_code", all.x = TRUE)

  # Monthly treatment indicator
  mir_panel[, date := as.Date(paste0(year_month, "-01"))]
  mir_panel[, treated := fifelse(!is.na(transposition_date) & date >= transposition_date,
                                  1L, 0L)]
  mir_panel[, group := fifelse(is.na(treatment_year), 0L, treatment_year)]
  mir_panel[, country_id := as.integer(factor(country_code))]
  # Time index for monthly
  mir_panel[, time_index := year * 12 + month]

  cat("  MIR panel:", nrow(mir_panel), "obs,",
      uniqueN(mir_panel$country_code), "countries\n")
}

cat("\n=== Saving analysis panels ===\n")

if (exists("panel_ibank") && nrow(panel_ibank) > 0) {
  fwrite(panel_ibank, "../data/panel_internet_banking.csv")
  cat("  panel_internet_banking.csv\n")
}

fwrite(findex_panel, "../data/panel_findex.csv")
cat("  panel_findex.csv\n")

if (exists("panel_hardship") && nrow(panel_hardship) > 0) {
  fwrite(panel_hardship, "../data/panel_hardship.csv")
  cat("  panel_hardship.csv\n")
}

if (exists("panel_placebo") && nrow(panel_placebo) > 0) {
  fwrite(panel_placebo, "../data/panel_placebo.csv")
  cat("  panel_placebo.csv\n")
}

if (exists("mir_panel") && nrow(mir_panel) > 0) {
  fwrite(mir_panel, "../data/panel_mir.csv")
  cat("  panel_mir.csv\n")
}

cat("\n=== PANEL CONSTRUCTION COMPLETE ===\n")
