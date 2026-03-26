## 02_clean_data.R — Clean and merge SNAP retailer + ACS data
## apep_1023: Redemption Deserts

source("00_packages.R")

census_key <- Sys.getenv("CENSUS_API_KEY")
if (nchar(census_key) > 0) census_api_key(census_key, install = FALSE)

# === Load raw data ===
acs_panel <- readRDS("../data/acs_snap_panel.rds")
ctrl_panel <- readRDS("../data/acs_controls_panel.rds")
snap_raw <- readRDS("../data/snap_retailers_raw.rds")

cat(sprintf("ACS panel: %d rows\n", nrow(acs_panel)))
cat(sprintf("Controls: %d rows\n", nrow(ctrl_panel)))
cat(sprintf("SNAP retailers: %d rows\n", nrow(snap_raw)))

# === Parse dates ===
# Known columns: "Authorization Date", "End Date", "Latitude", "Longitude",
#                "Store Name", "Store Type", "State"
snap_raw[, auth_date := as.Date(`Authorization Date`, format = "%m/%d/%Y")]
snap_raw[, end_dt := as.Date(`End Date`, format = "%m/%d/%Y")]
snap_raw[`End Date` == "" | is.na(`End Date`), end_dt := NA]

snap_raw[, auth_year := year(auth_date)]
snap_raw[, end_year := year(end_dt)]

cat(sprintf("Auth years range: %d - %d\n",
            min(snap_raw$auth_year, na.rm = TRUE),
            max(snap_raw$auth_year, na.rm = TRUE)))
cat(sprintf("End years (non-NA) range: %d - %d\n",
            min(snap_raw$end_year, na.rm = TRUE),
            max(snap_raw$end_year, na.rm = TRUE)))
cat(sprintf("Still active (no end date): %d\n", sum(is.na(snap_raw$end_dt))))

# === Filter to continental US with valid coordinates ===
snap_geo <- snap_raw[
  !is.na(Longitude) & !is.na(Latitude) &
  Longitude > -130 & Longitude < -60 &
  Latitude > 24 & Latitude < 50
]
cat(sprintf("Continental US retailers with coords: %d / %d\n",
            nrow(snap_geo), nrow(snap_raw)))

# === Spatial join: retailer → tract (state by state for performance) ===
cat("\n=== Spatial join (state by state) ===\n")

# Get unique states
snap_states <- unique(snap_geo$State)
snap_states <- snap_states[!snap_states %in% c("AK", "HI", "PR", "VI", "GU", "AS", "MP")]

# State FIPS lookup
state_fips_map <- c(
  AL="01",AZ="04",AR="05",CA="06",CO="08",CT="09",DE="10",DC="11",FL="12",
  GA="13",ID="16",IL="17",IN="18",IA="19",KS="20",KY="21",LA="22",ME="23",
  MD="24",MA="25",MI="26",MN="27",MS="28",MO="29",MT="30",NE="31",NV="32",
  NH="33",NJ="34",NM="35",NY="36",NC="37",ND="38",OH="39",OK="40",OR="41",
  PA="42",RI="44",SC="45",SD="46",TN="47",TX="48",UT="49",VT="50",VA="51",
  WA="53",WV="54",WI="55",WY="56"
)

all_matched <- list()
for (st_abbr in snap_states) {
  st_fips <- state_fips_map[st_abbr]
  if (is.na(st_fips)) next

  st_retailers <- snap_geo[State == st_abbr]
  if (nrow(st_retailers) == 0) next

  tryCatch({
    # Get tract boundaries for this state
    tracts <- get_acs(
      geography = "tract",
      variables = "B01003_001",
      year = 2020,
      state = st_fips,
      geometry = TRUE,
      survey = "acs5"
    ) %>%
      select(GEOID, geometry)

    # Convert retailers to sf
    pts <- st_as_sf(st_retailers,
                    coords = c("Longitude", "Latitude"),
                    crs = 4326)

    tracts <- st_transform(tracts, 4326)

    # Spatial join
    joined <- st_join(pts, tracts, join = st_within) %>%
      st_drop_geometry()

    matched_n <- sum(!is.na(joined$GEOID))
    cat(sprintf("  %s: %d/%d matched (%.0f%%)\n",
                st_abbr, matched_n, nrow(st_retailers),
                100 * matched_n / nrow(st_retailers)))

    all_matched[[st_abbr]] <- as.data.table(joined[!is.na(joined$GEOID), ])

  }, error = function(e) {
    cat(sprintf("  %s: FAILED - %s\n", st_abbr, e$message))
  })
}

