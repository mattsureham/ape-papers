## 02_clean_data.R — Construct analysis panel
## apep_0976: Yakuza Exclusion Ordinances and Real Estate Markets

source("00_packages.R")
load("../data/raw_data.RData")

# ── 1. Pivot indicators wide ─────────────────────────────────────────
panel <- all_data %>%
  pivot_wider(
    id_cols = c(pref_code, fy),
    names_from = indicator,
    values_from = value
  )

cat("Panel dimensions:", nrow(panel), "rows x", ncol(panel), "cols\n")
cat("Year range:", min(panel$fy), "-", max(panel$fy), "\n")
cat("Prefectures:", n_distinct(panel$pref_code), "\n")

# ── 2. Merge YEO treatment dates ─────────────────────────────────────
panel <- panel %>%
  left_join(
    yeo_dates %>% select(pref_code, pref_name_en, yeo_date, first_treat),
    by = "pref_code"
  )

# Verify all prefectures matched
stopifnot("All prefectures must have YEO dates" =
            sum(is.na(panel$first_treat)) == 0)

# ── 3. Construct treatment variables ─────────────────────────────────
panel <- panel %>%
  mutate(
    # Binary treatment: =1 if YEO adopted in or before current year
    treated = as.integer(fy >= first_treat),
    # Event time: years since adoption (negative = pre-treatment)
    event_time = fy - first_treat,
    # Treatment cohort groups (for CS DiD)
    cohort = first_treat,
    # Early adopter dummy (FY2010 = 4 prefectures)
    early_adopter = as.integer(first_treat == 2010),
    # Tohoku earthquake indicator (March 2011)
    # Heavily affected: Iwate (03), Miyagi (04), Fukushima (07)
    tohoku_affected = as.integer(pref_code %in% c("03", "04", "07"))
  )

# ── 4. Construct outcome variables ───────────────────────────────────
panel <- panel %>%
  mutate(
    # Log land price (drop zeros/NAs before logging)
    log_land_price = ifelse(land_price_residential > 0,
                            log(land_price_residential), NA_real_),
    # Crime per capita (per 1000 population)
    crime_rate = ifelse(population > 0,
                        crime_reported / population * 1000, NA_real_),
    violent_crime_rate = ifelse(population > 0,
                                crime_violent / population * 1000, NA_real_),
    rough_crime_rate = ifelse(population > 0,
                              crime_rough / population * 1000, NA_real_),
    # Log building starts
    log_building_starts = ifelse(building_starts > 0,
                                 log(building_starts), NA_real_),
    # Numeric prefecture ID for fixed effects
    pref_id = as.integer(pref_code)
  )

# ── 5. Summary statistics ────────────────────────────────────────────
cat("\n=== Summary Statistics ===\n")
summ <- panel %>%
  filter(fy >= 2005, fy <= 2019) %>%
  summarise(
    across(c(land_price_residential, log_land_price, land_price_change_pct,
             building_starts, log_building_starts,
             crime_reported, crime_rate, violent_crime_rate, rough_crime_rate,
             population),
           list(mean = ~mean(.x, na.rm = TRUE),
                sd = ~sd(.x, na.rm = TRUE),
                min = ~min(.x, na.rm = TRUE),
                max = ~max(.x, na.rm = TRUE),
                n = ~sum(!is.na(.x))),
           .names = "{.col}__{.fn}")
  ) %>%
  pivot_longer(everything(),
               names_to = c("variable", "stat"),
               names_sep = "__") %>%
  pivot_wider(names_from = stat, values_from = value)

print(summ, n = 20)

# ── 6. Pre/post comparison ──────────────────────────────────────────
cat("\n=== Pre vs Post Treatment Means ===\n")
pre_post <- panel %>%
  filter(fy >= 2005, fy <= 2019) %>%
  group_by(treated) %>%
  summarise(
    mean_log_land = mean(log_land_price, na.rm = TRUE),
    mean_crime_rate = mean(crime_rate, na.rm = TRUE),
    mean_violent_rate = mean(violent_crime_rate, na.rm = TRUE),
    mean_building = mean(log_building_starts, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  )
print(pre_post)

# ── 7. Treatment group balance ───────────────────────────────────────
cat("\n=== Early vs Late Adopter Pre-Treatment Balance (2005-2009) ===\n")
balance <- panel %>%
  filter(fy >= 2005, fy <= 2009) %>%
  group_by(early_adopter) %>%
  summarise(
    mean_log_land = mean(log_land_price, na.rm = TRUE),
    mean_crime_rate = mean(crime_rate, na.rm = TRUE),
    mean_violent = mean(violent_crime_rate, na.rm = TRUE),
    mean_pop = mean(population, na.rm = TRUE) / 1e6,
    n_pref = n_distinct(pref_code),
    .groups = "drop"
  )
print(balance)

# ── 8. Save analysis panel ──────────────────────────────────────────
# Restrict to study period
analysis <- panel %>%
  filter(fy >= 2005, fy <= 2019)

cat("\n=== Analysis panel ===\n")
cat("Observations:", nrow(analysis), "\n")
cat("Prefectures:", n_distinct(analysis$pref_code), "\n")
cat("Years:", min(analysis$fy), "-", max(analysis$fy), "\n")
cat("Missing log_land_price:", sum(is.na(analysis$log_land_price)), "\n")
cat("Missing crime_rate:", sum(is.na(analysis$crime_rate)), "\n")

save(analysis, summ, yeo_dates, file = "../data/analysis_panel.RData")
cat("\n✓ Analysis panel saved to data/analysis_panel.RData\n")
