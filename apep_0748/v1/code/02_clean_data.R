## 02_clean_data.R — Clean and merge GP closures with A&E provider panel
## apep_0748: GP Practice Closures and A&E Utilization

source("00_packages.R")

data_dir <- "../data"

cat("=== Loading raw data ===\n")
gp_raw <- readRDS(file.path(data_dir, "gp_practices_raw.rds"))
ae_panel <- readRDS(file.path(data_dir, "ae_provider_panel.rds"))
trusts <- readRDS(file.path(data_dir, "nhs_trusts_raw.rds"))
geocoded <- readRDS(file.path(data_dir, "postcodes_geocoded.rds"))

## ============================================================
## STEP 1: Clean GP Practice Closures
## ============================================================
cat("\n=== STEP 1: Clean GP Closures ===\n")

## Parse close dates
gp_closed <- gp_raw %>%
  filter(api_status == "Inactive", !is.na(close_date)) %>%
  mutate(
    close_date_parsed = as.Date(close_date),
    close_year = year(close_date_parsed),
    close_month = floor_date(close_date_parsed, "month"),
    postcode_clean = trimws(PostCode)
  ) %>%
  filter(
    close_year >= 2015 & close_year <= 2025,
    !is.na(postcode_clean),
    nchar(postcode_clean) > 3
  )

cat("GP closures 2015-2025:", nrow(gp_closed), "\n")
cat("Closures by year:\n")
print(table(gp_closed$close_year))

## Merge with geocoded postcodes
gp_closed <- gp_closed %>%
  left_join(geocoded, by = c("postcode_clean" = "postcode")) %>%
  filter(!is.na(latitude), !is.na(longitude))

cat("GP closures with coordinates:", nrow(gp_closed), "\n")

## ============================================================
## STEP 2: Clean A&E Provider Panel
## ============================================================
cat("\n=== STEP 2: Clean A&E Provider Panel ===\n")

## Standardize provider codes (remove spaces, uppercase)
ae_clean <- ae_panel %>%
  mutate(
    provider_code = trimws(toupper(provider_code)),
    type1_attendances = as.numeric(type1_attendances),
    total_attendances = as.numeric(total_attendances)
  ) %>%
  filter(
    !is.na(type1_attendances),
    type1_attendances > 0,
    nchar(provider_code) >= 3
  )

cat("A&E panel rows:", nrow(ae_clean), "\n")
cat("Unique A&E providers:", length(unique(ae_clean$provider_code)), "\n")
cat("Period range:", as.character(min(ae_clean$period)), "to", as.character(max(ae_clean$period)), "\n")

## ============================================================
## STEP 3: Get A&E Trust Locations
## ============================================================
cat("\n=== STEP 3: Map Trust Locations ===\n")

## Get trust postcodes from the ODS trust data
trust_locations <- trusts %>%
  mutate(postcode_clean = trimws(PostCode)) %>%
  left_join(geocoded, by = c("postcode_clean" = "postcode")) %>%
  filter(!is.na(latitude), !is.na(longitude)) %>%
  select(trust_code = OrgId, trust_name = Name, trust_lat = latitude,
         trust_lon = longitude, trust_postcode = postcode_clean,
         trust_la = local_authority, trust_region = region)

## Match A&E provider codes to trust locations
## Provider codes in A&E data should match trust codes (3-letter org codes)
ae_providers <- data.frame(provider_code = unique(ae_clean$provider_code))
ae_with_loc <- ae_providers %>%
  left_join(trust_locations, by = c("provider_code" = "trust_code"))

matched <- sum(!is.na(ae_with_loc$trust_lat))
cat("A&E providers matched to trust locations:", matched, "/", nrow(ae_with_loc), "\n")

## For unmatched, try to find locations from the geocoded postcodes
## using the provider mapping from the A&E files themselves
## (Some providers might use different org codes)

## ============================================================
## STEP 4: Map GP Closures to Nearest A&E Trusts
## ============================================================
cat("\n=== STEP 4: Map GP Closures to Nearest A&E Trust ===\n")

## For each GP closure, find the nearest A&E trust within 20km
## This creates the treatment mapping

trust_locs <- ae_with_loc %>%
  filter(!is.na(trust_lat)) %>%
  distinct(provider_code, .keep_all = TRUE)

cat("Trust locations available for matching:", nrow(trust_locs), "\n")

## Compute distances: each GP closure to each trust
## Using Haversine formula via geosphere package
gp_to_trust <- list()

for (i in seq_len(nrow(gp_closed))) {
  gp_loc <- c(gp_closed$longitude[i], gp_closed$latitude[i])
  trust_coords <- cbind(trust_locs$trust_lon, trust_locs$trust_lat)

  dists <- geosphere::distHaversine(gp_loc, trust_coords) / 1000  # km

  ## Find trusts within 20km
  nearby <- which(dists <= 20)
  if (length(nearby) > 0) {
    for (j in nearby) {
      gp_to_trust[[length(gp_to_trust) + 1]] <- data.frame(
        gp_code = gp_closed$OrgId[i],
        gp_postcode = gp_closed$postcode_clean[i],
        close_month = gp_closed$close_month[i],
        trust_code = trust_locs$provider_code[j],
        distance_km = dists[j],
        stringsAsFactors = FALSE
      )
    }
  }

  if (i %% 200 == 0) cat("  Mapped", i, "/", nrow(gp_closed), "closures\n")
}

