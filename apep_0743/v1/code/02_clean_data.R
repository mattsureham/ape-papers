# 02_clean_data.R — Construct border county pairs and analysis dataset
# APEP Paper apep_0743: Funeral Director Mandates and Death Care Markets

source("00_packages.R")

# ─── 1. Define FD-required states ───
# States requiring funeral director involvement for all body disposition
fd_required_states <- c("09", "17", "18", "19", "22", "26", "31", "34", "36")
# CT=09, IL=17, IN=18, IA=19, LA=22, MI=26, NE=31, NJ=34, NY=36

fd_state_names <- c(
  "09" = "Connecticut", "17" = "Illinois", "18" = "Indiana",
  "19" = "Iowa", "22" = "Louisiana", "26" = "Michigan",
  "31" = "Nebraska", "34" = "New Jersey", "36" = "New York"
)

# ─── 2. Load CBP data ───
cbp <- read_csv("../data/cbp_funeral_homes.csv", show_col_types = FALSE)
cbp_crem <- read_csv("../data/cbp_cemeteries_crematories.csv", show_col_types = FALSE)

# Average across years for cross-sectional analysis
cbp_avg <- cbp %>%
  group_by(fips, state) %>%
  summarize(
    estab = mean(ESTAB, na.rm = TRUE),
    emp = mean(EMP, na.rm = TRUE),
    payann = mean(PAYANN, na.rm = TRUE),
    n_years = n(),
    .groups = "drop"
  )

cbp_crem_avg <- cbp_crem %>%
  group_by(fips, state) %>%
  summarize(
    crem_estab = mean(ESTAB, na.rm = TRUE),
    crem_emp = mean(EMP, na.rm = TRUE),
    .groups = "drop"
  )

cat(sprintf("CBP funeral homes: %d unique counties\n", n_distinct(cbp_avg$fips)))
cat(sprintf("CBP crematories: %d unique counties\n", n_distinct(cbp_crem_avg$fips)))

# ─── 3. Load demographics ───
acs <- read_csv("../data/acs_demographics.csv", show_col_types = FALSE)

# ─── 4. Construct border pairs ───
# Since adjacency file is unavailable, we'll define the known border pairs
# between FD-required and non-FD-required states

# State borders between FD and non-FD states
border_segments <- tribble(
  ~fd_state, ~non_fd_state, ~segment_id,
  "09", "25", "CT_MA",    # Connecticut - Massachusetts
  "09", "44", "CT_RI",    # Connecticut - Rhode Island
  "17", "55", "IL_WI",    # Illinois - Wisconsin
  "17", "29", "IL_MO",    # Illinois - Missouri
  "17", "21", "IL_KY",    # Illinois - Kentucky
  "18", "21", "IN_KY",    # Indiana - Kentucky
  "18", "39", "IN_OH",    # Indiana - Ohio
  "19", "27", "IA_MN",    # Iowa - Minnesota
  "19", "55", "IA_WI",    # Iowa - Wisconsin
  "19", "29", "IA_MO",    # Iowa - Missouri
  "19", "46", "IA_SD",    # Iowa - South Dakota
  "22", "48", "LA_TX",    # Louisiana - Texas
  "22", "05", "LA_AR",    # Louisiana - Arkansas
  "22", "28", "LA_MS",    # Louisiana - Mississippi
  "26", "39", "MI_OH",    # Michigan - Ohio
  "26", "55", "MI_WI",    # Michigan - Wisconsin
  "31", "46", "NE_SD",    # Nebraska - South Dakota
  "31", "29", "NE_MO",    # Nebraska - Missouri
  "31", "20", "NE_KS",    # Nebraska - Kansas
  "31", "08", "NE_CO",    # Nebraska - Colorado
  "31", "56", "NE_WY",    # Nebraska - Wyoming
  "34", "42", "NJ_PA",    # New Jersey - Pennsylvania
  "34", "10", "NJ_DE",    # New Jersey - Delaware
  "36", "42", "NY_PA",    # New York - Pennsylvania
  "36", "25", "NY_MA",    # New York - Massachusetts
  "36", "50", "NY_VT",    # New York - Vermont
  "36", "06", "NY_CT"     # New York - Connecticut (both FD! skip later)
)

# Remove NY-CT pair since both are FD-required
border_segments <- border_segments %>%
  filter(!(fd_state %in% fd_required_states & non_fd_state %in% fd_required_states))

cat(sprintf("Border segments: %d\n", nrow(border_segments)))

