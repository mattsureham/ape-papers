## 02_clean_data.R — Clean and prepare World Bank panel
## APEP Working Paper apep_1323

source("00_packages.R")

data_dir <- "../data/"

## Load World Bank panel
wb <- readRDS(file.path(data_dir, "wb_panel.rds"))

cat(sprintf("Raw panel: %d obs, %d countries\n", nrow(wb), n_distinct(wb$country)))

## Rename indicators for readability
wb <- wb %>%
  rename(
    atm_per_100k = FB.ATM.TOTL.P5,
    branches_per_100k = FB.CBK.BRCH.P5,
    tax_rev_gdp = GC.TAX.TOTL.GD.ZS,
    rev_ex_grants_gdp = GC.REV.XGRT.GD.ZS,
    gdp_growth = NY.GDP.MKTP.KD.ZG,
    gdp_pc = NY.GDP.PCAP.KD,
    inflation = FP.CPI.TOTL.ZG,
    population = SP.POP.TOTL,
    mobile_subs = IT.CEL.SETS.P2,
    internet_pct = IT.NET.USER.ZS
  )

## Country names
wb <- wb %>%
  mutate(country_label = case_when(
    country == "NG" ~ "Nigeria",
    country == "GH" ~ "Ghana",
    country == "KE" ~ "Kenya",
    country == "ZA" ~ "South Africa",
    country == "TZ" ~ "Tanzania",
    country == "SN" ~ "Senegal",
    country == "CM" ~ "Cameroon",
    country == "ET" ~ "Ethiopia",
    country == "UG" ~ "Uganda",
    country == "CI" ~ "Côte d'Ivoire",
    country == "RW" ~ "Rwanda",
    country == "MZ" ~ "Mozambique",
    country == "ZM" ~ "Zambia",
    country == "BW" ~ "Botswana",
    TRUE ~ country
  ))

## Create numeric country ID for fixest
wb <- wb %>%
  mutate(country_id = as.integer(factor(country)))

## Treatment variables
wb <- wb %>%
  mutate(
    nigeria = as.integer(country == "NG"),
    post = as.integer(year >= 2012),
    treat = nigeria * post,
    ## Event time (relative to 2012)
    event_time = year - 2012,
    ## For CS estimator: first_treat (Nigeria=2012, all others=0 for never-treated)
    first_treat = ifelse(country == "NG", 2012L, 0L)
  )

## Check data coverage for key outcomes
cat("\n=== Data Coverage ===\n")
for (var in c("atm_per_100k", "branches_per_100k", "tax_rev_gdp")) {
  coverage <- wb %>%
    filter(!is.na(.data[[var]])) %>%
    group_by(country_label) %>%
    summarise(
      n_years = n(),
      year_min = min(year),
      year_max = max(year),
      .groups = "drop"
    )
  cat(sprintf("\n%s: %d countries with data\n", var, nrow(coverage)))
  print(as.data.frame(coverage), row.names = FALSE)
}

## Keep only countries with adequate ATM data (our primary outcome)
## Need at least 3 pre-treatment years (2009-2011) and 3 post (2012-2014)
adequate <- wb %>%
  filter(!is.na(atm_per_100k)) %>%
  group_by(country) %>%
  summarise(
    n_pre = sum(year < 2012),
    n_post = sum(year >= 2012),
    .groups = "drop"
  ) %>%
  filter(n_pre >= 3, n_post >= 3)

cat(sprintf("\nCountries with adequate ATM data: %d\n", nrow(adequate)))
print(adequate)

panel <- wb %>%
  filter(country %in% adequate$country)

## Log outcomes (add small constant for zeros)
panel <- panel %>%
  mutate(
    log_atm = log(atm_per_100k + 0.1),
    log_branches = log(branches_per_100k + 0.1),
    log_gdp_pc = log(gdp_pc)
  )

## Summary statistics
cat("\n=== Summary Statistics ===\n")
summ <- panel %>%
  group_by(nigeria = ifelse(nigeria == 1, "Nigeria", "Controls")) %>%
  summarise(
    across(c(atm_per_100k, branches_per_100k, tax_rev_gdp,
             gdp_growth, gdp_pc, mobile_subs, internet_pct),
           list(mean = ~mean(.x, na.rm = TRUE),
                sd = ~sd(.x, na.rm = TRUE)),
           .names = "{.col}_{.fn}"),
    n = n(),
    .groups = "drop"
  )
print(t(summ))

## Nigeria time series for primary outcomes
nga <- panel %>% filter(country == "NG") %>% arrange(year)
cat("\n=== Nigeria ATMs per 100k over time ===\n")
print(nga %>% select(year, atm_per_100k, branches_per_100k, tax_rev_gdp, gdp_growth))

saveRDS(panel, file.path(data_dir, "panel_clean.rds"))
cat(sprintf("\nClean panel saved: %d obs, %d countries, years %d-%d\n",
            nrow(panel), n_distinct(panel$country),
            min(panel$year), max(panel$year)))

## Save states_waves for reference (original idea design)
states_waves <- readRDS(file.path(data_dir, "states_waves.rds"))
cat(sprintf("States wave data: %d states\n", nrow(states_waves)))
