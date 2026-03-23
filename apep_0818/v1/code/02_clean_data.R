## 02_clean_data.R — Construct county-year panel with treatment and outcomes
## apep_0818: Zombie Nonprofits

source("00_packages.R")

data_dir <- "../data"

# ============================================================================
# 1. Process IRS Revocation List → County-Level Treatment
# ============================================================================
cat("=== Processing Revocation List ===\n")
revocations_raw <- fread(file.path(data_dir, "irs_revocation_list.csv"), encoding = "Latin-1")

# Standardize column names
names(revocations_raw) <- tolower(names(revocations_raw))
cat("Revocation columns:", paste(names(revocations_raw), collapse = ", "), "\n")

# Known columns: ein, org_name, sort_name, address, city, state,
# zip_code, country, subsection_code, revocation_date,
# revocation_posting_date, reinstatement_date

# Parse revocation dates (format: DD-MMM-YYYY e.g. "15-MAY-2011" or MM/DD/YYYY)
revocations <- revocations_raw %>%
  as_tibble() %>%
  mutate(
    # Try DD-MMM-YYYY first (e.g., "15-MAY-2011"), then MM/DD/YYYY, then YYYY-MM-DD
    revocation_date = as.Date(revocation_date, format = "%d-%b-%Y"),
    revocation_date = if_else(
      is.na(revocation_date),
      as.Date(revocations_raw$revocation_date, format = "%m/%d/%Y"),
      revocation_date
    ),
    revocation_date = if_else(
      is.na(revocation_date),
      as.Date(revocations_raw$revocation_date, format = "%Y-%m-%d"),
      revocation_date
    ),
    revocation_year = as.integer(format(revocation_date, "%Y")),
    zip5 = str_sub(str_pad(as.character(zip_code), 5, pad = "0"), 1, 5)
  ) %>%
  rename(state_abbr = state) %>%
  filter(!is.na(revocation_year), revocation_year >= 2010, revocation_year <= 2020)

cat("Revocations with valid dates:", nrow(revocations), "\n")
cat("Revocations by year:\n")
print(table(revocations$revocation_year))

# ============================================================================
# 2. ZIP-to-County Crosswalk
# ============================================================================
cat("\n=== Building ZIP-to-County Crosswalk ===\n")
# Use HUD USPS ZIP-County crosswalk or Census ZCTA-County relationship file
# For simplicity, use the Census ZCTA-County relationship file
crosswalk_file <- file.path(data_dir, "zip_county_crosswalk.csv")

if (!file.exists(crosswalk_file)) {
  # Download HUD ZIP-County crosswalk
  # Alternative: use the 2010 Census ZCTA to County relationship file
  xwalk_url <- "https://www2.census.gov/geo/docs/maps-data/data/rel/zcta_county_rel_10.txt"
  resp <- httr::GET(xwalk_url, httr::timeout(60),
                    httr::write_disk(crosswalk_file, overwrite = TRUE))
  if (httr::status_code(resp) != 200) {
    stop("FATAL: Cannot download ZIP-county crosswalk")
  }
}

xwalk <- fread(crosswalk_file)
names(xwalk) <- tolower(names(xwalk))

