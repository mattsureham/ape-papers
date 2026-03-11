# ============================================================================
# 02_clean_data.R — Classify border/interior regions, build analysis panel
# APEP-0593: Roaming Abolition and Cross-Border Tourism
# ============================================================================

source("00_packages.R")

data_dir <- "../data"

# -----------------------------------------------------------------------
# 1. Load data
# -----------------------------------------------------------------------
tourism <- fread(file.path(data_dir, "tourism_nuts2.csv"))
gdp <- fread(file.path(data_dir, "gdp_nuts2.csv"))
pop <- fread(file.path(data_dir, "pop_nuts2.csv"))
nuts2_sf <- sf::st_read(file.path(data_dir, "nuts2_2016.gpkg"), quiet = TRUE)

cat("Loaded:", nrow(tourism), "tourism rows,", nrow(nuts2_sf), "NUTS2 shapes\n")

# -----------------------------------------------------------------------
# 2. Classify border vs interior regions
#    A NUTS2 region is "border" if its geometry touches a NUTS2 region
#    in a different EU country (internal EU land border).
# -----------------------------------------------------------------------

# EU27 + EEA country codes
eu_eea <- c("AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR",
            "DE", "EL", "HU", "IE", "IT", "LV", "LT", "LU", "MT", "NL",
            "PL", "PT", "RO", "SK", "SI", "ES", "SE",
            "IS", "LI", "NO")  # EEA non-EU

# Extract country code from NUTS2 id
nuts2_sf$country <- substr(nuts2_sf$id, 1, 2)

# Filter to EU/EEA
nuts2_eu <- nuts2_sf[nuts2_sf$country %in% eu_eea, ]
cat("EU/EEA NUTS2 regions:", nrow(nuts2_eu), "\n")

# Find which pairs of NUTS2 regions share borders (touch)
cat("Computing NUTS2 adjacency (this may take a moment)...\n")
touches_mat <- sf::st_touches(nuts2_eu, sparse = TRUE)

# For each region, check if any touching region is in a DIFFERENT country
border_regions <- character(0)
border_pairs <- list()

for (i in seq_len(nrow(nuts2_eu))) {
  neighbors <- touches_mat[[i]]
  if (length(neighbors) > 0) {
    neighbor_countries <- nuts2_eu$country[neighbors]
    own_country <- nuts2_eu$country[i]
    # Check for neighbors in different EU/EEA countries
    foreign_neighbors <- neighbors[neighbor_countries != own_country &
                                     neighbor_countries %in% eu_eea]
    if (length(foreign_neighbors) > 0) {
      border_regions <- c(border_regions, nuts2_eu$id[i])
      for (fn in foreign_neighbors) {
        pair <- sort(c(nuts2_eu$id[i], nuts2_eu$id[fn]))
        border_pairs[[paste(pair, collapse = "-")]] <- pair
      }
    }
  }
}

border_regions <- unique(border_regions)
cat("Internal EU border NUTS2 regions:", length(border_regions), "\n")

# Also classify external border regions (EU-non-EU land borders)
# These are EU regions touching CH, UK, non-EU Balkans, etc.
non_eu <- setdiff(unique(nuts2_sf$country), eu_eea)
# Also consider CH, UK, etc. from the shapefile
external_border_regions <- character(0)
nuts2_all <- nuts2_sf  # includes non-EU if in shapefile
touches_all <- sf::st_touches(nuts2_all, sparse = TRUE)

for (i in seq_len(nrow(nuts2_all))) {
  if (nuts2_all$country[i] %in% eu_eea) {
    neighbors <- touches_all[[i]]
    if (length(neighbors) > 0) {
      neighbor_countries <- nuts2_all$country[neighbors]
      non_eu_neighbors <- neighbors[!(neighbor_countries %in% eu_eea)]
      if (length(non_eu_neighbors) > 0) {
        external_border_regions <- c(external_border_regions, nuts2_all$id[i])
      }
    }
  }
}

external_border_regions <- unique(external_border_regions)
# Remove any that are also internal border (classify as internal)
external_only <- setdiff(external_border_regions, border_regions)
cat("External EU border NUTS2 regions:", length(external_only), "\n")

# Interior = EU/EEA region that is neither internal nor external border
all_eu_ids <- nuts2_eu$id
interior_regions <- setdiff(all_eu_ids, c(border_regions, external_only))
cat("Interior NUTS2 regions:", length(interior_regions), "\n")

# Create classification table
border_class <- data.table(
  geo = c(border_regions, external_only, interior_regions),
  border_type = c(rep("internal_border", length(border_regions)),
                  rep("external_border", length(external_only)),
                  rep("interior", length(interior_regions)))
)
border_class[, country := substr(geo, 1, 2)]
fwrite(border_class, file.path(data_dir, "border_classification.csv"))