# ─── 5. Identify border counties ───
# A county is a "border county" if it's adjacent to a county in another state
# We approximate this by selecting counties that are geographically at the edge
# of their state. Since we lack adjacency data, we'll use ALL counties in
# border states and rely on border-pair FEs to absorb local conditions.

# Actually, for a clean border design, we need actual county adjacency.
# Let's download it from a different source.
cat("Downloading county adjacency from NBER...\n")

# Try NBER mirror of county adjacency
nber_url <- "https://data.nber.org/cbsa-csa-fips-county-crosswalk/county_adjacency2024.csv"
resp <- GET(nber_url, timeout(60))

if (status_code(resp) != 200) {
  # Alternative: use a direct construction approach
  # Download county centroids and use Haversine distance
  cat("NBER source unavailable. Using state-level aggregation approach.\n")

  # For a border discontinuity without county adjacency,
  # we aggregate to state-level and use state borders as the unit
  # OR we identify border counties manually using FIPS codes
  use_state_level <- TRUE
} else {
  adj_raw <- content(resp, as = "text", encoding = "UTF-8")
  writeLines(adj_raw, "../data/county_adjacency_nber.csv")
  use_state_level <- FALSE
}

# ─── Strategy: Use all counties, construct border pairs via adjacency ───
# If adjacency file unavailable, use alternative: download county coordinates
# and identify pairs within distance threshold

if (use_state_level) {
  cat("Downloading county coordinates (Gazetteer)...\n")

  gaz_url <- "https://www2.census.gov/geo/docs/maps-data/data/gazetteer/2020_Gazetteer/2020_Gaz_counties_national.zip"
  resp <- GET(gaz_url, timeout(120), write_disk("../data/gazetteer.zip", overwrite = TRUE))

  if (status_code(resp) == 200) {
    unzip("../data/gazetteer.zip", exdir = "../data/")
    gaz_files <- list.files("../data/", pattern = "Gaz_counties", full.names = TRUE)
    gaz <- read_tsv(gaz_files[1], show_col_types = FALSE)

    # Clean column names
    names(gaz) <- trimws(names(gaz))
    gaz <- gaz %>%
      mutate(fips = sprintf("%05d", as.numeric(GEOID))) %>%
      select(fips, lat = INTPTLAT, lon = INTPTLONG)

    cat(sprintf("Gazetteer: %d counties with coordinates\n", nrow(gaz)))
  } else {
    stop("Cannot download county coordinates. Cannot construct border pairs.")
  }

  # Haversine distance function
  haversine <- function(lat1, lon1, lat2, lon2) {
    R <- 6371 # km
    dlat <- (lat2 - lat1) * pi / 180
    dlon <- (lon2 - lon1) * pi / 180
    a <- sin(dlat/2)^2 + cos(lat1*pi/180) * cos(lat2*pi/180) * sin(dlon/2)^2
    2 * R * asin(sqrt(a))
  }

  # For each border segment, find county pairs within 75km of each other
  # across the state border
  border_pairs <- list()

  for (i in seq_len(nrow(border_segments))) {
    seg <- border_segments[i, ]

    # Counties in the FD state
    fd_counties <- gaz %>% filter(substr(fips, 1, 2) == seg$fd_state)
    # Counties in the non-FD state
    nfd_counties <- gaz %>% filter(substr(fips, 1, 2) == seg$non_fd_state)

    if (nrow(fd_counties) == 0 | nrow(nfd_counties) == 0) next

    # Cross join via base R
    fd_idx <- rep(seq_len(nrow(fd_counties)), each = nrow(nfd_counties))
    nfd_idx <- rep(seq_len(nrow(nfd_counties)), nrow(fd_counties))

    pairs <- tibble(
      fd_fips = fd_counties$fips[fd_idx],
      fd_lat = fd_counties$lat[fd_idx],
      fd_lon = fd_counties$lon[fd_idx],
      nfd_fips = nfd_counties$fips[nfd_idx],
      nfd_lat = nfd_counties$lat[nfd_idx],
      nfd_lon = nfd_counties$lon[nfd_idx]
    )

    pairs$dist_km <- haversine(
      pairs$fd_lat, pairs$fd_lon,
      pairs$nfd_lat, pairs$nfd_lon
    )

    # Keep pairs within 75km (typical adjacent county center-to-center distance)
    close_pairs <- pairs %>%
      filter(dist_km <= 75) %>%
      mutate(
        segment_id = seg$segment_id,
        pair_id = paste0(seg$segment_id, "_", row_number())
      ) %>%
      select(segment_id, pair_id, fd_fips, nfd_fips, dist_km)

    border_pairs[[i]] <- close_pairs
    cat(sprintf("  %s: %d county pairs within 75km\n", seg$segment_id, nrow(close_pairs)))
  }

  all_pairs <- bind_rows(border_pairs)
  cat(sprintf("Total border pairs: %d\n", nrow(all_pairs)))

} else {
  # Parse adjacency CSV
  adj <- read_csv("../data/county_adjacency_nber.csv", show_col_types = FALSE)

  # Filter to cross-state pairs between FD and non-FD states
  all_pairs <- adj %>%
    filter(substr(fipscounty, 1, 2) != substr(fipsneighbor, 1, 2)) %>%
    mutate(
      state1 = substr(fipscounty, 1, 2),
      state2 = substr(fipsneighbor, 1, 2)
    ) %>%
    # One county must be FD-required, other must not
    filter(
      (state1 %in% fd_required_states & !(state2 %in% fd_required_states)) |
      (state2 %in% fd_required_states & !(state1 %in% fd_required_states))
    ) %>%
    mutate(
      fd_fips = ifelse(state1 %in% fd_required_states, fipscounty, fipsneighbor),
      nfd_fips = ifelse(state1 %in% fd_required_states, fipsneighbor, fipscounty),
      fd_state = substr(fd_fips, 1, 2),
      nfd_state = substr(nfd_fips, 1, 2),
      segment_id = paste0(fd_state, "_", nfd_state),
      pair_id = paste0(fd_fips, "_", nfd_fips)
    ) %>%
    select(segment_id, pair_id, fd_fips, nfd_fips)
}