# Map ZCTA5 → county FIPS (use the county with largest overlap)
zip_to_county <- xwalk %>%
  as_tibble() %>%
  group_by(zcta5) %>%
  slice_max(order_by = zpoppct, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  select(zcta5, geoid, state, county) %>%
  mutate(
    county_fips = paste0(
      str_pad(state, 2, pad = "0"),
      str_pad(county, 3, pad = "0")
    ),
    zip5 = str_pad(as.character(zcta5), 5, pad = "0")
  ) %>%
  select(zip5, county_fips)

cat("ZIP-county crosswalk entries:", nrow(zip_to_county), "\n")

# ============================================================================
# 3. Merge Revocations → County Level
# ============================================================================
cat("\n=== Aggregating Revocations to County Level ===\n")
revocations_county <- revocations %>%
  left_join(zip_to_county, by = "zip5") %>%
  filter(!is.na(county_fips))

cat("Revocations matched to counties:", nrow(revocations_county), "of", nrow(revocations), "\n")

# Count revocations by county (total and by year)
county_revocations <- revocations_county %>%
  group_by(county_fips) %>%
  summarise(
    total_revocations = n(),
    revocations_2011 = sum(revocation_year == 2011),
    revocations_2010_2012 = sum(revocation_year >= 2010 & revocation_year <= 2012),
    .groups = "drop"
  )

cat("Counties with revocations:", nrow(county_revocations), "\n")

# ============================================================================
# 4. Process EO BMF → Pre-Period Nonprofit Counts
# ============================================================================
cat("\n=== Processing EO BMF ===\n")
bmf <- fread(file.path(data_dir, "eo_bmf.csv"), encoding = "Latin-1")
names(bmf) <- tolower(names(bmf))
cat("BMF columns:", paste(names(bmf), collapse = ", "), "\n")

# Key columns: ein, state, city, zip, ruling_date (YYYYMM format), ntee_cd
zip_col_bmf <- grep("zip|postal", names(bmf), value = TRUE)[1]
ruling_col <- grep("ruling", names(bmf), value = TRUE)[1]
stopifnot("Cannot find ZIP in BMF" = !is.na(zip_col_bmf))

bmf_clean <- bmf %>%
  as_tibble() %>%
  rename(zip_raw = all_of(zip_col_bmf)) %>%
  mutate(
    zip5 = str_sub(str_pad(as.character(zip_raw), 5, pad = "0"), 1, 5)
  )

if (!is.na(ruling_col)) {
  bmf_clean <- bmf_clean %>%
    rename(ruling_raw = all_of(ruling_col)) %>%
    mutate(
      ruling_year = as.integer(str_sub(as.character(ruling_raw), 1, 4))
    )
} else {
  # If no ruling date, we can still count orgs per county
  bmf_clean <- bmf_clean %>%
    mutate(ruling_year = NA_integer_)
}

# Merge with ZIP-county crosswalk
bmf_county <- bmf_clean %>%
  left_join(zip_to_county, by = "zip5") %>%
  filter(!is.na(county_fips))

# Pre-2010 nonprofit count per county (denominator for treatment intensity)
pre2010_counts <- bmf_county %>%
  filter(is.na(ruling_year) | ruling_year < 2010) %>%
  group_by(county_fips) %>%
  summarise(n_nonprofits_pre2010 = n(), .groups = "drop")

# New formations per county per year (ruling date as proxy)
new_formations <- bmf_county %>%
  filter(!is.na(ruling_year), ruling_year >= 2006, ruling_year <= 2020) %>%
  group_by(county_fips, ruling_year) %>%
  summarise(new_formations = n(), .groups = "drop") %>%
  rename(year = ruling_year)

cat("Pre-2010 nonprofit counts for", nrow(pre2010_counts), "counties\n")
cat("New formation records:", nrow(new_formations), "\n")

# ============================================================================
# 5. Construct Treatment Variable
# ============================================================================
cat("\n=== Constructing Treatment Variable ===\n")
treatment <- county_revocations %>%
  left_join(pre2010_counts, by = "county_fips") %>%
  mutate(
    n_nonprofits_pre2010 = replace_na(n_nonprofits_pre2010, 0),
    revocation_intensity = if_else(
      n_nonprofits_pre2010 > 0,
      revocations_2010_2012 / n_nonprofits_pre2010,
      0
    )
  ) %>%
  filter(n_nonprofits_pre2010 >= 10)  # Require minimum baseline for meaningful intensity

cat("Counties with treatment data:", nrow(treatment), "\n")
cat("Revocation intensity summary:\n")
print(summary(treatment$revocation_intensity))

# ============================================================================
# 6. Process SOI County Data → Charitable Giving
# ============================================================================
cat("\n=== Processing SOI County Data ===\n")
soi_dir <- file.path(data_dir, "soi_county")
soi_files <- list.files(soi_dir, pattern = "soi_county_\\d{4}\\.csv", full.names = TRUE)

soi_parts <- list()
for (f in soi_files) {
  yr <- as.integer(str_extract(basename(f), "\\d{4}"))
  df <- tryCatch(fread(f, encoding = "Latin-1"), error = function(e) NULL)
  if (is.null(df) || nrow(df) < 100) next

  names(df) <- tolower(names(df))

  # Find FIPS columns
  state_fips_col <- grep("^statefips|^state$|^stfips", names(df), value = TRUE)[1]
  county_fips_col <- grep("^countyfips|^county$|^cofips|^cnty", names(df), value = TRUE)[1]

  if (is.na(state_fips_col) || is.na(county_fips_col)) {
    cat("WARNING: Cannot identify FIPS columns in SOI", yr, "\n")
    next
  }

  # Find charitable deduction columns
  # Common names: a19300 (# returns with charitable deductions), a19700 (amount)
  charity_n_col <- grep("a19300|n19700|charit.*n|n.*charit", names(df), value = TRUE)[1]
  charity_amt_col <- grep("a19700|charit.*amt|a.*charit|amt.*charit", names(df), value = TRUE)[1]
  returns_col <- grep("^n1$|^n.*return|^mars1|^n00100", names(df), value = TRUE)[1]

  df_clean <- df %>%
    as_tibble() %>%
    rename(
      st_fips = all_of(state_fips_col),
      co_fips = all_of(county_fips_col)
    ) %>%
    mutate(
      county_fips = paste0(
        str_pad(as.character(st_fips), 2, pad = "0"),
        str_pad(as.character(co_fips), 3, pad = "0")
      ),
      year = yr
    ) %>%
    filter(co_fips != "000")  # Remove state totals

  # Add charitable giving if columns found
  if (!is.na(charity_amt_col)) {
    df_clean <- df_clean %>%
      mutate(charitable_deductions_1000 = as.numeric(get(charity_amt_col)))
  }
  if (!is.na(returns_col)) {
    df_clean <- df_clean %>%
      mutate(n_returns = as.numeric(get(returns_col)))
  }

  cols_to_keep <- c("county_fips", "year")
  if ("charitable_deductions_1000" %in% names(df_clean)) cols_to_keep <- c(cols_to_keep, "charitable_deductions_1000")
  if ("n_returns" %in% names(df_clean)) cols_to_keep <- c(cols_to_keep, "n_returns")

  soi_parts[[as.character(yr)]] <- df_clean %>% select(all_of(cols_to_keep))
  cat("SOI", yr, ":", nrow(df_clean), "rows\n")
}

if (length(soi_parts) > 0) {
  soi_panel <- rbindlist(soi_parts, fill = TRUE) %>% as_tibble()
  cat("SOI panel rows:", nrow(soi_panel), "\n")
} else {
  cat("WARNING: No SOI data loaded\n")
  soi_panel <- tibble(county_fips = character(), year = integer(),
                       charitable_deductions_1000 = numeric(), n_returns = numeric())
}

# ============================================================================
# 7. Process QWI → Nonprofit Employment
# ============================================================================
cat("\n=== Processing QWI Data ===\n")
qwi <- fread(file.path(data_dir, "qwi_naics813.csv"))
names(qwi) <- tolower(names(qwi))

# Construct county FIPS
qwi_clean <- qwi %>%
  as_tibble() %>%
  mutate(
    county_fips = paste0(
      str_pad(as.character(state_fips), 2, pad = "0"),
      str_pad(as.character(county), 3, pad = "0")
    ),
    year = as.integer(year),
    emp = as.numeric(emp),
    earns = as.numeric(earns)
  ) %>%
  filter(!is.na(year), year >= 2006, year <= 2020) %>%
  group_by(county_fips, year) %>%
  summarise(
    np_employment = mean(emp, na.rm = TRUE),
    np_earnings = mean(earns, na.rm = TRUE),
    .groups = "drop"
  )

cat("QWI county-year panel rows:", nrow(qwi_clean), "\n")

# ============================================================================
# 8. Process Population Data
# ============================================================================
cat("\n=== Processing Population Data ===\n")
pop <- fread(file.path(data_dir, "county_population.csv"))
names(pop) <- tolower(names(pop))

# The file already has county_fips, year, population columns from 01_fetch_data.R
pop_clean <- pop %>%
  as_tibble() %>%
  mutate(
    county_fips = as.character(county_fips),
    year = as.integer(year),
    population = as.numeric(population)
  ) %>%
  filter(!is.na(population), population > 0) %>%
  select(county_fips, year, population)

cat("Population panel rows:", nrow(pop_clean), "\n")

# ============================================================================
# 9. Build Final County-Year Panel
# ============================================================================
cat("\n=== Building Final Panel ===\n")

# Create balanced panel skeleton
all_counties <- treatment$county_fips
all_years <- 2006:2020
skeleton <- expand_grid(county_fips = all_counties, year = all_years)

panel <- skeleton %>%
  left_join(treatment %>% select(county_fips, revocation_intensity, total_revocations,
                                  n_nonprofits_pre2010), by = "county_fips") %>%
  left_join(new_formations, by = c("county_fips", "year")) %>%
  left_join(soi_panel, by = c("county_fips", "year")) %>%
  left_join(qwi_clean, by = c("county_fips", "year")) %>%
  left_join(pop_clean, by = c("county_fips", "year")) %>%
  mutate(
    new_formations = replace_na(new_formations, 0),
    post = as.integer(year >= 2011),
    intensity_x_post = revocation_intensity * post,
    # Per capita measures
    formations_per_10k = if_else(population > 0, new_formations / population * 10000, NA_real_),
    charitable_per_return = if_else(
      !is.na(n_returns) & n_returns > 0,
      charitable_deductions_1000 / n_returns,
      NA_real_
    )
  )

cat("Final panel dimensions:", nrow(panel), "rows x", ncol(panel), "cols\n")
cat("Counties:", n_distinct(panel$county_fips), "\n")
cat("Years:", sort(unique(panel$year)), "\n")
cat("Treatment intensity summary:\n")
print(summary(panel$revocation_intensity))

# Save
saveRDS(panel, file.path(data_dir, "analysis_panel.rds"))
fwrite(panel, file.path(data_dir, "analysis_panel.csv"))

cat("\n=== Panel saved to data/analysis_panel.rds ===\n")
