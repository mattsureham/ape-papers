# =============================================================================
# 01_fetch_data.R — Fetch QWI data from Azure and county adjacency from Census
# apep_0643: PFL Border County Pairs
# =============================================================================

source("00_packages.R")
source("../../../../scripts/lib/azure_data.R")

# ---- PFL Wave Definitions ----
# Each wave: treated state FIPS, treatment quarter, valid control state FIPS
pfl_waves <- list(
  NJ = list(
    treated_state = 34,
    treat_yq = "2009.3",  # July 2009
    control_states = c(42, 10)  # PA, DE (exclude NY which got PFL in 2018)
  ),
  NY = list(
    treated_state = 36,
    treat_yq = "2018.1",  # January 2018
    control_states = c(42, 50)  # PA, VT (exclude NJ/CT/MA which have PFL)
  ),
  WA = list(
    treated_state = 53,
    treat_yq = "2020.1",  # January 2020
    control_states = c(16)  # ID only (exclude OR which got PFL in 2023)
  )
)

# ---- Download County Adjacency File ----
cat("Downloading Census county adjacency file...\n")
adj_url <- "https://www2.census.gov/geo/docs/reference/county_adjacency.txt"
adj_file <- "../data/county_adjacency.txt"

download.file(adj_url, adj_file, quiet = TRUE)

# Parse the adjacency file
# Format: "County Name"\tFIPS\t"Neighbor Name"\tNeighbor FIPS
# County lines have all 4 fields; continuation lines have only fields 3-4
raw_lines <- readLines(adj_file, warn = FALSE)

adj_pairs <- list()
current_fips <- NA_character_

for (line in raw_lines) {
  parts <- strsplit(line, "\t")[[1]]
  if (length(parts) >= 4 && nchar(trimws(parts[1])) > 0) {
    current_fips <- trimws(parts[2])
    neighbor_fips <- trimws(parts[4])
  } else if (length(parts) >= 2) {
    neighbor_fips <- trimws(parts[length(parts)])
  } else {
    next
  }
  if (!is.na(current_fips) && nchar(neighbor_fips) > 0 &&
      current_fips != neighbor_fips) {
    adj_pairs[[length(adj_pairs) + 1]] <- data.frame(
      fips1 = current_fips,
      fips2 = neighbor_fips,
      stringsAsFactors = FALSE
    )
  }
}

adj_df <- bind_rows(adj_pairs) %>%
  mutate(
    fips1 = str_pad(fips1, 5, pad = "0"),
    fips2 = str_pad(fips2, 5, pad = "0"),
    state1 = as.integer(substr(fips1, 1, 2)),
    state2 = as.integer(substr(fips2, 1, 2))
  ) %>%
  filter(state1 != state2) %>%  # Only cross-state pairs
  distinct()

cat(sprintf("Found %d cross-state county adjacency pairs.\n", nrow(adj_df)))

# ---- Identify Border County Pairs for Each Wave ----
border_pairs <- list()

for (wave_name in names(pfl_waves)) {
  wave <- pfl_waves[[wave_name]]
  ts <- wave$treated_state
  cs <- wave$control_states

  # Pairs where one side is treated state and other is control state
  pairs_this_wave <- adj_df %>%
    filter(
      (state1 == ts & state2 %in% cs) |
      (state2 == ts & state1 %in% cs)
    ) %>%
    mutate(
      treated_fips = ifelse(state1 == ts, fips1, fips2),
      control_fips = ifelse(state1 == ts, fips2, fips1),
      wave = wave_name
    ) %>%
    select(treated_fips, control_fips, wave) %>%
    distinct()

  border_pairs[[wave_name]] <- pairs_this_wave
  cat(sprintf("Wave %s: %d treated counties, %d control counties, %d pairs\n",
              wave_name,
              n_distinct(pairs_this_wave$treated_fips),
              n_distinct(pairs_this_wave$control_fips),
              nrow(pairs_this_wave)))
}

all_border_pairs <- bind_rows(border_pairs)
cat(sprintf("\nTotal border pairs across all waves: %d\n", nrow(all_border_pairs)))

# ---- Get All Unique Counties Needed ----
all_counties <- unique(c(all_border_pairs$treated_fips, all_border_pairs$control_fips))
all_states <- unique(as.integer(substr(all_counties, 1, 2)))
cat(sprintf("Need QWI data for %d unique counties in %d states.\n",
            length(all_counties), length(all_states)))

