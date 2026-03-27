# =============================================================================
# 01_fetch_data.R — Fetch QWI data from Census Bureau API
# apep_1094: Film Tax Credits and Racial Employment Gains
# =============================================================================

source("00_packages.R")

# Load Census API key from .env
env_lines <- readLines("../../../../.env", warn = FALSE)
for (line in env_lines) {
  line <- trimws(line)
  if (nchar(line) == 0 || startsWith(line, "#")) next
  line <- sub("^export\\s+", "", line)
  eq_pos <- regexpr("=", line, fixed = TRUE)
  if (eq_pos > 0) {
    key <- substr(line, 1, eq_pos - 1)
    val <- substr(line, eq_pos + 1, nchar(line))
    val <- gsub('^["\'](.*)["\']+$', "\\1", val)
    do.call(Sys.setenv, setNames(list(val), key))
  }
}
census_key <- Sys.getenv("CENSUS_API_KEY")
stopifnot("CENSUS_API_KEY not found in .env" = nchar(census_key) > 0)
cat("Census API key loaded.\n")

# State FIPS codes
state_fips <- c(
  "01","02","04","05","06","08","09","10","11","12","13","15","16","17","18",
  "19","20","21","22","23","24","25","26","27","28","29","30","31","32","33",
  "34","35","36","37","38","39","40","41","42","44","45","46","47","48","49",
  "50","51","53","54","55","56"
)

fips_to_abbr <- c(
  "01"="AL","02"="AK","04"="AZ","05"="AR","06"="CA","08"="CO","09"="CT",
  "10"="DE","11"="DC","12"="FL","13"="GA","15"="HI","16"="ID","17"="IL",
  "18"="IN","19"="IA","20"="KS","21"="KY","22"="LA","23"="ME","24"="MD",
  "25"="MA","26"="MI","27"="MN","28"="MS","29"="MO","30"="MT","31"="NE",
  "32"="NV","33"="NH","34"="NJ","35"="NM","36"="NY","37"="NC","38"="ND",
  "39"="OH","40"="OK","41"="OR","42"="PA","44"="RI","45"="SC","46"="SD",
  "47"="TN","48"="TX","49"="UT","50"="VT","51"="VA","53"="WA","54"="WV",
  "55"="WI","56"="WY"
)

# -----------------------------------------------------------------------------
# Fetch QWI: use time=from+to to get all years/quarters in one call per state
# 408 calls total: 51 states x 2 industries x 4 races
# -----------------------------------------------------------------------------

fetch_qwi_all_years <- function(state_fips, industry, race) {
  url <- "https://api.census.gov/data/timeseries/qwi/rh"
  params <- list(
    get = "Emp,HirA,Sep,EarnHirAS",
    `for` = paste0("state:", state_fips),
    industry = industry,
    race = race,
    time = "from 2001 to 2024",
    key = census_key
  )

  resp <- GET(url, query = params)

  if (status_code(resp) == 200) {
    txt <- content(resp, "text", encoding = "UTF-8")
    if (nchar(txt) > 10) {
      json <- fromJSON(txt)
      if (is.matrix(json) && nrow(json) > 1) {
        df <- as.data.frame(json[-1, , drop = FALSE], stringsAsFactors = FALSE)
        names(df) <- json[1, ]
        return(df)
      }
    }
  }
  return(NULL)
}

cat("Fetching QWI data (fast: all years per call)...\n")

industries <- c("512", "722")
races <- c("A0", "A1", "A2", "A5")

all_qwi <- list()
total <- length(state_fips) * length(industries) * length(races)
counter <- 0

for (st in state_fips) {
  for (ind in industries) {
    for (rc in races) {
      counter <- counter + 1
      if (counter %% 20 == 0) {
        cat(sprintf("  Progress: %d/%d (state=%s, ind=%s, race=%s)\n",
                    counter, total, fips_to_abbr[st], ind, rc))
      }
      result <- fetch_qwi_all_years(st, ind, rc)
      if (!is.null(result)) {
        all_qwi[[length(all_qwi) + 1]] <- result
      }
      Sys.sleep(0.08)
    }
  }
}

qwi_raw <- bind_rows(all_qwi)
cat(sprintf("Fetched %d rows of QWI data.\n", nrow(qwi_raw)))

# Validate: must have real data
stopifnot("QWI fetch returned no data" = nrow(qwi_raw) > 1000)

# Parse the 'time' column (format: "YYYY-QN")
qwi_raw <- qwi_raw %>%
  mutate(
    year = as.integer(substr(time, 1, 4)),
    quarter = as.integer(substr(time, 7, 7))
  )

saveRDS(qwi_raw, "../data/qwi_raw.rds")
cat("Saved qwi_raw.rds\n")

# -----------------------------------------------------------------------------
# Film tax credit treatment dates
# -----------------------------------------------------------------------------

film_credits <- tribble(
  ~state_abbr, ~adopt_year, ~adopt_qtr, ~credit_rate, ~repeal_year,
  "LA",  2002, 3, 0.25, NA,
  "NM",  2003, 1, 0.25, NA,
  "CT",  2006, 3, 0.30, NA,
  "GA",  2008, 3, 0.20, NA,
  "MA",  2006, 1, 0.25, NA,
  "NY",  2004, 2, 0.30, NA,
  "NC",  2010, 1, 0.25, 2014,
  "PA",  2004, 3, 0.25, NA,
  "IL",  2009, 1, 0.30, NA,
  "MI",  2008, 2, 0.40, 2015,
  "OH",  2009, 3, 0.25, NA,
  "TX",  2007, 3, 0.20, NA,
  "SC",  2008, 3, 0.20, NA,
  "OK",  2006, 1, 0.35, NA,
  "RI",  2006, 1, 0.25, NA,
  "MO",  2013, 1, 0.25, NA,
  "NJ",  2019, 3, 0.30, NA,
  "FL",  2010, 3, 0.20, 2016,
  "CO",  2012, 1, 0.20, NA,
  "HI",  2006, 1, 0.20, NA,
  "MD",  2011, 3, 0.25, NA,
  "VA",  2011, 1, 0.15, NA,
  "OR",  2005, 1, 0.20, NA,
  "WV",  2007, 3, 0.27, NA,
  "NV",  2013, 3, 0.15, NA,
  "MN",  2012, 1, 0.25, NA,
  "TN",  2017, 1, 0.25, NA,
  "AL",  2009, 1, 0.25, NA,
  "MS",  2014, 1, 0.25, NA,
  "KY",  2009, 1, 0.20, NA,
  "AR",  2009, 1, 0.20, NA,
  "UT",  2004, 1, 0.20, NA,
  "WI",  2013, 1, 0.25, NA,
  "ME",  2006, 1, 0.12, NA,
  "MT",  2005, 1, 0.14, NA,
  "AZ",  2006, 1, 0.20, NA,
  "IN",  2008, 3, 0.15, NA
)

never_treated <- c("AK","CA","DE","ID","IA","KS","ND","NE","NH","SD","VT","WY","DC")

saveRDS(film_credits, "../data/film_credits.rds")
cat(sprintf("Film credit data: %d treated states, %d never-treated.\n",
            nrow(film_credits), length(never_treated)))

cat("\n=== DATA FETCH COMPLETE ===\n")
cat(sprintf("QWI rows: %d\n", nrow(qwi_raw)))
