# 01_fetch_data.R — Fetch SNAP participation (ACS), employment (FRED), BBCE timing
# apep_0758 v1
source("00_packages.R")

census_key <- Sys.getenv("CENSUS_API_KEY")
fred_key   <- Sys.getenv("FRED_API_KEY")
stopifnot("CENSUS_API_KEY not set" = nzchar(census_key))
stopifnot("FRED_API_KEY not set" = nzchar(fred_key))

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE)

# ===========================================================================
# 1. BBCE ADOPTION TIMING (manually constructed from published sources)
# ===========================================================================
message("Constructing BBCE adoption panel...")

bbce_states <- tribble(
  ~state_abbr, ~fips, ~first_treat_year,
  "DE", "10", 2000L, "ME", "23", 2000L, "TX", "48", 2001L,
  "MI", "26", 2002L, "MD", "24", 2003L, "WI", "55", 2003L,
  "SC", "45", 2003L, "AZ", "04", 2006L, "FL", "12", 2006L,
  "WA", "53", 2007L, "OR", "41", 2007L, "ID", "16", 2008L,
  "CT", "09", 2008L, "MT", "30", 2008L, "NV", "32", 2008L,
  "ND", "38", 2008L, "HI", "15", 2009L, "MA", "25", 2009L,
  "NH", "33", 2009L, "NM", "35", 2009L, "NY", "36", 2009L,
  "NC", "37", 2009L, "OH", "39", 2009L, "PA", "42", 2009L,
  "RI", "44", 2009L, "VT", "50", 2009L, "VA", "51", 2009L,
  "WV", "54", 2009L, "AL", "01", 2009L, "CA", "06", 2009L,
  "CO", "08", 2010L, "IL", "17", 2010L, "IA", "19", 2010L,
  "MN", "27", 2010L, "NJ", "34", 2010L, "OK", "40", 2010L,
  "NE", "31", 2010L, "GA", "13", 2011L, "IN", "18", 2018L
)

never_treated <- tribble(
  ~state_abbr, ~fips, ~first_treat_year,
  "AK", "02", NA_integer_, "AR", "05", NA_integer_,
  "KS", "20", NA_integer_, "KY", "21", NA_integer_,
  "LA", "22", NA_integer_, "MS", "28", NA_integer_,
  "MO", "29", NA_integer_, "SD", "46", NA_integer_,
  "TN", "47", NA_integer_, "UT", "49", NA_integer_,
  "WY", "56", NA_integer_, "DC", "11", NA_integer_
)

all_states <- bind_rows(bbce_states, never_treated) %>%
  mutate(first_treat = replace_na(first_treat_year, 0L))

message(sprintf("BBCE: %d treated, %d never-treated",
                sum(all_states$first_treat > 0), sum(all_states$first_treat == 0)))
saveRDS(all_states, file.path(data_dir, "bbce_timing.rds"))

# ===========================================================================
# 2. ACS SNAP PARTICIPATION (state-year, try from 2005+)
# ===========================================================================
message("\nFetching ACS SNAP data...")
census_api_key(census_key, install = FALSE, overwrite = TRUE)

acs_list <- list()
for (yr in 2005:2022) {
  if (yr == 2020) next
  cat(sprintf("  ACS %d... ", yr))
  res <- tryCatch({
    get_acs(geography = "state", survey = "acs1", year = yr, output = "wide",
            variables = c(snap_total = "B22003_001", snap_recv = "B22003_002"))
  }, error = function(e) { cat(sprintf("SKIP (%s)\n", substr(e$message, 1, 40))); NULL })
  if (!is.null(res) && nrow(res) > 0) {
    res$year <- yr
    acs_list[[as.character(yr)]] <- res
    cat(sprintf("OK (%d rows)\n", nrow(res)))
  }
  Sys.sleep(0.3)
}
acs_snap <- bind_rows(acs_list) %>%
  transmute(state_fips = GEOID, year = year,
            snap_total = as.numeric(snap_totalE),
            snap_recv  = as.numeric(snap_recvE),
            snap_rate  = snap_recv / pmax(snap_total, 1)) %>%
  filter(state_fips != "72")

message(sprintf("ACS SNAP: %d obs, %d-%d", nrow(acs_snap), min(acs_snap$year), max(acs_snap$year)))
stopifnot("ACS SNAP empty" = nrow(acs_snap) > 0)
saveRDS(acs_snap, file.path(data_dir, "acs_snap.rds"))

# ===========================================================================
# 3. FRED STATE UNEMPLOYMENT RATES (annual, 2000-2022)
# ===========================================================================
message("\nFetching state unemployment rates from FRED...")
fredr_set_key(fred_key)

ur_list <- list()
for (i in seq_len(nrow(all_states))) {
  sid <- paste0(all_states$state_abbr[i], "UR")
  cat(sprintf("  %s... ", sid))
  res <- tryCatch({
    fredr(series_id = sid,
          observation_start = as.Date("2000-01-01"),
          observation_end   = as.Date("2022-12-31"),
          frequency = "a")
  }, error = function(e) { cat(sprintf("FAIL\n")); NULL })
  if (!is.null(res) && nrow(res) > 0) {
    ur_list[[sid]] <- res %>%
      transmute(state_abbr = all_states$state_abbr[i],
                fips = all_states$fips[i],
                year = as.integer(format(date, "%Y")),
                unemp_rate = value / 100)
    cat(sprintf("OK (%d)\n", nrow(res)))
  }
  Sys.sleep(0.35)
}
fred_ur <- bind_rows(ur_list)
message(sprintf("FRED UR: %d obs", nrow(fred_ur)))
stopifnot("FRED empty" = nrow(fred_ur) > 0)
saveRDS(fred_ur, file.path(data_dir, "fred_ur.rds"))

message("\n=== Data fetch complete ===")
