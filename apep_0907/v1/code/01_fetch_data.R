## 01_fetch_data.R — Fetch SNAP data from USDA sources
## apep_0907: The Digital Door to Food Stamps

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================
# 1. SNAP Policy Database from USDA ERS (downloaded via curl)
# ============================================================
cat("Reading SNAP Policy Database...\n")

xlsx_path <- file.path(data_dir, "snap_policy_db.xlsx")
stopifnot("SNAP Policy DB not found — download with curl first" = file.exists(xlsx_path))

policy_raw <- readxl::read_excel(xlsx_path, sheet = "SNAP Policy Database")
cat("  Policy DB:", nrow(policy_raw), "rows x", ncol(policy_raw), "cols\n")
stopifnot("Policy DB has zero rows" = nrow(policy_raw) > 0)

# ============================================================
# 2. SNAP Participation Data from FRED API (state-monthly)
# Series pattern: BR{ST}{FIPS}M647NCEN (monthly)
# ============================================================
cat("\nFetching SNAP participation from FRED (monthly, by state)...\n")

fred_key <- Sys.getenv("FRED_API_KEY")
stopifnot("FRED_API_KEY not set" = nchar(fred_key) > 0)

state_fips <- data.frame(
  state_abbr = c("AL","AK","AZ","AR","CA","CO","CT","DE","FL","GA",
                 "HI","ID","IL","IN","IA","KS","KY","LA","ME","MD",
                 "MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ",
                 "NM","NY","NC","ND","OH","OK","OR","PA","RI","SC",
                 "SD","TN","TX","UT","VT","VA","WA","WV","WI","WY","DC"),
  fips = c("01","02","04","05","06","08","09","10","12","13",
           "15","16","17","18","19","20","21","22","23","24",
           "25","26","27","28","29","30","31","32","33","34",
           "35","36","37","38","39","40","41","42","44","45",
           "46","47","48","49","50","51","53","54","55","56","11"),
  state_name = c("Alabama","Alaska","Arizona","Arkansas","California",
                 "Colorado","Connecticut","Delaware","Florida","Georgia",
                 "Hawaii","Idaho","Illinois","Indiana","Iowa","Kansas",
                 "Kentucky","Louisiana","Maine","Maryland","Massachusetts",
                 "Michigan","Minnesota","Mississippi","Missouri","Montana",
                 "Nebraska","Nevada","New Hampshire","New Jersey",
                 "New Mexico","New York","North Carolina","North Dakota",
                 "Ohio","Oklahoma","Oregon","Pennsylvania","Rhode Island",
                 "South Carolina","South Dakota","Tennessee","Texas","Utah",
                 "Vermont","Virginia","Washington","West Virginia","Wisconsin",
                 "Wyoming","District of Columbia"),
  stringsAsFactors = FALSE
)

fetch_fred <- function(series_id, api_key) {
  url <- sprintf(
    "https://api.stlouisfed.org/fred/series/observations?series_id=%s&api_key=%s&file_type=json&observation_start=1996-01-01&observation_end=2024-12-31",
    series_id, api_key
  )
  resp <- httr::GET(url, httr::timeout(30))
  if (httr::status_code(resp) != 200) return(NULL)
  content <- httr::content(resp, as = "text", encoding = "UTF-8")
  parsed <- jsonlite::fromJSON(content)
  if (is.null(parsed$observations) || nrow(parsed$observations) == 0) return(NULL)
  df <- parsed$observations[, c("date", "value")]
  df$value <- as.numeric(df$value)
  df <- df[!is.na(df$value), ]
  return(df)
}

# Fetch monthly SNAP persons for each state
snap_list <- list()
success_count <- 0

for (i in seq_len(nrow(state_fips))) {
  st <- state_fips$state_abbr[i]
  fips_code <- state_fips$fips[i]

  # Series pattern: BR{ST}{FIPS}M647NCEN
  sid <- paste0("BR", st, fips_code, "M647NCEN")
  df <- fetch_fred(sid, fred_key)

  if (!is.null(df) && nrow(df) > 0) {
    df$state_abbr <- st
    df$fips <- fips_code
    df$series_id <- sid
    snap_list[[st]] <- df
    success_count <- success_count + 1
  } else {
    cat("  Missing:", st, "(", sid, ")\n")
  }

  Sys.sleep(0.12)
  if (i %% 10 == 0) cat("  Fetched", i, "of", nrow(state_fips), "states\n")
}

