## 01_fetch_data.R — Download state-year natality panel from Kids Count Data Center
## apep_0610: The Marginal Birth
##
## Downloads pre-aggregated state-year natality statistics from the Annie E.
## Casey Foundation's Kids Count Data Center (datacenter.aecf.org).
## Source data: CDC National Vital Statistics System (NVSS).
##
## Indicators downloaded:
##   6052  Total births
##   18    Preterm births (gestational age < 37 weeks)
##   5425  Low birth weight births (< 2,500 grams)
##   6053  Total teen births (mothers age 15-19)
##   7     Births to unmarried women

library(data.table)
library(readxl)

options(timeout = 300)

# ---- Kids Count indicator definitions ----
indicators <- list(
  list(id = 6052,  name = "total_births",    format = "Number"),
  list(id = 18,    name = "preterm",          format = "Number"),
  list(id = 5425,  name = "lbw",             format = "Number"),
  list(id = 6053,  name = "teen",            format = "Number"),
  list(id = 7,     name = "unmarried",       format = "Number")
)

# Also download percent/rate versions for cross-checking
indicators_pct <- list(
  list(id = 18,    name = "preterm_pct",      format = "Percent"),
  list(id = 5425,  name = "lbw_pct",         format = "Percent"),
  list(id = 7,     name = "unmarried_pct",   format = "Percent"),
  list(id = 6053,  name = "teen_rate",       format = "Rate per 1,000")
)

kc_url <- function(ind_id) {
  sprintf("https://datacenter.aecf.org/rawdata.axd?ind=%d&loc=1", ind_id)
}

# ---- Download and parse one indicator ----
fetch_indicator <- function(ind, target_format) {
  url <- kc_url(ind$id)
  dest <- tempfile(fileext = ".xlsx")

  cat(sprintf("Downloading %s (ind=%d)...\n", ind$name, ind$id))
  download.file(url, dest, mode = "wb", quiet = TRUE)

  dt <- as.data.table(read_excel(dest))
  file.remove(dest)

  # Filter: states + DC (DC is coded as "City" in Kids Count), target format, 2016-2023
  dt <- dt[(LocationType == "State" | Location == "District of Columbia") &
           DataFormat == target_format]
  dt[, year := as.integer(TimeFrame)]
  dt <- dt[year >= 2016 & year <= 2023]
  dt[, value := as.numeric(Data)]

  # Standardize state names
  dt[, state_name := Location]

  result <- dt[, .(state_name, year, value)]
  setnames(result, "value", ind$name)

  cat(sprintf("  %s: %d state-year obs, years %d-%d\n",
              ind$name, nrow(result),
              min(result$year), max(result$year)))

  return(result)
}

# ---- Download all indicators ----
cat("=== Downloading Kids Count natality indicators ===\n\n")

# Download count data
all_counts <- lapply(indicators, function(ind) {
  fetch_indicator(ind, ind$format)
})

# Merge into panel
panel <- all_counts[[1]]
for (i in 2:length(all_counts)) {
  panel <- merge(panel, all_counts[[i]], by = c("state_name", "year"), all = TRUE)
}

# Download percent/rate data for cross-checking
cat("\nDownloading percent/rate versions for validation...\n")
all_pcts <- lapply(indicators_pct, function(ind) {
  fetch_indicator(ind, ind$format)
})

for (pct_dt in all_pcts) {
  panel <- merge(panel, pct_dt, by = c("state_name", "year"), all.x = TRUE)
}

