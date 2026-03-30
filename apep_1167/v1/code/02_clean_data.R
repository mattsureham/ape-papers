## 02_clean_data.R — Build analysis dataset
## Link ARCOS county-level opioid supply to IPEDS SA counseling completions

library(dplyr)
library(tidyr)
library(readr)
library(stringr)

# ─────────────────────────────────────────────────────────
# 1. Load raw data
# ─────────────────────────────────────────────────────────
arcos <- read_csv("data/arcos_county_annual.csv", show_col_types = FALSE)
arcos_drugs <- read_csv("data/arcos_county_drugs.csv", show_col_types = FALSE)
ipeds_comp <- read_csv("data/ipeds_completions.csv", show_col_types = FALSE)
ipeds_dir <- read_csv("data/ipeds_directory.csv", show_col_types = FALSE)

cat(sprintf("Loaded: ARCOS=%d, ARCOS_drugs=%d, IPEDS_comp=%d, IPEDS_dir=%d\n",
            nrow(arcos), nrow(arcos_drugs), nrow(ipeds_comp), nrow(ipeds_dir)))

# ─────────────────────────────────────────────────────────
# 2. ARCOS: Aggregate to county-level total pills (2006-2012)
# ─────────────────────────────────────────────────────────
# County-year panel already exists; compute boom-period average (2006-2009)
arcos_boom <- arcos |>
  filter(year >= 2006, year <= 2009) |>
  group_by(buyer_state, buyer_county) |>
  summarise(
    pills_boom = sum(total_dosage_units, na.rm = TRUE),
    pills_boom_annual_avg = mean(total_dosage_units, na.rm = TRUE),
    n_years = n(),
    .groups = "drop"
  )
cat(sprintf("ARCOS boom counties: %d\n", nrow(arcos_boom)))

# Drug-specific shares
arcos_oxy_share <- arcos_drugs |>
  group_by(buyer_state, buyer_county) |>
  summarise(
    total_pills = sum(total_pills),
    oxy_pills = sum(total_pills[drug_name == "OXYCODONE"]),
    oxy_share = oxy_pills / total_pills,
    .groups = "drop"
  )

arcos_boom <- arcos_boom |>
  left_join(arcos_oxy_share, by = c("buyer_state", "buyer_county"))

# ─────────────────────────────────────────────────────────
# 3. IPEDS: Build institution → county crosswalk
# ─────────────────────────────────────────────────────────
# Use most recent directory year for each institution
inst_county <- ipeds_dir |>
  filter(!is.na(county_fips), county_fips > 0) |>
  group_by(unitid) |>
  slice_max(year, n = 1, with_ties = FALSE) |>
  ungroup() |>
  select(unitid, state, county_fips, county_name, latitude, longitude, control, level)

cat(sprintf("Institution-county crosswalk: %d institutions with county FIPS\n", nrow(inst_county)))

# ─────────────────────────────────────────────────────────
# 4. IPEDS: Aggregate SA completions to county × year
# ─────────────────────────────────────────────────────────
# Classify CIP codes
ipeds_comp <- ipeds_comp |>
  mutate(
    cipcode_str = sprintf("%.4f", cipcode),
    field_group = case_when(
      str_detect(cipcode_str, "^51\\.15") ~ "sa_counseling",
      str_detect(cipcode_str, "^14\\.") ~ "engineering",
      str_detect(cipcode_str, "^52\\.") ~ "business",
      TRUE ~ "other"
    )
  )

cat("\nCompletions by field group:\n")
ipeds_comp |>
  group_by(field_group) |>
  summarise(n_rows = n(), total_awards = sum(ctotalt, na.rm = TRUE), .groups = "drop") |>
  print()

# Join to county
ipeds_county <- ipeds_comp |>
  inner_join(inst_county |> select(unitid, county_fips, state), by = "unitid") |>
  filter(!is.na(county_fips), county_fips > 0)

