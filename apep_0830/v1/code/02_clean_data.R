## 02_clean_data.R — Construct analysis panel
## apep_0830: VAT Receipt Lotteries and Compliance Gaps

source("00_packages.R")

# --- Load raw data ---
vat_raw <- readRDS("../data/vat_revenue_raw.rds")
gdp_raw <- readRDS("../data/gdp_raw.rds")
income_tax_raw <- readRDS("../data/income_tax_raw.rds")
total_tax_raw <- readRDS("../data/total_tax_raw.rds")

# --- EU27 member states (as of 2020, excluding UK) ---
eu27 <- c("AT", "BE", "BG", "CY", "CZ", "DE", "DK", "EE", "EL", "ES",
           "FI", "FR", "HR", "HU", "IE", "IT", "LT", "LU", "LV", "MT",
           "NL", "PL", "PT", "RO", "SE", "SI", "SK")

# --- Clean VAT revenue ---
vat <- vat_raw |>
  filter(geo %in% eu27) |>
  select(geo, year = time, vat_meur = values) |>
  filter(!is.na(vat_meur), !is.na(year))

# --- Clean GDP ---
gdp <- gdp_raw |>
  filter(geo %in% eu27) |>
  select(geo, year = time, gdp_meur = values) |>
  filter(!is.na(gdp_meur), !is.na(year))

# --- Clean income tax ---
income_tax <- income_tax_raw |>
  filter(geo %in% eu27) |>
  select(geo, year = time, inc_tax_meur = values) |>
  filter(!is.na(inc_tax_meur), !is.na(year))

# --- Clean total tax on production ---
total_tax <- total_tax_raw |>
  filter(geo %in% eu27) |>
  select(geo, year = time, prod_tax_meur = values) |>
  filter(!is.na(prod_tax_meur), !is.na(year))

# --- Merge into panel ---
panel <- vat |>
  inner_join(gdp, by = c("geo", "year")) |>
  inner_join(income_tax, by = c("geo", "year")) |>
  inner_join(total_tax, by = c("geo", "year"))

# --- Construct outcome variables ---
panel <- panel |>
  mutate(
    vat_gdp_pct  = (vat_meur / gdp_meur) * 100,
    inc_tax_gdp_pct = (inc_tax_meur / gdp_meur) * 100,
    vat_share    = vat_meur / prod_tax_meur * 100
  )

# --- Treatment coding ---
# Receipt lottery adoption and cancellation dates (annual resolution)
# Treatment = 1 in years when lottery is active
lottery_events <- tribble(
  ~geo, ~start_year, ~end_year,
  "MT", 1997, NA,       # Malta — but pre-dates our panel
  "SK", 2013, 2020,     # Slovakia Sep 2013 - Feb 2021 (code 2020 as last full year)
  "PT", 2014, NA,       # Portugal e-Fatura
  "RO", 2015, NA,       # Romania
  "PL", 2015, 2016,     # Poland Oct 2015 - Mar 2017 (2016 last full year)
  "CZ", 2017, 2019,     # Czech Republic Oct 2017 - Apr 2020 (2019 last full year)
  "EL", 2017, NA,       # Greece (card payment incentives)
  "LV", 2019, 2022,     # Latvia Jul 2019 - Feb 2023 (2022 last full year)
  "LT", 2019, NA,       # Lithuania
  "IT", 2021, NA        # Italy
)

# Create treatment indicator for each country-year
panel <- panel |>
  left_join(
    lottery_events |> select(geo, start_year, end_year),
    by = "geo"
  ) |>
  mutate(
    lottery = case_when(
      is.na(start_year) ~ 0L,  # never-treated
      year < start_year ~ 0L,   # pre-treatment
      !is.na(end_year) & year > end_year ~ 0L,  # post-cancellation
      year >= start_year ~ 1L,  # active lottery
      TRUE ~ 0L
    ),
    # First treatment year (for CS-DiD, use Inf for never-treated)
    first_treat = case_when(
      is.na(start_year) ~ 0L,
      TRUE ~ as.integer(start_year)
    ),
    # Country numeric ID
    geo_id = as.integer(factor(geo))
  )

# --- Restrict to balanced panel years (2005-2022) ---
panel <- panel |>
  filter(year >= 2005, year <= 2022)

# --- Drop Malta from main sample (adopted in 1997, no pre-treatment period) ---
panel_main <- panel |> filter(geo != "MT")

# --- Validate ---
cat(sprintf("Panel: %d country-years (%d countries, %d years)\n",
    nrow(panel_main),
    n_distinct(panel_main$geo),
    n_distinct(panel_main$year)))
cat(sprintf("Treated country-years: %d\n", sum(panel_main$lottery == 1)))
cat(sprintf("Never-treated countries: %d\n",
    n_distinct(panel_main$geo[panel_main$first_treat == 0])))

stopifnot("Need at least 20 treated country-years" = sum(panel_main$lottery == 1) >= 20)
earliest_cohort <- min(panel_main$first_treat[panel_main$first_treat > 0])
n_pre_earliest <- earliest_cohort - min(panel_main$year)
cat(sprintf("Earliest cohort: %d, pre-periods: %d\n", earliest_cohort, n_pre_earliest))
stopifnot("Need at least 5 pre-periods for earliest cohort" = n_pre_earliest >= 5)

# --- Summary stats ---
cat("\n=== Summary Statistics ===\n")
cat(sprintf("VAT/GDP ratio: mean=%.2f, sd=%.2f, min=%.2f, max=%.2f\n",
    mean(panel_main$vat_gdp_pct), sd(panel_main$vat_gdp_pct),
    min(panel_main$vat_gdp_pct), max(panel_main$vat_gdp_pct)))

# Treated vs control means
treated_mean <- mean(panel_main$vat_gdp_pct[panel_main$lottery == 1])
control_mean <- mean(panel_main$vat_gdp_pct[panel_main$lottery == 0])
cat(sprintf("Mean VAT/GDP: treated=%.2f, control=%.2f\n",
    treated_mean, control_mean))

# --- Save ---
saveRDS(panel_main, "../data/panel_main.rds")
saveRDS(panel, "../data/panel_full.rds")
saveRDS(lottery_events, "../data/lottery_events.rds")

cat("\n=== Panel construction complete ===\n")
