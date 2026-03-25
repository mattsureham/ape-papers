## 02_clean_data.R — Clean and merge all datasets
## apep_0958: Dutch Nitrogen Ruling and Populist Backlash

source("00_packages.R")

data_dir <- "../data"

## ============================================================
## 1. Clean Building Permits
## ============================================================
cat("=== 1. Cleaning building permits ===\n")

permits_raw <- readRDS(file.path(data_dir, "cbs_permits_full.rds"))

permits <- permits_raw %>%
  mutate(RegioS = trimws(RegioS), Perioden = trimws(Perioden)) %>%
  filter(grepl("^GM", RegioS), grepl("KW", Perioden)) %>%
  mutate(
    gm_code = gsub("GM", "", RegioS),
    year = as.integer(substr(Perioden, 1, 4)),
    quarter = as.integer(gsub(".*KW0?(\\d).*", "\\1", Perioden)),
    yq = year + (quarter - 1) / 4,
    dwellings = as.numeric(Woningen_2)
  ) %>%
  group_by(gm_code, year, quarter, yq) %>%
  summarise(total_dwellings = sum(dwellings, na.rm = TRUE), .groups = "drop")

cat(sprintf("  Permits: %d obs, %d munis, years %d-%d\n",
            nrow(permits), n_distinct(permits$gm_code),
            min(permits$year), max(permits$year)))
saveRDS(permits, file.path(data_dir, "permits_clean.rds"))

## ============================================================
## 2. Clean Regional Key Figures (70072NED) — population,
##    employment, agriculture, nitrogen, urbanization
## ============================================================
cat("\n=== 2. Cleaning CBS regional key figures ===\n")

rk <- readRDS(file.path(data_dir, "cbs_population.rds"))
cat(sprintf("  Raw: %d rows, %d cols\n", nrow(rk), ncol(rk)))

rk_clean <- rk %>%
  mutate(RegioS = trimws(RegioS), Perioden = trimws(Perioden)) %>%
  filter(grepl("^GM", RegioS)) %>%
  mutate(
    gm_code = gsub("GM", "", RegioS),
    year = as.integer(substr(Perioden, 1, 4))
  ) %>%
  transmute(
    gm_code, year,
    population = as.numeric(TotaleBevolking_1),
    # Employment by sector
    total_jobs = as.numeric(TotaalBanen_116),
    agri_jobs = as.numeric(ALandbouwBosbouwEnVisserij_117),
    industry_jobs = as.numeric(BFNijverheidEnEnergie_118),
    commercial_jobs = as.numeric(GNCommercieleDienstverlening_119),
    public_jobs = as.numeric(OUNietCommercieleDienstverlening_120),
    # Agricultural data
    agri_land_pct = as.numeric(AgrarischTerrein_258),
    nitrogen_excretion = as.numeric(Stikstofuitscheiding_196),
    # Urbanization
    bev_dichtheid = as.numeric(Bevolkingsdichtheid_57),
    # Housing
    woz_value = as.numeric(GemiddeldeWOZWaardeVanWoningen_98),
    total_housing = as.numeric(VoorraadOp1Januari_90),
    new_construction = as.numeric(Nieuwbouw_91),
    # Employment shares
    agri_share = agri_jobs / pmax(total_jobs, 1),
    industry_share = industry_jobs / pmax(total_jobs, 1)
  ) %>%
  filter(!is.na(population), population > 0)

cat(sprintf("  Clean: %d obs, %d munis, years %d-%d\n",
            nrow(rk_clean), n_distinct(rk_clean$gm_code),
            min(rk_clean$year, na.rm=TRUE), max(rk_clean$year, na.rm=TRUE)))

# Pre-ruling (2018) municipality characteristics for treatment intensity
chars_2018 <- rk_clean %>%
  filter(year == 2018) %>%
  select(gm_code, population, total_jobs, agri_jobs, industry_jobs,
         agri_share, industry_share, agri_land_pct, nitrogen_excretion,
         bev_dichtheid, woz_value)

cat(sprintf("  2018 characteristics: %d munis\n", nrow(chars_2018)))
cat(sprintf("  Agri share: mean=%.3f, sd=%.3f\n",
            mean(chars_2018$agri_share, na.rm=TRUE), sd(chars_2018$agri_share, na.rm=TRUE)))
cat(sprintf("  N excretion: mean=%.0f, max=%.0f\n",
            mean(chars_2018$nitrogen_excretion, na.rm=TRUE),
            max(chars_2018$nitrogen_excretion, na.rm=TRUE)))

saveRDS(rk_clean, file.path(data_dir, "regional_keys_clean.rds"))
saveRDS(chars_2018, file.path(data_dir, "chars_2018.rds"))

## ============================================================
## 3. Clean Election Data (PS2023 BBB votes)
## ============================================================
cat("\n=== 3. Cleaning election data ===\n")

election <- read.csv(file.path(data_dir, "ps2023_gemeente_results.csv"), stringsAsFactors = FALSE)

# Parse municipality ID from EML format
# IDs look like "HSB1::0363" or "0363" or "GM0363"
election <- election %>%
  mutate(
    gm_code_raw = gsub(".*::", "", muni_id),
    gm_code = sprintf("%04d", as.integer(gm_code_raw)),
    bbb_share = bbb_votes / total_valid,
    fvd_share = fvd_votes / total_valid,
    pvv_share = pvv_votes / total_valid,
    populist_share = (bbb_votes + fvd_votes + pvv_votes) / total_valid
  )

cat(sprintf("  PS2023: %d munis, BBB mean=%.1f%%, range=[%.1f%%, %.1f%%]\n",
            nrow(election), mean(election$bbb_share)*100,
            min(election$bbb_share)*100, max(election$bbb_share)*100))