# Aggregate to county × year × field
county_year_comp <- ipeds_county |>
  group_by(county_fips, state, year, field_group) |>
  summarise(
    completions = sum(ctotalt, na.rm = TRUE),
    n_institutions = n_distinct(unitid),
    .groups = "drop"
  )

cat(sprintf("\nCounty-year-field panel: %d rows\n", nrow(county_year_comp)))
cat(sprintf("Counties: %d, Years: %d-%d\n",
            n_distinct(county_year_comp$county_fips),
            min(county_year_comp$year), max(county_year_comp$year)))

# ─────────────────────────────────────────────────────────
# 5. Compute long differences for SA and placebo fields
# ─────────────────────────────────────────────────────────
compute_long_diff <- function(df, field, pre_years, post_years) {
  pre <- df |>
    filter(field_group == field, year %in% pre_years) |>
    group_by(county_fips, state) |>
    summarise(pre_comp = mean(completions, na.rm = TRUE),
              pre_inst = max(n_institutions, na.rm = TRUE), .groups = "drop")

  post <- df |>
    filter(field_group == field, year %in% post_years) |>
    group_by(county_fips, state) |>
    summarise(post_comp = mean(completions, na.rm = TRUE), .groups = "drop")

  inner_join(pre, post, by = c("county_fips", "state")) |>
    mutate(
      delta_comp = post_comp - pre_comp,
      pct_change = ifelse(pre_comp > 0, delta_comp / pre_comp, NA_real_)
    )
}

sa_diff <- compute_long_diff(county_year_comp, "sa_counseling",
                             2006:2009, 2018:2021)
eng_diff <- compute_long_diff(county_year_comp, "engineering",
                              2006:2009, 2018:2021)
bus_diff <- compute_long_diff(county_year_comp, "business",
                              2006:2009, 2018:2021)

cat(sprintf("\nLong differences: SA=%d counties, Eng=%d, Bus=%d\n",
            nrow(sa_diff), nrow(eng_diff), nrow(bus_diff)))

# ─────────────────────────────────────────────────────────
# 6. Get county population from Census for per-capita
# ─────────────────────────────────────────────────────────
# Use state FIPS from ARCOS + IPEDS — map states to FIPS
state_fips <- data.frame(
  abbr = c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL",
           "GA","HI","ID","IL","IN","IA","KS","KY","LA","ME",
           "MD","MA","MI","MN","MS","MO","MT","NE","NV","NH",
           "NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI",
           "SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY"),
  fips_st = c(1,2,4,5,6,8,9,10,11,12,13,15,16,17,18,19,20,21,22,23,
              24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,44,
              45,46,47,48,49,50,51,53,54,55,56),
  stringsAsFactors = FALSE
)

# Triplicate-prescription states (Alpert et al. 2022 QJE IV)
triplicate_states <- c("CA", "ID", "IL", "IN", "NY", "TX")

# ─────────────────────────────────────────────────────────
# 7. Build ARCOS county crosswalk using FIPS
# ─────────────────────────────────────────────────────────
# ARCOS uses county names (uppercase), IPEDS uses FIPS
# IPEDS county_fips is a 5-digit FIPS code
# We need to match ARCOS state+county_name to FIPS

# Get unique ARCOS counties
arcos_counties <- arcos_boom |>
  select(buyer_state, buyer_county) |>
  distinct()

# Get unique IPEDS counties
ipeds_counties <- county_year_comp |>
  select(county_fips, state) |>
  distinct() |>
  left_join(
    inst_county |> select(county_fips, county_name) |> distinct(),
    by = "county_fips"
  )

# To match ARCOS to FIPS, we use the institution directory's county info
# ARCOS buyer_state is state abbreviation, buyer_county is county name (UPPERCASE)
# IPEDS has county_fips

# Build matching on state + normalized county name
arcos_match <- arcos_boom |>
  mutate(
    state_abbr = buyer_state,
    county_clean = toupper(str_replace_all(buyer_county, "[^A-Z ]", ""))
  )

