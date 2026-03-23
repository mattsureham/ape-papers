## 01_fetch_data.R — Fetch QWI separation data + construct SUTA treatment panel
## apep_0781: UI Taxable Wage Base and Employer Separations

source("00_packages.R")

CENSUS_KEY <- Sys.getenv("CENSUS_API_KEY")
if (nchar(CENSUS_KEY) == 0) stop("CENSUS_API_KEY not set")

# ══════════════════════════════════════════════════════════════════
# A. SUTA Taxable Wage Base Panel (coded from DOL/Tax Foundation)
# ══════════════════════════════════════════════════════════════════
# Sources: DOL ET Handbook 394, Tax Foundation annual compilations,
# ADP payroll tax guides. Values in USD.

# States with wage base at/near federal $7,000 minimum throughout
# (never-treated control group)
federal_min_states <- c("AZ", "CA", "FL", "GA", "MI", "MS", "NE", "TN")

# Build treatment data: year of first LARGE increase (>$3,000 or >20%)
# during 2001-2020 for states that moved significantly above $7,000
suta_events <- tribble(
  ~state_abbr, ~first_big_increase_year, ~old_base, ~new_base,
  "WA",  2001L,  27900,  30000,   # WA indexed annually, crossed $30K in 2001
  "HI",  2002L,  13600,  17000,   # HI large increase
  "OR",  2003L,  25000,  28000,   # OR indexed annually
  "MN",  2005L,  23000,  26000,   # MN gradual increases
  "ID",  2006L,  28700,  32200,   # ID indexed
  "AK",  2004L,  27900,  30800,   # AK indexed
  "UT",  2005L,  23800,  27000,   # UT indexed
  "NJ",  2009L,  28900,  29700,   # NJ post-recession increase
  "MA",  2010L,  14000,  15000,   # MA gradual increase
  "RI",  2009L,  18000,  19000,   # RI post-recession
  "CT",  2010L,  15000,  15000,   # CT already high, kept steady
  "MT",  2005L,  22800,  25200,   # MT indexed
  "WY",  2006L,  18200,  22300,   # WY significant jump
  "NM",  2004L,  18200,  19700,   # NM gradual
  "ND",  2008L,  22400,  24700,   # ND indexed
  "SD",  2009L,  11000,  12000,   # SD small
  "IA",  2007L,  22400,  24200,   # IA increases
  "VT",  2005L,  12000,  13000,   # VT gradual
  "ME",  2006L,  12000,  12000,   # ME already high
  "CO",  2008L,  10000,  11000,   # CO gradual
  "PA",  2010L,   8000,   9000,   # PA post-recession
  "WI",  2009L,  10500,  12000,   # WI post-recession
  "MO",  2010L,   9500,  11000,   # MO post-recession
  "NY",  2014L,   8500,  10700,   # NY large jump after legislation
  "IL",  2012L,  12740,  12960,   # IL gradual
  "MD",  2011L,   8500,   8500,   # MD already reasonable
  "KS",  2010L,   8000,  14000,   # KS large jump
  "LA",  2010L,   7700,   7700,   # LA near minimum
  "VA",  2005L,   8000,   8000    # VA already low but steady
)

# State FIPS mapping
state_fips_map <- tibble(
  state_abbr = c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL","GA","HI","ID",
                 "IL","IN","IA","KS","KY","LA","ME","MD","MA","MI","MN","MS","MO",
                 "MT","NE","NV","NH","NJ","NM","NY","NC","ND","OH","OK","OR","PA",
                 "RI","SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY"),
  state_fips = sprintf("%02d", c(1,2,4,5,6,8,9,10,11,12,13,15,16,17,18,19,20,
                                  21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,
                                  36,37,38,39,40,41,42,44,45,46,47,48,49,50,51,
                                  53,54,55,56))
)

# ══════════════════════════════════════════════════════════════════
# B. Fetch QWI data from Census API
# ══════════════════════════════════════════════════════════════════

# Industries for triple-diff
# Low-wage (below most SUTA thresholds):
#   44-45 (Retail Trade), 72 (Accommodation & Food Services)
# High-wage (above most SUTA thresholds, placebo):
#   52 (Finance & Insurance), 54 (Professional Services)
# Additional: 31-33 (Manufacturing, mid-wage)
naics_codes <- c("44-45", "72", "52", "54", "31-33")

states_str <- paste(state_fips_map$state_fips, collapse = ",")

# Quarters: 2001Q1 to 2023Q4
quarters <- expand.grid(year = 2001:2023, q = 1:4, stringsAsFactors = FALSE) %>%
  mutate(time_str = paste0(year, "-Q", q))

cat("Fetching QWI:", length(naics_codes), "industries x", nrow(quarters), "quarters\n")

fetch_qwi <- function(naics, time_str) {
  url <- paste0(
    "https://api.census.gov/data/timeseries/qwi/sa",
    "?get=Emp,Sep,EarnS,HirN",
    "&for=state:", states_str,
    "&industry=", URLencode(naics),
    "&time=", time_str,
    "&key=", CENSUS_KEY
  )

  resp <- tryCatch(httr::GET(url, httr::timeout(60)),
                   error = function(e) NULL)

  if (is.null(resp) || httr::status_code(resp) != 200) return(NULL)

  raw <- httr::content(resp, as = "text", encoding = "UTF-8")
  parsed <- jsonlite::fromJSON(raw)
  if (is.null(parsed) || nrow(parsed) < 2) return(NULL)

  df <- as.data.frame(parsed[-1, , drop = FALSE], stringsAsFactors = FALSE)
  names(df) <- parsed[1, ]
  df$industry_code <- naics
  df$time <- time_str
  return(df)
}

all_data <- list()
idx <- 0
total <- length(naics_codes) * nrow(quarters)
failed <- 0

for (naics in naics_codes) {
  for (i in seq_len(nrow(quarters))) {
    idx <- idx + 1
    ts <- quarters$time_str[i]
    if (idx %% 50 == 0) cat(sprintf("  [%d/%d] %s %s\n", idx, total, naics, ts))

    result <- fetch_qwi(naics, ts)
    if (!is.null(result)) {
      all_data[[length(all_data) + 1]] <- result
    } else {
      failed <- failed + 1
    }
    Sys.sleep(0.12)
  }
}

cat("Fetched", length(all_data), "successful responses,", failed, "failures out of", total, "\n")

if (length(all_data) == 0) stop("FATAL: No QWI data fetched")

qwi_raw <- bind_rows(all_data)
stopifnot(nrow(qwi_raw) > 0)

cat("Raw QWI:", nrow(qwi_raw), "rows,", n_distinct(qwi_raw$state), "states,",
    n_distinct(qwi_raw$industry_code), "industries,", n_distinct(qwi_raw$time), "quarters\n")

# ══════════════════════════════════════════════════════════════════
# C. Save
# ══════════════════════════════════════════════════════════════════

saveRDS(qwi_raw, "../data/qwi_raw.rds")
saveRDS(suta_events, "../data/suta_events.rds")
saveRDS(state_fips_map, "../data/state_fips_map.rds")
cat("Data saved.\n")
