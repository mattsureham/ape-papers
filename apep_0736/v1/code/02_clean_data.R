## 02_clean_data.R — Clean and merge all data sources
## apep_0736: Who Counts the Dead?

source("00_packages.R")

data_dir <- "../data"

# ─────────────────────────────────────────────────────────────────────
# 1. Clean COMEC MDI classification
# ─────────────────────────────────────────────────────────────────────
cat("Cleaning COMEC data...\n")
comec <- read_csv(file.path(data_dir, "cdc_comec_mdi.csv"), show_col_types = FALSE)

# Standardize column names
names(comec) <- trimws(names(comec))
names(comec) <- gsub("\\s+", "_", names(comec))

# Create clean FIPS and MDI type
comec_clean <- comec %>%
  mutate(
    fips = sprintf("%05d", as.integer(FIPS_CODE)),
    state_fips = sprintf("%02d", as.integer(STATE_CODE)),
    mdi_type = trimws(Medicolegal_Death_Investigation_Type),
    is_coroner = as.integer(mdi_type == "Coroner"),
    is_me = as.integer(grepl("Medical Examiner", mdi_type)),
    elected = trimws(ELECTED) == "Yes"
  ) %>%
  select(fips, state_fips, state_name = STATE_NAME, county_name = COUNTY_NAME,
         mdi_type, is_coroner, is_me, elected)

cat(sprintf("MDI types: %s\n", paste(names(table(comec_clean$mdi_type)), collapse = ", ")))
cat(sprintf("Coroner: %d, ME: %d, Other: %d\n",
            sum(comec_clean$is_coroner), sum(comec_clean$is_me),
            sum(!comec_clean$is_coroner & !comec_clean$is_me)))

# Identify mixed states (states with both coroner and ME counties)
state_types <- comec_clean %>%
  group_by(state_fips, state_name) %>%
  summarise(
    n_coroner = sum(is_coroner),
    n_me = sum(is_me),
    n_other = n() - sum(is_coroner) - sum(is_me),
    .groups = "drop"
  ) %>%
  mutate(is_mixed = n_coroner > 0 & n_me > 0)

cat(sprintf("\nMixed states: %d\n", sum(state_types$is_mixed)))
cat("Mixed states: ", paste(state_types$state_name[state_types$is_mixed], collapse = ", "), "\n")

# ─────────────────────────────────────────────────────────────────────
# 2. Clean model-based drug overdose data
# ─────────────────────────────────────────────────────────────────────
cat("\nCleaning drug overdose data...\n")
model_od <- read_csv(file.path(data_dir, "nchs_model_drug_overdose.csv"), show_col_types = FALSE)

od_clean <- model_od %>%
  mutate(
    fips = sprintf("%05d", as.integer(fips)),
    year = as.integer(year),
    od_rate = as.numeric(model_based_death_rate),
    od_rate_sd = as.numeric(standard_deviation),
    od_rate_lo = as.numeric(lower95ci),
    od_rate_hi = as.numeric(upper95ci),
    urban_rural = urbanrural
  ) %>%
  filter(!is.na(od_rate)) %>%
  select(fips, year, state, county, population, od_rate, od_rate_sd,
         od_rate_lo, od_rate_hi, urban_rural, censusdivision)

cat(sprintf("Drug OD cleaned: %d obs, %d unique counties, years %d-%d\n",
            nrow(od_clean), n_distinct(od_clean$fips),
            min(od_clean$year), max(od_clean$year)))

# ─────────────────────────────────────────────────────────────────────
# 3. Parse county adjacency file and build border pairs
# ─────────────────────────────────────────────────────────────────────
cat("\nParsing county adjacency file...\n")
adj_raw <- readLines(file.path(data_dir, "county_adjacency.txt"))

# Parse tab-delimited adjacency file
# Format: "County, ST"\tFIPS\t"Neighbor, ST"\tNeighbor_FIPS
# Continuation rows: \t\t"Neighbor, ST"\tNeighbor_FIPS

adj_list <- list()
current_fips <- NA
for (line in adj_raw) {
  # Handle encoding issues
  line <- iconv(line, from = "latin1", to = "UTF-8", sub = "byte")
  parts <- strsplit(line, "\t")[[1]]
  if (is.null(parts) || length(parts) == 0) next
  parts <- trimws(gsub('"', '', parts))

  if (length(parts) >= 2 && !is.na(parts[1]) && nchar(parts[1]) > 0) {
    # New county line
    fips_val <- suppressWarnings(as.integer(parts[2]))
    if (!is.na(fips_val)) current_fips <- sprintf("%05d", fips_val)
  }
  # Neighbor FIPS is always the last element
  neighbor_val <- suppressWarnings(as.integer(parts[length(parts)]))
  if (!is.na(neighbor_val)) {
    neighbor_fips <- sprintf("%05d", neighbor_val)
    if (!is.na(current_fips) && current_fips != neighbor_fips) {
      adj_list[[length(adj_list) + 1]] <- data.frame(
        fips_a = current_fips, fips_b = neighbor_fips, stringsAsFactors = FALSE
      )
    }
  }
}

adjacency <- bind_rows(adj_list) %>%
  filter(!is.na(fips_a) & !is.na(fips_b))

