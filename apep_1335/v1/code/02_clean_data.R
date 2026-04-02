# 02_clean_data.R — Construct analysis panel with treatment variables
# apep_1335: Cannabis Lottery and Local Economic Renewal

source("00_packages.R")

data_dir <- "../data/"

# ============================================================================
# Load saved data
# ============================================================================

qwi_df <- readRDS(file.path(data_dir, "qwi_illinois.rds"))
disp_counties <- readRDS(file.path(data_dir, "dispensary_counties.rds"))
il_counties <- readRDS(file.path(data_dir, "il_counties.rds")) %>%
  mutate(county_fips = as.character(county_fips))
zc_il <- readRDS(file.path(data_dir, "zip_county_il.rds"))

cat("QWI rows:", nrow(qwi_df), "\n")
cat("Dispensary-county pairs:", nrow(disp_counties), "\n")

# ============================================================================
# Re-parse the PDF to classify dispensaries as lottery vs. pre-existing
# ============================================================================

# Read the raw PDF again for detailed parsing
pdf_text <- pdftools::pdf_text(file.path(data_dir, "idfpr_dispensaries.pdf"))

# Build a comprehensive dispensary dataset from the PDF
# The PDF typically has columns: License#, DBA, Address, City, State, Zip, Type, Issue Date

all_lines <- character()
for (p in seq_along(pdf_text)) {
  page_lines <- unlist(strsplit(pdf_text[[p]], "\n"))
  all_lines <- c(all_lines, trimws(page_lines))
}

# Identify lines with social equity markers
se_markers <- c("social equity", "craft grower", "conditional adult use",
                "lottery", "justice involved")

# Parse each dispensary entry
# Strategy: find lines with IL zip codes and dates, then classify
dispensary_entries <- list()

for (i in seq_along(all_lines)) {
  line <- all_lines[i]

  # Must have zip code
  zip_m <- regmatches(line, regexpr("\\b(6[0-9]{4})\\b", line))
  if (length(zip_m) == 0) next

  # Extract date
  date_m <- regmatches(line, gregexpr("\\d{1,2}/\\d{1,2}/\\d{4}", line))[[1]]
  issue_date <- if (length(date_m) > 0) {
    tryCatch(as.Date(date_m[length(date_m)], format = "%m/%d/%Y"), error = function(e) NA)
  } else NA

  # Check if social equity
  is_se <- any(sapply(se_markers, function(m) grepl(m, line, ignore.case = TRUE)))

  # Also check nearby lines (sometimes SE designation is on adjacent line)
  context_start <- max(1, i - 2)
  context_end <- min(length(all_lines), i + 2)
  context <- paste(all_lines[context_start:context_end], collapse = " ")
  is_se <- is_se || any(sapply(se_markers, function(m) grepl(m, context, ignore.case = TRUE)))

  dispensary_entries[[length(dispensary_entries) + 1]] <- data.frame(
    line_num = i,
    zip = zip_m[1],
    issue_date = issue_date,
    is_social_equity = is_se,
    raw = substr(line, 1, 200),
    stringsAsFactors = FALSE
  )
}

disp_parsed <- bind_rows(dispensary_entries)
cat("Total dispensary entries parsed:", nrow(disp_parsed), "\n")

# Remove obvious duplicates (same zip + same date)
disp_parsed <- disp_parsed %>%
  distinct(zip, issue_date, .keep_all = TRUE)

cat("After dedup:", nrow(disp_parsed), "\n")
cat("Social equity dispensaries:", sum(disp_parsed$is_social_equity), "\n")
cat("Non-SE (pre-existing) dispensaries:", sum(!disp_parsed$is_social_equity), "\n")

# ============================================================================
# Classify dispensaries by lottery status using timing
# ============================================================================

# Pre-existing licenses: issued before July 2021 (pre-lottery)
# Lottery licenses: issued July 2021 or later
# The July 2021 lottery date is the key cutoff

lottery_cutoff <- as.Date("2021-07-01")

disp_parsed <- disp_parsed %>%
  mutate(
    is_lottery = !is.na(issue_date) & issue_date >= lottery_cutoff,
    # Use both SE marker and timing for classification
    lottery_status = case_when(
      is_social_equity ~ "lottery_se",
      is_lottery ~ "lottery_other",
      TRUE ~ "pre_existing"
    )
  )

cat("\nDispensary classification:\n")
print(table(disp_parsed$lottery_status))

# ============================================================================
# Map dispensaries to counties and construct treatment timing
# ============================================================================

disp_county <- disp_parsed %>%
  left_join(zc_il %>% mutate(county_fips = as.character(county_fips)), by = "zip") %>%
  filter(!is.na(county_fips))

cat("\nDispensaries mapped to counties:", nrow(disp_county), "\n")

# For each county, find the quarter of first LOTTERY dispensary opening
# This is our treatment variable

disp_county <- disp_county %>%
  mutate(
    issue_year = year(issue_date),
    issue_qtr = quarter(issue_date),
    issue_yearqtr = issue_year + (issue_qtr - 1) / 4
  )

# Treatment timing: first lottery dispensary in each county
# Use issue date as proxy for opening (actual opening lags by ~3-6 months)
# Add a 2-quarter lag to account for buildout
OPENING_LAG_QUARTERS <- 2

