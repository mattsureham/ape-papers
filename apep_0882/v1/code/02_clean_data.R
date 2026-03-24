## 02_clean_data.R — Construct county-year panel for apep_0882
## Merges: CDC drug OD mortality + CBP oil/gas employment + FRED oil prices

library(tidyverse)
library(data.table)

data_dir <- file.path(dirname(getwd()), "data")

cat("=== 1. Clean CDC Drug Poisoning Data ===\n")

mort <- fread(file.path(data_dir, "cdc_drug_poisoning_raw.csv"))

# Convert categorical ranges to midpoints
# Categories: "0-2", "2.1-4", "4.1-6", ..., "28.1-30", ">30"
mort <- mort %>%
  mutate(
    rate_cat = estimated_age_adjusted_death_rate_11_categories_in_ranges,
    drug_od_rate = case_when(
      rate_cat == "0-2"     ~ 1.0,
      rate_cat == "2.1-4"   ~ 3.05,
      rate_cat == "4.1-6"   ~ 5.05,
      rate_cat == "6.1-8"   ~ 7.05,
      rate_cat == "8.1-10"  ~ 9.05,
      rate_cat == "10.1-12" ~ 11.05,
      rate_cat == "12.1-14" ~ 13.05,
      rate_cat == "14.1-16" ~ 15.05,
      rate_cat == "16.1-18" ~ 17.05,
      rate_cat == "18.1-20" ~ 19.05,
      rate_cat == "20.1-22" ~ 21.05,
      rate_cat == "22.1-24" ~ 23.05,
      rate_cat == "24.1-26" ~ 25.05,
      rate_cat == "26.1-28" ~ 27.05,
      rate_cat == "28.1-30" ~ 29.05,
      rate_cat == ">30"     ~ 34.0,  # Conservative top-code midpoint
      TRUE ~ NA_real_
    ),
    year = as.integer(year),
    population = as.numeric(population),
    fips = as.character(fips)
  ) %>%
  # Pad FIPS to 5 digits
  mutate(fips = str_pad(fips, 5, pad = "0")) %>%
  select(fips, year, state_name = state, county_name = county,
         population, drug_od_rate, rate_cat)

cat("  Mortality panel:", nrow(mort), "county-years\n")
cat("  Missing rates:", sum(is.na(mort$drug_od_rate)), "\n")
cat("  Rate distribution:\n")
print(summary(mort$drug_od_rate))

# Create state FIPS from county FIPS
mort <- mort %>%
  mutate(state_fips = substr(fips, 1, 2))


cat("\n=== 2. Construct Shale County Indicator from CBP ===\n")

cbp_211 <- fread(file.path(data_dir, "cbp_naics211_counties.csv"))
cbp_tot <- fread(file.path(data_dir, "cbp_total_counties.csv"))

# Clean CBP oil/gas data
cbp_211 <- cbp_211 %>%
  mutate(
    fips = str_pad(fips, 5, pad = "0"),
    emp_211 = as.numeric(EMP),
    estab_211 = as.numeric(ESTAB),
    year = as.integer(year)
  ) %>%
  select(fips, year, emp_211, estab_211)

# Clean CBP total employment
cbp_tot <- cbp_tot %>%
  mutate(
    fips = str_pad(fips, 5, pad = "0"),
    emp_total = as.numeric(EMP),
    year = as.integer(year)
  ) %>%
  select(fips, year, emp_total)

# Pre-boom average (2001-2004): oil/gas employment share
preboom <- cbp_211 %>%
  filter(year >= 2001, year <= 2004) %>%
  group_by(fips) %>%
  summarise(
    avg_emp_211 = mean(emp_211, na.rm = TRUE),
    avg_estab_211 = mean(estab_211, na.rm = TRUE),
    years_with_211 = n(),
    .groups = "drop"
  )

preboom_total <- cbp_tot %>%
  filter(year >= 2001, year <= 2004) %>%
  group_by(fips) %>%
  summarise(avg_emp_total = mean(emp_total, na.rm = TRUE), .groups = "drop")

