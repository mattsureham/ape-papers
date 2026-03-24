## 01_fetch_data.R — Fetch Business Formation Statistics from FRED API
## apep_0843: RON Laws and New Business Formation

source("00_packages.R")

# ------------------------------------------------------------------
# FRED API setup
# ------------------------------------------------------------------
fred_key <- Sys.getenv("FRED_API_KEY")
if (fred_key == "") stop("FRED_API_KEY not set in environment. Cannot proceed.")
fredr_set_key(fred_key)

# ------------------------------------------------------------------
# State FIPS codes for FRED series naming
# ------------------------------------------------------------------
state_info <- tibble(
  state_abbr = c("AL","AK","AZ","AR","CA","CO","CT","DE","FL","GA",
                 "HI","ID","IL","IN","IA","KS","KY","LA","ME","MD",
                 "MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ",
                 "NM","NY","NC","ND","OH","OK","OR","PA","RI","SC",
                 "SD","TN","TX","UT","VT","VA","WA","WV","WI","WY","DC"),
  state_name = c("Alabama","Alaska","Arizona","Arkansas","California",
                 "Colorado","Connecticut","Delaware","Florida","Georgia",
                 "Hawaii","Idaho","Illinois","Indiana","Iowa","Kansas",
                 "Kentucky","Louisiana","Maine","Maryland","Massachusetts",
                 "Michigan","Minnesota","Mississippi","Missouri","Montana",
                 "Nebraska","Nevada","New Hampshire","New Jersey",
                 "New Mexico","New York","North Carolina","North Dakota",
                 "Ohio","Oklahoma","Oregon","Pennsylvania","Rhode Island",
                 "South Carolina","South Dakota","Tennessee","Texas","Utah",
                 "Vermont","Virginia","Washington","West Virginia",
                 "Wisconsin","Wyoming","District of Columbia")
)

# ------------------------------------------------------------------
# Fetch BFS series for each state
# ------------------------------------------------------------------
# Series patterns:
#   BA:  BABATOTALSA{XX}    — Business Applications
#   HBA: BAHBATOTALSA{XX}   — High-Propensity BA
#   WBA: BAWBATOTALSA{XX}   — BA with Planned Wages
#   CBA: BACBATOTALSA{XX}   — BA from Corporations

series_prefixes <- c(
  BA  = "BABATOTALSA",
  HBA = "BAHBATOTALSA",
  WBA = "BAWBATOTALSA",
  CBA = "BACBATOTALSA"
)

fetch_state_series <- function(state_abbr, prefix, series_name) {
  series_id <- paste0(prefix, state_abbr)
  cat("  Fetching", series_id, "...\n")

  result <- tryCatch(
    fredr(series_id = series_id,
          observation_start = as.Date("2004-07-01"),
          observation_end = as.Date("2024-12-01")),
    error = function(e) {
      stop("FRED API fetch failed for ", series_id, ": ", e$message)
    }
  )

  if (is.null(result) || nrow(result) == 0) {
    stop("FRED returned empty data for ", series_id)
  }

  result %>%
    select(date, value) %>%
    mutate(
      state = state_abbr,
      series = series_name
    )
}

cat("Fetching Business Formation Statistics from FRED API...\n")
cat("This will make", nrow(state_info) * length(series_prefixes), "API calls.\n\n")

all_data <- list()

for (i in seq_len(nrow(state_info))) {
  st <- state_info$state_abbr[i]
  cat("State:", st, "\n")

  for (j in seq_along(series_prefixes)) {
    sname <- names(series_prefixes)[j]
    prefix <- series_prefixes[j]

    df_tmp <- fetch_state_series(st, prefix, sname)
    all_data[[length(all_data) + 1]] <- df_tmp

    Sys.sleep(0.15)  # Rate limiting
  }
}

bfs_raw <- bind_rows(all_data)

cat("\n=== Data Summary ===\n")
cat("Total observations:", nrow(bfs_raw), "\n")
cat("States:", n_distinct(bfs_raw$state), "\n")
cat("Series:", unique(bfs_raw$series), "\n")
cat("Date range:", as.character(min(bfs_raw$date)), "to", as.character(max(bfs_raw$date)), "\n")

# Validate: every state should have all 4 series
coverage <- bfs_raw %>%
  group_by(state, series) %>%
  summarise(n = n(), .groups = "drop") %>%
  pivot_wider(names_from = series, values_from = n)

missing <- coverage %>% filter(if_any(everything(), is.na))
if (nrow(missing) > 0) {
  cat("\nWARNING: Missing series for some states:\n")
  print(missing)
  stop("Incomplete data coverage. Cannot proceed.")
}

cat("\nAll states have all 4 series. Data fetch complete.\n")

saveRDS(bfs_raw, "../data/bfs_raw.rds")
cat("Saved to data/bfs_raw.rds\n")
