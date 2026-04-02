## 02_clean_data.R — Construct analysis panel for apep_1291
## Merges NASS farm data with county geography, creates border-county panel

source("00_packages.R")

cat("=== Loading raw data ===\n")

farms_raw <- readRDS("../data/farms_raw.rds")
land_raw <- readRDS("../data/land_raw.rds")
size_raw <- readRDS("../data/size_raw.rds")
county_geo <- readRDS("../data/county_geo.rds")
border_counties <- readRDS("../data/border_counties.rds")

# ---- Clean farm operations data ----
cat("Cleaning farm operations data...\n")

# Total farms by county-year (domain_desc == "TOTAL")
farms_total <- farms_raw |>
  filter(domain_desc == "TOTAL") |>
  mutate(
    fips = paste0(state_fips_code, county_code),
    year = as.integer(year),
    n_farms = as.numeric(gsub(",", "", Value))
  ) |>
  filter(!is.na(n_farms)) |>
  select(fips, year, state_alpha, county_name, n_farms) |>
  distinct(fips, year, .keep_all = TRUE)

cat(sprintf("  Total farm-county-year obs: %d\n", nrow(farms_total)))

# ---- Clean land in farms data ----
cat("Cleaning land in farms data...\n")

land_clean <- land_raw |>
  filter(domain_desc == "TOTAL") |>
  mutate(
    fips = paste0(state_fips_code, county_code),
    year = as.integer(year),
    land_acres = as.numeric(gsub(",", "", Value))
  ) |>
  filter(!is.na(land_acres)) |>
  select(fips, year, land_acres) |>
  distinct(fips, year, .keep_all = TRUE)

cat(sprintf("  Land-county-year obs: %d\n", nrow(land_clean)))

# ---- Clean farm size distribution ----
cat("Cleaning farm size distribution data...\n")

# Parse domaincat_desc to get size class
size_clean <- size_raw |>
  filter(grepl("AREA OPERATED", domain_desc, ignore.case = TRUE)) |>
  mutate(
    fips = paste0(state_fips_code, county_code),
    year = as.integer(year),
    n_ops = as.numeric(gsub(",", "", Value)),
    size_class = domaincat_desc
  ) |>
  filter(!is.na(n_ops)) |>
  select(fips, year, size_class, n_ops)

# Classify into large farms (1000+ acres)
size_summary <- size_clean |>
  mutate(
    is_large = grepl("1,000|2,000|5,000", size_class) &
               !grepl("1 TO|10 TO|100 TO", size_class)
  ) |>
  group_by(fips, year) |>
  summarise(
    n_large_farms = sum(n_ops[is_large], na.rm = TRUE),
    n_total_size = sum(n_ops, na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(share_large = n_large_farms / pmax(n_total_size, 1))

cat(sprintf("  Size distribution county-year obs: %d\n", nrow(size_summary)))

# ---- Merge all data ----
cat("Merging datasets...\n")

panel <- farms_total |>
  left_join(land_clean, by = c("fips", "year")) |>
  left_join(size_summary, by = c("fips", "year")) |>
  left_join(county_geo |> rename(fips = GEOID), by = "fips") |>
  mutate(
    avg_farm_size = land_acres / pmax(n_farms, 1),
    post = as.integer(year >= 2012),  # First Census after 2007 ruling (2007 = last pre-treatment)
    treat = as.integer(in_nebraska),
    treat_post = treat * post,
    is_border = fips %in% border_counties
  ) |>
  filter(!is.na(in_nebraska))  # Drop counties without geo data

cat(sprintf("  Full panel: %d obs, %d counties\n", nrow(panel), n_distinct(panel$fips)))

# ---- Create border county sample ----
border_panel <- panel |>
  filter(is_border)

cat(sprintf("  Border panel: %d obs, %d counties\n",
            nrow(border_panel), n_distinct(border_panel$fips)))

# ---- Create bandwidth samples ----
bw50 <- panel |> filter(dist_to_ne_border_km <= 50)
bw100 <- panel |> filter(dist_to_ne_border_km <= 100)
bw150 <- panel |> filter(dist_to_ne_border_km <= 150)

cat(sprintf("  50km band: %d obs | 100km: %d | 150km: %d\n",
            nrow(bw50), nrow(bw100), nrow(bw150)))

# ---- Summary statistics ----
cat("\n=== Summary Statistics ===\n")
border_panel |>
  group_by(in_nebraska, post) |>
  summarise(
    mean_farms = mean(n_farms, na.rm = TRUE),
    mean_size = mean(avg_farm_size, na.rm = TRUE),
    mean_share_large = mean(share_large, na.rm = TRUE),
    n_counties = n_distinct(fips),
    .groups = "drop"
  ) |>
  print()

# ---- Save analysis datasets ----
saveRDS(panel, "../data/panel.rds")
saveRDS(border_panel, "../data/border_panel.rds")

cat("\n=== Panel construction complete ===\n")
