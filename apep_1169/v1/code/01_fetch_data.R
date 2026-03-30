## 01_fetch_data.R — Fetch Business Formation Statistics from FRED
## apep_1169: Click to Incorporate

source("00_packages.R")

# ---- FRED API key ----
fred_key <- Sys.getenv("FRED_API_KEY")
if (fred_key == "") stop("FRED_API_KEY not set in .env")
fredr_set_key(fred_key)

# ---- State codes ----
states <- c("AL","AK","AZ","AR","CA","CO","CT","DE","FL","GA",
            "HI","ID","IL","IN","IA","KS","KY","LA","ME","MD",
            "MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ",
            "NM","NY","NC","ND","OH","OK","OR","PA","RI","SC",
            "SD","TN","TX","UT","VT","VA","WA","WV","WI","WY","DC")

cat("Fetching BFS data for", length(states), "jurisdictions...\n")

# ---- Series ID patterns (current weekly-windowed NSA series) ----
# BA:  BUSAPPWNSA{ST}   — all business applications
# HBA: HBUSAPPWNSA{ST}  — high-propensity applications
# WBA: WBUSAPPWNSA{ST}  — applications with planned wages
# CBA: CBUSAPPWNSA{ST}  — corporate applications (mechanism test)

fetch_series <- function(prefix, st) {
  series_id <- paste0(prefix, st)
  tryCatch({
    dat <- fredr(series_id = series_id,
                 observation_start = as.Date("2004-07-01"),
                 observation_end = as.Date("2025-12-01"))
    if (is.null(dat) || nrow(dat) == 0) {
      warning(paste("No data for", series_id))
      return(NULL)
    }
    data.frame(
      date = dat$date,
      value = dat$value,
      state = st,
      stringsAsFactors = FALSE
    )
  }, error = function(e) {
    warning(paste("Error fetching", series_id, ":", e$message))
    return(NULL)
  })
}

# Fetch all series with rate limiting
fetch_all <- function(prefix, label) {
  cat("Fetching", label, "...")
  dfs <- lapply(states, function(st) {
    Sys.sleep(0.25)
    fetch_series(prefix, st)
  })
  result <- bind_rows(dfs)
  cat(nrow(result), "rows from", length(unique(result$state)), "states\n")
  result
}

ba_df  <- fetch_all("BUSAPPWNSA",  "BA")
hba_df <- fetch_all("HBUSAPPWNSA", "HBA")
wba_df <- fetch_all("WBUSAPPWNSA", "WBA")
cba_df <- fetch_all("CBUSAPPWNSA", "CBA")

# Validate: real data exists
stopifnot(nrow(ba_df) > 5000)
stopifnot(length(unique(ba_df$state)) >= 45)

cat("\nBA:", nrow(ba_df), "rows,", length(unique(ba_df$state)), "states\n")
cat("HBA:", nrow(hba_df), "rows,", length(unique(hba_df$state)), "states\n")
cat("WBA:", nrow(wba_df), "rows,", length(unique(wba_df$state)), "states\n")
cat("CBA:", nrow(cba_df), "rows,", length(unique(cba_df$state)), "states\n")

# ---- Combine into wide panel (base on WBA which has all 51 states) ----
ba_df$BA <- ba_df$value
hba_df$HBA <- hba_df$value
wba_df$WBA <- wba_df$value
cba_df$CBA <- cba_df$value

bfs <- wba_df %>%
  select(state, date, WBA) %>%
  left_join(ba_df %>% select(state, date, BA), by = c("state","date")) %>%
  left_join(hba_df %>% select(state, date, HBA), by = c("state","date")) %>%
  left_join(cba_df %>% select(state, date, CBA), by = c("state","date"))

bfs$year <- as.integer(format(bfs$date, "%Y"))
bfs$month <- as.integer(format(bfs$date, "%m"))
bfs$ym <- bfs$year * 12L + bfs$month

saveRDS(bfs, "../data/bfs_monthly.rds")
cat("\nSaved:", nrow(bfs), "rows to data/bfs_monthly.rds\n")

# ---- Treatment coding ----
treatment <- tribble(
  ~state, ~portal_name,    ~launch_date,
  "VA",   "VBOS",          "2008-05-01",
  "KY",   "OneStop",       "2011-10-01",
  "NV",   "SilverFlume",   "2012-06-01",
  "KS",   "OneStop",       "2014-09-01",
  "MS",   "BOSS",          "2015-10-01",
  "WI",   "OneStop",       "2017-06-01",
  "PA",   "PA Login",      "2018-06-01",
  "DE",   "OneStop",       "2019-08-01",
  "CT",   "Business.CT",   "2020-07-01",
  "TX",   "TxT",           "2022-03-01",
  "AZ",   "AZBiz",         "2022-11-01"
)
treatment$launch_date <- as.Date(treatment$launch_date)
treatment$launch_ym <- as.integer(format(treatment$launch_date, "%Y")) * 12L +
  as.integer(format(treatment$launch_date, "%m"))

saveRDS(treatment, "../data/treatment_panel.rds")
cat("Treatment panel:", nrow(treatment), "treated states coded.\n")
cat("DATA FETCH COMPLETE.\n")