saveRDS(election, file.path(data_dir, "election_clean.rds"))

## ============================================================
## 4. Process Natura 2000 + Municipality Spatial Data
## ============================================================
cat("\n=== 4. Constructing treatment intensity ===\n")

n2k <- readRDS(file.path(data_dir, "natura2000_sf.rds"))
muni <- readRDS(file.path(data_dir, "municipalities_sf.rds"))

cat(sprintf("  N2K sites: %d, Municipalities raw: %d\n", nrow(n2k), nrow(muni)))

# Transform to Dutch RD New
n2k <- st_transform(n2k, 28992)
muni <- st_transform(muni, 28992)

# Dissolve multi-polygon municipalities (WFS returns split geometries)
sf_use_s2(FALSE)
muni <- muni %>%
  group_by(gemeentecode, gemeentenaam) %>%
  summarise(geometry = st_union(geometry), .groups = "drop")

cat(sprintf("  Municipalities after dissolve: %d\n", nrow(muni)))

muni$muni_area_m2 <- as.numeric(st_area(muni))

# Verify: Netherlands total ~41,500 km²
cat(sprintf("  Total muni area: %.0f km² (expect ~36,000 land)\n",
            sum(muni$muni_area_m2) / 1e6))

# Union N2K and intersect with municipalities
cat("  Computing spatial intersection...\n")
n2k_union <- st_union(n2k)
intersection <- st_intersection(muni, n2k_union)
intersection$n2k_area_m2 <- as.numeric(st_area(intersection))

n2k_by_muni <- intersection %>%
  st_drop_geometry() %>%
  group_by(gemeentecode) %>%
  summarise(n2k_area_m2 = sum(n2k_area_m2), .groups = "drop")

treatment <- muni %>%
  st_drop_geometry() %>%
  select(muni_id = gemeentecode, muni_name = gemeentenaam, muni_area_m2) %>%
  left_join(n2k_by_muni, by = c("muni_id" = "gemeentecode")) %>%
  mutate(
    n2k_area_m2 = replace_na(n2k_area_m2, 0),
    n2k_share = n2k_area_m2 / muni_area_m2,
    gm_code = gsub("^GM", "", muni_id)
  )

cat(sprintf("  N2K share: mean=%.3f, sd=%.3f, max=%.3f\n",
            mean(treatment$n2k_share), sd(treatment$n2k_share), max(treatment$n2k_share)))
cat(sprintf("  Munis with N2K>0: %d (%.0f%%)\n",
            sum(treatment$n2k_share > 0), mean(treatment$n2k_share > 0)*100))

saveRDS(treatment, file.path(data_dir, "treatment_intensity.rds"))

## ============================================================
## 5. Build Analysis Panel
## ============================================================
cat("\n=== 5. Building analysis panel ===\n")

# Merge treatment + chars_2018 to get composite treatment intensity
treatment_full <- treatment %>%
  left_join(chars_2018, by = "gm_code") %>%
  mutate(
    # Composite treatment: N2K share × (agriculture + construction employment share)
    agri_construction_share = agri_share + industry_share,
    exposure = n2k_share * agri_construction_share,
    # Binary high-exposure indicator (above median among exposed)
    high_exposure = as.integer(exposure > median(exposure[exposure > 0], na.rm=TRUE))
  )

cat(sprintf("  Exposure: mean=%.4f, sd=%.4f, max=%.4f\n",
            mean(treatment_full$exposure, na.rm=TRUE),
            sd(treatment_full$exposure, na.rm=TRUE),
            max(treatment_full$exposure, na.rm=TRUE)))

# Panel: municipality × quarter
panel <- permits %>%
  left_join(rk_clean %>% select(gm_code, year, population), by = c("gm_code", "year")) %>%
  left_join(treatment_full %>%
              select(gm_code, n2k_share, exposure, high_exposure, agri_share,
                     industry_share, nitrogen_excretion, bev_dichtheid),
            by = "gm_code") %>%
  filter(!is.na(n2k_share), !is.na(population), population > 0) %>%
  mutate(
    # Post: Q3 2019 onwards (ruling was May 29, 2019)
    post = as.integer(year > 2019 | (year == 2019 & quarter >= 3)),
    # Per capita permits (per 1000 residents)
    permits_pc = total_dwellings / (population / 1000),
    log_permits = log(total_dwellings + 1),
    # Interaction terms
    exposure_post = exposure * post,
    n2k_post = n2k_share * post,
    # Quarter ID for event study
    event_q = (year - 2019) * 4 + quarter - 2,  # 0 = Q2 2019 (ruling quarter)
    time_fe = paste0(year, "Q", quarter)
  )

cat(sprintf("  Panel: %d obs, %d munis, %d quarters\n",
            nrow(panel), n_distinct(panel$gm_code), n_distinct(panel$time_fe)))

# Cross-section: merge treatment with elections
cross_section <- treatment_full %>%
  left_join(election %>% select(gm_code, bbb_share, fvd_share, pvv_share,
                                 populist_share, bbb_votes, total_valid),
            by = "gm_code") %>%
  filter(!is.na(bbb_share))

cat(sprintf("  Cross-section: %d munis with BBB + treatment data\n", nrow(cross_section)))

if (nrow(cross_section) < 200) {
  cat("  Low match — checking code formats...\n")
  cat("  Treatment gm_code sample:", paste(head(treatment_full$gm_code), collapse = ", "), "\n")
  cat("  Election gm_code sample:", paste(head(election$gm_code), collapse = ", "), "\n")
}

saveRDS(panel, file.path(data_dir, "panel_clean.rds"))
saveRDS(cross_section, file.path(data_dir, "cross_section_clean.rds"))
saveRDS(treatment_full, file.path(data_dir, "treatment_full.rds"))

cat("\n=== Data cleaning complete ===\n")
