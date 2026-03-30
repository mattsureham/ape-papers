## 02_clean_data.R — Parse and construct analysis panel for apep_1125
## UK Breathing Space and personal insolvency

source("00_packages.R")

data_dir <- "data"

# ============================================================================
# 1. Parse E/W insolvency by LA (2015-2025)
# ============================================================================
cat("=== Parsing E/W insolvency data ===\n")

ew_file <- file.path(data_dir, "ew_insolvency_location_2015_2025.xlsx")
year_cols <- paste0("y", 2015:2025)
col_names <- c("code", "name", "geog_type", year_cols, "notes")

# Parse each insolvency type
parse_insolvency_sheet <- function(sheet, var_name) {
  df <- read_excel(ew_file, sheet = sheet, skip = 4, col_names = FALSE)
  # Determine actual number of columns
  ncols <- ncol(df)
  if (ncols == 15) {
    names(df) <- col_names
  } else if (ncols == 14) {
    names(df) <- col_names[1:14]
  } else {
    stop(paste("Unexpected column count in", sheet, ":", ncols))
  }

  # Keep only LA-level geographies
  la_types <- c("London Borough", "Metropolitan District",
                "Non-metropolitan District", "Unitary Authority")
  df <- df %>%
    filter(geog_type %in% la_types) %>%
    select(code, name, geog_type, starts_with("y")) %>%
    pivot_longer(cols = starts_with("y"),
                 names_to = "year",
                 values_to = var_name) %>%
    mutate(year = as.integer(gsub("y", "", year)),
           !!var_name := as.numeric(!!sym(var_name)))
  return(df)
}

total_insolvencies <- parse_insolvency_sheet("Table_1a", "total_insolvencies")
bankruptcies <- parse_insolvency_sheet("Table_2a", "bankruptcies")
dros <- parse_insolvency_sheet("Table_3a", "dros")
ivas <- parse_insolvency_sheet("Table_4a", "ivas")

cat("  Total insolvencies parsed:", nrow(total_insolvencies), "rows\n")
cat("  Unique LAs:", n_distinct(total_insolvencies$code), "\n")
cat("  Years:", paste(sort(unique(total_insolvencies$year)), collapse = ", "), "\n")

# Merge insolvency types
ew_insolvency <- total_insolvencies %>%
  left_join(bankruptcies %>% select(code, year, bankruptcies),
            by = c("code", "year")) %>%
  left_join(dros %>% select(code, year, dros),
            by = c("code", "year")) %>%
  left_join(ivas %>% select(code, year, ivas),
            by = c("code", "year"))

# ============================================================================
# 2. Parse Breathing Space registrations by LA (2021-2025)
# ============================================================================
cat("=== Parsing Breathing Space registration data ===\n")

bs_df <- read_excel(ew_file, sheet = "Table_5a", skip = 6, col_names = FALSE)
bs_ncols <- ncol(bs_df)
bs_year_cols <- paste0("y", 2021:2025)

if (bs_ncols >= 9) {
  bs_col_names <- c("code", "name", "geog_type", bs_year_cols, "notes")
  if (bs_ncols == 9) {
    names(bs_df) <- bs_col_names[1:9]
  } else {
    names(bs_df) <- bs_col_names[1:bs_ncols]
  }
} else {
  # Fewer columns than expected — adjust
  bs_n_years <- bs_ncols - 3
  bs_col_names <- c("code", "name", "geog_type", paste0("y", 2021:(2020 + bs_n_years)))
  names(bs_df) <- bs_col_names
}

la_types <- c("London Borough", "Metropolitan District",
              "Non-metropolitan District", "Unitary Authority")

bs_la <- bs_df %>%
  filter(geog_type %in% la_types) %>%
  select(code, name, geog_type, starts_with("y")) %>%
  pivot_longer(cols = starts_with("y"),
               names_to = "year",
               values_to = "bs_registrations") %>%
  mutate(year = as.integer(gsub("y", "", year)),
         bs_registrations = as.numeric(bs_registrations))

cat("  BS registrations parsed:", nrow(bs_la), "rows\n")

# ============================================================================
# 3. Parse population data
# ============================================================================
cat("=== Parsing population data ===\n")

pop_raw <- read_csv(file.path(data_dir, "population_adult_la.csv"),
                    show_col_types = FALSE)

pop <- pop_raw %>%
  rename(year_name = DATE_NAME,
         la_name = GEOGRAPHY_NAME,
         la_code = GEOGRAPHY_CODE,
         adult_pop = OBS_VALUE) %>%
  mutate(year = as.integer(year_name)) %>%
  select(la_code, la_name, year, adult_pop)

cat("  Population rows:", nrow(pop), "\n")
cat("  Unique LAs in pop:", n_distinct(pop$la_code), "\n")

# ============================================================================
# 4. Parse claimant count data
# ============================================================================
cat("=== Parsing claimant count data ===\n")

cc_raw <- read_csv(file.path(data_dir, "claimant_count_la.csv"),
                   show_col_types = FALSE)

cc <- cc_raw %>%
  rename(date_name = DATE_NAME,
         la_name = GEOGRAPHY_NAME,
         la_code = GEOGRAPHY_CODE,
         claimant_count = OBS_VALUE) %>%
  mutate(year = as.integer(substr(date_name, 1, 4))) %>%
  select(la_code, year, claimant_count)

cat("  Claimant count rows:", nrow(cc), "\n")

