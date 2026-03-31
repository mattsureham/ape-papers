## 02_clean_data.R — Clean and prepare data for SCM and DiD
## apep_1208: Ghana DDEP and Private Sector Credit

source("00_packages.R")

panel <- readRDS("../data/wdi_panel.rds")

## ---- Treatment definition ----
# Ghana DDEP announced December 5, 2022; bond exchange completed April 2023
# Treatment year = 2023 (first full year of impact)
treatment_year <- 2023

panel <- panel %>%
  mutate(
    treated = as.integer(iso3c == "GHA"),
    post = as.integer(year >= treatment_year),
    treat_post = treated * post
  )

## ---- Create numeric country ID for Synth package ----
country_ids <- panel %>%
  distinct(iso3c, country) %>%
  mutate(unit_id = row_number())

panel <- panel %>%
  left_join(country_ids, by = c("iso3c", "country"))

## ---- Interpolate sparse missing values for SCM predictors ----
# Only interpolate interior NAs (not extrapolate endpoints)
interpolate_interior <- function(x) {
  if (all(is.na(x))) return(x)
  first_obs <- min(which(!is.na(x)))
  last_obs <- max(which(!is.na(x)))
  if (first_obs == last_obs) return(x)
  interior <- first_obs:last_obs
  x[interior] <- approx(seq_along(x)[interior], x[interior],
                         xout = interior, rule = 1)$y
  x
}

panel <- panel %>%
  arrange(iso3c, year) %>%
  group_by(iso3c) %>%
  mutate(across(c(credit_gdp, npl_ratio, gdp_growth, inflation,
                  trade_gdp, govt_debt_gdp, gdp_pc, broad_money_gdp),
                interpolate_interior)) %>%
  ungroup()

## ---- Restrict to analysis period ----
# Pre-treatment: 2010-2022 (13 years)
# Post-treatment: 2023-2024
analysis <- panel %>%
  filter(year >= 2010, year <= 2024)

cat(sprintf("Analysis panel: %d country-years, %d countries, years %d-%d\n",
            nrow(analysis), n_distinct(analysis$iso3c),
            min(analysis$year), max(analysis$year)))

## ---- Summary statistics ----
cat("\nPre-treatment means (2010-2022):\n")
pre_means <- analysis %>%
  filter(year < treatment_year) %>%
  group_by(iso3c) %>%
  summarise(
    credit_gdp_mean = mean(credit_gdp, na.rm = TRUE),
    gdp_growth_mean = mean(gdp_growth, na.rm = TRUE),
    inflation_mean = mean(inflation, na.rm = TRUE),
    npl_mean = mean(npl_ratio, na.rm = TRUE),
    .groups = "drop"
  )
print(pre_means, n = 20)

## ---- Save cleaned data ----
saveRDS(analysis, "../data/analysis_panel.rds")
saveRDS(country_ids, "../data/country_ids.rds")

cat("\nCleaned data saved.\n")
cat("DONE: 02_clean_data.R\n")
