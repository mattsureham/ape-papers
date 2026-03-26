# 01_fetch_data.R — Fetch HMDA data from CFPB Data Browser API
# apep_1026: Marijuana legalization and FHA mortgage exclusion
# Strategy: fetch per-state per-year to keep downloads manageable

source("00_packages.R")

# ============================================================
# Treatment timing
# ============================================================
treatment <- data.table(
  state_code = c("CO", "WA", "AK", "OR", "DC",
                 "CA", "NV", "ME", "MA",
                 "VT", "MI",
                 "IL",
                 "AZ", "MT", "NJ",
                 "NY", "NM", "CT", "VA",
                 "RI", "MD", "MO",
                 "DE", "MN", "OH"),
  legalization_year = c(2012L, 2012L, 2014L, 2014L, 2014L,
                        2016L, 2016L, 2016L, 2016L,
                        2018L, 2018L,
                        2019L,
                        2020L, 2020L, 2020L,
                        2021L, 2021L, 2021L, 2021L,
                        2022L, 2022L, 2022L,
                        2023L, 2023L, 2023L)
)

all_states <- c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL",
                "GA","HI","ID","IL","IN","IA","KS","KY","LA","ME",
                "MD","MA","MI","MN","MS","MO","MT","NE","NV","NH",
                "NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI",
                "SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY")

# ============================================================
# Fetch per-state per-year, aggregate immediately
# ============================================================
cat("Fetching HMDA purchase originations 2018-2023 (per-state)...\n")

fetch_state_year <- function(st, yr) {
  url <- glue("https://ffiec.cfpb.gov/v2/data-browser-api/view/csv?",
              "states={st}&years={yr}&actions_taken=1&loan_purposes=1")

  resp <- GET(url, timeout(120))

  if (status_code(resp) != 200) {
    cat(glue("  WARNING: {st}/{yr} returned {status_code(resp)}\n\n"))
    return(NULL)
  }

  raw <- content(resp, as = "text", encoding = "UTF-8")
  if (nchar(raw) < 100) {
    cat(glue("  WARNING: {st}/{yr} empty response\n\n"))
    return(NULL)
  }

  dt <- fread(text = raw, select = c("loan_type", "income", "interest_rate"))

  # Aggregate immediately
  data.table(
    state = st,
    year = yr,
    n_total = nrow(dt),
    n_conventional = sum(dt$loan_type == 1),
    n_fha = sum(dt$loan_type == 2),
    n_va = sum(dt$loan_type == 3),
    n_usda = sum(dt$loan_type == 4),
    mean_income_conv = mean(as.numeric(dt$income[dt$loan_type == 1]), na.rm = TRUE),
    mean_income_fha = mean(as.numeric(dt$income[dt$loan_type == 2]), na.rm = TRUE),
    mean_rate_conv = mean(as.numeric(dt$interest_rate[dt$loan_type == 1]), na.rm = TRUE),
    mean_rate_fha = mean(as.numeric(dt$interest_rate[dt$loan_type == 2]), na.rm = TRUE)
  )
}

# Build all state-year combinations
combos <- expand.grid(state = all_states, year = 2018:2023, stringsAsFactors = FALSE)

results_list <- vector("list", nrow(combos))
for (i in seq_len(nrow(combos))) {
  st <- combos$state[i]
  yr <- combos$year[i]
  if (i %% 51 == 1) cat(glue("\n--- Year {yr} ---\n\n"))
  if (i %% 10 == 0) cat(glue("  {st}/{yr} ({i}/{nrow(combos)})...\n\n"))

  results_list[[i]] <- tryCatch(
    fetch_state_year(st, yr),
    error = function(e) {
      cat(glue("  ERROR: {st}/{yr}: {e$message}\n\n"))
      NULL
    }
  )

  # Brief pause to be polite to API
  if (i %% 20 == 0) Sys.sleep(1)
}

state_year <- rbindlist(Filter(function(x) !is.null(x), results_list))

stopifnot(nrow(state_year) > 200)  # Should have ~306 state-year obs

# ============================================================
# Compute shares
# ============================================================
state_year[, `:=`(
  fha_share = n_fha / n_total,
  va_share = n_va / n_total,
  conventional_share = n_conventional / n_total,
  usda_share = n_usda / n_total,
  govt_share = (n_fha + n_va + n_usda) / n_total
)]

# Merge treatment timing
state_year <- merge(state_year, treatment, by.x = "state", by.y = "state_code", all.x = TRUE)

# Never-treated: legalization_year stays NA
state_year[, `:=`(
  treated = as.integer(!is.na(legalization_year)),
  post = as.integer(!is.na(legalization_year) & year >= legalization_year),
  rel_year = fifelse(is.na(legalization_year), NA_integer_, year - legalization_year),
  cohort = fifelse(is.na(legalization_year), 0L, as.integer(legalization_year)),
  always_treated = as.integer(!is.na(legalization_year) & legalization_year <= 2018L)
)]

# ============================================================
# Summary
# ============================================================
cat("\n=== Panel Summary ===\n")
cat(glue("Observations: {nrow(state_year)}\n"))
cat(glue("States: {uniqueN(state_year$state)}\n"))
cat(glue("Years: {min(state_year$year)}-{max(state_year$year)}\n"))
cat(glue("Total loans: {format(sum(state_year$n_total), big.mark=',')}\n"))
cat(glue("Ever-treated: {uniqueN(state_year[treated == 1]$state)}\n"))
cat(glue("Never-treated: {uniqueN(state_year[treated == 0]$state)}\n"))
cat(glue("Always-treated (excluded from CS): {uniqueN(state_year[always_treated == 1]$state)}\n"))
cat(glue("Newly-treated 2019-2023: {uniqueN(state_year[treated == 1 & always_treated == 0]$state)}\n\n"))

cat("Mean FHA share by group:\n")
print(state_year[, .(mean_fha = round(mean(fha_share)*100, 1),
                      sd_fha = round(sd(fha_share)*100, 1),
                      n = .N), by = treated])

cat("\nFHA share by year:\n")
print(state_year[, .(mean_fha = round(mean(fha_share)*100, 1)), by = year][order(year)])

# ============================================================
# Save
# ============================================================
fwrite(state_year, "../data/state_year_panel.csv")
fwrite(treatment, "../data/treatment_timing.csv")

cat("\nData saved. Ready for analysis.\n")