# ---- Query QWI from Azure ----
con <- apep_azure_connect()

# Build state FIPS filter for the query
# QWI geography field is integer county FIPS
state_fips_list <- paste(all_states, collapse = ", ")

cat("Querying QWI sex×age data from Azure...\n")

# Query female (sex=2) all-age (agegrp=A00) data at NAICS sector level
# Also get male data for placebo
qwi_sa <- dbGetQuery(con, sprintf("
  SELECT
    geography, year, quarter, sex, agegrp, industry,
    Emp, EmpEnd, HirA, HirN, Sep, FrmJbGn, FrmJbLs, TurnOvrS, EarnS,
    sEmp, sHirA, sSep, sEarnS
  FROM 'az://derived/qwi/sa/ns/*.parquet'
  WHERE CAST(geography / 1000 AS INTEGER) IN (%s)
    AND agegrp = 'A00'
    AND sex IN (1, 2)
    AND industry = '00'
    AND year >= 2005
", state_fips_list))

cat(sprintf("QWI all-industry data: %d rows\n", nrow(qwi_sa)))

# Also query by key industries for heterogeneity
cat("Querying QWI industry-specific data...\n")
qwi_ind <- dbGetQuery(con, sprintf("
  SELECT
    geography, year, quarter, sex, agegrp, industry,
    Emp, EmpEnd, HirA, HirN, Sep, FrmJbGn, FrmJbLs, TurnOvrS, EarnS,
    sEmp, sHirA, sSep, sEarnS
  FROM 'az://derived/qwi/sa/ns/*.parquet'
  WHERE CAST(geography / 1000 AS INTEGER) IN (%s)
    AND agegrp = 'A00'
    AND sex = 2
    AND industry IN ('62', '44-45', '72')
    AND year >= 2005
", state_fips_list))

cat(sprintf("QWI industry data: %d rows\n", nrow(qwi_ind)))

# Query sex×education for education heterogeneity (female only)
cat("Querying QWI sex×education data...\n")
qwi_se <- dbGetQuery(con, sprintf("
  SELECT
    geography, year, quarter, sex, education, industry,
    Emp, EmpEnd, HirA, HirN, Sep, FrmJbGn, FrmJbLs, TurnOvrS, EarnS,
    sEmp, sHirA, sSep, sEarnS
  FROM 'az://derived/qwi/se/ns/*.parquet'
  WHERE CAST(geography / 1000 AS INTEGER) IN (%s)
    AND sex = 2
    AND industry = '00'
    AND year >= 2005
", state_fips_list))

cat(sprintf("QWI education data: %d rows\n", nrow(qwi_se)))

apep_azure_disconnect(con)

# ---- Filter to Border Counties Only ----
border_fips_int <- as.integer(all_counties)

qwi_sa <- qwi_sa %>% filter(geography %in% border_fips_int)
qwi_ind <- qwi_ind %>% filter(geography %in% border_fips_int)
qwi_se <- qwi_se %>% filter(geography %in% border_fips_int)

cat(sprintf("\nAfter filtering to border counties:\n"))
cat(sprintf("  All-industry: %d rows, %d counties\n", nrow(qwi_sa), n_distinct(qwi_sa$geography)))
cat(sprintf("  Industry-specific: %d rows, %d counties\n", nrow(qwi_ind), n_distinct(qwi_ind$geography)))
cat(sprintf("  Education: %d rows, %d counties\n", nrow(qwi_se), n_distinct(qwi_se$geography)))

# ---- Validate: Ensure No Empty Data ----
stopifnot("No QWI data fetched for border counties" = nrow(qwi_sa) > 0)
stopifnot("Fewer than 20 border counties found" = n_distinct(qwi_sa$geography) >= 20)

# ---- Save ----
saveRDS(qwi_sa, "../data/qwi_sa_border.rds")
saveRDS(qwi_ind, "../data/qwi_ind_border.rds")
saveRDS(qwi_se, "../data/qwi_se_border.rds")
saveRDS(all_border_pairs, "../data/border_pairs.rds")
saveRDS(pfl_waves, "../data/pfl_waves.rds")

cat("\nData saved. Ready for analysis.\n")
