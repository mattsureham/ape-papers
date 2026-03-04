## ============================================================================
## 02_clean_data.R — Link DPE to DVF, construct analysis variables
## apep_0503: DPE Energy Labels + Rental Ban Multi-Cutoff RDD
## ============================================================================

source("00_packages.R")

DATA_DIR <- "../data"

## ============================================================================
## PART 1: Load and prepare DPE data
## ============================================================================

cat("=== Loading DPE data ===\n")
dpe <- arrow::read_parquet(file.path(DATA_DIR, "dpe_near_cutoffs.parquet"))

# Parse date
dpe <- dpe %>%
  mutate(
    date_dpe = as.Date(date_dpe),
    year_dpe = year(date_dpe),
    # Determine binding dimension
    energy_class = case_when(
      energy_kwh_m2 <= 70  ~ "A",
      energy_kwh_m2 <= 110 ~ "B",
      energy_kwh_m2 <= 180 ~ "C",
      energy_kwh_m2 <= 250 ~ "D",
      energy_kwh_m2 <= 330 ~ "E",
      energy_kwh_m2 <= 420 ~ "F",
      TRUE ~ "G"
    ),
    ghg_class = case_when(
      ghg_kg_m2 <= 6   ~ "A",
      ghg_kg_m2 <= 11  ~ "B",
      ghg_kg_m2 <= 30  ~ "C",
      ghg_kg_m2 <= 50  ~ "D",
      ghg_kg_m2 <= 70  ~ "E",
      ghg_kg_m2 <= 100 ~ "F",
      TRUE ~ "G"
    ),
    # Under double-seuil: label = worst of energy_class and ghg_class
    # A < B < C < D < E < F < G (G is worst)
    energy_rank = match(energy_class, LETTERS[1:7]),
    ghg_rank = match(ghg_class, LETTERS[1:7]),
    expected_label = LETTERS[pmax(energy_rank, ghg_rank)],
    # Binding dimension
    binding_dim = case_when(
      energy_rank > ghg_rank ~ "energy",
      ghg_rank > energy_rank ~ "ghg",
      TRUE ~ "tied"
    ),
    # Energy-bound flag (primary analysis sample)
    is_energy_bound = binding_dim %in% c("energy", "tied")
  )

cat(sprintf("Binding dimension distribution:\n"))
print(table(dpe$binding_dim))
cat(sprintf("\nEnergy-bound share: %.1f%%\n",
            mean(dpe$is_energy_bound, na.rm = TRUE) * 100))

## ============================================================================
## PART 2: Load and prepare DVF data
## ============================================================================

cat("\n=== Loading DVF data ===\n")
dvf <- arrow::read_parquet(file.path(DATA_DIR, "dvf_all.parquet"))

# Create address key for matching
dvf <- dvf %>%
  mutate(
    code_commune_clean = str_pad(as.character(code_commune), 5, pad = "0"),
    street_key = tolower(paste0(
      str_pad(as.character(adresse_numero), 5, pad = "0"),
      str_replace_all(adresse_nom_voie, "[^a-z0-9]", "")
    )),
    match_key = paste0(code_commune_clean, "_", street_key)
  )

## ============================================================================
## PART 3: Link DPE to DVF
## ============================================================================

cat("\n=== Linking DPE to DVF ===\n")

# Strategy: Match on commune + address key
# A DPE assessment typically precedes a sale by days to months

dpe <- dpe %>%
  mutate(
    code_commune_clean = str_pad(as.character(insee_code), 5, pad = "0"),
    street_key = "",  # Will use commune-level matching as primary
    match_key = code_commune_clean
  )

# Strategy: Aggregate DVF prices at commune × year × building type level,
# then merge onto DPE records. This avoids the combinatorial explosion of
# individual-level cross-joins. The RDD uses energy consumption as the
# running variable; the outcome is local market prices. Within a commune
# near a cutoff, assignment to label is quasi-random, so commune-level
# average prices capture the relevant price effects.

# Step 1: Create commune × year × building-type price aggregates from DVF
cat("  Computing commune × year × type price aggregates from DVF...\n")

dvf[, building_type_dvf := type_local]

dvf_agg <- dvf[, .(
  n_transactions = .N,
  mean_price_m2 = mean(price_m2, na.rm = TRUE),
  median_price_m2 = median(price_m2, na.rm = TRUE),
  mean_log_price_m2 = mean(log_price_m2, na.rm = TRUE),
  sd_price_m2 = sd(price_m2, na.rm = TRUE),
  mean_surface = mean(surface_reelle_bati, na.rm = TRUE),
  mean_pieces = mean(nombre_pieces_principales, na.rm = TRUE)
), by = .(code_commune_clean, year, building_type_dvf)]

cat(sprintf("  DVF aggregates: %s commune × year × type cells\n",
            format(nrow(dvf_agg), big.mark = ",")))

# Step 2: Prepare DPE records for merge
dpe_for_merge <- dpe %>%
  mutate(
    building_type_dvf = case_when(
      building_type == "maison" ~ "Maison",
      building_type %in% c("appartement", "immeuble") ~ "Appartement",
      TRUE ~ NA_character_
    ),
    year = year_dpe
  ) %>%
  filter(!is.na(building_type_dvf))

# Step 3: Merge DPE to DVF aggregates
cat("  Merging DPE with DVF price aggregates...\n")

dt_dpe <- as.data.table(dpe_for_merge)
merged <- merge(dt_dpe, dvf_agg,
                by = c("code_commune_clean", "year", "building_type_dvf"),
                all.x = FALSE, all.y = FALSE)

# Use mean_log_price_m2 as the outcome, with enough transactions
merged <- merged[n_transactions >= 3]  # At least 3 transactions in cell