gp_trust_map <- bind_rows(gp_to_trust)
cat("GP-Trust mappings (within 20km):", nrow(gp_trust_map), "\n")
cat("Unique GP closures mapped:", length(unique(gp_trust_map$gp_code)), "\n")
cat("Unique trusts with nearby closures:", length(unique(gp_trust_map$trust_code)), "\n")

## ============================================================
## STEP 5: Construct Treatment Variables
## ============================================================
cat("\n=== STEP 5: Construct Treatment Variables ===\n")

## For each trust × month, count cumulative GP closures within 10km
## Treatment = first month with a closure within 10km

## Closures within 10km (primary specification)
closures_10km <- gp_trust_map %>%
  filter(distance_km <= 10) %>%
  group_by(trust_code) %>%
  summarise(
    first_closure = min(close_month),
    n_closures = n(),
    .groups = "drop"
  )

cat("Trusts with GP closures within 10km:", nrow(closures_10km), "\n")

## Create the analysis panel: trust × month
analysis_months <- sort(unique(ae_clean$period))
## Restrict to April 2017 - March 2025
analysis_months <- analysis_months[analysis_months >= as.Date("2017-04-01")]

## Build balanced panel for trusts that appear in most months
trust_freq <- ae_clean %>%
  filter(period >= as.Date("2017-04-01")) %>%
  count(provider_code) %>%
  filter(n >= 60)  # Present in at least 60 of ~94 months

cat("Trusts in balanced panel (≥60 months):", nrow(trust_freq), "\n")

panel <- expand.grid(
  provider_code = trust_freq$provider_code,
  period = analysis_months,
  stringsAsFactors = FALSE
) %>%
  as_tibble()

## Merge A&E attendance data
panel <- panel %>%
  left_join(ae_clean %>%
              select(provider_code, period, type1_attendances, total_attendances),
            by = c("provider_code", "period"))

## Merge treatment variables
panel <- panel %>%
  left_join(closures_10km, by = c("provider_code" = "trust_code")) %>%
  mutate(
    ## Binary treatment: post first closure
    treated = as.integer(!is.na(first_closure) & period >= first_closure),
    ## Treatment group (cohort) for C-S: month of first closure
    ## Never-treated trusts get first_closure = 0 (Inf)
    cohort = as.integer(format(first_closure, "%Y%m")),
    ## Time period as integer
    time_period = as.integer(format(period, "%Y%m")),
    ## Log outcomes
    log_type1 = log(type1_attendances),
    log_total = log(total_attendances)
  )

## Replace NAs for never-treated trusts
panel$cohort[is.na(panel$cohort)] <- 0
panel$n_closures[is.na(panel$n_closures)] <- 0

## ============================================================
## STEP 6: Compute cumulative closures per trust-month
## ============================================================

## Monthly closure counts per trust (within 10km)
monthly_closures <- gp_trust_map %>%
  filter(distance_km <= 10) %>%
  distinct(gp_code, trust_code, close_month) %>%
  group_by(trust_code, close_month) %>%
  summarise(closures_this_month = n(), .groups = "drop")

## Expand to full panel and compute cumulative
panel <- panel %>%
  left_join(monthly_closures,
            by = c("provider_code" = "trust_code", "period" = "close_month")) %>%
  mutate(closures_this_month = replace_na(closures_this_month, 0)) %>%
  group_by(provider_code) %>%
  arrange(period) %>%
  mutate(cumulative_closures = cumsum(closures_this_month)) %>%
  ungroup()

## ============================================================
## STEP 7: Add trust-level covariates
## ============================================================

## Merge trust region
panel <- panel %>%
  left_join(
    trust_locations %>% select(trust_code, trust_region, trust_la),
    by = c("provider_code" = "trust_code")
  )

## ============================================================
## Summary Statistics
## ============================================================
cat("\n=== ANALYSIS PANEL SUMMARY ===\n")
cat("Panel dimensions:", nrow(panel), "trust-months\n")
cat("Unique trusts:", length(unique(panel$provider_code)), "\n")
cat("Months:", length(unique(panel$period)), "\n")
cat("Period:", as.character(min(panel$period)), "to", as.character(max(panel$period)), "\n")
cat("\nTreatment:\n")
cat("  Ever-treated trusts:", sum(panel$cohort > 0 & !duplicated(panel$provider_code)), "\n")
cat("  Never-treated trusts:", sum(panel$cohort == 0 & !duplicated(panel$provider_code)), "\n")
cat("  Total GP closures (10km):", sum(panel$closures_this_month), "\n")
cat("\nOutcome (Type 1 Attendances):\n")
cat("  Mean:", round(mean(panel$type1_attendances, na.rm = TRUE)), "\n")
cat("  SD:", round(sd(panel$type1_attendances, na.rm = TRUE)), "\n")
cat("  Missing:", sum(is.na(panel$type1_attendances)), "\n")

## Save analysis panel
saveRDS(panel, file.path(data_dir, "analysis_panel.rds"))
cat("\nAnalysis panel saved to:", file.path(data_dir, "analysis_panel.rds"), "\n")

## Save diagnostics for validator
diagnostics <- list(
  n_treated = sum(panel$cohort > 0 & !duplicated(panel$provider_code)),
  n_pre = length(analysis_months[analysis_months < median(closures_10km$first_closure, na.rm = TRUE)]),
  n_obs = nrow(panel[!is.na(panel$type1_attendances), ])
)
jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)
cat("Diagnostics saved.\n")