ipeds_county_lookup <- inst_county |>
  filter(!is.na(county_fips), county_fips > 0) |>
  select(state, county_fips, county_name) |>
  distinct() |>
  mutate(
    # Strip "County", "Parish", "Borough", etc. suffix and normalize
    county_clean = county_name |>
      str_remove_all("(?i)\\s*(county|parish|borough|census area|municipality|city and borough|city)\\s*$") |>
      str_remove_all("[^A-Za-z ]") |>
      toupper() |>
      str_squish()
  )

# Keep only one FIPS per state-county to avoid duplicates
ipeds_county_lookup <- ipeds_county_lookup |>
  group_by(state, county_clean) |>
  slice_min(county_fips, n = 1, with_ties = FALSE) |>
  ungroup()

arcos_fips <- arcos_match |>
  left_join(ipeds_county_lookup, by = c("state_abbr" = "state", "county_clean"))

matched <- sum(!is.na(arcos_fips$county_fips))
cat(sprintf("ARCOS-FIPS match: %d/%d counties (%.1f%%)\n",
            matched, nrow(arcos_fips), 100*matched/nrow(arcos_fips)))

# ─────────────────────────────────────────────────────────
# 8. Merge ARCOS + IPEDS long differences
# ─────────────────────────────────────────────────────────
analysis_df <- sa_diff |>
  inner_join(
    arcos_fips |>
      filter(!is.na(county_fips)) |>
      select(county_fips, buyer_state, pills_boom, pills_boom_annual_avg,
             oxy_share, total_pills),
    by = "county_fips"
  ) |>
  mutate(
    triplicate = buyer_state %in% triplicate_states,
    # Log transformations
    log_pills = log(pills_boom + 1),
    log_pre_comp = log(pre_comp + 1),
    log_delta = log(post_comp + 1) - log(pre_comp + 1)
  )

cat(sprintf("\nAnalysis dataset: %d county observations\n", nrow(analysis_df)))
cat(sprintf("  Triplicate states: %d (%.1f%%)\n",
            sum(analysis_df$triplicate),
            100 * mean(analysis_df$triplicate)))
cat(sprintf("  Mean pre-period SA completions: %.1f\n", mean(analysis_df$pre_comp)))
cat(sprintf("  Mean post-period SA completions: %.1f\n", mean(analysis_df$post_comp)))
cat(sprintf("  Mean change: %.1f (%.0f%%)\n",
            mean(analysis_df$delta_comp),
            100 * mean(analysis_df$pct_change, na.rm = TRUE)))

# Add placebo long differences
analysis_df <- analysis_df |>
  left_join(eng_diff |> select(county_fips, delta_eng = delta_comp), by = "county_fips") |>
  left_join(bus_diff |> select(county_fips, delta_bus = delta_comp), by = "county_fips")

# ─────────────────────────────────────────────────────────
# 9. Save analysis dataset
# ─────────────────────────────────────────────────────────
write_csv(analysis_df, "data/analysis_df.csv")
write_csv(county_year_comp, "data/county_year_completions.csv")

cat(sprintf("\nSaved: analysis_df.csv (%d rows), county_year_completions.csv (%d rows)\n",
            nrow(analysis_df), nrow(county_year_comp)))

# Summary statistics
cat("\n═══ Summary Statistics ═══\n")
cat(sprintf("Counties in analysis: %d\n", nrow(analysis_df)))
cat(sprintf("States: %d\n", n_distinct(analysis_df$buyer_state)))
cat(sprintf("Pills (boom, mean): %.0f\n", mean(analysis_df$pills_boom)))
cat(sprintf("SA completions pre (mean): %.1f\n", mean(analysis_df$pre_comp)))
cat(sprintf("SA completions post (mean): %.1f\n", mean(analysis_df$post_comp)))
cat(sprintf("Oxycodone share (mean): %.3f\n", mean(analysis_df$oxy_share, na.rm = TRUE)))
