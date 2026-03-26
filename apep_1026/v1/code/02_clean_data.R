# 02_clean_data.R — Clean and prepare panel for analysis
# apep_1026: Marijuana legalization and FHA mortgage exclusion

source("00_packages.R")

# ============================================================
# Load data
# ============================================================
panel <- fread("../data/state_year_panel.csv")
cat(glue("Loaded panel: {nrow(panel)} obs\n\n"))

# ============================================================
# Add state-level controls from FRED/BLS
# (unemployment rate, house price index)
# ============================================================
# FRED API for state unemployment rates
fred_key <- Sys.getenv("FRED_API_KEY")
if (nchar(fred_key) > 0) {
  cat("Fetching state unemployment rates from FRED...\n")

  # State FIPS to FRED series mapping (e.g., COUR for CO unemployment rate)
  state_to_fred <- data.table(
    state = c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL",
              "GA","HI","ID","IL","IN","IA","KS","KY","LA","ME",
              "MD","MA","MI","MN","MS","MO","MT","NE","NV","NH",
              "NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI",
              "SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY"),
    fred_id = paste0(c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL",
                        "GA","HI","ID","IL","IN","IA","KS","KY","LA","ME",
                        "MD","MA","MI","MN","MS","MO","MT","NE","NV","NH",
                        "NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI",
                        "SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY"),
                     "UR")
  )

  fetch_fred <- function(series_id, start = "2017-01-01", end = "2024-01-01") {
    url <- glue("https://api.stlouisfed.org/fred/series/observations?",
                "series_id={series_id}&api_key={fred_key}&file_type=json",
                "&observation_start={start}&observation_end={end}&frequency=a")
    resp <- GET(url, timeout(30))
    if (status_code(resp) != 200) return(NULL)
    js <- content(resp, as = "parsed")
    if (length(js$observations) == 0) return(NULL)
    data.table(
      year = as.integer(substr(sapply(js$observations, `[[`, "date"), 1, 4)),
      unemp_rate = as.numeric(sapply(js$observations, `[[`, "value"))
    )
  }

  unemp_list <- lapply(seq_len(nrow(state_to_fred)), function(i) {
    st <- state_to_fred$state[i]
    dt <- fetch_fred(state_to_fred$fred_id[i])
    if (!is.null(dt)) dt[, state := st]
    return(dt)
  })

  unemp <- rbindlist(Filter(Nonnull <- function(x) !is.null(x), unemp_list))
  panel <- merge(panel, unemp[, .(state, year, unemp_rate)],
                 by = c("state", "year"), all.x = TRUE)
  cat(glue("  Merged unemployment data: {sum(!is.na(panel$unemp_rate))} obs with data\n\n"))
} else {
  cat("No FRED API key — skipping unemployment controls.\n")
  panel[, unemp_rate := NA_real_]
}

# ============================================================
# Fetch FHFA House Price Index (annual, state-level)
# ============================================================
cat("Fetching FHFA HPI...\n")
hpi_url <- "https://www.fhfa.gov/hpi/download/monthly/states.csv"
resp <- tryCatch(GET(hpi_url, timeout(60)), error = function(e) NULL)

if (!is.null(resp) && status_code(resp) == 200) {
  raw <- content(resp, as = "text", encoding = "UTF-8")
  hpi_raw <- fread(text = raw)

  # FHFA state HPI file has columns: state, year, quarter, index_nsa, index_sa
  # We want annual average
  if (all(c("state", "yr", "index_nsa") %in% names(hpi_raw))) {
    hpi <- hpi_raw[, .(hpi = mean(index_nsa, na.rm = TRUE)), by = .(state, year = yr)]
    panel <- merge(panel, hpi, by = c("state", "year"), all.x = TRUE)
    cat(glue("  Merged HPI: {sum(!is.na(panel$hpi))} obs with data\n\n"))
  } else {
    cat("  HPI file format unexpected, skipping.\n")
    panel[, hpi := NA_real_]
  }
} else {
  cat("  Could not fetch FHFA HPI, skipping.\n")
  panel[, hpi := NA_real_]
}

# ============================================================
# Create analysis variables
# ============================================================
# FHA share in percentage points for easier interpretation
panel[, fha_share_pct := fha_share * 100]
panel[, va_share_pct := va_share * 100]
panel[, conv_share_pct := conventional_share * 100]
panel[, govt_share_pct := govt_share * 100]

# Log total loans (size control)
panel[, log_total_loans := log(n_total)]

# Rate spread: conventional minus FHA
panel[, rate_gap := mean_rate_conv - mean_rate_fha]

# State numeric ID for fixest
panel[, state_id := as.integer(factor(state))]

# ============================================================
# Summary statistics
# ============================================================
cat("\n=== Clean Panel Summary ===\n")
cat(glue("Observations: {nrow(panel)}\n"))
cat(glue("States: {uniqueN(panel$state)}\n"))
cat(glue("Years: {paste(sort(unique(panel$year)), collapse=', ')}\n\n"))

cat("FHA share (pct) summary:\n")
print(summary(panel$fha_share_pct))

cat("\nBy treatment group:\n")
summary_tab <- panel[, .(
  mean_fha = round(mean(fha_share_pct), 1),
  sd_fha = round(sd(fha_share_pct), 1),
  mean_va = round(mean(va_share_pct), 1),
  mean_conv = round(mean(conv_share_pct), 1),
  mean_total = round(mean(n_total)),
  n = .N
), by = treated]
print(summary_tab)

# Pre-treatment SD of FHA share for SDE calculation
pre_sd <- panel[post == 0 | treated == 0, sd(fha_share_pct, na.rm = TRUE)]
cat(glue("\nPre-treatment SD of FHA share: {round(pre_sd, 2)} pp\n"))

# ============================================================
# Save
# ============================================================
fwrite(panel, "../data/analysis_panel.csv")
cat("\nCleaned panel saved to data/analysis_panel.csv\n")