snap_tract <- rbindlist(all_matched, fill = TRUE)
cat(sprintf("\nTotal matched to tracts: %d / %d\n", nrow(snap_tract), nrow(snap_geo)))

# === Identify store chains for IV1 ===
snap_tract[, store_upper := toupper(`Store Name`)]

snap_tract[, chain := fcase(
  grepl("FAMILY DOLLAR", store_upper), "FAMILY_DOLLAR",
  grepl("DOLLAR TREE", store_upper), "DOLLAR_TREE",
  grepl("WAL.?MART|WALMART", store_upper), "WALMART",
  grepl("A.?&.?P|A AND P|GREAT ATLANTIC", store_upper), "AP",
  grepl("DOLLAR GENERAL", store_upper), "DOLLAR_GENERAL",
  default = "OTHER"
)]

cat("\nChain distribution:\n")
print(snap_tract[, .N, by = chain][order(-N)])

# === Identify small-format stores for IV2 ===
cat("\nStore type distribution:\n")
print(snap_tract[, .N, by = `Store Type`][order(-N)])

snap_tract[, small_format := as.integer(
  grepl("Convenience|Small|Specialty", `Store Type`, ignore.case = TRUE) |
  chain %in% c("FAMILY_DOLLAR", "DOLLAR_TREE", "DOLLAR_GENERAL")
)]

cat(sprintf("Small-format retailers: %d / %d (%.0f%%)\n",
            sum(snap_tract$small_format), nrow(snap_tract),
            100 * mean(snap_tract$small_format)))

# === Construct tract-year retailer panel ===
cat("\n=== Building tract-year retailer panel ===\n")

panel_years <- 2013:2022

tract_year_list <- list()
for (yr in panel_years) {
  active <- snap_tract[auth_year <= yr & (is.na(end_year) | end_year >= yr)]
  new_auths <- snap_tract[auth_year == yr]
  exits <- snap_tract[end_year == yr]

  active_ct <- active[, .(
    n_retailers = .N,
    n_small_format = sum(small_format, na.rm = TRUE),
    n_family_dollar = sum(chain == "FAMILY_DOLLAR"),
    n_walmart = sum(chain == "WALMART"),
    n_ap = sum(chain == "AP"),
    n_dollar_general = sum(chain == "DOLLAR_GENERAL")
  ), by = GEOID]

  new_ct <- new_auths[, .(n_new = .N), by = GEOID]
  exit_ct <- exits[, .(n_exits = .N), by = GEOID]

  ty <- active_ct %>%
    left_join(new_ct, by = "GEOID") %>%
    left_join(exit_ct, by = "GEOID") %>%
    mutate(
      year = yr,
      n_new = replace_na(n_new, 0L),
      n_exits = replace_na(n_exits, 0L),
      net_exits = n_exits - n_new
    )

  tract_year_list[[as.character(yr)]] <- ty
  cat(sprintf("  %d: %d tracts, mean retailers = %.1f, mean net_exits = %.3f\n",
              yr, nrow(ty), mean(ty$n_retailers), mean(ty$net_exits)))
}

retailer_panel <- bind_rows(tract_year_list)
cat(sprintf("Retailer panel: %d rows\n", nrow(retailer_panel)))

# === Construct IV variables ===
cat("\n=== Constructing instrumental variables ===\n")

pre_counts <- snap_tract[auth_year <= 2014 & (is.na(end_year) | end_year >= 2014)] %>%
  .[, .(
    pre_family_dollar = sum(chain == "FAMILY_DOLLAR"),
    pre_walmart = sum(chain == "WALMART"),
    pre_ap = sum(chain == "AP")
  ), by = GEOID]