# ---- Add state abbreviations ----
state_xwalk <- data.table(
  state_name = c("Alabama","Alaska","Arizona","Arkansas","California",
                 "Colorado","Connecticut","Delaware","District of Columbia","Florida",
                 "Georgia","Hawaii","Idaho","Illinois","Indiana",
                 "Iowa","Kansas","Kentucky","Louisiana","Maine",
                 "Maryland","Massachusetts","Michigan","Minnesota","Mississippi",
                 "Missouri","Montana","Nebraska","Nevada","New Hampshire",
                 "New Jersey","New Mexico","New York","North Carolina","North Dakota",
                 "Ohio","Oklahoma","Oregon","Pennsylvania","Rhode Island",
                 "South Carolina","South Dakota","Tennessee","Texas","Utah",
                 "Vermont","Virginia","Washington","West Virginia","Wisconsin","Wyoming"),
  state_abbr = c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL",
                 "GA","HI","ID","IL","IN","IA","KS","KY","LA","ME",
                 "MD","MA","MI","MN","MS","MO","MT","NE","NV","NH",
                 "NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI",
                 "SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY"),
  state_fips = c(1,2,4,5,6,8,9,10,11,12,
                 13,15,16,17,18,19,20,21,22,23,
                 24,25,26,27,28,29,30,31,32,33,
                 34,35,36,37,38,39,40,41,42,44,
                 45,46,47,48,49,50,51,53,54,55,56)
)

panel <- merge(panel, state_xwalk, by = "state_name", all.x = TRUE)

# ---- Calculate shares from count data ----
panel[, `:=`(
  preterm_share   = preterm / total_births,
  lbw_share       = lbw / total_births,
  teen_share      = teen / total_births,
  unmarried_share = unmarried / total_births
)]

# ---- Validate against percent data ----
cat("\n=== Cross-validation: computed vs. reported shares ===\n")
# Preterm: our computed share vs. KidsCount percent
panel[!is.na(preterm_pct) & !is.na(preterm_share), {
  diff <- abs(preterm_share - preterm_pct)
  cat(sprintf("  Preterm: max abs diff = %.4f, mean abs diff = %.4f\n",
              max(diff), mean(diff)))
}]
panel[!is.na(lbw_pct) & !is.na(lbw_share), {
  diff <- abs(lbw_share - lbw_pct)
  cat(sprintf("  LBW: max abs diff = %.4f, mean abs diff = %.4f\n",
              max(diff), mean(diff)))
}]
panel[!is.na(unmarried_pct) & !is.na(unmarried_share), {
  diff <- abs(unmarried_share - unmarried_pct)
  cat(sprintf("  Unmarried: max abs diff = %.4f, mean abs diff = %.4f\n",
              max(diff), mean(diff)))
}]

# ---- Assertions ----
stopifnot("Missing state abbreviations" = !any(is.na(panel$state_abbr)))
stopifnot("Panel has 51 states+DC" = uniqueN(panel$state_abbr) == 51)
stopifnot("Panel years 2016-2023" = all(panel$year %in% 2016:2023))
n_sy <- nrow(panel)
cat(sprintf("\nAssertions passed. Panel: %d state-year obs\n", n_sy))
stopifnot("Expected ~408 obs (51 x 8)" = n_sy >= 350 & n_sy <= 420)

# ---- Keep analysis columns and save ----
keep_cols <- c("state_name", "state_abbr", "state_fips", "year",
               "total_births", "preterm", "lbw", "teen", "unmarried",
               "preterm_share", "lbw_share", "teen_share", "unmarried_share")
panel <- panel[, ..keep_cols]
setorder(panel, state_abbr, year)

dir.create("data", showWarnings = FALSE)
fwrite(panel, "data/natality_panel.csv")
cat(sprintf("\nSaved: data/natality_panel.csv (%d rows)\n", nrow(panel)))

# ---- Summary ----
cat("\n=== DATA SUMMARY ===\n")
cat(sprintf("Years: %d-%d\n", min(panel$year), max(panel$year)))
cat(sprintf("States: %d\n", uniqueN(panel$state_abbr)))
cat(sprintf("Total observations: %d\n", nrow(panel)))
cat(sprintf("Total births (sum): %s\n", format(sum(panel$total_births, na.rm = TRUE), big.mark = ",")))
cat("\nOutcome means (full sample):\n")
cat(sprintf("  Preterm share: %.4f\n", mean(panel$preterm_share, na.rm = TRUE)))
cat(sprintf("  LBW share: %.4f\n", mean(panel$lbw_share, na.rm = TRUE)))
cat(sprintf("  Teen share: %.4f\n", mean(panel$teen_share, na.rm = TRUE)))
cat(sprintf("  Unmarried share: %.4f\n", mean(panel$unmarried_share, na.rm = TRUE)))