county_treatment <- disp_county %>%
  filter(lottery_status %in% c("lottery_se", "lottery_other")) %>%
  group_by(county_fips) %>%
  summarise(
    first_lottery_license_date = min(issue_date, na.rm = TRUE),
    first_lottery_license_yearqtr = min(issue_yearqtr, na.rm = TRUE),
    n_lottery_dispensaries = n(),
    n_se_dispensaries = sum(lottery_status == "lottery_se"),
    .groups = "drop"
  ) %>%
  mutate(
    # Add opening lag (2 quarters after license)
    first_opening_yearqtr = first_lottery_license_yearqtr + OPENING_LAG_QUARTERS * 0.25,
    # Convert to integer period for CS estimator
    # Use quarterly periods: 2018Q1 = 1, 2018Q2 = 2, etc.
    first_treat_period = (year(first_lottery_license_date) - 2018) * 4 +
                          quarter(first_lottery_license_date) + OPENING_LAG_QUARTERS
  )

cat("\nTreated counties:", nrow(county_treatment), "\n")
cat("Lottery dispensaries per county:\n")
print(summary(county_treatment$n_lottery_dispensaries))

# Count pre-existing dispensaries per county
county_preexisting <- disp_county %>%
  filter(lottery_status == "pre_existing") %>%
  group_by(county_fips) %>%
  summarise(n_pre_existing = n(), .groups = "drop")

# ============================================================================
# Construct the analysis panel
# ============================================================================

# Create balanced county-quarter panel
panel_quarters <- expand.grid(
  county_fips = unique(il_counties$county_fips),
  year = 2018:2024,
  quarter = 1:4,
  stringsAsFactors = FALSE
) %>%
  mutate(
    yearqtr = year + (quarter - 1) / 4,
    time_period = (year - 2018) * 4 + quarter  # 1-indexed quarterly periods
  )

# Merge QWI employment data (pivot wide by industry)
qwi_wide <- qwi_df %>%
  select(county_fips, year, quarter, industry_code, Emp, EarnBeg, Payroll) %>%
  pivot_wider(
    id_cols = c(county_fips, year, quarter),
    names_from = industry_code,
    values_from = c(Emp, EarnBeg, Payroll),
    names_sep = "_"
  )

panel <- panel_quarters %>%
  left_join(qwi_wide, by = c("county_fips", "year", "quarter")) %>%
  left_join(il_counties, by = "county_fips") %>%
  left_join(county_treatment, by = "county_fips") %>%
  left_join(county_preexisting, by = "county_fips") %>%
  mutate(
    # Treatment indicator
    first_treat = ifelse(is.na(first_treat_period), 0, first_treat_period),
    treated = ifelse(first_treat > 0 & time_period >= first_treat, 1, 0),
    # Pre-existing dispensary count (control for incumbents)
    n_pre_existing = replace_na(n_pre_existing, 0),
    n_lottery_dispensaries = replace_na(n_lottery_dispensaries, 0),
    # County numeric ID for panel methods
    county_id = as.integer(as.factor(county_fips))
  )

cat("\nPanel dimensions:", nrow(panel), "rows\n")
cat("Counties:", n_distinct(panel$county_fips), "\n")
cat("Time periods:", n_distinct(panel$time_period), "\n")
cat("Treated counties:", sum(panel$first_treat > 0) / n_distinct(panel$time_period), "\n")
cat("Never-treated counties:", sum(panel$first_treat == 0) / n_distinct(panel$time_period), "\n")

# Rename employment variables for clarity
panel <- panel %>%
  rename(
    emp_retail = `Emp_44-45`,
    earn_retail = `EarnBeg_44-45`,
    payroll_retail = `Payroll_44-45`,
    emp_food = Emp_7225,
    earn_food = EarnBeg_7225,
    payroll_food = Payroll_7225,
    emp_total = Emp_00,
    earn_total = EarnBeg_00,
    payroll_total = Payroll_00
  )

# Log outcomes (adding 1 for zeros)
panel <- panel %>%
  mutate(
    log_emp_retail = log(emp_retail + 1),
    log_emp_food = log(emp_food + 1),
    log_emp_total = log(emp_total + 1),
    log_earn_retail = log(earn_retail + 1),
    log_earn_total = log(earn_total + 1)
  )

# Drop rows with all-NA employment (counties with suppressed QWI data)
panel <- panel %>%
  filter(!is.na(emp_total) | !is.na(emp_retail))

cat("\nFinal panel after dropping suppressed counties:", nrow(panel), "rows\n")
cat("Counties retained:", n_distinct(panel$county_fips), "\n")

# Treatment cohort distribution
cohort_dist <- panel %>%
  filter(first_treat > 0) %>%
  distinct(county_fips, first_treat) %>%
  count(first_treat, name = "n_counties")

cat("\nTreatment cohort distribution:\n")
print(cohort_dist)

# ============================================================================
# Save analysis panel
# ============================================================================

saveRDS(panel, file.path(data_dir, "analysis_panel.rds"))
cat("\nSaved analysis panel:", nrow(panel), "rows\n")

# Save treatment summary for diagnostics
treatment_summary <- list(
  n_treated_counties = sum(panel$first_treat > 0) / n_distinct(panel$time_period),
  n_control_counties = sum(panel$first_treat == 0) / n_distinct(panel$time_period),
  n_periods = n_distinct(panel$time_period),
  n_pre_periods = if (nrow(cohort_dist) > 0) min(cohort_dist$first_treat) - 1 else NA,
  cohort_distribution = as.list(setNames(cohort_dist$n_counties, cohort_dist$first_treat))
)

cat("\nTreatment summary:\n")
cat("  Treated counties:", treatment_summary$n_treated_counties, "\n")
cat("  Control counties:", treatment_summary$n_control_counties, "\n")
cat("  Total periods:", treatment_summary$n_periods, "\n")
cat("  Pre-treatment periods:", treatment_summary$n_pre_periods, "\n")