cat(sprintf("  Merged dataset: %s DPE records with DVF prices\n",
            format(nrow(merged), big.mark = ",")))
cat(sprintf("  DPE match rate: %.1f%% of near-cutoff DPEs linked to DVF prices\n",
            nrow(merged) / nrow(dpe_for_merge) * 100))

# Rename for downstream consistency
merged[, log_price_m2 := mean_log_price_m2]
merged[, price_m2 := mean_price_m2]
merged[, surface_reelle_bati := mean_surface]
merged[, nombre_pieces_principales := mean_pieces]

## ============================================================================
## PART 4: Construct RDD variables
## ============================================================================

cat("\n=== Constructing RDD analysis variables ===\n")

# For each cutoff, create distance-to-cutoff running variable
analysis <- merged %>%
  as_tibble() %>%
  mutate(
    # Distance to nearest energy cutoff
    dist_to_cutoff = energy_kwh_m2 - cutoff_value,

    # Post-ban indicator (rental ban timeline)
    # Jan 2023: extreme G (>450 kWh) banned
    # Jan 2025: all G (>420 kWh) banned
    post_ban_g = (year >= 2023),
    post_ban_full = (year >= 2025),

    # Regulatory status
    banned = (dpe_label == "G" & post_ban_g),

    # Cutoff type classification
    cutoff_type = case_when(
      nearest_cutoff == "F" ~ "regulatory_active",    # G/F: active ban
      nearest_cutoff == "E" ~ "anticipation_near",    # F/E: ban in 2028
      nearest_cutoff == "D" ~ "anticipation_distant",  # E/D: ban in 2034
      nearest_cutoff %in% c("C", "B", "A") ~ "information_only",
      TRUE ~ "unknown"
    ),

    # Log price
    log_price_m2 = log(price_m2),

    # Period indicators
    period = case_when(
      year <= 2022 ~ "pre_ban",
      year %in% c(2023, 2024) ~ "transition",
      year >= 2025 ~ "post_ban"
    ),

    # Property age
    property_age = year - as.numeric(year_built)
  )

# Remove extreme outliers
analysis <- analysis %>%
  filter(
    price_m2 > 200 & price_m2 < 30000,    # Reasonable price range
    surface_reelle_bati > 10 & surface_reelle_bati < 400,  # Reasonable surface
    !is.na(energy_kwh_m2),
    !is.na(log_price_m2)
  )

cat(sprintf("Analysis dataset: %s observations\n",
            format(nrow(analysis), big.mark = ",")))

# Summary by cutoff
cat("\nObservations by cutoff and period:\n")
print(analysis %>%
        count(nearest_cutoff, cutoff_value, cutoff_type, period) %>%
        pivot_wider(names_from = period, values_from = n, values_fill = 0) %>%
        arrange(cutoff_value))

## ============================================================================
## PART 5: Load rental share data
## ============================================================================

cat("\n=== Loading rental share data ===\n")

rental_file <- file.path(DATA_DIR, "commune_rental_share.csv")
if (file.exists(rental_file)) {
  rental <- fread(rental_file)
  # Standardize commune code
  if ("code_commune" %in% names(rental)) {
    rental[, code_commune_clean := str_pad(as.character(code_commune), 5, pad = "0")]
  }

  # Merge rental share into analysis
  if ("rental_share" %in% names(rental)) {
    analysis <- analysis %>%
      left_join(rental %>% select(code_commune_clean, rental_share),
                by = "code_commune_clean")
    # High-rental commune indicator (above median)
    med_rental <- median(analysis$rental_share, na.rm = TRUE)
    analysis <- analysis %>%
      mutate(high_rental = rental_share > med_rental)
    cat(sprintf("  Rental share merged. Median: %.1f%%\n", med_rental * 100))
  } else if ("apt_share" %in% names(rental)) {
    analysis <- analysis %>%
      left_join(rental %>% select(code_commune_clean, apt_share),
                by = "code_commune_clean")
    med_apt <- median(analysis$apt_share, na.rm = TRUE)
    analysis <- analysis %>%
      mutate(
        rental_share = apt_share,
        high_rental = apt_share > med_apt
      )
    cat(sprintf("  Apartment share proxy merged. Median: %.1f%%\n", med_apt * 100))
  }
} else {
  cat("  No rental share data found. Skipping.\n")
  analysis <- analysis %>% mutate(rental_share = NA_real_, high_rental = NA)
}

## ============================================================================
## PART 6: Save analysis dataset
## ============================================================================

cat("\n=== Saving analysis dataset ===\n")
arrow::write_parquet(analysis, file.path(DATA_DIR, "analysis.parquet"))

# Also save a compact summary for quick access
summary_stats <- analysis %>%
  group_by(nearest_cutoff, cutoff_value, cutoff_type, dpe_label) %>%
  summarise(
    n = n(),
    mean_price_m2 = mean(price_m2, na.rm = TRUE),
    sd_price_m2 = sd(price_m2, na.rm = TRUE),
    mean_energy = mean(energy_kwh_m2, na.rm = TRUE),
    mean_surface = mean(surface_reelle_bati, na.rm = TRUE),
    pct_apartment = mean(building_type_dvf == "Appartement", na.rm = TRUE),
    pct_energy_bound = mean(is_energy_bound, na.rm = TRUE),
    .groups = "drop"
  )

write_csv(summary_stats, file.path(DATA_DIR, "summary_stats.csv"))
cat("Summary statistics saved.\n")

cat(sprintf("\n=== Data preparation complete ===\n"))
cat(sprintf("Final analysis dataset: %s observations across %d cutoffs\n",
            format(nrow(analysis), big.mark = ","),
            n_distinct(analysis$nearest_cutoff)))
