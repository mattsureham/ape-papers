# 02_clean_data.R — Construct analysis dataset
source("00_packages.R")

paper_root <- normalizePath(file.path(getwd(), ".."), mustWork = FALSE)
if (file.exists(file.path(paper_root, "data"))) setwd(paper_root)

if (!requireNamespace("readxl", quietly = TRUE)) install.packages("readxl", repos = "https://cloud.r-project.org")
library(readxl)

# ---------------------------------------------------------------
# 1) Load and parse construction investment data
# ---------------------------------------------------------------
cat("=== Loading construction data ===\n")
construction <- readRDS("data/construction_raw.rds")
sector_lookup <- readRDS("data/sector_lookup.rds")

cat(sprintf("Raw construction: %d rows, %d municipalities, years %d-%d\n",
  nrow(construction), n_distinct(construction$muni_code),
  min(construction$year), max(construction$year)))

# Key sectors for analysis
# 0: Total, 900: Wohnen (Residential), 1100: Industrie/Gewerbe/Dienstleistungen (Commercial)
# 700: Freizeit und Kultur (Leisure/Culture — includes tourism), 300: Strassenverkehr (Infrastructure placebo)
key_sectors <- c("0", "900", "1100", "700", "300", "100", "200", "800")
construction <- construction %>%
  filter(sector_code %in% key_sectors) %>%
  mutate(
    sector = case_when(
      sector_code == "0" ~ "total",
      sector_code == "900" ~ "residential",
      sector_code == "1100" ~ "commercial",
      sector_code == "700" ~ "leisure_culture",
      sector_code == "300" ~ "roads",
      sector_code == "100" ~ "supply_infra",
      sector_code == "200" ~ "waste_infra",
      sector_code == "800" ~ "other_infra",
      TRUE ~ "other"
    ),
    # Replace NA investment with 0 (no construction)
    investment = ifelse(is.na(investment), 0, investment)
  )

# Pivot to wide format: one row per municipality-year
construction_wide <- construction %>%
  select(muni_code, year, sector, investment) %>%
  pivot_wider(names_from = sector, values_from = investment, values_fill = 0)

cat(sprintf("Wide construction: %d rows\n", nrow(construction_wide)))

# ---------------------------------------------------------------
# 2) Load second-home share data from ARE XLSX (2017)
# ---------------------------------------------------------------
cat("\n=== Loading second-home share data ===\n")

# Download 2017 XLSX if not already present
if (!file.exists("data/zweitwohnung_2017.xlsx")) {
  url <- "https://data.geo.admin.ch/ch.are.wohnungsinventar-zweitwohnungsanteil/wohnungsinventar-zweitwohnungsanteil_2017/wohnungsinventar-zweitwohnungsanteil_2017_2056.xlsx.zip"
  temp_zip <- tempfile(fileext = ".zip")
  download.file(url, temp_zip, mode = "wb", quiet = TRUE)
  temp_dir <- tempdir()
  unzip(temp_zip, exdir = temp_dir)
  xlsx_file <- list.files(temp_dir, pattern = "[.]xlsx$", recursive = TRUE, full.names = TRUE)[1]
  file.copy(xlsx_file, "data/zweitwohnung_2017.xlsx")
}

zweit <- read_excel("data/zweitwohnung_2017.xlsx", sheet = "Wohnungsinventar")
cat(sprintf("Zweitwohnung data: %d municipalities\n", nrow(zweit)))
cat(sprintf("Columns: %s\n", paste(names(zweit), collapse = ", ")))

# Clean the data
zweit <- zweit %>%
  rename(
    canton = KT,
    muni_id = GdeNr,
    muni_name = GdeName,
    total_dwellings = ZWG_3150,
    occupied_dwellings = ZWG_3010,
    pct_primary = ZWG_3110,
    pct_second_home = ZWG_3120,
    status = ZWG_3200
  ) %>%
  mutate(
    muni_code = as.character(muni_id),
    # Treatment: municipality appears on the official ARE list (status 2 = confirmed above 20%)
    treated = as.integer(status %in% c(2, 4)),  # 2=confirmed, 4=newly above
    # Also flag those under review (status 3)
    treated_broad = as.integer(status %in% c(2, 3, 4)),
    second_home_share = pct_second_home / 100  # Convert to proportion
  )

