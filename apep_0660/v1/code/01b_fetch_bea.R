# 01b_fetch_bea.R — Parse BEA REIS county earnings data (1980-2005)
# Extends pre-treatment period for parallel trends testing

source("00_packages.R")

data_dir <- "../data"

cat("=== Parsing BEA REIS Data ===\n")

bea_file <- file.path(data_dir, "CAINC4__ALL_AREAS_1969_2024.csv")
stopifnot("BEA REIS file missing" = file.exists(bea_file))

dat <- read.csv(bea_file, stringsAsFactors = FALSE, colClasses = "character",
                check.names = FALSE)
names(dat) <- trimws(names(dat))
cat(sprintf("Columns: %s\n", paste(head(names(dat), 12), collapse=", ")))
cat(sprintf("Year-like columns: %s\n",
            paste(head(grep("^[12][09]", names(dat), value = TRUE)), collapse=", ")))

# Extract wages and salaries (LineCode 50) and personal income (LineCode 10)
wages <- dat %>%
  filter(LineCode == "50") %>%
  filter(nchar(trimws(GeoFIPS)) == 5)  # County-level only (5-digit FIPS)

cat(sprintf("County wage records: %d\n", nrow(wages)))

# Reshape to long format for years 1980-2005
year_cols <- as.character(1980:2005)
year_cols_exist <- intersect(year_cols, names(wages))
cat(sprintf("Year columns available: %s\n", paste(range(year_cols_exist), collapse = "-")))

wages_long <- wages %>%
  select(GeoFIPS, GeoName, all_of(year_cols_exist)) %>%
  tidyr::pivot_longer(
    cols = all_of(year_cols_exist),
    names_to = "year",
    values_to = "wages_salaries"
  ) %>%
  mutate(
    fips = trimws(GeoFIPS),
    year = as.integer(year),
    wages_salaries = suppressWarnings(as.numeric(gsub("[^0-9.-]", "", wages_salaries)))
  ) %>%
  filter(!is.na(wages_salaries) & wages_salaries > 0) %>%
  select(fips, year, wages_salaries)

# Also get personal income (LineCode 10)
pi <- dat %>%
  filter(LineCode == "10") %>%
  filter(nchar(trimws(GeoFIPS)) == 5)

pi_long <- pi %>%
  select(GeoFIPS, all_of(year_cols_exist)) %>%
  tidyr::pivot_longer(
    cols = all_of(year_cols_exist),
    names_to = "year",
    values_to = "personal_income"
  ) %>%
  mutate(
    fips = trimws(GeoFIPS),
    year = as.integer(year),
    personal_income = suppressWarnings(as.numeric(gsub("[^0-9.-]", "", personal_income)))
  ) %>%
  filter(!is.na(personal_income) & personal_income > 0) %>%
  select(fips, year, personal_income)

# Merge
bea_panel <- wages_long %>%
  left_join(pi_long, by = c("fips", "year")) %>%
  mutate(
    log_wages = log(wages_salaries),
    log_pi = log(personal_income),
    state_fips = substr(fips, 1, 2)
  )

cat(sprintf("BEA panel: %d county-years, %d counties, years %d-%d\n",
            nrow(bea_panel), n_distinct(bea_panel$fips),
            min(bea_panel$year), max(bea_panel$year)))

saveRDS(bea_panel, file.path(data_dir, "bea_panel.rds"))
cat("=== BEA data ready ===\n")