# ============================================================================
# 5. Parse Scotland and NI annual national data (quarterly file Table_7, Table_8)
# ============================================================================
cat("=== Parsing Scotland national-level data ===\n")

qtr_file <- file.path(data_dir, "quarterly_insolvency_2023q4.xlsx")

# Scotland (Table_7): annual rows have no quarter
scot_raw <- read_excel(qtr_file, sheet = "Table_7", skip = 5, col_names = FALSE)
scot_names <- c("year", "quarter", "total", "r1", "all_bankrupt", "r2",
                "lila_map", "r3", "ptds", "r4")
if (ncol(scot_raw) >= 10) {
  names(scot_raw) <- scot_names[1:ncol(scot_raw)]
}

scot_annual <- scot_raw %>%
  filter(is.na(quarter) | quarter == "") %>%
  mutate(year = as.integer(year),
         total = as.numeric(total),
         all_bankrupt = as.numeric(all_bankrupt),
         ptds = as.numeric(ptds)) %>%
  filter(!is.na(year), year >= 2015) %>%
  select(year, scot_total = total, scot_bankrupt = all_bankrupt, scot_ptds = ptds)

cat("  Scotland annual data:", nrow(scot_annual), "years\n")
print(scot_annual)

# NI (Table_8)
ni_raw <- read_excel(qtr_file, sheet = "Table_8", skip = 5, col_names = FALSE)
ni_names <- c("year", "quarter", "total", "r1", "bankrupt", "r2",
              "dros", "r3", "ivas", "r4")
if (ncol(ni_raw) >= 10) {
  names(ni_raw) <- ni_names[1:ncol(ni_raw)]
}

ni_annual <- ni_raw %>%
  filter(is.na(quarter) | quarter == "") %>%
  mutate(year = as.integer(year),
         total = as.numeric(total)) %>%
  filter(!is.na(year), year >= 2015) %>%
  select(year, ni_total = total)

cat("  NI annual data:", nrow(ni_annual), "years\n")

# ============================================================================
# 6. Construct main analysis panel
# ============================================================================
cat("=== Constructing analysis panel ===\n")

# Merge insolvency + BS registrations + population + claimant count
panel <- ew_insolvency %>%
  left_join(bs_la %>% select(code, year, bs_registrations),
            by = c("code", "year")) %>%
  left_join(pop %>% select(la_code, year, adult_pop),
            by = c("code" = "la_code", "year")) %>%
  left_join(cc %>% select(la_code, year, claimant_count),
            by = c("code" = "la_code", "year"))

# Fill BS registrations with 0 for pre-treatment years
panel <- panel %>%
  mutate(bs_registrations = ifelse(is.na(bs_registrations) & year < 2021,
                                    0, bs_registrations))

# Construct per-capita rates (per 10,000 adults)
panel <- panel %>%
  mutate(
    insolvency_rate = (total_insolvencies / adult_pop) * 10000,
    bankruptcy_rate = (bankruptcies / adult_pop) * 10000,
    dro_rate = (dros / adult_pop) * 10000,
    iva_rate = (ivas / adult_pop) * 10000,
    bs_rate = (bs_registrations / adult_pop) * 10000,
    claimant_rate = (claimant_count / adult_pop) * 10000
  )

# Treatment timing
panel <- panel %>%
  mutate(
    post = as.integer(year >= 2021),
    treat_england_wales = 1L,  # all E/W LAs are treated
    event_year = year - 2021   # event time relative to treatment
  )

# Construct BS take-up intensity measure (average BS rate 2021-2023)
bs_intensity <- panel %>%
  filter(year %in% 2021:2023) %>%
  group_by(code) %>%
  summarize(bs_intensity = mean(bs_rate, na.rm = TRUE), .groups = "drop")

panel <- panel %>%
  left_join(bs_intensity, by = "code")

# Create quartile groups based on BS intensity
panel <- panel %>%
  mutate(bs_quartile = ntile(bs_intensity, 4))

# Summary stats
cat("\n--- Panel summary ---\n")
cat("Rows:", nrow(panel), "\n")
cat("LAs:", n_distinct(panel$code), "\n")
cat("Years:", paste(sort(unique(panel$year)), collapse = ", "), "\n")
cat("LAs with population data:", sum(!is.na(panel$adult_pop[panel$year == 2020])), "\n")

# Check for missing rates
missing_rate <- mean(is.na(panel$insolvency_rate))
cat("Missing insolvency rate:", round(missing_rate * 100, 1), "%\n")

# Summary of BS take-up intensity
cat("\nBS take-up intensity (per 10K adults, 2021-2023 avg):\n")
cat("  Min:", round(min(bs_intensity$bs_intensity, na.rm = TRUE), 1), "\n")
cat("  Median:", round(median(bs_intensity$bs_intensity, na.rm = TRUE), 1), "\n")
cat("  Max:", round(max(bs_intensity$bs_intensity, na.rm = TRUE), 1), "\n")
cat("  SD:", round(sd(bs_intensity$bs_intensity, na.rm = TRUE), 1), "\n")

# ============================================================================
# 7. Save panel
# ============================================================================
saveRDS(panel, file.path(data_dir, "analysis_panel.rds"))
saveRDS(scot_annual, file.path(data_dir, "scotland_annual.rds"))
saveRDS(ni_annual, file.path(data_dir, "ni_annual.rds"))

cat("\n=== Panel saved to data/analysis_panel.rds ===\n")