# Deduplicate: keep only (min, max) pairs
adjacency <- adjacency %>%
  mutate(
    fips_lo = pmin(fips_a, fips_b),
    fips_hi = pmax(fips_a, fips_b)
  ) %>%
  distinct(fips_lo, fips_hi) %>%
  rename(fips_a = fips_lo, fips_b = fips_hi)

cat(sprintf("Adjacency pairs: %d unique county pairs\n", nrow(adjacency)))

# ─────────────────────────────────────────────────────────────────────
# 4. Build cross-MDI border pairs (coroner↔ME within same state)
# ─────────────────────────────────────────────────────────────────────
cat("\nConstructing cross-MDI border pairs...\n")

# Merge MDI type onto adjacency
adj_mdi <- adjacency %>%
  inner_join(comec_clean %>% select(fips, state_fips, mdi_type_a = mdi_type,
                                     is_coroner_a = is_coroner, is_me_a = is_me),
             by = c("fips_a" = "fips")) %>%
  inner_join(comec_clean %>% select(fips, state_fips_b = state_fips, mdi_type_b = mdi_type,
                                     is_coroner_b = is_coroner, is_me_b = is_me),
             by = c("fips_b" = "fips"))

# Cross-MDI pairs: one coroner, one ME, SAME STATE
cross_mdi <- adj_mdi %>%
  filter(state_fips == state_fips_b) %>%  # Same state
  filter(
    (is_coroner_a == 1 & is_me_b == 1) |
    (is_me_a == 1 & is_coroner_b == 1)
  ) %>%
  mutate(pair_id = paste0(fips_a, "_", fips_b))

cat(sprintf("Cross-MDI border pairs (within-state): %d\n", nrow(cross_mdi)))

# List of counties involved in cross-MDI pairs
border_counties <- unique(c(cross_mdi$fips_a, cross_mdi$fips_b))
cat(sprintf("Unique border counties: %d\n", length(border_counties)))

# ─────────────────────────────────────────────────────────────────────
# 5. Clean ACS demographics
# ─────────────────────────────────────────────────────────────────────
cat("\nCleaning ACS demographics...\n")
acs <- read_csv(file.path(data_dir, "acs_county_demographics.csv"), show_col_types = FALSE)

acs_clean <- acs %>%
  mutate(
    fips = sprintf("%05d", as.integer(paste0(state, county))),
    total_pop = as.numeric(B01003_001E),
    poverty_n = as.numeric(B17001_002E),
    median_income = as.numeric(B19013_001E),
    white_pop = as.numeric(B02001_002E),
    black_pop = as.numeric(B02001_003E),
    pct_poverty = poverty_n / total_pop * 100,
    pct_white = white_pop / total_pop * 100,
    pct_black = black_pop / total_pop * 100,
    log_pop = log(total_pop)
  ) %>%
  select(fips, total_pop, log_pop, pct_poverty, median_income, pct_white, pct_black)

cat(sprintf("ACS cleaned: %d counties\n", nrow(acs_clean)))

# ─────────────────────────────────────────────────────────────────────
# 6. Merge everything into analysis panel
# ─────────────────────────────────────────────────────────────────────
cat("\nMerging into analysis panel...\n")

panel <- od_clean %>%
  inner_join(comec_clean %>% select(fips, state_fips, is_coroner, is_me, mdi_type, elected),
             by = "fips") %>%
  left_join(acs_clean, by = "fips")

cat(sprintf("Full panel: %d obs, %d counties, %d years\n",
            nrow(panel), n_distinct(panel$fips), n_distinct(panel$year)))

# Border pair panel: only counties in cross-MDI pairs
border_panel <- panel %>%
  filter(fips %in% border_counties)

cat(sprintf("Border panel: %d obs, %d counties\n",
            nrow(border_panel), n_distinct(border_panel$fips)))

# Create pair-level dataset (long form: each county appears once per pair per year)
pair_long <- cross_mdi %>%
  select(pair_id, fips_a, fips_b) %>%
  pivot_longer(cols = c(fips_a, fips_b), names_to = "side", values_to = "fips") %>%
  inner_join(panel, by = "fips")

cat(sprintf("Pair-level panel: %d obs\n", nrow(pair_long)))

# ─────────────────────────────────────────────────────────────────────
# 7. Save cleaned datasets
# ─────────────────────────────────────────────────────────────────────
saveRDS(panel, file.path(data_dir, "analysis_panel.rds"))
saveRDS(border_panel, file.path(data_dir, "border_panel.rds"))
saveRDS(pair_long, file.path(data_dir, "pair_panel.rds"))
saveRDS(cross_mdi, file.path(data_dir, "cross_mdi_pairs.rds"))
saveRDS(comec_clean, file.path(data_dir, "comec_clean.rds"))
saveRDS(state_types, file.path(data_dir, "state_types.rds"))

cat("\n=== Data cleaning complete ===\n")
cat(sprintf("Full panel: %d obs\n", nrow(panel)))
cat(sprintf("Border panel: %d obs\n", nrow(border_panel)))
cat(sprintf("Cross-MDI pairs: %d\n", nrow(cross_mdi)))