# Merge to compute employment share
shale_class <- preboom %>%
  left_join(preboom_total, by = "fips") %>%
  mutate(
    oil_share = avg_emp_211 / avg_emp_total,
    oil_share = ifelse(is.na(oil_share) | is.infinite(oil_share), 0, oil_share),
    # Binary treatment: county had ANY oil/gas extraction in pre-boom period
    has_oil = 1L,
    # Establishment-based intensity (avoids employment suppression issues)
    log_estab = log1p(avg_estab_211)
  )

# All counties in the mortality panel that are NOT in CBP 211 have zero oil/gas
all_counties <- mort %>%
  distinct(fips) %>%
  left_join(shale_class, by = "fips") %>%
  mutate(
    has_oil = replace_na(has_oil, 0L),
    oil_share = replace_na(oil_share, 0),
    avg_estab_211 = replace_na(avg_estab_211, 0),
    log_estab = replace_na(log_estab, 0),
    avg_emp_211 = replace_na(avg_emp_211, 0),
    avg_emp_total = replace_na(avg_emp_total, 0)
  )

cat("  Counties with oil/gas extraction:", sum(all_counties$has_oil == 1), "\n")
cat("  Counties without:", sum(all_counties$has_oil == 0), "\n")
cat("  Oil employment share distribution (among oil counties):\n")
print(summary(all_counties$oil_share[all_counties$has_oil == 1]))

# High oil/gas: top quartile of establishment count among oil counties
estab_q75 <- quantile(all_counties$avg_estab_211[all_counties$has_oil == 1], 0.75)
all_counties <- all_counties %>%
  mutate(high_oil = as.integer(avg_estab_211 >= estab_q75 & has_oil == 1))

cat("  High oil/gas counties (top quartile estab):", sum(all_counties$high_oil), "\n")


cat("\n=== 3. Merge Oil Prices ===\n")

oil <- fread(file.path(data_dir, "fred_wti_annual.csv"))
cat("  Oil price panel: ", nrow(oil), " years\n")
cat("  Key years: 2004=$", oil$wti_price[oil$year == 2004],
    ", 2008=$", oil$wti_price[oil$year == 2008],
    ", 2015=$", oil$wti_price[oil$year == 2015], "\n")


cat("\n=== 4. Construct Final Panel ===\n")

panel <- mort %>%
  left_join(all_counties %>% select(fips, has_oil, oil_share, avg_estab_211,
                                     log_estab, high_oil, avg_emp_total),
            by = "fips") %>%
  left_join(oil, by = "year") %>%
  mutate(
    # Period indicators
    period = case_when(
      year <= 2004 ~ "pre_boom",
      year <= 2014 ~ "boom",
      TRUE         ~ "bust"
    ),
    boom = as.integer(year >= 2005 & year <= 2014),
    bust = as.integer(year >= 2015),
    post = as.integer(year >= 2005),
    # Log oil price for continuous treatment
    log_wti = log(wti_price),
    # Interaction terms
    oil_x_boom = oil_share * boom,
    oil_x_bust = oil_share * bust,
    oil_x_post = oil_share * post,
    estab_x_boom = log_estab * boom,
    estab_x_bust = log_estab * bust,
    has_oil_x_boom = has_oil * boom,
    has_oil_x_bust = has_oil * bust
  )

cat("  Final panel: ", nrow(panel), " county-years\n")
cat("  Counties: ", length(unique(panel$fips)), "\n")
cat("  Years: ", min(panel$year), "-", max(panel$year), "\n")

# Summary by period and oil status
panel %>%
  group_by(period, has_oil) %>%
  summarise(
    n = n(),
    mean_rate = mean(drug_od_rate, na.rm = TRUE),
    sd_rate = sd(drug_od_rate, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(period, has_oil) %>%
  print()

fwrite(panel, file.path(data_dir, "panel.csv"))
cat("\n  Saved panel.csv\n")

cat("\n=== Panel construction complete ===\n")
