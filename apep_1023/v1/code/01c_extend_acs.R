## 01c_extend_acs.R — Add 2013-2014 ACS data to existing panel
source("00_packages.R")

census_key <- Sys.getenv("CENSUS_API_KEY")
if (nchar(census_key) > 0) census_api_key(census_key, install = FALSE)

state_fips <- c(sprintf("%02d", c(1,2,4:6,8:13,15:42,44:51,53:56)))

acs_panel <- readRDS("../data/acs_snap_panel.rds")
ctrl_panel <- readRDS("../data/acs_controls_panel.rds")
cat(sprintf("Existing ACS: %d rows, years %d-%d\n",
            nrow(acs_panel), min(acs_panel$year), max(acs_panel$year)))

extra_years <- 2013:2014

# Fetch SNAP data for 2013-2014
snap_vars <- c(total_hh = "B22003_001", snap_hh = "B22003_002")
ctrl_vars <- c(
  pov_total = "B17001_001", pov_below = "B17001_002",
  veh_total = "B08141_001", veh_none = "B08141_002",
  pop_total = "B01003_001", med_hh_inc = "B19013_001",
  pct_black = "B02001_003", pop_race_tot = "B02001_001",
  pct_hisp = "B03003_003", pop_hisp_tot = "B03003_001"
)

acs_new <- list()
ctrl_new <- list()

for (yr in extra_years) {
  cat(sprintf("Fetching ACS %d...\n", yr))

  yr_snap <- list()
  yr_ctrl <- list()

  for (st in state_fips) {
    tryCatch({
      d <- get_acs(geography = "tract", variables = snap_vars,
                   year = yr, survey = "acs5", output = "wide", state = st)
      if (!is.null(d) && nrow(d) > 0) yr_snap[[st]] <- d
    }, error = function(e) {})

    tryCatch({
      d <- get_acs(geography = "tract", variables = ctrl_vars,
                   year = yr, survey = "acs5", output = "wide", state = st)
      if (!is.null(d) && nrow(d) > 0) yr_ctrl[[st]] <- d
    }, error = function(e) {})
  }

  snap_yr <- bind_rows(yr_snap) %>%
    mutate(year = yr) %>%
    select(GEOID, NAME, year,
           total_hh = total_hhE, snap_hh = snap_hhE,
           total_hh_moe = total_hhM, snap_hh_moe = snap_hhM) %>%
    mutate(snap_rate = ifelse(total_hh > 0, snap_hh / total_hh, NA_real_)) %>%
    filter(!is.na(snap_rate), total_hh >= 50)

  ctrl_yr <- bind_rows(yr_ctrl) %>%
    mutate(year = yr) %>%
    select(GEOID, year,
           pov_total = pov_totalE, pov_below = pov_belowE,
           veh_total = veh_totalE, veh_none = veh_noneE,
           pop_total = pop_totalE, med_hh_inc = med_hh_incE,
           pop_black = pct_blackE, pop_race_tot = pop_race_totE,
           pop_hisp = pct_hispE, pop_hisp_tot = pop_hisp_totE)

  acs_new[[as.character(yr)]] <- snap_yr
  ctrl_new[[as.character(yr)]] <- ctrl_yr
  cat(sprintf("  Got %d SNAP tracts, %d control tracts\n", nrow(snap_yr), nrow(ctrl_yr)))
}

# Append to existing panels
acs_panel <- bind_rows(acs_panel, bind_rows(acs_new))
ctrl_panel <- bind_rows(ctrl_panel, bind_rows(ctrl_new))

cat(sprintf("Extended ACS: %d rows, years %d-%d\n",
            nrow(acs_panel), min(acs_panel$year), max(acs_panel$year)))

saveRDS(acs_panel, "../data/acs_snap_panel.rds")
saveRDS(ctrl_panel, "../data/acs_controls_panel.rds")
cat("Saved extended panels.\n")
