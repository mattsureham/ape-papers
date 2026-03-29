# =============================================================================
# 01b_fix_fips.R — Fix FIPS matching for ARCOS county data
# The original fetch had a merge key bug. This script re-does FIPS matching.
# =============================================================================
source("00_packages.R")

arcos <- fread("../data/arcos_county_hcp_share.csv")
cat(sprintf("ARCOS data: %d county-state pairs\n", nrow(arcos)))

# Load tigris FIPS codes
if (!requireNamespace("tigris", quietly = TRUE)) install.packages("tigris")
fips_df <- as.data.table(tigris::fips_codes)

# tigris::fips_codes columns: state, state_code, state_name, county_code, county
# state = 2-letter abbreviation (e.g., "WV")
# county = full name with suffix (e.g., "Mingo County")
cat("tigris columns:", paste(names(fips_df), collapse=", "), "\n")
cat("Sample:", fips_df$state[1], fips_df$county[1], "\n")

# Clean county names for matching
fips_df[, county_clean := toupper(gsub(
  " County$| Parish$| Borough$| Census Area$| Municipality$| city$| City and Borough$| City$| Municipio$",
  "", county))]
fips_df[, fips := paste0(state_code, county_code)]

# ARCOS: state = 2-letter abbreviation, county_name = uppercase county name
# Handle ARCOS county name peculiarities
arcos[, county_match := toupper(gsub("[.]", "", county_name))]

# Direct merge on state abbreviation + cleaned county name
merged <- merge(
  arcos,
  fips_df[, .(state_abb = state, county_clean, fips)],
  by.x = c("state", "county_match"),
  by.y = c("state_abb", "county_clean"),
  all.x = TRUE
)

match_rate <- mean(!is.na(merged$fips))
cat(sprintf("FIPS match rate: %.1f%% (%d of %d)\n",
            match_rate * 100, sum(!is.na(merged$fips)), nrow(merged)))

# Check unmatched
unmatched <- merged[is.na(fips), .(state, county_name, county_match)]
if (nrow(unmatched) > 0) {
  cat(sprintf("\nUnmatched counties: %d\n", nrow(unmatched)))
  # Try fuzzy matching for common discrepancies
  # ST. vs SAINT, MC vs MC, DE vs DE
  for (i in 1:nrow(unmatched)) {
    st <- unmatched$state[i]
    cn <- unmatched$county_match[i]
    # Try variants
    variants <- c(
      cn,
      gsub("^ST ", "SAINT ", cn),
      gsub("^ST\\.", "SAINT", cn),
      gsub("DEKALB", "DE KALB", cn),
      gsub("DE KALB", "DEKALB", cn),
      gsub("LAPORTE", "LA PORTE", cn),
      gsub("LA PORTE", "LAPORTE", cn),
      gsub("OBRIEN", "O'BRIEN", cn),
      gsub("O'BRIEN", "OBRIEN", cn)
    )
    match_found <- FALSE
    for (v in variants) {
      match_row <- fips_df[state == st & county_clean == v]
      if (nrow(match_row) > 0) {
        merged[state == st & county_match == cn, fips := match_row$fips[1]]
        match_found <- TRUE
        break
      }
    }
  }
  match_rate2 <- mean(!is.na(merged$fips))
  cat(sprintf("After fuzzy matching: %.1f%% (%d of %d)\n",
              match_rate2 * 100, sum(!is.na(merged$fips)), nrow(merged)))

  # Show remaining unmatched
  still_unmatched <- merged[is.na(fips), .N, by = state][order(-N)]
  if (nrow(still_unmatched) > 0) {
    cat("\nRemaining unmatched by state:\n")
    print(head(still_unmatched, 10))
  }
}

# Filter to counties with meaningful opioid volume
arcos_final <- merged[!is.na(fips) & total_pills > 100000]
cat(sprintf("\nFinal ARCOS dataset: %d counties with FIPS and >100K pills\n", nrow(arcos_final)))
cat(sprintf("HCP share: mean=%.3f, sd=%.3f, min=%.3f, max=%.3f\n",
            mean(arcos_final$hcp_share), sd(arcos_final$hcp_share),
            min(arcos_final$hcp_share), max(arcos_final$hcp_share)))

# Overwrite with fixed data
fwrite(arcos_final, "../data/arcos_county_hcp_share.csv")
cat("Saved fixed arcos_county_hcp_share.csv\n")
