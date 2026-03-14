## 02_clean_data.R — Clean data and construct analysis panel
## apep_0666: EU smoking bans

source("code/00_packages.R")

emp_raw <- readRDS("data/emp_raw.rds")
hours_raw <- readRDS("data/hours_raw.rds")

cat("=== Cleaning data ===\n")

## ---- 1. Treatment coding: comprehensive smoking ban adoption years ----
ban_dates <- tribble(
  ~country, ~ban_year,
  "IE",     2004,   # Ireland: March 2004
  "NO",     2004,   # Norway: June 2004
  "IT",     2005,   # Italy: January 2005
  "SE",     2005,   # Sweden: June 2005
  "BE",     2007,   # Belgium: January 2007
  "DK",     2007,   # Denmark: August 2007
  "UK",     2007,   # UK: July 2007 (England)
  "DE",     2008,   # Germany: 2007-2008 (state-level, most by 2008)
  "FR",     2008,   # France: January 2008 (restaurants/bars)
  "NL",     2008,   # Netherlands: July 2008
  "PT",     2008,   # Portugal: January 2008
  "FI",     2008,   # Finland: June 2007 (effective 2008)
  "EL",     2010,   # Greece: July 2009 (enforced 2010)
  "PL",     2010,   # Poland: November 2010
  "ES",     2011,   # Spain: January 2011
  "HU",     2012,   # Hungary: January 2012
  "CZ",     2017,   # Czech Republic: May 2017
  "AT",     2019    # Austria: November 2019
)

cat("Treated countries:", nrow(ban_dates), "\n")

## ---- 2. Clean employment data ----
emp <- emp_raw %>%
  select(country = geo, year = TIME_PERIOD, sector = nace_r2,
         employment = OBS_VALUE) %>%
  filter(!is.na(employment)) %>%
  mutate(year = as.integer(year))

# Keep only standard countries (2-letter codes, not aggregates)
emp <- emp %>% filter(nchar(country) == 2)

cat("Countries in data:", paste(sort(unique(emp$country)), collapse=", "), "\n")

## ---- 3. Clean hours data ----
hours <- hours_raw %>%
  select(country = geo, year = TIME_PERIOD, sector = nace_r2,
         hours = OBS_VALUE) %>%
  filter(!is.na(hours), nchar(country) == 2) %>%
  mutate(year = as.integer(year))

## ---- 4. Construct panel ----
# Focus on hospitality (G-I = trade/transport/hospitality)
# Note: NACE A*10 doesn't separate I from G-I. G-I includes:
# G: Wholesale/retail, H: Transport/storage, I: Accommodation/food
# This is our best available sector grouping. The treatment effect
# should still be detectable as hospitality (I) is a major component.

panel <- emp %>%
  left_join(ban_dates, by = "country") %>%
  mutate(
    treated = as.integer(!is.na(ban_year)),
    post = as.integer(!is.na(ban_year) & year >= ban_year),
    treat_post = treated * post,

    # For CS-DiD
    first_treat = ifelse(!is.na(ban_year), ban_year, 0),

    # Log outcome
    ln_emp = log(employment),

    # Hospitality indicator (our treatment sector)
    hospitality = as.integer(sector == "G-I"),

    # Triple-diff interaction
    triple_did = treat_post * hospitality,

    # Relative time
    rel_year = ifelse(!is.na(ban_year), year - ban_year, NA),

    # Country ID for CS-DiD
    country_id = as.integer(as.factor(country))
  )

# Add hours per worker
panel <- panel %>%
  left_join(hours, by = c("country", "year", "sector")) %>%
  mutate(
    hours_pw = ifelse(!is.na(hours) & employment > 0, hours / employment, NA),
    ln_hours_pw = ifelse(!is.na(hours_pw) & hours_pw > 0, log(hours_pw), NA)
  )

## ---- 5. Employment shares (for DDD) ----
# Compute hospitality share of total employment
total_emp <- panel %>%
  filter(sector == "TOTAL") %>%
  select(country, year, total_emp = employment)

panel <- panel %>%
  left_join(total_emp, by = c("country", "year")) %>%
  mutate(emp_share = employment / total_emp)

## ---- Summary ----
cat("\n=== Panel summary ===\n")
cat("Rows:", nrow(panel), "\n")
cat("Countries:", length(unique(panel$country)), "\n")
cat("Treated:", length(unique(panel$country[panel$treated == 1])), "\n")
cat("Never-treated:", length(unique(panel$country[panel$treated == 0])), "\n")
cat("Years:", paste(range(panel$year), collapse="-"), "\n")
cat("Sectors:", paste(sort(unique(panel$sector)), collapse=", "), "\n")

saveRDS(panel, "data/panel.rds")
cat("Panel saved.\n")