write_csv(all_pairs, "../data/border_pairs.csv")
cat(sprintf("Saved %d border pairs\n", nrow(all_pairs)))

# ─── 6. Build analysis dataset ───
# Stack FD and non-FD counties from border pairs

fd_counties <- all_pairs %>%
  select(segment_id, pair_id, fips = fd_fips) %>%
  mutate(fd_required = 1) %>%
  distinct()

nfd_counties <- all_pairs %>%
  select(segment_id, pair_id, fips = nfd_fips) %>%
  mutate(fd_required = 0) %>%
  distinct()

border_counties <- bind_rows(fd_counties, nfd_counties)

# Merge with CBP averages
analysis <- border_counties %>%
  left_join(cbp_avg, by = "fips") %>%
  left_join(cbp_crem_avg %>% select(fips, crem_estab, crem_emp), by = "fips") %>%
  left_join(acs, by = "fips")

# Replace NA establishments/employment with 0 (counties with no funeral homes)
analysis <- analysis %>%
  mutate(
    across(c(estab, emp, payann, crem_estab, crem_emp), ~replace_na(., 0)),
    # Per capita rates (per 10,000 population)
    estab_pc = estab / total_pop * 10000,
    emp_pc = emp / total_pop * 10000,
    payann_pc = payann / total_pop * 10000,
    crem_estab_pc = crem_estab / total_pop * 10000,
    # Firm size
    emp_per_estab = ifelse(estab > 0, emp / estab, NA),
    payroll_per_emp = ifelse(emp > 0, payann * 1000 / emp, NA),
    # Log outcomes
    log_pop = log(total_pop),
    log_income = log(median_income)
  )

# Drop counties with missing population
analysis <- analysis %>% filter(!is.na(total_pop) & total_pop > 0)

cat(sprintf("Analysis dataset: %d county-pair observations\n", nrow(analysis)))
cat(sprintf("  FD-required counties: %d\n", sum(analysis$fd_required == 1)))
cat(sprintf("  Non-FD counties: %d\n", sum(analysis$fd_required == 0)))
cat(sprintf("  Unique segments: %d\n", n_distinct(analysis$segment_id)))
cat(sprintf("  Unique pairs: %d\n", n_distinct(analysis$pair_id)))

write_csv(analysis, "../data/analysis_data.csv")
cat("Saved analysis_data.csv\n")

# ─── 7. Summary statistics ───
cat("\n=== Summary Statistics ===\n")
analysis %>%
  group_by(fd_required) %>%
  summarize(
    n = n(),
    mean_estab = mean(estab, na.rm = TRUE),
    mean_emp = mean(emp, na.rm = TRUE),
    mean_estab_pc = mean(estab_pc, na.rm = TRUE),
    mean_emp_per_estab = mean(emp_per_estab, na.rm = TRUE),
    mean_payroll_per_emp = mean(payroll_per_emp, na.rm = TRUE),
    mean_pop = mean(total_pop, na.rm = TRUE),
    mean_pct65 = mean(pct_65plus, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  print()