cat("  FRED monthly SNAP data: found", success_count, "of", nrow(state_fips), "states\n")

# For any missing, try annual series: BR{ST}{FIPS}A647NCEN
missing_states <- setdiff(state_fips$state_abbr, names(snap_list))
if (length(missing_states) > 0) {
  cat("  Trying annual series for", length(missing_states), "missing states...\n")
  for (st in missing_states) {
    fips_code <- state_fips$fips[state_fips$state_abbr == st]
    sid <- paste0("BR", st, fips_code, "A647NCEN")
    df <- fetch_fred(sid, fred_key)
    if (!is.null(df) && nrow(df) > 0) {
      df$state_abbr <- st
      df$fips <- fips_code
      df$series_id <- sid
      df$frequency <- "annual"
      snap_list[[st]] <- df
      success_count <- success_count + 1
      cat("    Got annual for:", st, "\n")
    }
    Sys.sleep(0.12)
  }
  cat("  After annual fallback: found", success_count, "states\n")
}

stopifnot("Need at least 40 states of SNAP data" = success_count >= 40)

# ============================================================
# 3. Population data from FRED (state-level annual)
# Series: {ST}POP (thousands)
# ============================================================
cat("\nFetching state population from FRED...\n")

pop_list <- list()
pop_count <- 0

for (i in seq_len(nrow(state_fips))) {
  st <- state_fips$state_abbr[i]

  sid <- paste0(st, "POP")
  df <- fetch_fred(sid, fred_key)

  if (!is.null(df) && nrow(df) > 0) {
    df$state_abbr <- st
    df$fips <- state_fips$fips[i]
    pop_list[[st]] <- df
    pop_count <- pop_count + 1
  }

  Sys.sleep(0.12)
  if (i %% 10 == 0) cat("  Fetched", i, "of", nrow(state_fips), "states\n")
}

cat("  Population data: found", pop_count, "states\n")

# For DC and others without {ST}POP, try DCPOP or FRED search
missing_pop <- setdiff(state_fips$state_abbr, names(pop_list))
if (length(missing_pop) > 0) {
  cat("  Missing population for:", paste(missing_pop, collapse=", "), "\n")
  # Try RESIDENT population series
  for (st in missing_pop) {
    fips_code <- state_fips$fips[state_fips$state_abbr == st]
    alt_ids <- c(
      paste0(st, "POPN"),
      paste0(st, "RPOP"),
      paste0(st, "TOTPOP")
    )
    for (sid in alt_ids) {
      df <- fetch_fred(sid, fred_key)
      if (!is.null(df) && nrow(df) > 0) {
        df$state_abbr <- st
        df$fips <- fips_code
        pop_list[[st]] <- df
        pop_count <- pop_count + 1
        break
      }
      Sys.sleep(0.12)
    }
  }
  cat("  After alt: found", pop_count, "states\n")
}

# ============================================================
# 4. Save all raw data
# ============================================================
saveRDS(policy_raw, file.path(data_dir, "policy_raw.rds"))
saveRDS(state_fips, file.path(data_dir, "state_fips.rds"))

snap_fred <- bind_rows(snap_list)
saveRDS(snap_fred, file.path(data_dir, "snap_fred.rds"))
cat("\nSaved SNAP data:", nrow(snap_fred), "rows,",
    n_distinct(snap_fred$state_abbr), "states\n")

if (length(pop_list) > 0) {
  pop_fred <- bind_rows(pop_list)
  saveRDS(pop_fred, file.path(data_dir, "pop_fred.rds"))
  cat("Saved pop data:", nrow(pop_fred), "rows,",
      n_distinct(pop_fred$state_abbr), "states\n")
}

cat("\n=== Data fetch complete ===\n")