# Save border pairs for border-pair FE
bp_dt <- rbindlist(lapply(names(border_pairs), function(x) {
  data.table(pair = x, region1 = border_pairs[[x]][1],
             region2 = border_pairs[[x]][2])
}))
fwrite(bp_dt, file.path(data_dir, "border_pairs.csv"))

cat("\nBorder classification summary:\n")
print(border_class[, .N, by = border_type])

# -----------------------------------------------------------------------
# 3. Build analysis panel
# -----------------------------------------------------------------------

# Pivot tourism: foreign and domestic nights as separate columns
tourism_wide <- dcast(
  tourism[nace_r2 %in% c("I551-I553", "TOTAL")],
  geo + time ~ c_resid,
  value.var = "values",
  fun.aggregate = sum, na.rm = TRUE
)
setnames(tourism_wide, c("FOR", "DOM", "TOTAL"),
         c("foreign_nights", "domestic_nights", "total_nights"),
         skip_absent = TRUE)

# Merge border classification
panel <- merge(tourism_wide, border_class, by = "geo", all.x = TRUE)

# Drop non-EU/EEA regions (no classification)
panel <- panel[!is.na(border_type)]

# Add GDP (merge on geo + time)
gdp_clean <- gdp[, .(geo, time, gdp_mio = values)]
panel <- merge(panel, gdp_clean, by = c("geo", "time"), all.x = TRUE)

# Add population
pop_clean <- pop[, .(geo, time, population = values)]
panel <- merge(panel, pop_clean, by = c("geo", "time"), all.x = TRUE)

# -----------------------------------------------------------------------
# 4. Create treatment variables
# -----------------------------------------------------------------------

# Binary border treatment
panel[, border := as.integer(border_type == "internal_border")]

# Post-treatment indicator (RLAH effective June 2017; using annual data, 2017 is first treated year)
panel[, post := as.integer(time >= 2017)]

# DiD interaction
panel[, border_post := border * post]

# Event-time variable
panel[, event_time := time - 2017]

# Log outcomes (adding 1 to handle zeros)
panel[, log_foreign := log(foreign_nights + 1)]
panel[, log_domestic := log(domestic_nights + 1)]
panel[, log_total := log(total_nights + 1)]

# Per-capita outcomes
panel[, foreign_pc := foreign_nights / population * 1000]
panel[, domestic_pc := domestic_nights / population * 1000]

# -----------------------------------------------------------------------
# 5. Compute pre-treatment cross-border tourism share (continuous treatment)
# -----------------------------------------------------------------------

# Pre-treatment average share of foreign nights
pre <- panel[time >= 2012 & time <= 2016]
pre_share <- pre[, .(
  pre_foreign_share = mean(foreign_nights / (total_nights + 1), na.rm = TRUE),
  pre_foreign_avg = mean(foreign_nights, na.rm = TRUE),
  pre_total_avg = mean(total_nights, na.rm = TRUE)
), by = geo]

panel <- merge(panel, pre_share, by = "geo", all.x = TRUE)

# Continuous treatment: pre_foreign_share × post
panel[, share_post := pre_foreign_share * post]

# -----------------------------------------------------------------------
# 6. Drop islands and special territories
# -----------------------------------------------------------------------

# Drop island/overseas regions where border concept is meaningless
# Canary Islands (ES70), Azores (PT20), Madeira (PT30), French overseas (FRY*),
# Cyprus (CY00), Malta (MT00), Iceland (IS*)
island_pattern <- "^(ES70|PT20|PT30|FRY|CY00|MT00|IS)"
panel <- panel[!grepl(island_pattern, geo)]

# -----------------------------------------------------------------------
# 7. Final panel summary and save
# -----------------------------------------------------------------------
cat("\n=== ANALYSIS PANEL ===\n")
cat("Regions:", uniqueN(panel$geo), "\n")
cat("Years:", paste(range(panel$time), collapse = "-"), "\n")
cat("Observations:", nrow(panel), "\n")
cat("Border regions:", sum(panel[time == 2017]$border, na.rm = TRUE), "\n")
cat("Interior regions:", sum(panel[time == 2017]$border == 0, na.rm = TRUE), "\n")
cat("\nBorder type distribution:\n")
print(panel[time == 2017, .N, by = border_type])

# Summary statistics
cat("\nForeign nights summary (2012-2019):\n")
print(panel[time <= 2019, .(
  mean = mean(foreign_nights, na.rm = TRUE),
  median = median(foreign_nights, na.rm = TRUE),
  sd = sd(foreign_nights, na.rm = TRUE),
  min = min(foreign_nights, na.rm = TRUE),
  max = max(foreign_nights, na.rm = TRUE)
), by = border_type])

fwrite(panel, file.path(data_dir, "analysis_panel.csv"))
cat("\nAnalysis panel saved to", file.path(data_dir, "analysis_panel.csv"), "\n")