retailer_panel <- retailer_panel %>%
  left_join(pre_counts, by = "GEOID") %>%
  mutate(
    pre_family_dollar = replace_na(pre_family_dollar, 0L),
    pre_walmart = replace_na(pre_walmart, 0L),
    pre_ap = replace_na(pre_ap, 0L),
    iv_fd = pre_family_dollar * as.integer(year >= 2019),
    iv_wm = pre_walmart * as.integer(year >= 2016),
    iv_ap = pre_ap * as.integer(year >= 2015)
  )

pre_small <- snap_tract[auth_year <= 2017 & (is.na(end_year) | end_year >= 2017)] %>%
  .[, .(
    pre_total = .N,
    pre_small = sum(small_format, na.rm = TRUE)
  ), by = GEOID] %>%
  .[, pre_small_share := ifelse(pre_total > 0, pre_small / pre_total, 0)]

retailer_panel <- retailer_panel %>%
  left_join(pre_small %>% select(GEOID, pre_small_share), by = "GEOID") %>%
  mutate(
    pre_small_share = replace_na(pre_small_share, 0),
    iv_stock_rule = pre_small_share * as.integer(year >= 2018)
  )

# === Merge with ACS panel ===
cat("\n=== Merging retailer panel with ACS data ===\n")

ctrl_panel <- ctrl_panel %>%
  mutate(
    poverty_rate = ifelse(pov_total > 0, pov_below / pov_total, NA_real_),
    no_vehicle_rate = ifelse(veh_total > 0, veh_none / veh_total, NA_real_),
    pct_black = ifelse(pop_race_tot > 0, pop_black / pop_race_tot, NA_real_),
    pct_hispanic = ifelse(pop_hisp_tot > 0, pop_hisp / pop_hisp_tot, NA_real_),
    log_pop = log(pop_total + 1),
    log_med_inc = log(pmax(med_hh_inc, 1))
  )

analysis_df <- acs_panel %>%
  left_join(ctrl_panel %>%
              select(GEOID, year, poverty_rate, no_vehicle_rate,
                     pct_black, pct_hispanic, log_pop, log_med_inc, pop_total),
            by = c("GEOID", "year")) %>%
  left_join(retailer_panel, by = c("GEOID", "year"))

# Fill missing retailer counts with 0
retailer_cols <- c("n_retailers", "n_small_format", "n_new", "n_exits", "net_exits",
                   "iv_fd", "iv_wm", "iv_ap", "iv_stock_rule",
                   "pre_family_dollar", "pre_walmart", "pre_ap", "pre_small_share")
for (col in retailer_cols) {
  if (col %in% names(analysis_df)) {
    analysis_df[[col]][is.na(analysis_df[[col]])] <- 0
  }
}

analysis_df <- analysis_df %>%
  mutate(
    state_fips = substr(GEOID, 1, 2),
    county_fips = substr(GEOID, 1, 5)
  ) %>%
  filter(
    !is.na(snap_rate),
    !is.na(poverty_rate),
    !is.na(log_pop)
  )

cat(sprintf("\nFinal analysis dataset: %d rows\n", nrow(analysis_df)))
cat(sprintf("Tracts: %d\n", n_distinct(analysis_df$GEOID)))
cat(sprintf("Years: %d-%d\n", min(analysis_df$year), max(analysis_df$year)))
cat(sprintf("Counties: %d\n", n_distinct(analysis_df$county_fips)))
cat(sprintf("Mean SNAP rate: %.3f\n", mean(analysis_df$snap_rate)))
cat(sprintf("Mean retailers per tract: %.2f\n", mean(analysis_df$n_retailers)))
cat(sprintf("Mean net exits: %.3f\n", mean(analysis_df$net_exits)))
cat(sprintf("Tracts with exits: %d\n", n_distinct(analysis_df$GEOID[analysis_df$n_exits > 0])))

saveRDS(analysis_df, "../data/analysis_panel.rds")
cat("\n=== Data cleaning complete ===\n")
