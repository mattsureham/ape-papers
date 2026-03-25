# =============================================================================
# 01_fetch_data.R — Fetch QWI data from Census API (batch by state)
# apep_0965: EU Retaliatory Tariffs and US County Employment
# =============================================================================

source("00_packages.R")

# Load Census API key
env_file <- "../../../../.env"
if (file.exists(env_file)) {
  lines <- readLines(env_file, warn = FALSE)
  for (line in lines) {
    line <- trimws(line)
    if (nchar(line) == 0 || startsWith(line, "#")) next
    line <- sub("^export\\s+", "", line)
    eq_pos <- regexpr("=", line, fixed = TRUE)
    if (eq_pos > 0) {
      key <- substr(line, 1, eq_pos - 1)
      val <- substr(line, eq_pos + 1, nchar(line))
      val <- gsub('^["\'](.*)["\']$', "\\1", val)
      if (nchar(Sys.getenv(key, "")) == 0) {
        do.call(Sys.setenv, setNames(list(val), key))
      }
    }
  }
}

api_key <- Sys.getenv("CENSUS_API_KEY", "")
key_param <- if (nchar(api_key) > 0) paste0("&key=", api_key) else ""

base_url <- "https://api.census.gov/data/timeseries/qwi/sa"

# ---------------------------------------------------------------------------
# Fetch: one state, one industry, ALL years+quarters at once
# ---------------------------------------------------------------------------
fetch_qwi_bulk <- function(state_fips, industry) {
  state_str <- sprintf("%02d", state_fips)

  # Request all years and quarters in one call
  url <- sprintf(
    "%s?get=Emp,HirA,Sep,EarnS&for=county:*&in=state:%s&industry=%s&sex=0&agegrp=A00&ownercode=A05&periodicity=Q&year=2015,2016,2017,2018,2019,2020,2021,2022&quarter=1,2,3,4%s",
    base_url, state_str, industry, key_param
  )

  resp <- tryCatch({
    raw <- readLines(url, warn = FALSE)
    if (length(raw) == 0) return(NULL)
    parsed <- jsonlite::fromJSON(paste(raw, collapse = ""))
    if (!is.matrix(parsed) || nrow(parsed) < 2) return(NULL)
    df <- as.data.frame(parsed[-1, , drop = FALSE], stringsAsFactors = FALSE)
    names(df) <- parsed[1, ]
    df
  }, error = function(e) {
    message(sprintf("    Error state %s industry %s: %s", state_str, industry, e$message))
    NULL
  })

  if (is.null(resp) || nrow(resp) == 0) return(NULL)
  as.data.table(resp)
}

# ---------------------------------------------------------------------------
# Fetch all states × industries
# ---------------------------------------------------------------------------
state_fips_codes <- c(
  1,2,4,5,6,8,9,10,11,12,13,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,
  30,31,32,33,34,35,36,37,38,39,40,41,42,44,45,46,47,48,49,50,51,53,54,55,56
)

# EU-targeted industries
targeted_industries <- c("312", "331", "336")

message("Fetching QWI data from Census API (bulk mode)...")

# Fetch targeted industries
all_targeted <- list()
for (ind in targeted_industries) {
  message(sprintf("  Fetching NAICS %s (%d states)...", ind, length(state_fips_codes)))
  for (st in state_fips_codes) {
    dt <- fetch_qwi_bulk(st, ind)
    if (!is.null(dt) && nrow(dt) > 0) {
      dt[, industry_code := ind]
      all_targeted[[length(all_targeted) + 1]] <- dt
    }
    Sys.sleep(0.15)
  }
  message(sprintf("    Done: %d state files collected for NAICS %s",
                  sum(sapply(all_targeted, function(x) !is.null(x) && x$industry_code[1] == ind)),
                  ind))
}

# Fetch total manufacturing (sector 31-33)
message("  Fetching total manufacturing (NAICS 31-33)...")
all_mfg <- list()
for (st in state_fips_codes) {
  dt <- fetch_qwi_bulk(st, "31-33")
  if (!is.null(dt) && nrow(dt) > 0) {
    dt[, industry_code := "31-33"]
    all_mfg[[length(all_mfg) + 1]] <- dt
  }
  Sys.sleep(0.15)
}
message(sprintf("    Done: %d state files for total manufacturing", length(all_mfg)))

# ---------------------------------------------------------------------------
# Combine and clean
# ---------------------------------------------------------------------------
targeted_dt <- rbindlist(all_targeted, fill = TRUE)
mfg_dt <- rbindlist(all_mfg, fill = TRUE)

stopifnot("No targeted industry data returned from API" = nrow(targeted_dt) > 0)
stopifnot("No manufacturing data returned from API" = nrow(mfg_dt) > 0)

# Create FIPS and convert types
for (dt in list(targeted_dt, mfg_dt)) {
  dt[, fips := as.integer(paste0(state, county))]
  dt[, year := as.integer(year)]
  dt[, quarter := as.integer(quarter)]
  for (col in c("Emp", "HirA", "Sep", "EarnS")) {
    dt[, (col) := as.numeric(get(col))]
  }
}

setnames(targeted_dt, c("Emp", "HirA", "Sep", "EarnS"),
         c("emp", "hira", "sep", "earns"))
setnames(mfg_dt, c("Emp", "HirA", "Sep", "EarnS"),
         c("emp", "hira", "sep", "earns"))

message(sprintf("Targeted rows: %s, Mfg rows: %s",
                format(nrow(targeted_dt), big.mark = ","),
                format(nrow(mfg_dt), big.mark = ",")))

# Aggregate targeted to county × quarter
targeted_county <- targeted_dt[, .(
  emp_targeted = sum(emp, na.rm = TRUE),
  hira_targeted = sum(hira, na.rm = TRUE),
  sep_targeted = sum(sep, na.rm = TRUE)
), by = .(fips, year, quarter)]

# Manufacturing county × quarter
mfg_county <- mfg_dt[, .(
  emp = sum(emp, na.rm = TRUE),
  hira = sum(hira, na.rm = TRUE),
  sep = sum(sep, na.rm = TRUE),
  earns = mean(earns, na.rm = TRUE)
), by = .(fips, year, quarter)]

# Per-industry 2017Q4 for leave-one-out
ind_2017q4 <- targeted_dt[year == 2017 & quarter == 4, .(
  emp = sum(emp, na.rm = TRUE)
), by = .(fips, industry_code)]

# Save
fwrite(targeted_county, "../data/targeted_county_qtr.csv")
fwrite(mfg_county, "../data/mfg_county_qtr.csv")
fwrite(ind_2017q4, "../data/industry_2017q4.csv")

message(sprintf("Counties with targeted emp: %d", targeted_county[, uniqueN(fips)]))
message(sprintf("Counties with mfg emp: %d", mfg_county[, uniqueN(fips)]))
message("Data fetch complete.")