cat(sprintf("\nTreatment assignment (2017 status):\n"))
cat(sprintf("  Status 1 (below 20%%): %d municipalities\n", sum(zweit$status == 1)))
cat(sprintf("  Status 2 (above 20%%, confirmed): %d municipalities\n", sum(zweit$status == 2)))
cat(sprintf("  Status 3 (under review): %d municipalities\n", sum(zweit$status == 3)))
cat(sprintf("  Status 4 (newly above): %d municipalities\n", sum(zweit$status == 4)))
cat(sprintf("  Treated (strict, 2+4): %d\n", sum(zweit$treated)))
cat(sprintf("  Treated (broad, 2+3+4): %d\n", sum(zweit$treated_broad)))

# ---------------------------------------------------------------
# 3) Merge datasets
# ---------------------------------------------------------------
cat("\n=== Merging datasets ===\n")

# Merge construction with second-home treatment
panel <- construction_wide %>%
  inner_join(
    zweit %>% select(muni_code, canton, muni_name, treated, treated_broad,
                     second_home_share, total_dwellings, pct_second_home),
    by = "muni_code"
  )

cat(sprintf("Merged panel: %d municipality-years\n", nrow(panel)))
cat(sprintf("Unique municipalities: %d\n", n_distinct(panel$muni_code)))
cat(sprintf("Treated municipalities: %d\n", n_distinct(panel$muni_code[panel$treated == 1])))
cat(sprintf("Control municipalities: %d\n", n_distinct(panel$muni_code[panel$treated == 0])))

# ---------------------------------------------------------------
# 4) Construct analysis variables
# ---------------------------------------------------------------
cat("\n=== Constructing analysis variables ===\n")

panel <- panel %>%
  mutate(
    # Post-initiative indicator (voted March 2012, implementing ordinance 2013)
    post = as.integer(year >= 2013),
    # Log transformations (IHS for zeros)
    log_residential = log(residential + 1),
    log_commercial = log(commercial + 1),
    log_total = log(total + 1),
    log_leisure = log(leisure_culture + 1),
    log_roads = log(roads + 1),
    # Non-residential: everything except residential
    non_residential = total - residential,
    log_non_residential = log(non_residential + 1),
    # Residential share of total
    residential_share = ifelse(total > 0, residential / total, NA_real_),
    # Treatment intensity (continuous)
    treat_intensity = second_home_share,
    # DiD interaction
    treat_post = treated * post,
    # Continuous DiD
    intensity_post = treat_intensity * post,
    # Municipality ID for fixed effects (numeric)
    muni_id_num = as.numeric(muni_code)
  )

# ---------------------------------------------------------------
# 5) Summary statistics
# ---------------------------------------------------------------
cat("\n=== Summary Statistics ===\n")

summary_stats <- panel %>%
  filter(year <= 2011) %>%  # Pre-treatment period
  group_by(treated) %>%
  summarise(
    n_munis = n_distinct(muni_code),
    mean_total = mean(total, na.rm = TRUE),
    sd_total = sd(total, na.rm = TRUE),
    mean_residential = mean(residential, na.rm = TRUE),
    sd_residential = sd(residential, na.rm = TRUE),
    mean_commercial = mean(commercial, na.rm = TRUE),
    sd_commercial = sd(commercial, na.rm = TRUE),
    mean_leisure = mean(leisure_culture, na.rm = TRUE),
    mean_second_home_share = mean(second_home_share, na.rm = TRUE),
    .groups = "drop"
  )

cat("\nPre-treatment means (CHF 1000):\n")
print(summary_stats)

# Save
saveRDS(panel, "data/panel.rds")
cat(sprintf("\nSaved data/panel.rds (%d rows)\n", nrow(panel)))

# Check Davos and Zermatt
cat("\n=== Smoke test: Davos and Zermatt ===\n")
for (muni in c("3851", "6300")) {
  d <- panel %>% filter(muni_code == muni) %>%
    select(muni_name, year, treated, residential, commercial, total, second_home_share) %>%
    filter(year %in% c(2010, 2011, 2012, 2013, 2014, 2016, 2020))
  cat(sprintf("\n%s (second home share: %.1f%%):\n", d$muni_name[1], d$second_home_share[1] * 100))
  print(d %>% select(-muni_name, -second_home_share))
}
